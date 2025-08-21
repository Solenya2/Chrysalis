# CharacterMover.gd — Static utility for moving CharacterBody2D nodes using shared logic.
# All functions are static, so no instancing needed — call directly from anywhere.

class_name CharacterMover
extends RefCounted

# Accelerates the character toward a given direction using MovementStats.
# - 'direction' should be a normalized Vector2 (e.g., from input or AI).
# - Uses move_toward to approach the target speed smoothly.
static func accelerate_in_direction(character: CharacterBody2D, direction: Vector2, movement_stats: MovementStats, delta: float) -> void:
	character.velocity = character.velocity.move_toward(
		direction * movement_stats.max_speed,        # ← max speed (tunable per-character)
		movement_stats.acceleration * delta          # ← acceleration rate (feel-based)
	)

# Slows the character down by moving velocity toward zero using friction.
# Useful when no input is applied or the character needs to decelerate naturally.
static func decelerate(character: CharacterBody2D, movement_stats: MovementStats, delta: float) -> void:
	character.velocity = character.velocity.move_toward(
		Vector2.ZERO,
		movement_stats.friction * delta              # ← friction affects stopping feel
	)

# Applies velocity-based movement using move_and_slide().
# Should be called once per physics frame after modifying velocity.
static func move(character: CharacterBody2D) -> void:
	character.move_and_slide()

# Moves the character with direct collision response.
# If a collision occurs, velocity is reflected using the surface normal (bounce effect).
# - Ideal for knockbacks, projectiles, or ricochet-like movement.
static func move_and_bounce(character: CharacterBody2D, delta: float) -> void:
	var collision := character.move_and_collide(character.velocity * delta)
	if collision:
		character.velocity = character.velocity.bounce(collision.get_normal())

# Applies instant knockback by directly overriding velocity.
# Should be followed by a movement call on the next physics frame.
# - Use for reactions like taking damage, explosions, or heavy hits.
static func apply_knockback(character: CharacterBody2D, knockback: Vector2) -> void:
	character.velocity = knockback
