# InventorySlotUI.gd — UI button representing a single inventory slot.
# Handles input, sound, tooltip descriptions, and visual updates in sync with ItemBox data.

class_name InventorySlotUI
extends Button

# Label showing stack amount
@onready var amount_label: Label = $AmountLabel

# The actual item data source for this slot (binds to signals on set)
@onready var item_box := ItemBox.new() :
	set(value):
		item_box = value
		if item_box is not ItemBox: return
		item_box.item_changed.connect(update_item)
		item_box.amount_changed.connect(update_label_amount)
		update_item()

# Signal emitted when this slot is selected with input (roll, weapon, misc)
signal selected(inventory_slot_ui, event)

func _ready() -> void:
	update_item()

	# When focused (via keyboard/gamepad), show tooltip and play move sound
	focus_entered.connect(func():
		show_item_description()
		Sound.play(Sound.menu_move, randf_range(0.6, 1.0), -10.0)
	)

	# When selected, play selection sound
	selected.connect(Sound.play.bind(Sound.menu_select).unbind(2))

# Handle specific key/mouse inputs for assigning the slot
func _gui_input(event: InputEvent) -> void:
	if (
		event.is_action_pressed("roll")
		or event.is_action_pressed("weapon")
		or event.is_action_pressed("misc")
	):
		selected.emit(self, event)

# Shows the item’s name and description in the DescriptionUI panel
func show_item_description() -> void:
	var title := ""
	var description := ""
	if item_box.item is Item:
		title = item_box.item.name
		description = item_box.item.description
	Events.request_description.emit(title, description)

# Updates icon and amount label based on current item state
func update_item() -> void:
	ItemSlotManager.update_slot_icon(item_box, self, "icon")
	update_label_amount()

# Updates just the stack amount label
func update_label_amount() -> void:
	ItemSlotManager.update_slot_amount(item_box, amount_label)
