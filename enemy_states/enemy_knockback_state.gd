# EnemyKnockbackState.gd — A temporary FSM state for handling enemy knockback and potential death.
# Disables collision, applies knockback force, plays visual/audio effects, and waits until motion ends.

class_name EnemyKnockbackState
extends State

# Visual explosion effect shown if the enemy dies in this state.
const EXPLOSION_EFFECT_SCENE := preload("res://effects/explosion_effect.tscn")

# Direction and magnitude of knockback to apply.
var knockback := Vector2.ZERO : set = set_knockback

# Setter to allow fluent chaining when assigning knockback.
func set_knockback(value: Vector2) -> EnemyKnockbackState:
	knockback = value
	return self

# Called once when the state is entered.
func enter() -> void:
	var enemy := actor as Enemy

	# Temporarily disable enemy collision during knockback to avoid overlap issues.
	enemy.set_enemy_collision(false)

	# Apply knockback force immediately using CharacterMover.
	CharacterMover.apply_knockback(enemy, knockback)

	# Play a flash effect (visual feedback for getting hit).
	enemy.flasher.flash()

# Called every physics frame — decelerates and moves the enemy until it stops.
func physics_process(delta: float) -> void:
	var enemy := actor as Enemy

	# Gradually reduce velocity using friction.
	CharacterMover.decelerate(enemy, enemy.movement_stats, delta)

	# Apply movement and handle bounce if hitting a wall.
	CharacterMover.move_and_bounce(enemy, delta)

	# When velocity reaches (near) zero, finish the state.
	if enemy.velocity.is_equal_approx(Vector2.ZERO):
		finished.emit()

# Called once when the state is exited — restores collision and checks for death.
func exit() -> void:
	var enemy := actor as Enemy
	enemy.set_enemy_collision(true)

	if enemy.stats.is_health_gone():
		# New: emit +1 evil point for killing this enemy
		ReferenceStash.alignment.evil_score += 1
		Events.bat_killed.emit()  # Optional, can rename later if needed

		enemy.queue_free()
		Utils.instantiate_scene_on_level(EXPLOSION_EFFECT_SCENE, enemy.global_position)
		Sound.play(Sound.explosion)
