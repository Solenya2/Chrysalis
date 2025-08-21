@tool  # Enables editor drawing and property updates
class_name Door
extends Area2D

# Collision layer setup (matches your player/world config)
const WORLD_COLLISION_LAYER_NAME = 1
const PLAYER_COLLISION_LAYER_NAME = 2

# Cardinal directions for door exit logic
enum DIRECTION { RIGHT, UP, LEFT, DOWN }

# Maps enum to actual direction vectors
var direction_map = {
	DIRECTION.RIGHT: Vector2.RIGHT,
	DIRECTION.UP: Vector2.UP,
	DIRECTION.LEFT: Vector2.LEFT,
	DIRECTION.DOWN: Vector2.DOWN,
}

# Direction the player will exit toward after entering this door
@export var exit_direction: DIRECTION:
	set(value):
		exit_direction = value
		queue_redraw()  # Trigger editor preview update

# Distance the player will be offset upon entering this door
@export var exit_distance := 16:
	set(value):
		exit_distance = value
		queue_redraw()

# Optional link or data about the destination (could store ID, name, etc.)
@export var connection: Resource

# Path to the scene this door leads to
@export_file("*.tscn") var next_level_path

func _ready() -> void:
	queue_redraw()

	# Skip runtime logic when in the editor
	if Engine.is_editor_hint(): return
	set_collision_layer_value(PLAYER_COLLISION_LAYER_NAME, true)

	# Setup collision only for the player (not world objects)
	set_collision_mask_value(PLAYER_COLLISION_LAYER_NAME, true)
	set_collision_mask_value(WORLD_COLLISION_LAYER_NAME, false)
	set_collision_layer_value(WORLD_COLLISION_LAYER_NAME, false)

	# Tag this node as part of the 'doors' group for easy discovery
	add_to_group("doors")

	# Trigger door entry logic on player collision
	body_entered.connect(func(body: Node2D):
		print("hi")
		if body is not Hero: return
		Events.door_entered.emit(self)
		Sound.play(Sound.room_transition)
	)

# Returns the world position the player should be moved to after entering
func get_exit_point() -> Vector2:
	return global_position + get_exit_offset()

# Returns the offset vector based on direction and distance
func get_exit_offset() -> Vector2:
	return direction_map[exit_direction] * exit_distance

# Calculates offset to position the player along one axis (used during transition)
func get_offset(target: Node2D) -> Vector2:
	var offset := global_position - target.global_position
	match exit_direction:
		DIRECTION.RIGHT, DIRECTION.LEFT:
			offset.x = 0.0
		DIRECTION.UP, DIRECTION.DOWN:
			offset.y = 0.0
	return offset

# Editor-only drawing for visualizing direction + offset
func _draw() -> void:
	if not Engine.is_editor_hint(): return
	draw_circle(Vector2.ZERO, 1, Color.WHITE)  # Origin
	draw_line(Vector2.ZERO, get_exit_offset(), Color.WHITE, 1, false)
	draw_circle(get_exit_offset(), 2, Color.WHITE)  # Exit point
