## DialogBox.gd
class_name DialogBox
extends PanelContainer

const CHARACTER_DISPLAY_DURATION := 0.08

# ── State ────────────────────────────────────────────────────────────────
var typer: Tween
var is_typing: bool = false
var is_showing_choices: bool = false
var signals_connected: bool = false

# Staged prompt→choices mode
var awaiting_prompt_dismiss: bool = false
var staged_choices: Array = []
@export var clear_text_on_choices: bool = true  # true = hide text when showing staged choices

# Bookkeeping for choices
var current_choices: Array = []
var choice_buttons: Array[Button] = []

# ── Nodes ────────────────────────────────────────────────────────────────
@onready var rich_text_label: RichTextLabel = $MarginContainer/RichTextLabel
@onready var choices_container: VBoxContainer = $MarginContainer/ChoicesContainer
@onready var button_template: Button = $MarginContainer/ChoicesContainer/ButtonTemplate

# ── Lifecycle ────────────────────────────────────────────────────────────
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	rich_text_label.bbcode_enabled = true

	# Button template setup
	button_template.hide()
	button_template.custom_minimum_size = Vector2(50, 22)
	button_template.add_theme_font_size_override("font_size", 11)

	# Choices container cosmetics
	choices_container.size_flags_vertical = Control.SIZE_SHRINK_END
	choices_container.size_flags_horizontal = Control.SIZE_SHRINK_END
	choices_container.add_theme_constant_override("separation", 4)
	choices_container.hide()

	_connect_signals()

func _exit_tree() -> void:
	if signals_connected:
		if Events.request_show_dialog.is_connected(show_dialog):
			Events.request_show_dialog.disconnect(show_dialog)
		if Events.request_dialog_choices.is_connected(show_choices):
			Events.request_dialog_choices.disconnect(show_choices)
		if Events.request_close_dialog.is_connected(close_dialog):
			Events.request_close_dialog.disconnect(close_dialog)
		if Events.request_prompt_then_choices.is_connected(show_prompt_then_choices):
			Events.request_prompt_then_choices.disconnect(show_prompt_then_choices)
		signals_connected = false

func _connect_signals() -> void:
	if signals_connected:
		return

	# Disconnect first (safety in case of hot-reload)
	if Events.request_show_dialog.is_connected(show_dialog):
		Events.request_show_dialog.disconnect(show_dialog)
	if Events.request_dialog_choices.is_connected(show_choices):
		Events.request_dialog_choices.disconnect(show_choices)
	if Events.request_close_dialog.is_connected(close_dialog):
		Events.request_close_dialog.disconnect(close_dialog)
	if Events.request_prompt_then_choices.is_connected(show_prompt_then_choices):
		Events.request_prompt_then_choices.disconnect(show_prompt_then_choices)

	Events.request_show_dialog.connect(show_dialog)
	Events.request_dialog_choices.connect(show_choices)
	Events.request_close_dialog.connect(close_dialog)
	# NEW: staged flow (prompt → skip → choices)
	Events.request_prompt_then_choices.connect(show_prompt_then_choices)

	signals_connected = true

# ── Input handling ───────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if not visible:
		return

	# Only handle input when NOT showing choices
	if not is_showing_choices and (
		event.is_action_pressed("roll")
		or event.is_action_pressed("weapon")
		or event.is_action_pressed("left_mouse")
		or event.is_action_pressed("right_mouse")
	):
		if is_typing:
			# Skip typing animation
			is_typing = false
			if typer is Tween:
				typer.kill()
			# Instantly reveal text
			rich_text_label.visible_ratio = 1.0
			get_viewport().set_input_as_handled()
		else:
			# If we're awaiting prompt dismissal, switch to choices instead of closing
			if awaiting_prompt_dismiss:
				_transition_prompt_to_choices()
				get_viewport().set_input_as_handled()
				return

			# Normal: close dialog
			close_dialog()
			get_viewport().set_input_as_handled()

# ── API: staged prompt → choices ─────────────────────────────────────────
func show_prompt_then_choices(bbcode: String, options: Array) -> void:
	# Reset UI
	awaiting_prompt_dismiss = true
	staged_choices = options.duplicate()
	is_showing_choices = false
	current_choices.clear()
	clear_choices() # just in case
	rich_text_label.text = ""
	rich_text_label.visible_characters = 0

	# Open dialog and type prompt
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

func _transition_prompt_to_choices() -> void:
	awaiting_prompt_dismiss = false

	# Clear the prompt text if requested
	if clear_text_on_choices:
		rich_text_label.text = ""
		rich_text_label.visible_characters = 0

	# Show the already-staged options without closing/unpausing
	show_choices(staged_choices)
	staged_choices.clear()

# ── API: show a line of text (keeps dialog open) ─────────────────────────
func show_dialog(bbcode: String) -> void:
	clear_choices()
	rich_text_label.text = ""
	rich_text_label.visible_characters = 0
	awaiting_prompt_dismiss = false
	staged_choices.clear()

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

# ── API: show choices (assumes dialog already open) ──────────────────────
func show_choices(options: Array) -> void:
	is_showing_choices = true
	current_choices = options.duplicate()

	# Wait for any ongoing typing to finish
	if is_typing:
		await typer.finished

	# Build buttons
	for i in options.size():
		var btn: Button = button_template.duplicate()
		btn.text = str(options[i])
		btn.visible = true

		# Compact style to match your template
		btn.custom_minimum_size = Vector2(50, 22)
		btn.add_theme_font_size_override("font_size", 11)

		btn.pressed.connect(_on_choice_pressed.bind(i))
		choices_container.add_child(btn)
		choice_buttons.append(btn)

	# Wait a frame for proper layout, then position choices
	await get_tree().process_frame
	_position_choices_based_on_text()

	choices_container.show()

	# Focus first button
	if choice_buttons.size() > 0:
		choice_buttons[0].grab_focus()

# ── Choice plumbing ──────────────────────────────────────────────────────
func _on_choice_pressed(choice_index: int) -> void:
	Events.dialog_choice_made.emit(choice_index)
	# Clear choices and close dialog (this will emit dialog_finished + unpause)
	clear_choices()
	close_dialog()

# ── Utilities ────────────────────────────────────────────────────────────
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
	choices_container.position = Vector2.ZERO

func close_dialog() -> void:
	if is_typing and typer is Tween:
		typer.kill()
	is_typing = false
	awaiting_prompt_dismiss = false
	staged_choices.clear()

	clear_choices()
	hide()

	# Unpause and inform listeners
	get_tree().paused = false
	Events.dialog_finished.emit()

func _position_choices_based_on_text() -> void:
	# Measure text block
	var text_width := rich_text_label.get_content_width()
	var text_height := rich_text_label.get_content_height()
	var text_position := rich_text_label.position

	# Choices size after layout
	var choices_size := choices_container.size

	# Space to the right / below
	var available_space_right := size.x - (text_position.x + text_width)
	var available_space_below := size.y - (text_position.y + text_height)

	# Prefer right of text, then below, else bottom-right corner
	if available_space_right > choices_size.x + 20:
		choices_container.position = Vector2(
			text_position.x + text_width + 10,
			text_position.y + text_height - choices_size.y
		)
	elif available_space_below > choices_size.y + 10:
		choices_container.position = Vector2(
			text_position.x + text_width - choices_size.x,
			text_position.y + text_height + 10
		)
	else:
		choices_container.position = Vector2(
			size.x - choices_size.x - 10,
			size.y - choices_size.y - 10
		)
