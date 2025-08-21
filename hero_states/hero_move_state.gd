# HeroMoveState.gd — FSM state for normal player movement and interaction handling.
# Handles directional input, acceleration/deceleration, and rolls/interactions.

class_name HeroMoveState
extends State

# Last directional input from the player.
var input_vector := Vector2.ZERO

# Signals emitted to request transitions to other states (roll, weapon attack, etc.)
signal request_roll()
signal request_weapon()
signal request_sunbeam()
signal request_misc()

func physics_process(delta: float) -> void:
	var hero := actor as Hero

	# Get input direction from movement keys.
	input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# Update movement and facing direction.
	hero.facing_direction = input_vector
	hero.direction = input_vector

	# Flip the sprite visually if moving left/right.
	if hero.facing_direction.x != 0.0:
		hero.flip_anchor.scale.x = hero.facing_direction.x

	# Handle movement logic based on input.
	if input_vector != Vector2.ZERO:
		hero.play_animation("run")
		CharacterMover.accelerate_in_direction(hero, input_vector, hero.movement_stats, delta)
	else:
		hero.play_animation("idle")
		CharacterMover.decelerate(hero, hero.movement_stats, delta)

	# Apply movement after adjusting velocity.
	CharacterMover.move(hero)

func unhandled_input(event: InputEvent) -> void:
	var hero := actor as Hero

	# Allow interaction override if pressing roll/weapon near an interactable.
	if event.is_action_pressed("roll") or event.is_action_pressed("weapon"):
		if hero.interaction_detector.can_interact() and input_vector == Vector2.ZERO:
			# Trigger interaction instead of combat/movement.
			hero.interaction_detector.trigger_interaction()
			return

	# Emit state transition requests.
	if event.is_action_pressed("roll"):
		request_roll.emit()

	if event.is_action_pressed("weapon"):
		request_weapon.emit()

	if event.is_action_pressed("misc"):
		request_misc.emit()

	if event.is_action_pressed("shoot_sunbeam"):
		request_sunbeam.emit()
