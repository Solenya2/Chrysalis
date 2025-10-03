extends Level
class_name RapBattleManager

# ───────── Tunables ─────────
@export var bpm: float = 92.0
@export var bars_per_turn: int = 2
@export var rounds_total: int = 1                 # one round, as requested
@export var npc_goes_first: bool = true
@export var instrumental: AudioStream

# Duration overrides (seconds). -1 = auto.
@export var npc_turn_seconds: float = -1.0        # if > 0, force NPC verse length (e.g. 60.0)
@export var player_turn_seconds: float = 60.0     # if > 0, force player window (default: 60s)
@export var fallback_turn_seconds: float = 60.0   # used when no song length/anim is known

# ───────── Nodes ─────────
@onready var stage: Sprite2D                 = $Stage
@onready var anim: AnimationPlayer           = $AnimationPlayer
@onready var music: AudioStreamPlayer2D      = $Instrumental
@onready var npc_song: AudioStreamPlayer2D   = get_node_or_null("NpcSong") as AudioStreamPlayer2D
@onready var hud: CanvasLayer                = $RapHUD
@onready var camera_focus: RemoteTransform2D = $CameraFocus

@onready var count_label: Label = $RapHUD/CountLabel
@onready var turn_label: Label  = $RapHUD/TurnLabel

# ───────── State ─────────
var round_idx: int = 0
var player_total: float = 0.0
var npc_total: float = 0.0
var listen_window_ms: int = 0
var battle_running: bool = false
var waiting_for_judge: bool = false

var original_camera_target: RemoteTransform2D
var player_disabled: bool = false

# ───────── Lifecycle ─────────
func _enter_tree() -> void:
	if Events and not Events.is_connected("rap_player_scored", Callable(self, "_on_player_scored")):
		Events.rap_player_scored.connect(_on_player_scored)

func _ready() -> void:
	# If VoiceReceiver stored a bpm/instrumental in SceneTree meta, use it; then clear.
	var tree := get_tree()
	if tree.has_meta("rap_bpm"):
		bpm = float(tree.get_meta("rap_bpm"))
		tree.set_meta("rap_bpm", null)
	if tree.has_meta("rap_instrumental"):
		var inst = tree.get_meta("rap_instrumental")
		if inst is AudioStream:
			instrumental = inst
		tree.set_meta("rap_instrumental", null)

	# Compute player window (seconds override > BPM/bars)
	listen_window_ms = _compute_player_window_ms()
	print("[RAP] listen_window_ms=", listen_window_ms)

	# HUD prep
	count_label.visible = false
	turn_label.visible = false

	# Assign instrumental stream
	if instrumental:
		music.stream = instrumental

	_start_battle()

# ───────── Helpers ─────────
func _compute_player_window_ms() -> int:
	if player_turn_seconds > 0.0:
		return int(player_turn_seconds * 1000.0)
	# default: bars→beats (4/4)→seconds
	return int(bars_per_turn * 4.0 * (60.0 / bpm) * 1000.0)

func _stream_length_sec(s: AudioStream) -> float:
	if s and s.has_method("get_length"):
		var L := float(s.call("get_length"))
		return max(L, 0.0)
	return 0.0

# ───────── Flow ─────────
func _start_battle() -> void:
	_disable_player()
	_take_camera_control()

	battle_running = true
	round_idx = 0
	player_total = 0.0
	npc_total = 0.0

	var music_autoload := get_node_or_null("/root/Music")
	if music_autoload and music_autoload.has_method("fade"):
		music_autoload.fade(0.5)

	if anim.has_animation("Intro"):
		anim.play("Intro")
		await anim.animation_finished

	await _count_in()
	_play_instrumental()

	if Events:
		Events.rap_battle_started.emit(self, bpm)

	await _run_round_loop()

	await _show_outro()
	_end_battle()

func _run_round_loop() -> void:
	while round_idx < rounds_total and battle_running:
		if npc_goes_first:
			await _do_npc_turn()
			await _do_player_turn()
		else:
			await _do_player_turn()
			await _do_npc_turn()
		round_idx += 1

# ───────── Turns ─────────
func _do_npc_turn() -> void:
	turn_label.text = "TRASH TURN"
	turn_label.visible = true
	if Events:
		Events.rap_turn_changed.emit(false, round_idx, 0)

	if anim.has_animation("TrashRap"):
		anim.play("TrashRap")

	var waited := false
	var npc_secs := npc_turn_seconds

	# Try stream length if not explicitly set
	if npc_secs <= 0.0 and npc_song and npc_song.stream:
		# ensure non-looping so finished can emit
		if "loop" in npc_song.stream:
			npc_song.stream.loop = false
		var L := _stream_length_sec(npc_song.stream)
		if L > 0.0:
			npc_secs = L

	if npc_song and npc_song.stream:
		npc_song.play()
		if npc_secs > 0.0:
			print("[RAP] NPC verse secs =", npc_secs)
			await get_tree().create_timer(npc_secs).timeout
			waited = true
		else:
			await npc_song.finished
			waited = true

	if not waited:
		if npc_turn_seconds > 0.0:
			await get_tree().create_timer(npc_turn_seconds).timeout
		elif anim.has_animation("TrashRap"):
			await anim.animation_finished
		else:
			await get_tree().create_timer(fallback_turn_seconds).timeout

	# Optional quick cut
	if anim.has_animation("PlayerReaction"):
		anim.play("PlayerReaction")
		await anim.animation_finished

	turn_label.visible = false

	# Baseline NPC score per round (tweak if you want difficulty curves)
	npc_total += 0.55 + randf() * 0.15

