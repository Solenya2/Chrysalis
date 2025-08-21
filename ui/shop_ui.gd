extends PanelContainer

@onready var grid: GridContainer = $ItemsGrid
@onready var exit_button: Button = $ExitButton

var _buttons: Array[Button] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	exit_button.pressed.connect(close_shop)
	Events.request_open_shop.connect(show_shop)

func show_shop(shop_items: Array[ShopItem]) -> void:
	get_tree().paused = true
	clear_grid()

	for s in shop_items:
		var slot := preload("res://ui/shop_slot_ui.tscn").instantiate()
		slot.setup(s)
		grid.add_child(slot)
		_buttons.append(slot)

	if _buttons:
		_buttons[0].grab_focus()

	show()
	exit_button.grab_focus()  # fallback if no items

func close_shop() -> void:
	hide()
	clear_grid()
	get_tree().paused = false
	Events.shop_closed.emit()

func clear_grid() -> void:
	for c in grid.get_children():
		c.queue_free()
	_buttons.clear()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		close_shop()
