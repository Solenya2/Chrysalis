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
	print("DialogBox _ready() called")  # Debug
	process_mode = Node.PROCESS_MODE_ALWAYS
	rich_text_label.bbcode_enabled = true
	button_template.hide()
	
	# Safely connect signals only once
	_connect_signals()

func _connect_signals() -> void:
	if signals_connected:
		print("Signals already connected, skipping.")  # Debug
		return
	
	print("Connecting signals")  # Debug
	
	# Disconnect first to avoid duplicates (in case of hot-reload)
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
	print("DialogBox _exit_tree() called")  # Debug
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
		else:
			# Close dialog
			close_dialog()

func show_dialog(bbcode: String) -> void:
	print("Show dialog: ", bbcode)  # Debug
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
	print("Show choices: ", options)  # Debug
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
		btn.pressed.connect(_on_choice_pressed.bind(i))
		choices_container.add_child(btn)
		choice_buttons.append(btn)
	
	# Show the choices container
	choices_container.show()
	
	# Focus the first button
	if choice_buttons.size() > 0:
		choice_buttons[0].grab_focus()

func _on_choice_pressed(choice_index: int) -> void:
	print("Choice pressed: ", choice_index)  # Debug
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

func close_dialog() -> void:
	print("Close dialog")  # Debug
	if is_typing and typer is Tween:
		typer.kill()
	
	is_typing = false
	clear_choices()
	hide()
	
	get_tree().paused = false
	Events.dialog_finished.emit()
