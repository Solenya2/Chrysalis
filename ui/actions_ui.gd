# ActionsUI.gd — Manages the 3 action slots in the UI for assigning and using quick-access items.
# Handles swapping, updating visuals, and save/load via serialized indexes.

class_name ActionsUI
extends VBoxContainer

# Tracks which item index is assigned to each action slot.
# -1 means empty slot.
var _action_item_indexes = [-1, -1, -1]

# Signal to notify the system/UI that an item's index changed in one of the slots.
signal item_index_changed(action_index)

# References to each ActionSlotUI node.
@onready var action_slot_ui_1: ActionSlotUI = %ActionSlotUI1
@onready var action_slot_ui_2: ActionSlotUI = %ActionSlotUI2
@onready var action_slot_ui_3: ActionSlotUI = %ActionSlotUI3

# Register in MainInstances when added to the scene.
func _enter_tree() -> void:
	MainInstances.actions_ui = self

# Deregister on removal.
func _exit_tree() -> void:
	MainInstances.actions_ui = null

func _ready() -> void:
	# When an action is requested (e.g. by inventory or drag/drop), assign it.
	Events.request_new_action.connect(set_action)

	# When an item's slot changes, update the UI to reflect it.
	item_index_changed.connect(update_action_slot_ui_item_index)

# Internal setter for a specific action index → sets item and triggers events.
func _set_action_item_index(action_index: int, new_item_index: int) -> void:
	_action_item_indexes[action_index] = new_item_index
	item_index_changed.emit(action_index)
	Events.action_changed.emit(action_index, new_item_index)

# If an item is already assigned to a different slot, swap the two.
func _swap_action_item_indexes(previous_action_index: int, new_action_index: int) -> void:
	var temp_item_index: int = _action_item_indexes[previous_action_index]
	_set_action_item_index(previous_action_index, _action_item_indexes[new_action_index])
	_set_action_item_index(new_action_index, temp_item_index)

# Public method to assign an item to a slot.
# If it's already assigned, it swaps slots instead.
func set_action(action_index: int, new_item_index: int) -> void:
	var found_action_index = _action_item_indexes.find(new_item_index)
	if found_action_index != -1:
		_swap_action_item_indexes(found_action_index, action_index)
	else:
		_set_action_item_index(action_index, new_item_index)

# Updates the corresponding ActionSlotUI with the correct item index.
func update_action_slot_ui_item_index(action_index: int) -> void:
	var item_index: int = _action_item_indexes[action_index]
	var action_slot_ui := get_child(action_index) as ActionSlotUI
	action_slot_ui.action_item_index = item_index

# Serializes the action bar state for saving.
func serialize() -> Dictionary:
	var data := {}
	data.action_item_indexes = []
	for item_index in _action_item_indexes:
		data.action_item_indexes.append(item_index)
	return data

# Rebuilds the action bar state from saved data.
func update_from_serialized_data(data: Dictionary) -> void:
	for i in data.action_item_indexes.size():
		var item_index = data.action_item_indexes[i]
		_set_action_item_index(i, item_index)
