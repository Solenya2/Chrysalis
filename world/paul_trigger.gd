extends CutsceneTrigger

# Car root can be StaticBody2D (inherits Node2D) or a Marker2D under the car.
@export_node_path("Node2D") var car_anchor_path: NodePath      # e.g. Car (StaticBody2D) or Car/CarAnchor (Marker2D)
@export_node_path("RemoteTransform2D") var car_focus_path: NodePath  # e.g. Car/CameraFocus (RemoteTransform2D)

@export var car_zoom: Vector2 = Vector2(1.35, 1.35)
@export var pan_time: float = 0.8       # how long to pan/zoom in
@export var shot_hold: float = 5.0      # how long to HOLD on the car after pan

func _ready() -> void:
	super()
	cutscene_requested.connect(_run_cutscene)

func _run_cutscene(_trigger):
	# Step 1: Pause gameplay
	Events.cutscene_started.emit()

	# Resolve nodes
	var car_anchor := get_node_or_null(car_anchor_path) as Node2D
	var car_focus  := get_node_or_null(car_focus_path)  as RemoteTransform2D
	if car_anchor == null:
		push_error("Cutscene: car_anchor_path is not set or invalid.")
		Events.cutscene_finished.emit()
		return

	# Step 2: Make the camera follow the car focus (so it doesn’t snap back to hero)
	if car_focus:
		Events.request_camera_target.emit(car_focus)
	await get_tree().process_frame  # give the camera one frame to switch target

	# Step 3: Ask the camera to frame the car and STAY there for pan+hold seconds
	var total := pan_time + shot_hold
	Events.request_cutscene_camera_focus.emit(car_anchor, car_zoom, total)

	# If you want the line to appear DURING the 5s hold, schedule it right after the pan time:
	await get_tree().create_timer(pan_time).timeout
	Events.request_show_dialog.emit("[center]Oh no—the car’s burning!")
	await Events.dialog_finished

	# DO NOT manually retarget the hero here. Your CharacterCamera will:
	# - wait 'total' seconds
	# - then emit request_camera_target(hero) and reset zoom to (1,1)

	# Step 6: Resume gameplay
	Events.cutscene_finished.emit()
