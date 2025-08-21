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
