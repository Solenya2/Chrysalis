class_name Hero
extends CharacterBody2D

# Constants
const CUSTOM_RED: = Color("e64539")  # Used for flash effect when hit
const SIDE_BIAS: = 0.1               # Used to bias directional facing (helps lock vertical vs horizontal)

# References to shared player data
var stats: = ReferenceStash.hero_stats as Stats
var inventory: = ReferenceStash.inventory as Inventory

# Movement settings
@export var movement_stats: MovementStats         # Normal movement stats
@export var roll_movement_stats: MovementStats    # Movement stats while rolling

# Current directional input (normalized)
var direction: = Vector2.DOWN :
	set(value):
		if value == Vector2.ZERO: return
		value = value.normalized()
		direction = value

# Current facing direction (used for animation and interaction facing)
var facing_direction: = Vector2.DOWN :
	set(value):
		if value == Vector2.ZERO: return
		value = value.normalized()
		if abs(value.x) >= abs(value.y) - SIDE_BIAS:
			value = Vector2(sign(value.x), 0)
		else:
			value = Vector2(0, sign(value.y))
		facing_direction = value
		# Rotate interaction detector to match new facing
		if interaction_detector is Area2D:
			interaction_detector.rotation = facing_direction.angle()

# Alignment-based sprite references
@onready var normal_sprite: Sprite2D = $FlipAnchor/NormalSprite2D
@onready var good_sprite: Sprite2D = $FlipAnchor/GoodSprite2D
@onready var evil_sprite: Sprite2D = $FlipAnchor/EvilSprite2D

# Current active sprite (will be set based on alignment)
var active_sprite: Sprite2D

# Node references
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var flip_anchor: Node2D = $FlipAnchor
@onready var remote_transform_2d: RemoteTransform2D = $RemoteTransform2D
@onready var flasher: Flasher = Flasher.new()
@onready var blinker: Blinker = Blinker.new()
@onready var hitbox: Hitbox = $FlipAnchor/Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var interaction_detector: Area2D = $InteractionDetector

# States
@onready var move_state: = HeroMoveState.new().set_actor(self) as HeroMoveState
@onready var roll_state: HeroRollState = HeroRollState.new().set_actor(self).set_item(load("res://items/roll_ring_item.tres"))
@onready var weapon_state: HeroWeaponState = HeroWeaponState.new().set_actor(self).set_item(load("res://items/sword_item.tres"))
@onready var heal_state: = HeroHealState.new().set_actor(self)
@onready var place_state: = HeroPlaceState.new().set_actor(self)
@onready var laser_state := HeroLaserState.new().set_actor(self)
@onready var centipede_state: HeroCentipedeState = HeroCentipedeState.new().set_actor(self).set_item(load("res://items/CentipedeItem.tres"))
@onready var cutscene_pause_state: = CutscenePauseState.new().set_actor(self)
@onready var clap_state: = HeroClapState.new().set_actor(self)  # Add this line

# Finite State Machine controller
@onready var fsm: = FSM.new().set_state(move_state)

# Maps item types to their handling states
@onready var item_state_lookup: = {
	RollItem : roll_state,
	WeaponItem : weapon_state,
	HealingItem : heal_state,
	PlaceableItem : place_state,
	SunbeamItem : laser_state,
}

# Register hero instance globally on load
func _enter_tree() -> void:
	MainInstances.hero = self

# Remove global reference on unload
func _exit_tree() -> void:
	MainInstances.hero = null

func _ready() -> void:
	add_to_group("Player")
	clap_state.finished.connect(fsm.change_state.bind(move_state))
	# Initialize alignment system
	check_alignment()
	
	# Set up flasher and blinker for the active sprite
	flasher.set_target(active_sprite).set_color(CUSTOM_RED)
	blinker.set_target(active_sprite)
	
	Events.cutscene_resume.connect(func():
		if fsm.state == cutscene_pause_state:
			fsm.change_state(move_state)
	)
	# Listen for bat kills to trigger alignment updates
	Events.bat_killed.connect(check_alignment)

	facing_direction = Vector2.DOWN

	# Set up camera to follow the hero
	Events.request_camera_target.emit.call_deferred(remote_transform_2d)

	# Connect damage handling and death
	hurtbox.hurt.connect(take_hit)
	stats.no_health.connect(queue_free)

	# Use floating motion mode (Godot 4 top-down standard)
	motion_mode = MOTION_MODE_FLOATING

	# Listen for quick-action slot changes and bind correct item logic
	Events.action_changed.connect(func(action_index: int, item_index: int):
		var state: State

		var item := inventory.get_item(item_index)
		var state_signal: Signal

		if item == null:
			push_warning("Tried to assign action slot with null item (index: %d)" % item_index)
			return

	# Assign state based on item type
		state = item_state_lookup.get(item.get_script(), null)
		if "item" in state:
			state.item = item
		if state == null:
			push_warning("No state found for item script: %s" % item.get_script())
			return
		state.item = item

		match action_index:
			0: state_signal = move_state.request_roll
			1: state_signal = move_state.request_weapon
			2:
				match item.get_script():
					SunbeamItem: state_signal = move_state.request_sunbeam
					

		connect_action(state_signal, state)
	)


	# Initialize default roll item in slot 0
	set_action_from_item(load("res://items/roll_ring_item.tres"), 0)
	var sunbeam_item := load("res://items/SunbeamItem.tres")
	if not inventory.has_item(sunbeam_item):
		inventory.add_item(sunbeam_item)
	set_action_from_item(sunbeam_item, 2)

	laser_state.projectile_scene = preload("res://projectiles/laser_projectile.tscn")  #  path
	
	# Centipede attack setup
	move_state.request_centipede.connect(fsm.change_state.bind(centipede_state))
	centipede_state.finished.connect(fsm.change_state.bind(move_state))

