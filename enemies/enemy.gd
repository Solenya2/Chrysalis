# Enemy.gd — Base enemy class with KO-on-lethal and KO-guard (2 hits while KO before lethal allowed)
# Now with voice command stopping system

class_name Enemy
extends CharacterBody2D

# -------------------
# Constants / Config
# -------------------
const ENEMY_COLLISION_LAYER_NUMBER := 3
const KO_HITS_TO_KILL := 2   # how many hits WHILE KO before lethal is allowed

# -------------------
# Exports / Data
# -------------------
@export var movement_stats: MovementStats

@export var stats: Stats :
	set(value):
		stats = value
		if stats is not Stats:
			return
		stats = stats.duplicate()  # ensure unique instance per enemy

# Voice stop system - child classes will configure their own stop_phrases
var stop_duration: float = 3.0  # How long to stay stopped when voice command hits

# -------------------
# Node refs
# -------------------
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $Hitbox   # enemy's own hitbox if it has one
@onready var voice_proximity: Area2D = $VoiceProximity  # Voice proximity area

@onready var flasher = Flasher.new().set_target(sprite_2d)

# -------------------
# State
# -------------------
var is_knocked_out: bool = false
var ko_hits_guard_remaining := 0

# Voice stop state
var stopped_by_voice: bool = false
var stop_timer: Timer

# Voice proximity tracking
var player_in_voice_range: bool = false

# -------------------
# Lifecycle
# -------------------
func _ready() -> void:
	add_to_group("enemies")
	motion_mode = MOTION_MODE_FLOATING

	assert(movement_stats is MovementStats, "ERROR: No movement stats set on enemy: " + str(name))

	# Use a method so we can control KO/death logic centrally.
	hurtbox.hurt.connect(_on_hurt)
	
	# Voice stop system setup
	_setup_voice_stop_system()
	
	# Voice proximity connections
	_setup_voice_proximity()

# -------------------
# Voice Proximity System
# -------------------
func _setup_voice_proximity() -> void:
	if voice_proximity:
		voice_proximity.body_entered.connect(_on_voice_proximity_body_entered)
		voice_proximity.body_exited.connect(_on_voice_proximity_body_exited)
	else:
		push_warning("VoiceProximity Area2D not found on enemy: " + name)

# In Enemy.gd, update the voice proximity functions:
func _on_voice_proximity_body_entered(body: Node) -> void:
	# Use the same check as rap system
	if body.is_in_group("Player"):
		player_in_voice_range = true
		print("[Enemy] Player entered voice range: ", name)

func _on_voice_proximity_body_exited(body: Node) -> void:
	# Use the same check as rap system
	if body.is_in_group("Player"):
		player_in_voice_range = false
		print("[Enemy] Player exited voice range: ", name)

func is_player_in_voice_range() -> bool:
	return player_in_voice_range

# -------------------
# Voice Stop System
# -------------------
func _setup_voice_stop_system() -> void:
	# Add to stop eligible group if we have stop phrases
	# Child classes will override get_stop_phrases() to provide their phrases
	if get_stop_phrases().size() > 0:
		add_to_group("StopEligible")
	
	# Create stop timer
	stop_timer = Timer.new()
	stop_timer.one_shot = true
	add_child(stop_timer)
	stop_timer.timeout.connect(_on_stop_timeout)

func stop_by_voice(phrase: String) -> void:
	if stopped_by_voice or is_knocked_out:
		return
		
	# Only stop if player is in voice range
	if not player_in_voice_range:
		print("[Enemy] ", name, " not stopping - player not in voice range")
		return
		
	print("[Enemy] ", name, " stopped by voice: ", phrase)
	stopped_by_voice = true
	velocity = Vector2.ZERO
	
	# Start stop timer
	stop_timer.start(stop_duration)
 
	
	# Play stopped animation if available
	if animation_player and animation_player.has_animation("stopped"):
		animation_player.play("stopped")
	elif animation_player and animation_player.has_animation("idle"):
		animation_player.play("idle")

func _on_stop_timeout() -> void:
	if stopped_by_voice:
		stopped_by_voice = false
		print("[Enemy] ", name, " voice stop expired")
		
		# Resume normal animation
		if animation_player and animation_player.has_animation("move"):
			animation_player.play("move")
		elif animation_player and animation_player.has_animation("idle"):
			animation_player.play("idle")

