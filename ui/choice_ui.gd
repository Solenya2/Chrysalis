class_name ChoiceUI
extends PanelContainer

@onready var button_template: Button      = $VBoxContainer/Button
@onready var vbox: VBoxContainer           = $VBoxContainer

var _buttons: Array[Button] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # keeps UI alive while tree is paused
	hide()
	Events.request_dialog_choices.connect(_show_choices)

# ------------------------------------------------------------------ #
func _show_choices(options) -> void:
	_clear_buttons()

	for i in options.size():
		var btn: Button = button_template.duplicate() as Button
		btn.visible = true
		btn.text    = options[i]
		vbox.add_child(btn)
		_buttons.append(btn)
		btn.pressed.connect(_on_choice_pressed.bind(i))

	if _buttons:
		_buttons[0].grab_focus()

	show()
	get_tree().paused = true                  # 🔒 freeze gameplay here
											  
# ------------------------------------------------------------------ #
func _on_choice_pressed(choice_idx: int) -> void:
	hide()
	_clear_buttons()
	get_tree().paused = false                 # 🔓 resume gameplay
	Events.dialog_choice_made.emit(choice_idx)

# ------------------------------------------------------------------ #
func _clear_buttons() -> void:
	for b in _buttons:
		b.queue_free()
	_buttons.clear()