func check_alignment() -> void:
	# Hide all sprites first
	normal_sprite.visible = false
	good_sprite.visible = false
	evil_sprite.visible = false
	
	# Determine which sprite to use based on alignment
	if ReferenceStash.alignment.evil_score >= 1:
		active_sprite = evil_sprite
		active_sprite.modulate = Color(0.6, 0.6, 0.6)  # Your existing evil tint
	# Add condition for good alignment when implemented
	# elif ReferenceStash.alignment.good_score >= 3:
	#     active_sprite = good_sprite
	else:
		active_sprite = normal_sprite
		active_sprite.modulate = Color.WHITE  # Reset tint for normal sprite
	
	# Show the active sprite
	active_sprite.visible = true
	
	# Update flasher and blinker targets
	flasher.set_target(active_sprite)
	blinker.set_target(active_sprite)

func get_facing_vector() -> Vector2:
	return facing_direction

func _physics_process(delta: float) -> void:
	fsm.state.physics_process(delta)

func _unhandled_input(event: InputEvent) -> void:
	# Check for clap input first
	if event.is_action_pressed("clap"):
		fsm.change_state(clap_state)
		return
	
	# Process other inputs through the current state
	fsm.state.unhandled_input(event)

# Helper to assign an item to a specific action slot
func set_action_from_item(item: Item, action_index: int) -> void:
	var item_index = inventory.get_item_index(item)
	Events.request_new_action.emit(action_index, item_index)

# Connects a signal to a new state in the FSM, also ensures state finishes return to move
func connect_action(action_signal: Signal, state: State) -> void:
	if action_signal.is_connected(fsm.change_state):
		action_signal.disconnect(fsm.change_state)
	if state is not State: return
	action_signal.connect(fsm.change_state.bind(state))
	if not state.finished.is_connected(fsm.change_state):
		state.finished.connect(fsm.change_state.bind(move_state))
	state.set_actor(self)

# Triggered when hero is hit by an enemy or effect
func take_hit(other_hitbox: Hitbox) -> void:
	hurtbox.is_invincible = true
	stats.health -= other_hitbox.damage
	Events.request_camera_screenshake.emit(4, 0.3)
	Events.hero_hurt.emit()
	Sound.play(Sound.hurt, 1.0, -5.0)
	
	# Update flasher target in case it changed
	flasher.set_target(active_sprite)
	await flasher.flash(0.2)
	
	# Update blinker target in case it changed
	blinker.set_target(active_sprite)
	await blinker.blink()
	
	hurtbox.is_invincible = false
# In Hero.gd - add to _unhandled_input

func play_animation(animation: String) -> void:
	var alignment_prefix := ""
	
	# Determine animation prefix based on alignment
	if ReferenceStash.alignment.evil_score >= 1:
		alignment_prefix = "evil_"
	# Add condition for good alignment when implemented
	# elif ReferenceStash.alignment.good_score >= 3:
	#     alignment_prefix = "good_"
	else:
		alignment_prefix = "normal_"
	
	# Explicitly declare the type as String
	var animation_name: String = alignment_prefix + animation + "_" + get_direction_string()
	
	# Ensure the animation exists before trying to play it
	if animation_player.has_animation(animation_name):
		animation_player.play(animation_name)
	else:
		# Fallback to normal animation if alignment-specific doesn't exist
		var fallback_name: String = "normal_" + animation + "_" + get_direction_string()
		if animation_player.has_animation(fallback_name):
			animation_player.play(fallback_name)
		else:
			push_error("Animation not found: " + animation_name)

func play_dusted():
	var anim_player := $AnimationPlayer
	if anim_player and anim_player.has_animation("Dusted"):
		anim_player.play("Dusted")
	else:
		print("⚠️ No Dusted animation found.")

	# Freeze player control
	set_physics_process(false)

	await get_tree().create_timer(3.0).timeout  # wait 3 seconds

	# Kill the player directly using the existing stats reference
	if stats:
		stats.health -= stats.max_health
	else:
		print("⚠️ No stats reference available.")

# Converts facing direction into string for animation naming
func get_direction_string() -> String:
	var direction_string: = ""
	if facing_direction.x == 0.0:
		if facing_direction.y < 0.0:
			direction_string = "up"
		else:
			direction_string = "down"
	else:
		direction_string = "side"
	return direction_string

# Add this function to update alignment when it changes
func update_alignment() -> void:
	check_alignment()
	
	# Also update any ongoing animations
	if fsm.state is HeroMoveState:
		play_animation("idle")  # Refresh the idle animation with correct alignment

# Serializes hero state to dictionary (used by SaveManager)
func serialize() -> Dictionary:
	var data := {}
	data.global_position = var_to_str(global_position)
	data.direction = var_to_str(direction)
	data.facing_direction = var_to_str(facing_direction)
	return data

# Restores hero state from serialized save data
func update_from_serialized_data(data: Dictionary) -> void:
	global_position = str_to_var(data.global_position)
	direction = str_to_var(data.direction)
	facing_direction = str_to_var(data.facing_direction)
	play_animation("idle")
	Events.request_camera_target.emit(remote_transform_2d)
