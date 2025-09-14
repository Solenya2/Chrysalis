class_name DialogBox
extends PanelContainer

const CHARACTER_DISPLAY_DURATION := 0.08

var typer: Tween
var is_typing: bool = false
var current_choices: Array = []
var choice_buttons: Array[Button] = []
var is_showing_choices: bool = false
var signals_connected: bool = false

@onready var rich_text_label: RichTextLabel = $MarginContainer/RichTextLabel
@onready var choices_container: VBoxContainer = $MarginContainer/ChoicesContainer
@onready var button_template: Button = $MarginContainer/ChoicesContainer/ButtonTemplate

func _ready() -> void:
	print("DialogBox _ready() called")
	process_mode = Node.PROCESS_MODE_ALWAYS
	rich_text_label.bbcode_enabled = true
	button_template.hide()
	
	# Make the button template itself very small
	button_template.custom_minimum_size = Vector2(50, 22)
	button_template.add_theme_font_size_override("font_size", 11)
	
	# Configure the choices container
	choices_container.size_flags_vertical = Control.SIZE_SHRINK_END
	choices_container.size_flags_horizontal = Control.SIZE_SHRINK_END
	choices_container.add_theme_constant_override("separation", 4)
	
	# Safely connect signals only once
	_connect_signals()

func _connect_signals() -> void:
	if signals_connected:
		return
	
	# Disconnect first to avoid duplicates
	if Events.request_show_dialog.is_connected(show_dialog):
		Events.request_show_dialog.disconnect(show_dialog)
	if Events.request_dialog_choices.is_connected(show_choices):
		Events.request_dialog_choices.disconnect(show_choices)
	if Events.request_close_dialog.is_connected(close_dialog):
		Events.request_close_dialog.disconnect(close_dialog)
	
	Events.request_show_dialog.connect(show_dialog)
	Events.request_dialog_choices.connect(show_choices)
	Events.request_close_dialog.connect(close_dialog)
	
	signals_connected = true

func _exit_tree() -> void:
	# Safely disconnect from events
	if signals_connected:
		if Events.request_show_dialog.is_connected(show_dialog):
			Events.request_show_dialog.disconnect(show_dialog)
		if Events.request_dialog_choices.is_connected(show_choices):
			Events.request_dialog_choices.disconnect(show_choices)
		if Events.request_close_dialog.is_connected(close_dialog):
			Events.request_close_dialog.disconnect(close_dialog)
		signals_connected = false

func _input(event: InputEvent) -> void:
	if not visible:
		return
		
	# Only handle input if we're not showing choices
	if not is_showing_choices and (
		event.is_action_pressed("roll") or
		event.is_action_pressed("weapon") or
		event.is_action_pressed("left_mouse") or
		event.is_action_pressed("right_mouse")
	):
		if is_typing:
			# Skip typing animation
			is_typing = false
			if typer is Tween:
				typer.kill()
			rich_text_label.visible_ratio = 1.0
			
			# Consume the input event so it doesn't trigger other actions
			get_viewport().set_input_as_handled()
		else:
			# Close dialog and consume the input event
			close_dialog()
			get_viewport().set_input_as_handled()

func show_dialog(bbcode: String) -> void:
	# Clear any previous choices and text
	clear_choices()
	rich_text_label.text = ""
	
	is_typing = true
	get_tree().paused = true
	show()

	rich_text_label.text = bbcode
	var total_characters: int = rich_text_label.get_total_character_count()
	var duration: float = total_characters * CHARACTER_DISPLAY_DURATION

	typer = create_tween()
	typer.tween_method(set_visible_characters, 0, total_characters, duration)
	await typer.finished
	is_typing = false

func show_choices(options: Array) -> void:
	is_showing_choices = true
	current_choices = options.duplicate()
	
	# Wait for any ongoing typing to finish
	if is_typing:
		await typer.finished
	
	# Create choice buttons
	for i in options.size():
		var btn: Button = button_template.duplicate()
		btn.text = str(options[i])
		btn.visible = true
		
		# Make buttons smaller
		btn.custom_minimum_size = Vector2(50, 22)
		btn.add_theme_font_size_override("font_size", 11)
		
		btn.pressed.connect(_on_choice_pressed.bind(i))
		choices_container.add_child(btn)
		choice_buttons.append(btn)
	
	# Position the choices container dynamically based on text
	await get_tree().process_frame  # Wait for layout to update
	_position_choices_based_on_text()
	
	# Show the choices container
	choices_container.show()
	
	# Focus the first button
	if choice_buttons.size() > 0:
		choice_buttons[0].grab_focus()

func _position_choices_based_on_text() -> void:
	# Calculate text metrics
	var text_width = rich_text_label.get_content_width()
	var text_height = rich_text_label.get_content_height()
	var text_position = rich_text_label.position
	
	# Get choices container size
	var choices_size = choices_container.size
	
	# Calculate available space
	var available_space_right = size.x - (text_position.x + text_width)
	var available_space_below = size.y - (text_position.y + text_height)
	
	# Position choices based on available space
	if available_space_right > choices_size.x + 20:  # Enough space to the right
		# Position to the right of the text with a small margin
		choices_container.position = Vector2(
			text_position.x + text_width + 10,  # 10px right of text
			text_position.y + text_height - choices_size.y  # Align with text bottom
		)
	elif available_space_below > choices_size.y + 10:  # Enough space below
		# Position below the text
		choices_container.position = Vector2(
			text_position.x + text_width - choices_size.x,  # Right-align with text
			text_position.y + text_height + 10  # 10px below text
		)
	else:
		# Not enough space anywhere, position at bottom right of dialog
		choices_container.position = Vector2(
			size.x - choices_size.x - 10,  # 10px from right edge
			size.y - choices_size.y - 10   # 10px from bottom edge
		)

func _on_choice_pressed(choice_index: int) -> void:
	# Emit the choice made event
	Events.dialog_choice_made.emit(choice_index)
	
	# Clear choices and close dialog
	clear_choices()
	close_dialog()

func set_visible_characters(index: int) -> void:
	rich_text_label.visible_characters = index

func clear_choices() -> void:
	is_showing_choices = false
	current_choices.clear()
	
	for btn in choice_buttons:
		if is_instance_valid(btn):
			btn.queue_free()
	choice_buttons.clear()
	
	choices_container.hide()
	choices_container.position = Vector2.ZERO  # Reset position

func close_dialog() -> void:
	if is_typing and typer is Tween:
		typer.kill()
	
	is_typing = false
	clear_choices()
	hide()
	
	get_tree().paused = false
	Events.dialog_finished.emit()
