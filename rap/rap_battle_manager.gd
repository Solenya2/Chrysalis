extends Node2D
class_name RapBattleManager

# ────────────────────────────────────────────────
# Tunables
# ────────────────────────────────────────────────
@export var bpm: float = 92.0                  # used to compute listen window for player's turn
@export var bars_per_turn: int = 2
@export var rounds_total: int = 3
@export var npc_goes_first: bool = true
@export var instrumental: AudioStream          # backing track (loop) for the battle scene
@export var return_scene_path: String = ""     # where to go back after battle (can be filled via SceneTree meta)

# ────────────────────────────────────────────────
# Nodes
# ────────────────────────────────────────────────
@onready var stage: Sprite2D           = $Stage
@onready var anim: AnimationPlayer     = $AnimationPlayer
@onready var music                     = $Instrumental            # AudioStreamPlayer or AudioStreamPlayer2D (no strict type)
@onready var npc_song: AudioStreamPlayer = ($NpcSong if has_node("NpcSong") else null)   # optional: dedicated NPC vocal/long track
@onready var hud: CanvasLayer          = $RapHUD

@onready var count_label: Label = $RapHUD/CountLabel
@onready var turn_label: Label = $RapHUD/TurnLabel

# ────────────────────────────────────────────────
# State
# ────────────────────────────────────────────────
var round_idx: int = 0
var player_total: float = 0.0
var npc_total: float = 0.0
var listen_window_ms: int = 0
var battle_running: bool = false
var waiting_for_judge: bool = false

# ────────────────────────────────────────────────
# Lifecycle
# ────────────────────────────────────────────────
func _enter_tree() -> void:
	# Keep running during any global pause (if you ever use it)

	# Judge callback from the voice system
	if Events and not Events.is_connected("rap_player_scored", Callable(self, "_on_player_scored")):
		Events.rap_player_scored.connect(_on_player_scored)

func _ready() -> void:
	# Pull session data from SceneTree meta (set by VoiceReceiver)
	var tree := get_tree()
	if tree.has_meta("rap_bpm"):
		bpm = float(tree.get_meta("rap_bpm"))
	if tree.has_meta("rap_instrumental"):
		var inst = tree.get_meta("rap_instrumental")
		if inst is AudioStream:
			instrumental = inst
	if tree.has_meta("rap_return_path"):
		return_scene_path = String(tree.get_meta("rap_return_path"))

	# Clear metas so they don't leak to the next battle
	if tree.has_meta("rap_bpm"): tree.set_meta("rap_bpm", null)
	if tree.has_meta("rap_instrumental"): tree.set_meta("rap_instrumental", null)
	if tree.has_meta("rap_return_path"): tree.set_meta("rap_return_path", null)

	# Compute window (4 beats per bar)
	listen_window_ms = int(bars_per_turn * 4.0 * (60.0 / bpm) * 1000.0)

	# Prep UI
	count_label.visible = false
	turn_label.visible = false

	# Set instrumental if provided
	if instrumental:
		music.stream = instrumental

	_start_battle()

# ────────────────────────────────────────────────
# Flow
# ────────────────────────────────────────────────
func _start_battle() -> void:
	battle_running = true
	round_idx = 0
	player_total = 0.0
	npc_total = 0.0

	# Optional: duck any global music autoload you use
	var music_autoload := get_node_or_null("/root/Music")
	if music_autoload and music_autoload.has_method("fade"):
		music_autoload.fade(0.5)

	# Intro → count-in → start instrumental
	if anim.has_animation("Intro"):
		anim.play("Intro")
		await anim.animation_finished

	await _count_in()
	_play_instrumental()

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

