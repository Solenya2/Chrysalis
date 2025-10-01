# Mori.gd — Judge / Router
extends Node2D

@onready var anim: AnimationPlayer = $AnimationPlayer

const SLIME_SCENE   := "res://side_worlds/slime_world.tscn"
const CANDY_SCENE   := "res://side_worlds/candy_world.tscn"
const NEUTRAL_SCENE := "res://side_worlds/neutral_world.tscn"

func _ready() -> void:
	# Listen for the waiting room telling us to judge
	if not Events.is_connected("request_judgment", Callable(self, "_on_request_judgment")):
		Events.request_judgment.connect(_on_request_judgment)
	
	# Connect the cutscene signal
	if not Events.is_connected("start_cutscene_one", Callable(self, "_on_start_cutscene_one")):
		Events.start_cutscene_one.connect(_on_start_cutscene_one)

func _on_start_cutscene_one() -> void:
	# Start cutscene after 5 seconds
	await get_tree().create_timer(5.0).timeout
	_run_cutscene_one()

func _run_cutscene_one() -> void:
	# Step 1: Pause gameplay
	Events.cutscene_started.emit()
	
	# Step 2: Focus camera on Mori
	var mori_focus := get_node_or_null("RemoteTransform2D")
	if mori_focus is RemoteTransform2D:
		Events.request_camera_target.emit(mori_focus)
	
	# Step 3: Play the animation
	if anim and anim.has_animation("first_cutscene"):
		anim.play("first_cutscene")
		
		# Step 4: Trigger dialogue at specific times within the animation
		# At 3 seconds
		await get_tree().create_timer(3.0).timeout
		Events.request_show_dialog.emit("this sword kills")
		await Events.dialog_finished
		
		# At 5 seconds (2 seconds after the previous)
		await get_tree().create_timer(2.0).timeout
		Events.request_show_dialog.emit("and this one does not ")
		await Events.dialog_finished
		
		# At 7 seconds (2 seconds after the previous)
		await get_tree().create_timer(2.0).timeout
		Events.request_show_dialog.emit("good luck (;)")
		await Events.dialog_finished
		
		# Wait for animation to finish if it's still playing
		if anim.is_playing():
			await anim.animation_finished
	else:
		print("Mori: first_cutscene animation not found!")
	
	# Step 5: Return camera to hero - FIXED VERSION
	if MainInstances and is_instance_valid(MainInstances.hero):
		var hero = MainInstances.hero
		if hero and hero.has_node("RemoteTransform2D"):
			Events.request_camera_target.emit(hero.get_node("RemoteTransform2D"))
	
	# Step 6: Resume gameplay
	Events.cutscene_finished.emit()

# ... rest of your existing code remains the same ...
func _on_request_judgment() -> void:
	# Optional appear anim
	if anim and anim.has_animation("appear"):
		anim.play("appear")
		await anim.animation_finished

	var path := _pick_destination_path()
	var line := _line_for_path(path)

	# Say one quick line
	Events.request_show_dialog.emit(line)
	await Events.dialog_finished

	# Sanity check so bad paths fail loudly in dev
	assert(ResourceLoader.exists(path), "[Mori] Bad scene path: %s" % path)

	# Tell waiting_room what to load
	Events.interstice_route_decided.emit(path)

	# Consume the flag so we don't auto-route here again unless re-earned
	_consume_flag_for_path(path)

func _pick_destination_path() -> String:
	var f := ReferenceStash.dimension_flags
	if f.get("slime", false):
		return SLIME_SCENE
	if f.get("candy", false):
		return CANDY_SCENE
	return NEUTRAL_SCENE

func _line_for_path(path: String) -> String:
	if path == SLIME_SCENE:
		return "You really liked slimes, huh?"
	elif path == CANDY_SCENE:
		return "Glutton, huh."
	else:
		return "Learn to be intresting and do cool stuff next time."

func _consume_flag_for_path(path: String) -> void:
	# Only clear the one we used
	if path == SLIME_SCENE:
		ReferenceStash.dimension_flags["slime"] = false
	elif path == CANDY_SCENE:
		ReferenceStash.dimension_flags["candy"] = false
