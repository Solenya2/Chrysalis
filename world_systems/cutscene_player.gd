class_name CutscenePlayer
extends Node

signal cutscene_started
signal cutscene_finished

var _commands: Array[Callable] = []
var _is_running := false

func play(commands: Array[Callable]) -> void:
	if _is_running:
		push_warning("Cutscene already running.")
		return

	_commands = commands
	_is_running = true
	emit_signal("cutscene_started")
	_process_next()

func _process_next() -> void:
	if _commands.is_empty():
		_is_running = false
		emit_signal("cutscene_finished")
		Events.dialog_finished.emit()
		return

	var command: Callable = _commands.pop_front()
	await command.call()
	_process_next()
