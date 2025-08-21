# Inventory.gd — Manages an array of ItemBoxes and provides all core inventory logic.
# Supports adding, removing, searching, serializing, and signal-based UI updates.

class_name Inventory
extends RefCounted

# Internal list of item containers
var _item_boxes: Array[ItemBox] = []

# Emitted when an item box is changed (for UI sync or logic updates)
signal item_box_changed(item_box, item_box_index)

# Sets the number of inventory slots and initializes them with empty ItemBoxes.
func set_size(size: int = 16) -> Inventory:
	_item_boxes.clear()
	_item_boxes.resize(size)
	for i in _item_boxes.size():
		_item_boxes[i] = ItemBox.new()
	return self

# Returns the list of ItemBoxes for external access (e.g., UI)
func get_item_boxes() -> Array:
	return _item_boxes

# Returns the item at a given index or null if out of bounds
func get_item(index: int) -> Item:
	if index < 0 or index >= _item_boxes.size():
		return null
	return _item_boxes[index].item

# Finds the index of an Item in the inventory (returns -1 if not found)
func get_item_index(item: Item) -> int:
	return _find_item_box_index_with_item(item)

# Adds an item to the inventory. If found, increase its stack; otherwise use a new slot.
func add_item(item: Item, amount: int = 1) -> Inventory:
	var item_box_index := _find_item_box_index_with_item(item)
	if item_box_index != -1:
		_change_item_amount(item_box_index, amount)
	else:
		_append_item(item, amount)
	return self

# Removes the specified amount of an item. Does nothing if item isn't found.
func remove_item(item: Item, amount := 1) -> Inventory:
	var item_box_index := _find_item_box_index_with_item(item)
	if item_box_index != -1:
		_change_item_amount(item_box_index, -amount)
	return self

# Returns the matching item if found, else null
func find_item(search_item: Item) -> Item:
	var item_box := _find_item_box_with_item(search_item)
	return item_box.item if item_box is ItemBox else null

# Returns true if the item exists in the inventory
func has_item(search_item: Item) -> bool:
	return find_item(search_item) is Item

# INTERNAL: Returns the index of the first ItemBox containing the given item
func _find_item_box_index_with_item(search_item: Item) -> int:
	var item_box := _find_item_box_with_item(search_item)
	return _item_boxes.find(item_box)

# INTERNAL: Finds the first ItemBox containing the given item
func _find_item_box_with_item(search_item: Item) -> ItemBox:
	var found_item_boxes := _item_boxes.filter(_item_box_has_item.bind(search_item))
	return found_item_boxes.front() if not found_item_boxes.is_empty() else null

# INTERNAL: Predicate function used to filter ItemBoxes
func _item_box_has_item(item_box: ItemBox, item: Item) -> bool:
	return item_box.item == item

# INTERNAL: Sets a specific ItemBox's item and amount, then emits change signal
func _set_item_box_item(index: int, item: Item, amount := 1) -> void:
	var item_box := _item_boxes[index]
	item_box.set_item_and_amount(item, amount)
	item_box_changed.emit(item_box, index)

# INTERNAL: Appends a new item to the first empty box
func _append_item(new_item: Item, amount := 1) -> void:
	var empty_item_box_index := _find_item_box_index_with_item(null)
	_set_item_box_item(empty_item_box_index, new_item, amount)

# INTERNAL: Changes the amount of an item in a specific box
func _change_item_amount(index: int, change_amount: int) -> void:
	var item_box := _item_boxes[index]
	_set_item_box_item(index, item_box.item, item_box.amount + change_amount)

# Saves all item boxes into a dictionary (for saving to disk)
func serialize() -> Dictionary:
	var data := {}
	data.item_boxes = []
	for item_box: ItemBox in _item_boxes:
		data.item_boxes.append(item_box.serialize())
	return data

# Loads item boxes from a saved dictionary
func deserialize(data: Dictionary) -> Inventory:
	_item_boxes.clear()
	for item_box_data in data.item_boxes:
		var item_box: ItemBox
		if item_box_data is Dictionary:
			item_box = ItemBox.new().deserialize(item_box_data)
		_item_boxes.append(item_box)
	return self
