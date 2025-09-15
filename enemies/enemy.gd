# Enemy.gd — Base enemy class with KO-on-lethal and KO-guard (2 hits while KO before lethal allowed)

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

# -------------------
# Node refs
# -------------------
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $Hitbox   # enemy's own hitbox if it has one

@onready var flasher = Flasher.new().set_target(sprite_2d)

# -------------------
# State
# -------------------
var is_knocked_out: bool = false
var ko_hits_guard_remaining := 0

# -------------------
# Lifecycle
# -------------------
func _ready() -> void:
	add_to_group("enemies")
	motion_mode = MOTION_MODE_FLOATING

	assert(movement_stats is MovementStats, "ERROR: No movement stats set on enemy: " + str(name))

	# Use a method so we can control KO/death logic centrally.
	hurtbox.hurt.connect(_on_hurt)

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
