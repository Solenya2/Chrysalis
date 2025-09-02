class_name CutsceneDialogbox
extends DialogBox

func _ready() -> void:
	super._ready()  # Call parent ready so rich_text_label is assigned properly.

	# Disconnect only if it's connected (avoids warning).
	if Events.request_show_dialog.is_connected(type_dialog):
		Events.request_show_dialog.disconnect(type_dialog)

	# Already enabled in parent, but harmless to repeat if needed.
	rich_text_label.bbcode_enabled = true
	hide()  # Ensure it's hidden initially.

func _input(_event: InputEvent) -> void:
	pass  # Cutscene dialog shouldn't respond to any input.

func type_dialog(bbcode: String) -> void:
	is_typing = true
	show()

	rich_text_label.text = bbcode
	var total_characters: int = rich_text_label.text.length()
	var duration: float = total_characters * CHARACTER_DISPLAY_DURATION

	typer = create_tween()
	typer.tween_method(set_visible_characters, 0, total_characters, duration)
	await typer.finished

	is_typing = false
	hide()
	Events.dialog_finished.emit()
