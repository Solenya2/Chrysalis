# ItemBox.gd — A container that holds an item and its stack amount.
# Used by the inventory system to manage slots, serialization, and UI sync.

class_name ItemBox
extends RefCounted

# Stack size boundaries
const MIN_ITEM_STACK := 0
const MAX_ITEM_STACK := 99  # ← Tweak if you want limited/realistic stacks

# The actual item stored in this box (null if empty).
var item: Item :
	set(value):
		item = value
		item_changed.emit()

# Number of items in the stack. Clamped between min and max.
# If the amount drops to 0, the item is cleared (null).
var amount: int = 0 :
	set(value):
		amount = clamp(value, MIN_ITEM_STACK, MAX_ITEM_STACK)
		if amount == 0:
			item = null
		amount_changed.emit()

# Signals emitted when item or amount changes (for inventory UI, tooltips, etc.)
signal item_changed()
signal amount_changed()

# Sets both the item and the amount at once (e.g., during load or pickup).
# NOTE: Sets item first so amount setter can validate properly.
func set_item_and_amount(new_item: Item, new_amount := 1) -> ItemBox:
	item = new_item  # NOTE: Set item before amount so that amount logic sees a valid item
	amount = new_amount
	return self

# Returns true if the slot is completely empty (null item and 0 amount).
func is_empty() -> bool:
	return item is not Item and amount <= 0

# Saves this ItemBox as a dictionary (for file saving or stashing).
func serialize() -> Dictionary:
	var data := {}
	if item is Item:
		data.item_path = item.resource_path  # ← Assumes item is saved as a .tres or .res file
		data.amount = amount
	return data

# Loads this ItemBox from a dictionary.
# NOTE: Only works if the item resource exists at the saved path.
func deserialize(data: Dictionary) -> ItemBox:
	if data.has("item_path"):
		var loaded_item := load(data.item_path)
		item = loaded_item
		amount = data.amount
	return self
