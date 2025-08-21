# Utils.gd — Autoloaded singleton used for various generic utility functions
# This function helps you dynamically instantiate a scene into the current level at runtime.

extends Node

# Instantiates a PackedScene (e.g. enemy, item, effect) at a specific position
# and adds it to the current level or, if unavailable, to the current scene as fallback.
func instantiate_scene_on_level(scene: PackedScene, position: Vector2) -> Node:
	# Create an instance of the given scene.
	var node := scene.instantiate()
	
	# Get the root scene — expected to be of type World (your main game scene container).
	var main := get_tree().current_scene as World
	
	# Set the node's position before adding it.
	node.position = position
	
	# Try to add the node to the current level (World.current_level should be a Level node).
	if main is World:
		var level := main.current_level as Level
		
		if level is Level:
			# Expected path — attach the new node to the active level.
			level.add_child(node)
		else:
			# Fallback: if no level exists, just add it to the root scene (not ideal but prevents crash).
			main.add_child(node)
	
	# Return the node in case you want to manipulate it afterward.
	return node
# Loads a new level scene, replacing the current level in the World scene
func load_level(path: String) -> void:
	var main := get_tree().current_scene as World
	if main is World:
		# Remove current level
		if main.current_level:
			main.current_level.queue_free()

		# Load and instance the new level
		var level_scene: PackedScene = load(path)
		var new_level: Node = level_scene.instantiate()
		main.add_child(new_level)
		main.current_level = new_level
	else:
		push_error("Utils.load_level(): Current scene is not of type World.")