func is_stopped_by_voice() -> bool:
	return stopped_by_voice

# Virtual method - child classes should override this
func get_stop_phrases() -> Array[String]:
	return []
# In Enemy.gd, add this function to manually check the Area2D:
func _process(delta: float) -> void:
	# Temporary debug - remove this after testing
	if voice_proximity and voice_proximity.has_overlapping_bodies():
		for body in voice_proximity.get_overlapping_bodies():
			print("[DEBUG] VoiceProximity overlapping with: ", body.name)
			if body == MainInstances.hero:
				print("[DEBUG] VoiceProximity overlapping with hero!")
# -------------------
# Physics Process with Voice Stop Support
# -------------------
func _physics_process(delta: float) -> void:

	# If stopped by voice, don't move
	if stopped_by_voice:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	# If KO'd, don't move (existing KO behavior)
	if is_knocked_out:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	# Child classes will override this with their specific movement logic
	# This ensures base enemies at least handle the stop state correctly

# -------------------
# Public helpers
# -------------------
func set_enemy_collision(value: bool) -> void:
	set_collision_layer_value(ENEMY_COLLISION_LAYER_NUMBER, value)
	set_collision_mask_value(ENEMY_COLLISION_LAYER_NUMBER, value)

func create_hit_particles(other_hitbox: Hitbox, particle_scene: PackedScene, distance_from_hitbox := 8) -> void:
	var particle_position = global_position.move_toward(other_hitbox.global_position, distance_from_hitbox)
	var hit_particles := Utils.instantiate_scene_on_level(particle_scene, particle_position)
	hit_particles.rotation = global_position.direction_to(other_hitbox.global_position).angle()

# -------------------
# Damage / KO logic
# -------------------
func _on_hurt(other_hitbox: Hitbox) -> void:
	# If stopped by voice, being hit cancels the stop early
	if stopped_by_voice:
		stop_timer.stop()
		stopped_by_voice = false
		print("[Enemy] ", name, " voice stop cancelled by hit")
		
		# Resume normal animation
		if animation_player and animation_player.has_animation("move"):
			animation_player.play("move")

	# original hit sound behavior
	Sound.play(Sound.hit, randf_range(0.8, 1.3))

	# If already KO'd: apply KO guard logic.
	if is_knocked_out:
		if ko_hits_guard_remaining > 0:
			# consume a guard charge
			ko_hits_guard_remaining -= 1
			if ko_hits_guard_remaining > 0:
				# still guarded AFTER this hit: cannot die yet; clamp > 0
				stats.health = max(stats.health - other_hitbox.damage, 0.1)
				return
			else:
				# guard just expired ON THIS HIT: apply damage normally (this hit can kill)
				stats.health -= other_hitbox.damage
				return
		else:
			# no guard left: normal damage (can kill)
			stats.health -= other_hitbox.damage
			return

	# Not KO'd yet: if this hit would kill → KO instead; else take damage normally.
	var new_hp := stats.health - other_hitbox.damage
	if new_hp <= 0.0:
		stats.health = 0.1  # keep above zero to avoid triggering death
		_enter_knockout()
	else:
		stats.health = new_hp

func _enter_knockout() -> void:
	is_knocked_out = true
	ko_hits_guard_remaining = KO_HITS_TO_KILL  # require two hits while KO before lethal allowed

	# Stop any voice stop if active
	if stopped_by_voice:
		stop_timer.stop()
		stopped_by_voice = false

	# stop movement/AI here; if your AI runs elsewhere, disable it there instead
	velocity = Vector2.ZERO
	set_physics_process(false)

	# keep them hittable while KO (do NOT set invincible)
	# hurtbox.is_invincible = true  # leave OFF

	# optionally disable enemy's own hitbox while down
	if is_instance_valid(hitbox):
		hitbox.set_deferred("monitoring", false)

	# play KO animation indefinitely (fallback: just stop current anim)
	if animation_player and animation_player.has_animation("knocked_out"):
		animation_player.play("knocked_out")
	else:
		animation_player.stop()
