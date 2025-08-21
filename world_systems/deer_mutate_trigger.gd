extends CutsceneTrigger

func _ready() -> void:
	super()
	cutscene_requested.connect(_run_cutscene)
func _run_cutscene(_trigger):
	# Step 1: Pause gameplay
	Events.cutscene_started.emit()

	# Step 2: Focus camera on the deer
	var deer := get_parent()
	var deer_focus := deer.get_node_or_null("RemoteTransform2D")

	# Only emit the camera signal if the focus target is valid
	if deer_focus is RemoteTransform2D:
		Events.request_camera_target.emit(deer_focus)

	# Zoom + pan camera (this supports any Node2D)
	Events.request_cutscene_camera_focus.emit(deer, Vector2(1.3, 1.3), 0.8)

	# Step 3: Trigger mutation
	Events.infected_deer_mutate.emit()

	# Step 4: Dialog
	await get_tree().create_timer(0.3).timeout
	Events.request_show_dialog.emit("[center]The deer... it's changing...")
	await Events.dialog_finished

	# Step 5: Return camera to hero
	Events.request_camera_target.emit(MainInstances.hero.remote_transform_2d)

	# Step 6: Resume
	Events.cutscene_finished.emit()
