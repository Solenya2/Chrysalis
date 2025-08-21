#!/usr/bin/env python3
import os, sys, json, asyncio, re
import websockets
import sounddevice as sd
import audioop  # NOTE: deprecated in Py3.13+, fine for now
from vosk import Model, KaldiRecognizer
from time import monotonic

# =========================
# Config
# =========================
HOST = "localhost"
PORT = 8765

SAMPLE_RATE = 16000
BLOCKSIZE   = 8000                 # ~0.5s frames
SILENCE_RMS = 800                  # gate: ignore quiet blocks (tune 600–1200)

MIN_GAP_BETWEEN_FINALS = 1.5       # debounce same-final repeats from Vosk (s)
SERVER_COOLDOWN        = 1.2       # prevent rapid-fire commands (s)

# Exact phrases ONLY. Keep them multi-word to reduce hallucinations.
GRAMMAR = [
    # Demo
    "pizza time",
    "open the door",
    "spaghetti ravioli",

    # Punishments
    "this game is bad",
    "this game sucks",
    "bad game",
    "boom boom",

    # Warps / debug
    "bedroom player",
    "bedroom sister",
    "corruption level",
    "boss level one",
    "boss level two",

    # Allow recognizer to decline instead of forcing a match
    "[unk]",
]

# =========================
# PyInstaller support
# =========================
# If bundled with PyInstaller, point Vosk at its native lib folder
if hasattr(sys, "_MEIPASS"):
    os.environ["VOSK_LIBRARY_PATH"] = os.path.join(sys._MEIPASS, "vosk")

def data_path(*parts: str) -> str:
    """Resolve a data path both in dev and in PyInstaller one-file."""
    if getattr(sys, 'frozen', False) and hasattr(sys, "_MEIPASS"):
        return os.path.join(sys._MEIPASS, *parts)
    return os.path.join(os.path.dirname(__file__), *parts)

# Where to look for the model (first hit wins)
MODEL_CANDIDATES = [
    data_path('vosk_models', 'vosk-model-small-en-us-0.15'),                            # bundled via --add-data
    os.path.join(os.path.dirname(sys.argv[0]), 'vosk_models', 'vosk-model-small-en-us-0.15'),  # next to exe
    os.path.join(os.path.dirname(sys.argv[0]), '_internal', 'vosk_models', 'vosk-model-small-en-us-0.15'),  # legacy
]
MODEL_DIR = next((p for p in MODEL_CANDIDATES if os.path.exists(p)), None)
if not MODEL_DIR:
    raise RuntimeError("Vosk model not found. Looked in:\n  " + "\n  ".join(MODEL_CANDIDATES))

# =========================
# Init recognizer
# =========================
print("🔧 Loading Vosk model from:", MODEL_DIR)
model = Model(MODEL_DIR)
recognizer = KaldiRecognizer(model, SAMPLE_RATE, json.dumps(GRAMMAR))
recognizer.SetMaxAlternatives(0)
recognizer.SetWords(False)

print("🧩 Grammar:", GRAMMAR)

# Default sounddevice format
sd.default.samplerate = SAMPLE_RATE
sd.default.channels   = 1

# =========================
# Normalization helpers
# =========================
# collapse runs of same word >=3 to 2: "boom boom boom boom" -> "boom boom"
_RE_REPEAT = re.compile(r'\b(\w+)(\s+\1){2,}\b', re.IGNORECASE)
# squeeze whitespace
_RE_WS = re.compile(r'\s+')

_PHRASES = [p for p in GRAMMAR if p != "[unk]"]

def normalize_final(text: str) -> str:
    t = (text or "").lower().strip()
    if not t:
        return ""
    t = t.replace("[unk]", " ").strip()
    if not t:
        return ""
    t = _RE_REPEAT.sub(lambda m: f"{m.group(1)} {m.group(1)}", t)
    t = _RE_WS.sub(" ", t)
    return t.strip()

def pick_phrase(text: str) -> str | None:
    """Return the single phrase we care about, preferring the longest contained phrase."""
    hits = [p for p in _PHRASES if p in text]
    if not hits:
        return None
    return max(hits, key=len)

# =========================
# Server
# =========================
async def handle_client(websocket):
    print("🟢 Client connected.")
    loop = asyncio.get_running_loop()

    last_final_text = ""
    last_final_time = 0.0
    last_sent_time  = 0.0  # server-side cooldown so Godot never sees floods

    def send_final(text: str):
        payload = json.dumps({"type": "final", "text": text})
        loop.call_soon_threadsafe(asyncio.create_task, websocket.send(payload))

    def callback(indata, frames, t, status):
        nonlocal last_final_text, last_final_time, last_sent_time

        audio_bytes = bytes(indata)

        # Silence gate — prevents hallucinations on noise/idling
        try:
            if audioop.rms(audio_bytes, 2) < SILENCE_RMS:  # 2 bytes/sample (int16)
                return
        except Exception:
            return  # don't crash the stream on edge cases

        if recognizer.AcceptWaveform(audio_bytes):
            # FINAL
            try:
                res = json.loads(recognizer.Result())
            except json.JSONDecodeError:
                return

            raw = res.get("text") or ""
            text = normalize_final(raw)
            if not text:
                return

            # Debounce duplicate finals coming from Vosk
            now = monotonic()
            if text == last_final_text and (now - last_final_time) < MIN_GAP_BETWEEN_FINALS:
                return
            last_final_text = text
            last_final_time = now

            # Map to exactly one known phrase; drop if no hit
            phrase = pick_phrase(text)
            if not phrase:
                return

            # Server-side cooldown so “boom boom boom …” cannot stack triggers
            if (now - last_sent_time) < SERVER_COOLDOWN:
                return
            last_sent_time = now

            print(f"[VOICE FINAL] {text}  ->  [{phrase}]")
            send_final(phrase)

        else:
            # PARTIAL — log only (comment out if you want silence)
            try:
                pres = json.loads(recognizer.PartialResult())
                ptxt = (pres.get("partial") or "").strip().lower()
                if ptxt:
                    print(f"[VOICE PARTIAL] {ptxt}")
            except json.JSONDecodeError:
                pass

    # Open mic stream
    with sd.RawInputStream(
        samplerate=SAMPLE_RATE,
        blocksize=BLOCKSIZE,
        dtype='int16',
        channels=1,
        callback=callback
    ):
        await websocket.wait_closed()
        print("🔴 Client disconnected.")

async def main():
    async with websockets.serve(handle_client, HOST, PORT):
        print(f"🟢 Voice server running on ws://{HOST}:{PORT}")
        await asyncio.Future()

if __name__ == "__main__":
    asyncio.run(main())
