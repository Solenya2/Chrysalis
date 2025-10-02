extends Node
class_name VoiceReceiver

const SPEECH_URL := "ws://localhost:8765"
var ws := WebSocketPeer.new()

# --- Command-mode cooldowns ---
var last_trigger_time := {}
const COOLDOWN := 1.5  # seconds per word
# --- Voice aliases (exact phrases from Python server) ---
const PLAY_MOZART_ALIASES := [
	"play mozart",
	"spill mozart",     # Norwegian
	"soita mozartia",   # Finnish
	"chohpa mozart"     # Sámi phonetic
]
const LOVE_ALIASES := [
	"i love you",
	"jeg elsker deg",   # Norwegian Bokmål
	"eg elskar deg"     # Nynorsk
]
# --- Rap battle protocol state ---
var mode: String = "command"
var battle_active: bool = false
var pending_round_idx: int = -1

# Distance gate for hotphrase → NPC
@export var rap_trigger_radius: float = 160.0

# Where to load the rap scene
@export var rap_scene_path: String = "res://rapattle_scene.tscn"

@onready var explosion_scene := preload("res://effects/explosion.tscn")

@onready var love_scene := preload("res://blush_scene.tscn")
func _ready() -> void:
	var err := ws.connect_to_url(SPEECH_URL)
	if err != OK:
		push_error("Failed to connect to speech server: %s" % err)
		set_process(false)
		return
	print("🟢 Connecting to ", SPEECH_URL)
	set_process(true)

func _process(_delta: float) -> void:
	ws.poll()

	match ws.get_ready_state():
		WebSocketPeer.STATE_OPEN:
			while ws.get_available_packet_count() > 0:
				var pkt := ws.get_packet()
				if not ws.was_string_packet():
					continue
				var raw := pkt.get_string_from_utf8()
				var data: Dictionary = {}
				var parsed: Variant = JSON.parse_string(raw)
				if typeof(parsed) == TYPE_DICTIONARY:
					data = parsed
				else:
					data = {"type":"final", "text": raw} # back-compat

				_handle_message(data)

		WebSocketPeer.STATE_CLOSED:
			print("🔴 Speech connection closed")
			set_process(false)

# -------------------------------------------------
# Incoming message handler
# -------------------------------------------------
func _handle_message(data: Dictionary) -> void:
	var mtype: String = str(data.get("type", ""))
	match mtype:
		"final":
			_handle_command_final(str(data.get("text","")))
		"hotphrase":
			_handle_hotphrase(str(data.get("text","")))
		"freestyle_final":
			_handle_freestyle_final(data)
		_:
			pass

# -------------------------------------------------
# Command / hotphrase path (grammar-mode)
# -------------------------------------------------
func _handle_command_final(text_raw: String) -> void:
	var text := text_raw.strip_edges().to_lower()
	if text.is_empty():
		return

	# Per-phrase cooldown
	var now := Time.get_unix_time_from_system()
	if text in last_trigger_time and now - last_trigger_time[text] < COOLDOWN:
		return
	last_trigger_time[text] = now

	# Your existing triggers
	if "pizza" in text or "sup" in text:
		Utils.load_level("res://levels/level_1.tscn")
		print("🍕 PIZZA DETECTED!")
		_on_pizza()
	elif "boom boom" in text:
		print("💥 BOMB DETONATED!")
		_on_bomb()
	elif "i love you" in text or "eg elsker deg" in text :
		print("oh my (;")
		_on_love()
	elif "bad game" in text or "this game sucks" in text:
		print("dusted")
		_on_dusted()
	elif "bedroom player" in text:
		Utils.load_level("res://levels/levelbedroom.tscn")
	elif "boss level one" in text:
		Utils.load_level("res://enemies/sami_boss_level.tscn")
	elif "corruption level" in text:
		Utils.load_level("res://corupted_levels/corupted_outside.tscn")
	elif "slime world" in text:
		Utils.load_level("res://side_worlds/slime_world.tscn")
	elif "neutral world" in text:
		Utils.load_level("res://side_worlds/neutral_world.tscn")
	elif "candy world" in text:
		Utils.load_level("res://side_worlds/candy_world.tscn")
	elif "pizza" in text: 
		Utils.load_level("res://levels/level_1.tscn")

	elif text in PLAY_MOZART_ALIASES:
		print("🎼 PLAY MOZART")
		if Music.play_track_by_key("mozart"):
			# Optional: add UI feedback / toast / sfx here
			pass
		else:
			print("⚠️ 'mozart' not found in Music.track_map")

	elif "i challenge you to a rap battle" in text:
		_try_emit_rap_battle_requested()

