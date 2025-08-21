class_name LaserProjectile
extends Projectile

@export var fade_time := 3.0
@export var max_distance := 1000.0

var distance_traveled := 0.0
var fade_started := false
var ready_to_start := false

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	super()

func _physics_process(delta: float) -> void:
	if not ready_to_start:
		return

	var movement := direction * speed * delta
	translate(movement)
	distance_traveled += movement.length()

	if not fade_started:
		start_fade()

	if distance_traveled >= max_distance:
		queue_free()

func impact() -> void:
	queue_free()

func start_fade() -> void:
	if fade_started:
		return
	fade_started = true

	if animation_player.has_animation("fade"):
		animation_player.play("fade")
		await animation_player.animation_finished

	hitbox.set_deferred("monitoring", false)
	queue_free()


func set_direction(value: Vector2) -> LaserProjectile:
	direction = value.normalized()
	ready_to_start = true
	return self

func set_speed(value: float) -> LaserProjectile:
	speed = value
	return self
