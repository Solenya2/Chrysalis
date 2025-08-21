class_name EnemyDodgeState
extends State

@export var dodge_distance := 64.0        # ← How far the dodge travels
@export var dodge_duration := 0.25        # ← How long the dodge lasts
@export var invincible_for := 0.3         # ← Time enemy is invincible (optional)
@export var danger_cooldown := 0.3  # ← delay before enemy resumes pursuit after dodge

@export var danger_range := 128.0         # ← How close the attack must be to trigger dodge

var _timer: float = 0.0
var _direction: Vector2 = Vector2.ZERO
var _waiting_to_dodge: bool = false

func configure(direction: Vector2) -> EnemyDodgeState:
	_direction = direction.normalized()
	return self

func enter() -> void:
	_timer = 0.0
	var e := actor as Enemy

	# Become invincible
	e.hurtbox.set_deferred("monitoring", false)
	e.set_enemy_collision(false)

	# Play dodge animation if it exists
	if e.animation_player.has_animation("dodge"):
		e.animation_player.play("dodge")

	# Calculate proper speed for the desired distance
	var calculated_speed := dodge_distance / dodge_duration
	CharacterMover.apply_knockback(e, _direction * calculated_speed)

	# Debug
	print("💨 Dodge started → Distance:", dodge_distance, " Speed:", calculated_speed)

func physics_process(delta: float) -> void:
	_timer += delta
	CharacterMover.move(actor)

	if _timer >= dodge_duration:
		actor.fsm.revert_state()

func exit() -> void:
	var e := actor as Enemy
	e.hurtbox.set_deferred("monitoring", true)
	e.set_enemy_collision(true)
	e.velocity = Vector2.ZERO

	# Optional: assign cooldown directly to rabbit if supported
	if e is RabbitEnemy:
		e.dodge_cooldown_timer = danger_cooldown
