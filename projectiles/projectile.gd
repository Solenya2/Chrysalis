# Projectile.gd — Base class for all projectile types.
# Handles directional movement, collision detection, impact effects, and auto-despawn.

class_name Projectile
extends Node2D

# Optional visual effect to spawn on impact (e.g. explosion, flash).
@export var impact_effect_scene: PackedScene

# Direction the projectile travels in (should be normalized).
var direction := Vector2.ZERO : set = set_direction

# Speed in pixels per second.
var speed := 100.0 : set = set_speed

# Node references
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var hitbox: Hitbox = $Hitbox
@onready var visible_on_screen_notifier_2d: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

# Set the direction and rotate the projectile to face it.
func set_direction(value: Vector2) -> Projectile:
	direction = value
	rotation = direction.angle()
	return self

# Set the movement speed.
func set_speed(value: float) -> Projectile:
	speed = value
	return self

func _ready() -> void:
	# Connect hitbox signals to the impact handler, ignoring the second argument (collider).
	hitbox.hit_hurtbox.connect(impact.unbind(1))
	hitbox.body_entered.connect(impact.unbind(1))

	# Automatically free projectile when off-screen.
	visible_on_screen_notifier_2d.screen_exited.connect(queue_free)

func _physics_process(delta: float) -> void:
	# Move the projectile based on direction and speed.
	translate(direction * speed * delta)

# Called when projectile hits something.
# Spawns impact effect and removes the projectile.
func impact() -> void:
	queue_free()
	var impact_effect := Utils.instantiate_scene_on_level(impact_effect_scene, global_position) as Node2D
	impact_effect.rotation = rotation
