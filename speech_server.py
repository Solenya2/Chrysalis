#!/usr/bin/env python3
import os, sys, json, asyncio, re, math, collections
import websockets
import sounddevice as sd
import audioop  # NOTE: deprecated in Py3.13+, fine for now
from vosk import Model, KaldiRecognizer
from time import monotonic
from typing import Optional, Dict, Any, List

# =========================
# Config
# =========================
HOST = "localhost"
PORT = 8765

SAMPLE_RATE = 16000
BLOCKSIZE   = 3200                 # ~0.2s frames (more responsive)
SILENCE_RMS = 1100                 # tweak 900–1500 depending on room noise
END_SILENCE_SEC = 0.6              # quiet duration that forces a final (seg boundary)

MIN_GAP_BETWEEN_FINALS = 1.5       # debounce same-final repeats from Vosk (s)
SERVER_COOLDOWN        = 1.2       # prevent rapid-fire commands (s)

UNMATCHED_LOG = os.path.join(os.path.dirname(__file__), "unmatched_phrases.txt")

# =========================
# Grammar (command mode)
# =========================
GRAMMAR = [
    # English
    "boom boom", "bad game", "this game sucks",
    "bedroom player", "boss level one", "corruption level",
    "i challenge you to a rap battle",
    "candy world", "slime world", "neutral world",
    "play mozart", "mute sound", "summon", "pizza", "help", "kill them", "i love you", "please stop", "pretty please stop", "stop", "you're pretty", 

    # Norwegian phonetics / variants
    "dorlee spill", "detta spillet soooger", "so verom spiller",
    "shef nivoh en", "korrup shon nivoh", "yai oodforrer dai til en rap battle",
    "gottery verden", "sleem verden", "noytral verden",
    "spill mozart", "demp leeden", "pawkalle",

    # Finnish phonetics
    "huo no pelli", "tama peli on pasca", "makoo hoo one pelaya",
    "pomo taso ooksi", "korrup shun taso", "haastan sinut rap taisteloon",
    "karki ma il ma", "leema ma il ma", "neutrahli ma il ma",
    "soita mozartia", "mykista aani", "kutsua",

    # Sámi phonetics
    "heyoss spelloo", "dat spelloo ee let buorre", "songut spelloo",
    "bassi dassi okta", "korup shuvna dassi", "valdan du rahpat dakon",
    "goddi mailbmi", "sleema mailbmi", "neutraala mailbmi",
    "chohpa mozart", "yoga yietna", "chokket",

    # German phonetics
    "shlek tes shpeel", "dee zes shpeel ist shlekt", "shlaf tseemer shpeeler",
    "boss level ayns", "ko rup tsee ons shtoo feh", "ikh for der uh dikh tsu rap betl",
    "bon bon velt", "shlime velt", "noy trah le velt",
    "shpeel mozart", "shtoom shal ten", "besh vuren",

    # Spanish phonetics
    "hweh go malo", "es te hweh go a pes ta", "hoo ga dor del dor mee toh rio",
    "nee vel he feh oo no", "nee vel de ko rup see on", "te deh sa fee oh a oo na ba tah ya de rap",
    "moon do de dool sess", "moon do de slaym", "moon do new tral",
    "toh ka mozart", "see len see ah el so nee do", "een vo car",

    # Allow recognizer to decline instead of forcing a match
    "[unk]",
]
_PHRASES = [p for p in GRAMMAR if p != "[unk]"]

# =========================
# PyInstaller support
# =========================
if hasattr(sys, "_MEIPASS"):
    os.environ["VOSK_LIBRARY_PATH"] = os.path.join(sys._MEIPASS, "vosk")

def data_path(*parts: str) -> str:
    if getattr(sys, 'frozen', False) and hasattr(sys, "_MEIPASS"):
        return os.path.join(sys._MEIPASS, *parts)
    return os.path.join(os.path.dirname(__file__), *parts)

MODEL_CANDIDATES = [
    data_path('vosk_models', 'vosk-model-small-en-us-0.15'),
    os.path.join(os.path.dirname(sys.argv[0]), 'vosk_models', 'vosk-model-small-en-us-0.15'),
    os.path.join(os.path.dirname(sys.argv[0]), '_internal', 'vosk_models', 'vosk-model-small-en-us-0.15'),
]
MODEL_DIR = next((p for p in MODEL_CANDIDATES if os.path.exists(p)), None)
if not MODEL_DIR:
    raise RuntimeError("Vosk model not found. Looked in:\n  " + "\n  ".join(MODEL_CANDIDATES))

