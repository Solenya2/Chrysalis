# ActionSlotUI.gd — A single slot in the ActionsUI, visually linked to an inventory item.
# Updates icon and amount label based on the assigned inventory index.

class_name ActionSlotUI
extends TextureRect

# Reference to the global inventory (assumes it's already stashed).
var inventory := ReferenceStash.inventory as Inventory

# Which item index in the inventory this slot is linked to.
var action_item_index := -1 : set = set_action_item_index

# Label node that displays how many items are in the stack.
@onready var amount_label: Label = $AmountLabel

# Called when action_item_index is changed — reconnects signals and refreshes UI.
func set_action_item_index(value: int) -> void:
	disconnect_from_item_box()  # Remove previous signal connections
	action_item_index = value
	connect_to_item_box()       # Connect to new item box's signals
	update_item()               # Refresh visuals

func _ready() -> void:
	update_item()

# Gets the ItemBox in inventory assigned to this slot.
func get_item_box() -> ItemBox:
	var item_box: ItemBox = inventory.get_item_boxes()[action_item_index]
	assert(item_box is ItemBox, "No item box found at index " + str(action_item_index))
	return item_box

# Connects to the item box's change signals so the UI stays updated.
func connect_to_item_box() -> void:
	var item_box := get_item_box()
	item_box.item_changed.connect(update_item)
	item_box.amount_changed.connect(update_label_amount)

# Disconnects from old item box signals before re-assigning or freeing.
func disconnect_from_item_box() -> void:
	var item_box := get_item_box()
	if item_box.item_changed.is_connected(update_item):
		item_box.item_changed.disconnect(update_item)
	if item_box.amount_changed.is_connected(update_label_amount):
		item_box.amount_changed.disconnect(update_label_amount)

# Updates the icon and amount label based on the assigned item.
func update_item() -> void:
	ItemSlotManager.update_slot_icon(get_item_box(), self, "texture")
	update_label_amount()

# Updates just the amount label.
func update_label_amount() -> void:
	ItemSlotManager.update_slot_amount(get_item_box(), amount_label)
