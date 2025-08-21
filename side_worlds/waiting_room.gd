extends Level

	  # rename if needed
@onready var cam_remote: RemoteTransform2D = $CameraRemote        # <-- THIS is the camera target

var _routed := false

func _ready() -> void:
	# Fade in (we faded to black before loading this scene)
	if typeof(FadeLayer) != TYPE_NIL:
		FadeLayer.fade_from_black(0.8)

	# Tell CharacterCamera to follow our RemoteTransform2D
	if cam_remote:
		Events.request_camera_target.emit(cam_remote)

 
	# Listen for Mori’s decision
	if not Events.is_connected("interstice_route_decided", Callable(self, "_on_route_decided")):
		Events.interstice_route_decided.connect(_on_route_decided)

	# Kick off the judge after a short beat
	_start_sequence()

func _start_sequence() -> void:
	await get_tree().create_timer(1.0).timeout
	Events.request_judgment.emit()

	# Failsafe so you don't softlock if Mori never replies
	await get_tree().create_timer(6.0).timeout
	if not _routed:
		print("[waiting_room] No decision received, defaulting.")
		_on_route_decided("res://side_worlds/neutral_world.tscn")
 
func _on_route_decided(scene_path: String) -> void:
	if _routed:
		return
	_routed = true

	if typeof(FadeLayer) != TYPE_NIL:
		FadeLayer.fade_to_black(0.8)
		await get_tree().create_timer(0.85).timeout

	assert(ResourceLoader.exists(scene_path), "[waiting_room] Bad scene path: %s" % scene_path)
	Utils.load_level(scene_path)