# ────────────────────────────────────────────────
# Turns
# ────────────────────────────────────────────────
func _do_npc_turn() -> void:
	turn_label.text = "TRASH TURN"
	turn_label.visible = true
	Events.rap_turn_changed.emit(false, round_idx, 0)

	# Start their animation if present
	if anim.has_animation("TrashRap"):
		anim.play("TrashRap")
	else:
		push_warning("Missing 'TrashRap' animation")

	# Prefer audio-driven duration if you have NpcSong with a stream
	var waited := false
	if npc_song and npc_song.stream:
		npc_song.play()
		await npc_song.finished
		waited = true
	elif anim.has_animation("TrashRap"):
		# If the TrashRap animation spans the whole performance, wait for it
		await anim.animation_finished
		waited = true

	# Fallback to the short 2-bar timer if we had neither long audio nor long anim
	if not waited:
		await get_tree().create_timer(listen_window_ms / 1000.0).timeout

	# Quick opponent reaction cut
	if anim.has_animation("PlayerReaction"):
		anim.play("PlayerReaction")
		await anim.animation_finished

	turn_label.visible = false

	# Baseline NPC score per round (tweak as needed)
	npc_total += 0.55 + randf() * 0.15   # 0.55–0.70

func _do_player_turn() -> void:
	turn_label.text = "YOUR TURN"
	turn_label.visible = true
	Events.rap_turn_changed.emit(true, round_idx, 0)

	# Player animation
	if anim.has_animation("PlayerRap"):
		anim.play("PlayerRap")
	else:
		push_warning("Missing 'PlayerRap' animation")

	# Voice path: ask server to open a listen window and wait for judge
	var voice := get_node_or_null("/root/VoiceReceiver")
	waiting_for_judge = false

	if voice and voice.has_method("start_listen_window"):
		waiting_for_judge = true
		voice.call_deferred("start_listen_window", listen_window_ms, bpm, bars_per_turn, round_idx)

		var max_wait := (listen_window_ms / 1000.0) + 0.5
		var elapsed := 0.0
		while waiting_for_judge and elapsed < max_wait:
			await get_tree().process_frame
			elapsed += get_process_delta_time()

		if waiting_for_judge:
			# No server response; assign a low score
			waiting_for_judge = false
			player_total += 0.3
			await _show_round_score({"rhyme":0.1,"onbeat":0.2,"variety":0.2,"complete":0.4,"total":0.3,"rank":"D"})
	else:
		# No voice integration; just wait the window and give neutral score
		await get_tree().create_timer(listen_window_ms / 1000.0).timeout
		player_total += 0.5
		await _show_round_score({"rhyme":0.4,"onbeat":0.5,"variety":0.5,"complete":0.6,"total":0.5,"rank":"C"})

	# Opponent reaction
	if anim.has_animation("TrashReaction"):
		anim.play("TrashReaction")
		await anim.animation_finished

	turn_label.visible = false

# Called when VoiceReceiver emits Events.rap_player_scored(round_idx, judge)
func _on_player_scored(round_i: int, judge: Dictionary) -> void:
	if not battle_running or round_i != round_idx:
		return
	waiting_for_judge = false
	var total := float(judge.get("total", 0.0))
	player_total += clamp(total, 0.0, 1.0)
	await _show_round_score(judge)

# ────────────────────────────────────────────────
# UI helpers
# ────────────────────────────────────────────────
func _show_round_score(judge: Dictionary) -> void:
	var r: String = str(judge.get("rank", "?"))
	var total_percent: int = int(round(100.0 * float(judge.get("total", 0.0))))
	turn_label.text = "YOUR SCORE: %s (%d%%)" % [r, total_percent]
	await get_tree().create_timer(0.9).timeout

func _count_in() -> void:
	count_label.visible = true
	var beat_s := 60.0 / bpm
	var seq := ["3", "2", "1", "Go!"]
	for s in seq:
		count_label.text = s
		await get_tree().create_timer(beat_s).timeout
	count_label.visible = false

func _play_instrumental() -> void:
	if music and music.stream:
		music.play()

# ────────────────────────────────────────────────
# Outro / End
# ────────────────────────────────────────────────
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

	var result := {
		"player_total": player_total,
		"npc_total": npc_total,
		"winner": "player" if player_total >= npc_total else "npc"
	}
	Events.rap_battle_ended.emit(self, result)

	# Return to previous scene if provided
	if return_scene_path != "":
		if Utils and Utils.has_method("load_level"):
			Utils.load_level(return_scene_path)
		else:
			get_tree().change_scene_to_file(return_scene_path)
