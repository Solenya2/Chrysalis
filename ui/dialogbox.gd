# Dialogbox.gd — A rich-text dialog system with typewriter effect and input-based control.
# Uses Events.request_show_dialog(bbcode) to display text, supports BBCode and auto-pauses gameplay.

class_name Dialogbox
extends PanelContainer

# Duration per character for the typewriter effect.
const CHARACTER_DISPLAY_DURATION := 0.08

# Tween used for typing effect and flag to track if it's active.
var typer: Tween
var is_typing: bool = false

# UI reference
@onready var rich_text_label: RichTextLabel = $MarginContainer/RichTextLabel

func _ready() -> void:
	# Enable BBCode so formatting tags can be used.
	rich_text_label.bbcode_enabled = true

	# Listen for global dialog trigger events.
	Events.request_show_dialog.connect(type_dialog)

func _input(event: InputEvent) -> void:
	# Ignore input if dialog box isn't shown.
	if not visible:
		return

	# Only respond to input mapped to confirm/advance actions.
	if not (
		event.is_action_pressed("roll")
		or event.is_action_pressed("weapon")
		or event.is_action_pressed("left_mouse")
		or event.is_action_pressed("right_mouse")
	):
		return

	if is_typing:
		# If text is still typing, instantly reveal it.
		is_typing = false
		if typer is Tween:
			typer.kill()
		rich_text_label.visible_ratio = 1.0
	else:
		# If text is fully shown, close dialog and resume game.
		hide()
		get_tree().paused = false
		get_viewport().set_input_as_handled()
		Events.dialog_finished.emit()

func type_dialog(bbcode: String) -> void:
	# Start typing the dialog.
	is_typing = true
	get_tree().paused = true  # Pause the game while dialog is active.
	show()

	rich_text_label.text = bbcode
	var total_characters: int = rich_text_label.text.length()
	var duration: float = total_characters * CHARACTER_DISPLAY_DURATION

	# Start typewriter tween.
	typer = create_tween()
	typer.tween_method(set_visible_characters, 0, total_characters, duration)
	await typer.finished
	is_typing = false

func set_visible_characters(index: int) -> void:
	# Updates how many characters are visible as text types in.
	rich_text_label.visible_characters = index
