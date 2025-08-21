# Hurtbox.gd — Area2D used to detect when a character receives damage via hitboxes.
# Usually attached to a player or enemy to represent their vulnerable area.

class_name Hurtbox
extends Area2D

# If true, this hurtbox will ignore incoming damage (e.g., during dodge or invincibility).
# Automatically disables 'monitoring' to avoid processing collision signals.
var is_invincible := false :
	set(value):
		is_invincible = value
		# Disable Area2D monitoring while invincible to skip hit detection.
		# NOTE: Using set_deferred to avoid runtime errors during signal emission.
		set_deferred("monitoring", not is_invincible)

# Signal emitted when a hitbox collides with this hurtbox (and it's not invincible).
# The connected logic (usually in the character script) handles what to do when hit.
signal hurt(hitbox: Hitbox)