func _do_player_turn() -> void:
	turn_label.text = "YOUR TURN"
	turn_label.visible = true
	if Events:
		Events.rap_turn_changed.emit(true, round_idx, 0)

	if anim.has_animation("PlayerRap"):
		anim.play("PlayerRap")

	# Count-in before opening the mic each turn
	await _count_in()

	# Resolve VoiceReceiver robustly by group
	var voice := get_tree().get_first_node_in_group("VoiceReceiver")
	waiting_for_judge = false

	if voice and voice.has_method("start_listen_window"):
		waiting_for_judge = true
		print("[RAP] Opening listen window for", float(listen_window_ms) / 1000.0, "seconds")
		voice.call_deferred("start_listen_window", listen_window_ms, bpm, bars_per_turn, round_idx)

		# Wait for 'freestyle_final' with a small cushion for server processing
		var max_wait := (listen_window_ms / 1000.0) + 1.5
		var elapsed := 0.0
		while waiting_for_judge and elapsed < max_wait:
			await get_tree().process_frame
			elapsed += get_process_delta_time()

		if waiting_for_judge:
			# Server didn't reply (mic muted, server down, etc.)
			waiting_for_judge = false
			player_total += 0.3
			await _show_round_score({"rhyme":0.1,"onbeat":0.2,"variety":0.2,"complete":0.4,"total":0.3,"rank":"D"})
	else:
		push_warning("VoiceReceiver missing or no start_listen_window – neutral score applied.")
		await get_tree().create_timer(listen_window_ms / 1000.0).timeout
		player_total += 0.5
		await _show_round_score({"rhyme":0.4,"onbeat":0.5,"variety":0.5,"complete":0.6,"total":0.5,"rank":"C"})

	# Opponent reaction cut
	if anim.has_animation("TrashReaction"):
		anim.play("TrashReaction")
		await anim.animation_finished

	turn_label.visible = false

func _on_player_scored(round_i: int, judge: Dictionary) -> void:
	if not battle_running or round_i != round_idx:
		return
	waiting_for_judge = false
	var total := float(judge.get("total", 0.0))
	player_total += clamp(total, 0.0, 1.0)
	await _show_round_score(judge)

# ───────── UI helpers ─────────
func _show_round_score(judge: Dictionary) -> void:
	var r: String = str(judge.get("rank", "?"))
	var total_percent: int = int(round(100.0 * float(judge.get("total", 0.0))))
	turn_label.text = "YOUR SCORE: %s (%d%%)" % [r, total_percent]
	await get_tree().create_timer(0.9).timeout

func _count_in() -> void:
	count_label.visible = true
	var beat_s := 60.0 / bpm
	for s in ["3", "2", "1", "Go!"]:
		count_label.text = s
		await get_tree().create_timer(beat_s).timeout
	count_label.visible = false

func _play_instrumental() -> void:
	if music and music.stream:
		if "loop" in music.stream:
			music.stream.loop = true
		music.play()

# ───────── Outro / End ─────────
func _show_outro() -> void:
	var player_won := player_total >= npc_total
	if player_won and anim.has_animation("PlayerWin"):
		anim.play("PlayerWin")
	elif (not player_won) and anim.has_animation("TrashWin"):
		anim.play("TrashWin")

	turn_label.visible = true
	turn_label.text = "YOU WIN!" if player_won else "YOU LOSE!"
	await get_tree().create_timer(1.2).timeout
	turn_label.visible = false

func _end_battle() -> void:
	battle_running = false
	if music and music.playing:
		music.stop()

	_enable_player()
	_return_camera_control()

	# Keep other signals if you want, but they can trigger external logic.
	# If that caused your 'current_level' error, comment the next 2 lines out.
	if Events:
		Events.rap_battle_ended.emit(self, {
			"player_total": player_total,
			"npc_total": npc_total,
			"winner": "player" if player_total >= npc_total else "npc"
		})

	# Leave exactly the way you requested, nothing else:
	call_deferred("_return_to_trash_level")

func _return_to_trash_level() -> void:
	Utils.load_level("res://rap/trash_can_level.tscn")

# ───────── Player & Camera ─────────
func _disable_player() -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.set_process(false)
		player.set_physics_process(false)
		player.hide()
		player_disabled = true

func _enable_player() -> void:
	if player_disabled:
		var player = get_tree().get_first_node_in_group("Player")
		if player:
			player.set_process(true)
			player.set_physics_process(true)
			player.show()
		player_disabled = false

func _take_camera_control() -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if player and player.has_node("RemoteTransform2D"):
		original_camera_target = player.get_node("RemoteTransform2D")
	if camera_focus:
		Events.request_camera_target.emit(camera_focus)

func _return_camera_control() -> void:
	if original_camera_target:
		Events.request_camera_target.emit(original_camera_target)
