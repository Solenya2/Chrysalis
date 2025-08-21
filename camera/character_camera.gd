# CharacterCamera.gd — Camera2D controller that follows the player and responds to game-wide events.
# Receives its target, screen shake, and camera bounds from global Events signals.

class_name CharacterCamera
extends Camera2D

# These margins add padding to camera limits so the player doesn't get too close to screen edges.
# NOTE: These values are visual design choices and will likely be adjusted later.
const FRAME_HORIZONTAL_MARGIN := 28  # ← will likely be tweaked based on level layout feel
const FRAME_VERTICAL_MARGIN := 6     # ← same, affects how close player can get to top/bottom

# Private target reference — not exposed directly to avoid misuse.
# Target is a RemoteTransform2D node used to link the camera to a moving object.
var _target: RemoteTransform2D : set = set_target

# Setter for the camera's tracking target.a
# It ensures the previous target is unlinked and new target is set to follow this camera.
func set_target(value: RemoteTransform2D) -> void:
	if _target is RemoteTransform2D:
		# Clear the old RemoteTransform’s path so it doesn’t keep linking to this camera.
		_target.remote_path = ""
	_target = value
	# Link the new RemoteTransform2D to this camera so it follows it.
	_target.remote_path = get_path()
	
	# Reset smoothing to avoid jumps when switching targets.
	reset_smoothing()

func _ready() -> void:
	# Connect global events to this camera's handler methods.
	Events.request_camera_target.connect(set_target)
	Events.request_camera_limits.connect(update_limits)
	Events.request_camera_screenshake.connect(apply_screenshake)
	Events.request_cutscene_camera_focus.connect(_focus_on_target)
# Applies a camera shake using a tween that gradually lowers the shake amount to zero.
# NOTE: Both 'amount' and 'duration' are visual feel parameters — expect to tweak these.
func apply_screenshake(amount: float, duration: float = 0.3) -> void:  # ← 0.3s is a placeholder value
	var tween := create_tween()
	tween.tween_method(shake, amount, 0.0, duration)
	await tween.finished
func _focus_on_target(target_node: Node2D, zoom_level: Vector2, duration: float) -> void:
	# Temporarily disable smoothing and follow logic
	if target_node == null:
		return
	
	global_position = target_node.global_position
	zoom = zoom_level

	# Optional: disable smoothing so it snaps cleanly
	position_smoothing_enabled = false


	await get_tree().create_timer(duration).timeout

	# Return to player afterwards (assuming you still have a RemoteTransform2D following the player)
	Events.request_camera_target.emit(MainInstances.hero.remote_transform_2d)

	zoom = Vector2(1, 1)  # Reset zoom
	position_smoothing_enabled = true

# Called by the tween. Offsets the camera randomly within a range defined by 'amount'.
# NOTE: Shake intensity formula may need tuning based on camera zoom/screen size.
func shake(amount: float) -> void:
	offset = Vector2(
		randf_range(-1.0, 1.0),  # ← jitter range is fixed, may want to scale with zoom later
		randf_range(-1.0, 1.0)
	) * amount

# Receives a CameraLimits node and sets the camera bounds using its position and size.
# Margins are applied to prevent edge-clipping and jitter.
func update_limits(camera_limits: CameraLimits) -> void:
	limit_left = camera_limits.position.x - FRAME_HORIZONTAL_MARGIN
	limit_right = camera_limits.position.x + camera_limits.size.x + FRAME_HORIZONTAL_MARGIN
	limit_top = camera_limits.position.y - FRAME_VERTICAL_MARGIN
	limit_bottom = camera_limits.position.y + camera_limits.size.y + FRAME_VERTICAL_MARGIN
