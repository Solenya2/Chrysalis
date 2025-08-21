# PauseManager.gd — Centralized system for handling game pause state.
# Emits events, toggles engine pause, and plays audio feedback.

class_name PauseManager
extends Node

# Signals for UI and systems to respond to pause state changes
signal paused()
signal unpaused()

# Internal pause state flag (setter handles full pause behavior)
var is_paused := false :
	set(value):
		is_paused = value
		get_tree().paused = is_paused
		if is_paused:
			paused.emit()
		else:
			unpaused.emit()

func _ready() -> void:
	# Connect sounds to pause state changes
	paused.connect(Sound.play.bind(Sound.pause, 1.0, -10.0))
	unpaused.connect(Sound.play.bind(Sound.unpause, 1.0, -10.0))

	# Ensure this node continues receiving input even when game is paused
	process_mode = PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	# Toggle pause when the pause input is pressed
	if event.is_action_pressed("pause"):
		is_paused = not is_paused