func _handle_hotphrase(text: String) -> void:
	var t := text.strip_edges().to_lower()
	if t == "i challenge you to a rap battle":
		_try_emit_rap_battle_requested()

func _try_emit_rap_battle_requested() -> void:
	var npc := _find_nearest_rap_npc(rap_trigger_radius)
	if npc:
		print("🎤 Rap battle requested near: ", npc.name)
		# notify listeners (optional)
		Events.rap_battle_requested.emit(npc)
		# stash per-NPC params on the SceneTree and warp to the battle scene
		_start_rap_battle_with_npc(npc)
	else:
		print("⚠️ No RapEligible NPC in range (", rap_trigger_radius, " px ).")

func _start_rap_battle_with_npc(npc: Node2D) -> void:
	# Pull optional NPC data if provided
	var bpm: float = 92.0
	if npc.has_method("get_rap_bpm"):
		bpm = float(npc.call("get_rap_bpm"))

	var instrumental: AudioStream = null
	if npc.has_method("get_rap_instrumental"):
		instrumental = npc.call("get_rap_instrumental")

	# Stash into SceneTree metadata so the battle scene can read it on _ready()
	var tree := get_tree()
	tree.set_meta("rap_bpm", bpm)
	tree.set_meta("rap_instrumental", instrumental)
	if tree.current_scene and tree.current_scene.scene_file_path != "":
		tree.set_meta("rap_return_path", tree.current_scene.scene_file_path)
	else:
		tree.set_meta("rap_return_path", "")

	# Optional: brief fade / lock inputs could go here

	# Load the rap battle scene directly
	Utils.load_level(rap_scene_path)

func _find_nearest_rap_npc(max_dist: float) -> Node2D:
	var hero: Node2D = MainInstances.hero if MainInstances.hero else get_tree().get_first_node_in_group("Player")
	if hero == null:
		return null

	var best: Node2D = null
	var best_d: float = max_dist

	for n in get_tree().get_nodes_in_group("RapEligible"):
		if not (n is Node2D):
			continue
		var npc: Node2D = n
		if not _is_npc_available_for_rap(npc):
			continue

		var d: float = hero.global_position.distance_to(npc.global_position)
		if d <= best_d:
			best_d = d
			best = npc

	return best

func _is_npc_available_for_rap(npc: Node2D) -> bool:
	# Must be in current scene & visible
	if not npc.is_inside_tree():
		return false
	if not npc.is_visible_in_tree():
		return false

	# Opt-in group
	if not npc.is_in_group("RapEligible"):
		return false

	# Optional per-NPC flag (exported on NPC script)
	var available := true
	if "rap_available" in npc and typeof(npc.get("rap_available")) == TYPE_BOOL:
		available = bool(npc.get("rap_available"))

	# Optional global busy gate (PauseManager autoload with method `is_cinematic`)
	var busy_globally := false
	var pm := get_node_or_null("/root/PauseManager")
	if pm and pm.has_method("is_cinematic"):
		busy_globally = pm.call("is_cinematic")

	return available and not busy_globally

# -------------------------------------------------
# Freestyle window path (battle turns)
# -------------------------------------------------
# Called by RapBattleManager when your 2-bar turn starts.
# Server should answer with one "freestyle_final" message.
func start_listen_window(ms: int, bpm: float, bars: int, round_idx: int = -1) -> void:
	pending_round_idx = round_idx
	battle_active = true
	set_mode("freestyle")
	var payload := {
		"type":"listen_window",
		"ms": ms,
		"bpm": bpm,
		"bars": bars,
		"grid": "eighth"
	}
	_send_json(payload)

