# HeroInventoryManager.gd — Manages inventory interactions specific to the hero/player.
# Handles slot selection, emits quick-slot assignment requests via input mapping.

class_name HeroInventoryManager
extends VBoxContainer

# Reference to the visual InventoryUI component
@onready var inventory_ui: InventoryUI = $InventoryUI

func _ready() -> void:
	# Link this UI to the current inventory (from ReferenceStash)
	inventory_ui.inventory = ReferenceStash.inventory

	# Respond to slot selection events (usually via key or mouse input)
	inventory_ui.inventory_slot_selected.connect(_on_inventory_slot_selected)

# Used to programmatically focus the inventory (e.g., when opening the inventory menu)
func grab_inventory_ui_focus() -> void:
	inventory_ui.grab_inventory_slot_focus()

# Called when the player selects an inventory slot with an input action.
# Emits an event to assign that slot to a corresponding action slot (0 = roll, 1 = weapon, etc.)
func _on_inventory_slot_selected(
	inventory_ui: InventoryUI,
	inventory_slot_ui: InventorySlotUI,
	event: InputEvent
) -> void:
	var slot_index: int = inventory_slot_ui.get_index()

	# Assign slot to Action 0 (Roll)
	if event.is_action("roll"):
		Events.request_new_action.emit(0, slot_index)

	# Assign slot to Action 1 (Weapon)
	if event.is_action("weapon"):
		Events.request_new_action.emit(1, slot_index)

	# Assign slot to Action 2 (Misc)
	if event.is_action("misc"):
		Events.request_new_action.emit(2, slot_index)
