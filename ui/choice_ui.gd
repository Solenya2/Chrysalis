class_name ChoiceUI
extends PanelContainer

@onready var vbox: VBoxContainer      = $VBoxContainer
@onready var button_template: Button  = $VBoxContainer/Button

@export var horizontal_layout: bool = true
@export var panel_min_width: float = 120.0
@export var button_min_width: float = 40.0
@export var button_min_height: float = 36.0
@export var button_spacing: int = 12

var _buttons: Array[Button] = []
var _buttons_container: Container
var _paused_game := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()

	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_minimum_size.x = panel_min_width

	button_template.hide()
	button_template.reparent(self)

	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)

	if horizontal_layout:
		var row := HBoxContainer.new()
		row.name = "ButtonsRow"
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", button_spacing)
		_buttons_container = row
		vbox.add_child(row)
	else:
		_buttons_container = vbox
		vbox.add_theme_constant_override("separation", button_spacing)

	Events.request_dialog_choices.connect(_show_choices)

func _show_choices(options: Array) -> void:
	_clear_buttons()

	for i in options.size():
		var btn := button_template.duplicate() as Button
		btn.name = "Choice_%d" % i
		btn.visible = true
		btn.text = str(options[i])

		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_stretch_ratio = 1.0
		var tmin := button_template.get_combined_minimum_size()
		btn.custom_minimum_size = Vector2(
			maxf(button_min_width, tmin.x),
			maxf(button_min_height, tmin.y)
		)

		_buttons_container.add_child(btn)
		_buttons.append(btn)
		btn.pressed.connect(_on_choice_pressed.bind(i))

	if _buttons.size() > 0:
		_buttons[0].grab_focus()

	show()

	# Let layout settle before pausing
	await get_tree().process_frame
	if not _paused_game:
		get_tree().paused = true
		_paused_game = true

func _on_choice_pressed(choice_idx: int) -> void:
	# 1) Tell the dialog box to close if it’s still open
	Events.request_close_dialog.emit()

	# 2) Close choices UI
	hide()
	_clear_buttons()

	# 3) Safety: if still paused after dialog handles its close, unpause
	await get_tree().process_frame
	if get_tree().paused:
		get_tree().paused = false
		_paused_game = false

	# 4) Notify listeners about the choice
	Events.dialog_choice_made.emit(choice_idx)

func _clear_buttons() -> void:
	for b in _buttons:
		if is_instance_valid(b):
			b.queue_free()
	_buttons.clear()
	if is_instance_valid(_buttons_container):
		for c in _buttons_container.get_children():
			if c is Button:
				c.queue_free()