func set_mode(new_mode: String) -> void:
	if mode == new_mode:
		return
	mode = new_mode
	_send_json({"type":"set_mode", "mode": new_mode})

func _handle_freestyle_final(data: Dictionary) -> void:
	# Expected: { type:"freestyle_final", text:String, words:Array, judge:Dictionary }
	battle_active = false
	var judge: Dictionary = {}
	if data.has("judge") and typeof(data["judge"]) == TYPE_DICTIONARY:
		judge = data["judge"]
	if judge.is_empty():
		judge = {"rhyme":0.2,"onbeat":0.2,"variety":0.2,"complete":0.2,"total":0.2,"rank":"D"}

	# Emit to battle manager via Events (direct – autoload)
	var r_idx := pending_round_idx
	pending_round_idx = -1
	Events.rap_player_scored.emit(r_idx, judge)

	# Return to command mode after each window
	set_mode("command")

# -------------------------------------------------
# Low-level send
# -------------------------------------------------
func _send_json(obj: Dictionary) -> void:
	if ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return
	var txt := JSON.stringify(obj)
	ws.send_text(txt)

# -------------------------------------------------
# Existing helpers
# -------------------------------------------------
func _on_pizza() -> void:
	get_tree().call_group("Player", "eat_pizza")

func _on_bomb() -> void:
	var explosion := explosion_scene.instantiate()
	var cam := get_viewport().get_camera_2d()
	if cam:
		explosion.global_position = cam.get_screen_center_position()
	else:
		explosion.global_position = Vector2.ZERO
	get_tree().get_root().add_child(explosion)
	_trigger_nuke_flash(0.06, 0.35, 2.0, 0.25)

func _on_love() -> void:
	print("oh my (;")
	
	var love := love_scene.instantiate()
	
	# Add to canvas layer to ensure it's always on top
	var canvas_layer := CanvasLayer.new()
	canvas_layer.layer = 100  # High layer number to ensure it's on top
	get_tree().root.add_child(canvas_layer)
	canvas_layer.add_child(love)
	
	# Center on screen
	var viewport_size := get_viewport().get_visible_rect().size
	love.position = viewport_size / 2
	
	# Play animation
	var anim_player: AnimationPlayer = love.find_child("AnimationPlayer")
	if anim_player:
		anim_player.play("blush")
		anim_player.animation_finished.connect(func(_anim_name):
			canvas_layer.queue_free()  # Remove both the layer and blush
		)
	else:
		print("Warning: No AnimationPlayer found in blush scene")
		await get_tree().create_timer(2.0).timeout
		canvas_layer.queue_free()
func _trigger_nuke_flash(
	peak_time: float = 0.05,
	hold_time: float = 0.10,
	fade_time: float = 1.00,
	delay_before: float = 0.00
) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	get_tree().root.add_child(layer)

	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(flash)

	if delay_before > 0.0:
		await get_tree().create_timer(delay_before).timeout

	var tween := create_tween()
	tween.tween_property(flash, "color:a", 1.0, peak_time)
	tween.tween_interval(hold_time)
	tween.tween_property(flash, "color:a", 0.0, fade_time)
	tween.finished.connect(func(): layer.queue_free())

func _on_dusted() -> void:
	var player := MainInstances.hero if MainInstances.hero else get_tree().get_first_node_in_group("Player")
	if not player:
		print("⚠️ No player found.")
		return
	if player.has_method("play_dusted"):
		player.play_dusted()
	else:
		print("⚠️ Player has no 'play_dusted' method")

func _on_change_level(scene_path: String) -> void:
	if not ResourceLoader.exists(scene_path):
		push_error("⚠️ Level not found: %s" % scene_path)
		return
	print("🌍 Changing level to: ", scene_path)
	get_tree().change_scene_to_file(scene_path)
