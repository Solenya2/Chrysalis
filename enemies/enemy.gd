# Enemy.gd — Base enemy class with movement, stats, damage response, hit effects, and modular setup.
# Extends CharacterBody2D for physics-based movement, and integrates with FSM and combat systems.

class_name Enemy
extends CharacterBody2D

# Constants
const ENEMY_COLLISION_LAYER_NUMBER := 3  # ← Used for enabling/disabling collision dynamically

# Movement stats for this enemy (e.g., speed, acceleration, etc.)
@export var movement_stats: MovementStats
 

# Health and damage resistance system for the enemy.
# Automatically duplicates the resource to avoid shared state between enemies.
@export var stats: Stats :
	set(value):
		stats = value
		if stats is not Stats:
			return
		stats = stats.duplicate()  # ← Ensures each enemy has its own unique stats instance

# Cached references to child nodes
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $Hitbox

# Instantiates a Flasher effect and assigns it to the sprite (used for hit flashes)
@onready var flasher = Flasher.new().set_target(sprite_2d)

func _ready() -> void:
	# Floating mode removes ground snapping — better for top-down or hover enemies.
	add_to_group("enemies")
	motion_mode = MOTION_MODE_FLOATING

	# Make sure movement stats were assigned properly.
	assert(movement_stats is MovementStats, "ERROR: No movement stats set on enemy: " + str(name))

	# Connect the Hurtbox signal — plays a hit sound when damaged.
	hurtbox.hurt.connect(func(other_hitbox: Hitbox) -> void:
		Sound.play(Sound.hit, randf_range(0.8, 1.3))  # ← pitch randomized for variety
	)

# Enables or disables collision for this enemy on its assigned collision layer/mask.
# Useful for temporary invincibility, death effects, or phasing.
func set_enemy_collision(value: bool) -> void:
	set_collision_layer_value(ENEMY_COLLISION_LAYER_NUMBER, value)
	set_collision_mask_value(ENEMY_COLLISION_LAYER_NUMBER, value)

# Spawns particles at the midpoint between this enemy and the hitbox that struck it.
# - particle_scene: a PackedScene to instantiate (e.g. blood spray, spark, etc.)
# - distance_from_hitbox: how close to move toward the attacker (default: 8px)
func create_hit_particles(other_hitbox: Hitbox, particle_scene: PackedScene, distance_from_hitbox := 8) -> void:
	var particle_position = global_position.move_toward(other_hitbox.global_position, distance_from_hitbox)
	var hit_particles := Utils.instantiate_scene_on_level(particle_scene, particle_position)
	
	# Rotate the particles to face away from the attacker
	hit_particles.rotation = global_position.direction_to(other_hitbox.global_position).angle()
