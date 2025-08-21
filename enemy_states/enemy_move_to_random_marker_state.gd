# EnemyMoveToRandomMarkerState.gd — FSM state where the enemy moves to randomized marker points.
# Can be used for boss repositioning or enemy patrol behavior.

class_name EnemyMoveToRandomMarkerState
extends State

# Distance threshold to consider the target "reached".
# WARNING: This is affected by the enemy's acceleration and friction.
# If it's too small, fast enemies may overshoot; too large, they may stop too early.
const REACHED_TARGET_MARGIN := 8  # ← Tweak based on enemy speed/playtest feel

# Array of marker nodes the enemy can travel to.
var markers: Array[Marker2D] : set = set_markers

# Queue of Vector2 positions extracted from shuffled markers.
var target_positions: Array[Vector2]

# The current position we're trying to reach.
var target_position: Vector2

# Assigns a set of marker nodes and returns self for chaining.
func set_markers(value: Array[Marker2D]) -> EnemyMoveToRandomMarkerState:
	markers = value
	return self

# Called once when entering the state — sets up a target destination.
func enter() -> void:
	var enemy := actor as Enemy

	# If we have no positions queued, shuffle the markers and enqueue their positions.
	if target_positions.is_empty():
		markers.shuffle()
		for marker in markers:
			target_positions.append(marker.global_position)

	# Choose a target position from the front or back based on where we are in the list.
	if is_current_position_in_front():
		target_position = target_positions.pop_back()
	else:
		target_position = target_positions.pop_front()

# Called every physics frame — moves enemy toward the current target.
func physics_process(delta: float) -> void:
	var enemy := actor as Enemy
	var direction: Vector2 = enemy.global_position.direction_to(target_position)

	# Play movement animation and face direction.
	enemy.animation_player.play("move")
	if direction.x != 0:
		enemy.sprite_2d.scale.x = sign(direction.x)

	# Apply movement.
	CharacterMover.accelerate_in_direction(enemy, direction, enemy.movement_stats, delta)
	CharacterMover.move(enemy)

	# WARNING: This code uses the margin to determine if the enemy has reached the target
	# This is also affected by the enemy's acceleration and friction
	var distance := enemy.global_position.distance_to(target_position)
	if distance <= REACHED_TARGET_MARGIN:
		# Stop the enemy and signal state completion.
		enemy.velocity = Vector2.ZERO
		finished.emit()

# Determines if we were just moving toward the front of the queue (used to alternate direction).
func is_current_position_in_front() -> bool:
	return (target_positions.front() == target_position)
