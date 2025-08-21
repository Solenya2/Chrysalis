# EnemyChargeState.gd — FSM state for enemies that do a burst charge in a set direction.
class_name EnemyChargeState
extends State

@export var charge_speed := 160        # Charge velocity magnitude
@export var charge_duration := 0.6       # How long the charge lasts (in seconds)
@export var charge_animation := "charge"  # Animation to play during charge
@export var enable_hitbox_during_charge := true  # Should hitbox be active during charge?

var _timer := 0.0
var _direction := Vector2.ZERO

func set_direction(direction: Vector2) -> EnemyChargeState:
	_direction = direction.normalized()
	return self

func enter() -> void:
	var enemy := actor as Enemy
	_timer = 0.0

	# Optional animation
	if enemy.animation_player.has_animation(charge_animation):
		enemy.animation_player.play(charge_animation)

	# Optional hitbox toggle
	if enable_hitbox_during_charge:
		enemy.hitbox.set_deferred("monitoring", true)

	# Apply knockback-like burst speed
	CharacterMover.apply_knockback(enemy, _direction * charge_speed)
func physics_process(delta: float) -> void:
	var enemy := actor as Enemy
	_timer += delta

	if _timer >= charge_duration:
		enemy.velocity = Vector2.ZERO
		finished.emit()
		return  # Prevent further processing this frame

	var collision = enemy.move_and_collide(enemy.velocity * delta)
	if collision:
		enemy.velocity = enemy.velocity.bounce(collision.get_normal()) * 0.5  # dampen bounce
		finished.emit()
	else:
		enemy.move_and_slide()

func exit() -> void:
	var enemy := actor as Enemy
	enemy.velocity = Vector2.ZERO  # Stop on exit
