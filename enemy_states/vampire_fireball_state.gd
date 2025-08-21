# VampireFireballState.gd — FSM state where the vampire boss fires a radial burst of fireballs.
# Waits for an animation, spawns projectiles in a circle, then finishes after a short delay.

class_name VampireFireballState
extends State

# Preloaded fireball projectile scene — must extend a custom Projectile class.
const FIREBALL_PROJECTILE_SCENE := preload("res://projectiles/fireball_projectile.tscn")

func enter() -> void:
	var vampire := actor as VampireBoss

	# Play wind-up or opening animation before firing.
	vampire.animation_player.play("open_cloak")
	await vampire.animation_player.animation_finished

	# Fireball spawn origin — usually a marker node in the vampire's scene.
	var marker_position := vampire.fireball_marker_2d.global_position

	# Initial angle (diagonally down-left), normalized for safe rotation math.
	var starting_fireball_angle := Vector2(-1, 1).normalized()

	# Spawn 8 fireballs in a full radial pattern (360°), each 45° apart.
	for i in 8:
		var fireball := Utils.instantiate_scene_on_level(
			FIREBALL_PROJECTILE_SCENE,
			marker_position
		) as Projectile

		# Set fireball direction by rotating the base vector.
		# Each fireball rotates 45° from the last (PI/4 radians).
		fireball.set_direction(starting_fireball_angle.rotated(-i * PI / 4)).set_speed(100)

	# Wait a brief moment after firing to create a cooldown or pacing delay.
	await vampire.get_tree().create_timer(0.5).timeout

	# Done — emit finished to move to the next state.
	finished.emit()