# =========================
# Init recognizers
# - recognizer_cmd: grammar-locked for exact phrases
# - recognizer_free: open dictation for freestyle rap windows
# =========================
print("🔧 Loading Vosk model from:", MODEL_DIR)
model = Model(MODEL_DIR)
recognizer_cmd  = KaldiRecognizer(model, SAMPLE_RATE, json.dumps(GRAMMAR))
recognizer_cmd.SetMaxAlternatives(0)
recognizer_cmd.SetWords(False)

recognizer_free = KaldiRecognizer(model, SAMPLE_RATE)  # no grammar → free dictation
recognizer_free.SetMaxAlternatives(0)
recognizer_free.SetWords(True)  # words true helps segmentation; not required

print("🧩 Grammar:", GRAMMAR)

# Default sounddevice format
sd.default.samplerate = SAMPLE_RATE
sd.default.channels   = 1

# =========================
# Text helpers
# =========================
_RE_REPEAT = re.compile(r'\b(\w+)(\s+\1){2,}\b', re.IGNORECASE)
_RE_WS = re.compile(r'\s+')
_RE_WORD = re.compile(r"[a-zA-Zøæåäöáéíóúýčšžñß’']+", re.UNICODE)

def normalize_final(text: str) -> str:
    t = (text or "").lower().strip()
    if not t:
        return ""
    t = _RE_REPEAT.sub(lambda m: f"{m.group(1)} {m.group(1)}", t)
    t = _RE_WS.sub(" ", t)
    return t.strip()

def pick_phrase(text: str) -> Optional[str]:
    return text if text in _PHRASES else None

def tokenize_words(text: str) -> List[str]:
    return [m.group(0).lower() for m in _RE_WORD.finditer(text or "")]

def last_letters(word: str, n: int) -> str:
    w = re.sub(r"[^a-zA-Zøæåäöáéíóúýčšžñß’']", "", word.lower())
    return w[-n:] if len(w) >= n else w

def rhyme_density(lines: List[str]) -> float:
    """Very simple rhyme score: use last word of each non-empty line,
    check how many share the same 2–3 letter suffix."""
    ends = []
    for ln in lines:
        ws = tokenize_words(ln)
        if not ws:
            continue
        last = ws[-1]
        # choose 3 letters if possible, else 2, else 1
        suf = last_letters(last, 3) if len(last) >= 5 else last_letters(last, 2)
        if suf:
            ends.append(suf)
    if len(ends) < 2:
        return 0.0
    freq = collections.Counter(ends)
    dominant = freq.most_common(1)[0][1]
    return dominant / max(1, len(ends))

def split_lines_for_rap(text: str) -> List[str]:
    # split by newline or natural pauses (.,!?)
    raw_lines = re.split(r"[ \t]*[\n\r]+|[.!?]+", text or "")
    return [ln.strip() for ln in raw_lines if ln.strip()]

def clamp01(x: float) -> float:
    return max(0.0, min(1.0, x))

def rank_from_total(score: float) -> str:
    if score >= 0.90: return "S"
    if score >= 0.75: return "A"
    if score >= 0.60: return "B"
    if score >= 0.45: return "C"
    return "D"

def log_unmatched(text: str):
    try:
        with open(UNMATCHED_LOG, "a", encoding="utf-8") as f:
            f.write(text + "\n")
    except Exception:
        pass

