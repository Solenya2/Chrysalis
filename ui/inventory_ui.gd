# InventoryUI.gd — Grid-based UI component that displays inventory slots using InventorySlotUI.
# Dynamically creates, updates, and connects each slot to a shared inventory.

class_name InventoryUI
extends GridContainer

# Reference to the InventorySlotUI scene (instanced per slot)
const INVENTORY_SLOT_UI = preload("res://ui/inventory_slot_ui.tscn")

# Which slot is currently focused (for controller navigation)
var inventory_slot_index := 0

# Signal emitted when a slot is selected via input
signal inventory_slot_selected(inventory_ui, slot, event)

# Inventory data source this UI displays (set externally or via ReferenceStash)
var inventory: Inventory = null :
	set(value):
		inventory = value
		if inventory is not Inventory: return
		update_inventory_grid.call_deferred()

func _ready() -> void:
	# Set inventory from global stash if not already set
	inventory = ReferenceStash.inventory

# Programmatically focus the currently selected/focused inventory slot
func grab_inventory_slot_focus() -> void:
	get_child(inventory_slot_index).grab_focus()

# Main function to refresh all slots based on inventory content
func update_inventory_grid() -> void:
	clear_inventory_slots()
	fill_inventory_slots()

# Removes all existing InventorySlotUI children
func clear_inventory_slots() -> void:
	for child in get_children():
		child.queue_free()

# Re-populates the grid with slots based on current Inventory contents
func fill_inventory_slots() -> void:
	for item_box: ItemBox in inventory.get_item_boxes():
		var inventory_slot_ui := INVENTORY_SLOT_UI.instantiate()
		add_child(inventory_slot_ui)

		# When the slot is selected (via input), relay the signal up
		inventory_slot_ui.selected.connect(func(inventory_slot_ui: InventorySlotUI, event: InputEvent):
			inventory_slot_selected.emit(self, inventory_slot_ui, event)
		)

		# Update the current focus index when a slot gains focus
		inventory_slot_ui.focus_entered.connect(func():
			inventory_slot_index = inventory_slot_ui.get_index()
		)

		# Bind the inventory data to the slot
		inventory_slot_ui.item_box = item_box
