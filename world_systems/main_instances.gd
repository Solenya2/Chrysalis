# MainInstances.gd — Autoloaded singleton for exposing references to core scene instances.
# Used for global access to the player (Hero) and ActionsUI for UI logic and gameplay systems.

extends Node

# Reference to the player character (set from the scene or during instantiation)
var hero: Hero

# Reference to the actions UI (used to manage quick-slot assignments)
var actions_ui: ActionsUI