# =========================
# Client session handler
# =========================
async def handle_client(websocket):
    print("🟢 Client connected.")
    loop = asyncio.get_running_loop()

    # --- state
    mode: str = "command"          # "command" | "freestyle"
    active_rec = recognizer_cmd
    last_final_text = ""
    last_final_time = 0.0
    last_sent_time  = 0.0
    silence_start   = None

    # freestyle window state
    window_deadline: Optional[float] = None
    freestyle_buffer: List[str] = []
    freestyle_finalized: bool = False
    cur_partial: str = ""

    def switch_mode(m: str):
        nonlocal mode, active_rec, freestyle_buffer, window_deadline, freestyle_finalized, cur_partial
        if m == mode:
            return
        # reset both recognizers to avoid leakage
        recognizer_cmd.Reset()
        recognizer_free.Reset()
        if m == "freestyle":
            mode = "freestyle"
            active_rec = recognizer_free
            freestyle_buffer = []
            window_deadline = None
            freestyle_finalized = False
            cur_partial = ""
            print("🎤 Mode -> FREESTYLE")
        else:
            mode = "command"
            active_rec = recognizer_cmd
            window_deadline = None
            freestyle_finalized = False
            cur_partial = ""
            print("🎮 Mode -> COMMAND")

    async def send_json(obj: Dict[str, Any]):
        try:
            await websocket.send(json.dumps(obj))
        except Exception as e:
            print("Send error:", e)

    def score_and_send_freestyle():
        """Finalize current freestyle buffer, compute judge scores, send."""
        nonlocal freestyle_finalized
        if freestyle_finalized:
            return
        freestyle_finalized = True

        # Pull any last result from recognizer
        try:
            res = json.loads(active_rec.Result())
            txt_piece = (res.get("text") or "").strip()
            if txt_piece:
                freestyle_buffer.append(txt_piece)
        except Exception:
            pass

        text = " ".join(freestyle_buffer).strip()
        words = tokenize_words(text)
        lines = split_lines_for_rap(text)

        # --- judging ---
        total_ms = 0.0
        if window_deadline is not None:
            # we don't know start_ms precisely here; approximate via last window length we were given
            # The caller (Godot) knows "ms" and uses that for timing; we just evaluate content ratios.
            pass

        word_count = len(words)
        uniq_ratio = (len(set(words)) / word_count) if word_count else 0.0
        rhyme = rhyme_density(lines)

        # on-beat: approximate target words-per-second from bpm and grid
        # Assume 4/4, words per beat ~= 0.75 baseline (tweakable)
        # words_per_sec_target = (bpm / 60.0) * 0.75
        # Instead, infer from observed speaking rate vs a reasonable rap rate (2.5–4.5 wps).
        # Without exact time here, we approximate by text structure: longer lines get a mild bonus.
        avg_line_len = sum(len(tokenize_words(ln)) for ln in lines) / max(1, len(lines))
        onbeat = clamp01((avg_line_len / 8.0))  # 8 words per line considered "on-beat" sweet spot

        # completion: did they say "enough"? Use total word_count as proxy against a soft minimum.
        completion = clamp01(word_count / 24.0)  # 24+ words ≈ full credit for a short (2-bar) turn

        # weighted total
        # You can tweak these. Keep simple and readable.
        rhyme_w     = 0.35
        onbeat_w    = 0.20
        variety_w   = 0.20
        complete_w  = 0.25

        total = (rhyme * rhyme_w) + (onbeat * onbeat_w) + (uniq_ratio * variety_w) + (completion * complete_w)
        total = clamp01(total)
        rank  = rank_from_total(total)

        judge = {
            "rhyme": round(rhyme, 3),
            "onbeat": round(onbeat, 3),
            "variety": round(uniq_ratio, 3),
            "complete": round(completion, 3),
            "total": round(total, 3),
            "rank": rank
        }

        print(f"[FREESTYLE FINAL] words={word_count} judge={judge}")
        asyncio.run_coroutine_threadsafe(send_json({
            "type": "freestyle_final",
            "text": text,
            "words": words,
            "judge": judge
        }), loop)

        # reset recognizer after final to avoid carry over
        active_rec.Reset()

    def handle_command_final(now: float):
        nonlocal last_final_text, last_final_time, last_sent_time
        try:
            res  = json.loads(active_rec.Result())
        except json.JSONDecodeError:
            return
        raw  = res.get("text") or ""
        text = normalize_final(raw)
        if not text:
            return

        if text == "[unk]":
            print(f"[VOICE FINAL UNK]")
            log_unmatched("[unk]")
            active_rec.Reset()
            return

        if text == last_final_text and (now - last_final_time) < MIN_GAP_BETWEEN_FINALS:
            return
        last_final_text = text
        last_final_time = now

        phrase = pick_phrase(text)
        if not phrase:
            print(f"[VOICE FINAL UNMATCHED] {text}")
            log_unmatched(text)
            active_rec.Reset()
            return

        if (now - last_sent_time) < SERVER_COOLDOWN:
            return
        last_sent_time = now

        print(f"[VOICE FINAL] {text}  ->  [{phrase}]")
        asyncio.run_coroutine_threadsafe(send_json({"type": "final", "text": phrase}), loop)
        active_rec.Reset()

    def handle_freestyle_stream(now: float, audio_bytes: bytes, is_silence: bool):
        nonlocal silence_start, cur_partial
        got_final = active_rec.AcceptWaveform(audio_bytes)
        if got_final:
            # append final chunk text
            try:
                res = json.loads(active_rec.Result())
                txt = (res.get("text") or "").strip()
                if txt:
                    freestyle_buffer.append(txt)
            except Exception:
                pass
            silence_start = None
            return

        # track partial (optional; not sent to client to keep bandwidth tiny)
        try:
            pres = json.loads(active_rec.PartialResult())
            ptxt = (pres.get("partial") or "").strip().lower()
            cur_partial = ptxt
            if ptxt:
                print(f"[FREESTYLE PARTIAL] {ptxt}")
        except json.JSONDecodeError:
            pass

        # silence → nudge segment
        if is_silence:
            if silence_start is None:
                silence_start = now
            if (now - silence_start) >= END_SILENCE_SEC:
                active_rec.AcceptWaveform(b"")
                try:
                    res = json.loads(active_rec.Result())
                    txt = (res.get("text") or "").strip()
                    if txt:
                        freestyle_buffer.append(txt)
                except Exception:
                    pass
                silence_start = None
        else:
            silence_start = None

        # window deadline check
        if window_deadline is not None and now >= window_deadline:
            score_and_send_freestyle()

    # ---- audio callback ----
    def callback(indata, frames, t, status):
        nonlocal silence_start
        audio_bytes = bytes(indata)
        now = monotonic()

        try:
            rms = audioop.rms(audio_bytes, 2)
        except Exception:
            rms = 0
        is_silence = rms < SILENCE_RMS

        if mode == "command":
            got_final = active_rec.AcceptWaveform(audio_bytes)
            if got_final:
                handle_command_final(now)
                silence_start = None
                return

            # segment on long silence to avoid buffering forever
            if is_silence:
                if silence_start is None:
                    silence_start = now
                if (now - silence_start) >= END_SILENCE_SEC:
                    active_rec.AcceptWaveform(b"")
                    handle_command_final(now)
                    silence_start = None
            else:
                silence_start = None

            # lightweight partial logging
            try:
                pres = json.loads(active_rec.PartialResult())
                ptxt = (pres.get("partial") or "").strip().lower()
                if ptxt:
                    print(f"[VOICE PARTIAL] {ptxt}")
            except json.JSONDecodeError:
                pass

        else:  # freestyle
            handle_freestyle_stream(now, audio_bytes, is_silence)

    # ---- incoming control messages from Godot ----
    async def recv_loop():
        nonlocal window_deadline, freestyle_finalized
        async for msg in websocket:
            try:
                data = json.loads(msg)
            except Exception:
                continue
            typ = data.get("type")

            if typ == "set_mode":
                m = str(data.get("mode", "command"))
                switch_mode(m)

            elif typ == "listen_window":
                # {ms, bpm, bars, grid}
                ms   = int(data.get("ms", 4000))
                bpm  = float(data.get("bpm", 92.0))
                bars = int(data.get("bars", 2))
                grid = str(data.get("grid", "eighth"))
                print(f"🎧 LISTEN WINDOW: {ms}ms, bpm={bpm}, bars={bars}, grid={grid}")
                switch_mode("freestyle")
                # start a fresh window
                recognizer_free.Reset()
                freestyle_finalized = False
                start = monotonic()
                window_deadline = start + (ms / 1000.0)

            else:
                # unknown control message; ignore
                pass

    # Open mic stream + run recv loop
    with sd.RawInputStream(
        samplerate=SAMPLE_RATE,
        blocksize=BLOCKSIZE,
        dtype='int16',
        channels=1,
        callback=callback
    ):
        # Run the recv loop until the client disconnects
        try:
            await recv_loop()
        except websockets.ConnectionClosed:
            pass
        finally:
            # If they disconnect mid-window, finalize what we have
            if mode == "freestyle":
                print("⚠️ Client disconnected during freestyle; finalizing.")
                # best-effort final send
                try:
                    # push a final empty buffer to flush
                    recognizer_free.AcceptWaveform(b"")
                except Exception:
                    pass

    print("🔴 Client disconnected.")

async def main():
    async with websockets.serve(handle_client, HOST, PORT):
        print(f"🟢 Voice server running on ws://{HOST}:{PORT}")
        await asyncio.Future()

if __name__ == "__main__":
    asyncio.run(main())
