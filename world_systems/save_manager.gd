# SaveManager.gd — Handles saving and loading of game state: player, inventory, stats, UI, and level.
# Uses JSON to serialize data to a local save file. Supports both production and test paths.

extends Node

# File paths for different environments
const TEST_PATH := "res://arpg_save.txt"
const PRODUCTION_PATH := "user://arpg_save.save"

# Current active path (can be swapped for testing)
var save_path := PRODUCTION_PATH

# Holds the serialized game data as a dictionary
var save_data := {}

# Serializes and saves all major game systems to disk
func save_game() -> void:
	var hero := MainInstances.hero as Hero
	var inventory := ReferenceStash.inventory as Inventory
	var world := get_tree().current_scene as World
	var actions_ui := MainInstances.actions_ui as ActionsUI
	var hero_stats := ReferenceStash.hero_stats as Stats
	
	assert(hero is Hero, "There is no hero to save.")
	assert(world is World, "There is no world to save.")
	assert(actions_ui is ActionsUI, "There is no actions UI to save.")
	
	save_data.hero = hero.serialize()
	save_data.hero_stats = hero_stats.serialize()
	save_data.inventory = inventory.serialize()
	save_data.actions_ui = actions_ui.serialize()
	save_data.level_path = world.current_level.scene_file_path
	save_data.alignment = ReferenceStash.alignment.evil_score  # Save evil_score instead
# In save_game():


# In load_game():

	var save_file = FileAccess.open(save_path, FileAccess.WRITE)
	var data_string := JSON.stringify(save_data)
	save_file.store_string(data_string)
	save_file.close()

# Loads and reconstructs game state from a save file
func load_game() -> void:
	var save_file = get_save_file()
	if not save_file is FileAccess: return
	
	# Read and parse save file
	save_data = JSON.parse_string(save_file.get_line())
	
	# Restore shared resources


	ReferenceStash.inventory = Inventory.new().deserialize(save_data.inventory)
	ReferenceStash.hero_stats = Stats.new().deserialize(save_data.hero_stats)
	ReferenceStash.alignment.evil_score = int(save_data.alignment)  # Load evil_score instead
	# Load world base scene and prepare it
	var tree = get_tree() as SceneTree
	var world = load("res://world.tscn").instantiate() as World
	tree.current_scene.queue_free()
	await tree.root.child_exiting_tree
	
	tree.root.add_child.call_deferred(world)
	await tree.root.child_entered_tree
	
	tree.current_scene = world
	await world.ready
	
	# Restore level and hero state
	world.set_level(save_data.level_path)
	var hero = MainInstances.hero as Hero
	hero.update_from_serialized_data(save_data.hero)
	
	# Restore UI state
	var actions_ui = MainInstances.actions_ui as ActionsUI
	actions_ui.update_from_serialized_data(save_data.actions_ui)

# Tries to open the save file and return the file handle if it exists
func get_save_file() -> FileAccess:
	var save_file = FileAccess.open(save_path, FileAccess.READ)
	if save_file is FileAccess:
		return save_file
	else:
		print("NO SAVE FILE!!!")
		return null

# Returns true if a valid save file is detected
func has_save_file() -> bool:
	return (get_save_file() is FileAccess)
