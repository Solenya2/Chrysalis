# Stasher.gd — Used to persist simple per-object state (e.g., collected, opened, triggered)
# via a position-based ID and SaveManager.save_data dictionary.

class_name Stasher
extends RefCounted

# Target Node2D whose state will be tracked
var target: set = set_target

# Stores the global position where the object existed on scene load
var starting_position: Vector2

# Assign the target node and capture its world position
func set_target(value: Node2D) -> Stasher:
	target = value
	if target is not Node2D:
		return self
	starting_position = target.global_position
	return self

# Generates a unique ID string for the target using scene path + position
func get_id() -> String:
	var world := target.get_tree().current_scene as World
	assert(world is World, "You can't get the id for an object outside of the world scene.")
	var id: String = (
		target.scene_file_path +
		" at " + str(starting_position) +
		" in " + world.current_level.scene_file_path
	)
	return id

# Stores a named property (e.g., "collected") under this object's ID
func stash_property(property: String, value) -> void:
	var id := get_id()
	if not SaveManager.save_data.has(id):
		SaveManager.save_data[id] = {}
	SaveManager.save_data[id][property] = value

# Retrieves a previously stored property value (or null if missing)
func retrieve_property(property: String):
	var id := get_id()
	if not SaveManager.save_data.has(id): return null
	if not SaveManager.save_data[id].has(property): return null
	return SaveManager.save_data[id][property]
