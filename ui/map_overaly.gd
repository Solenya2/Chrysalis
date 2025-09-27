# res://ui/MapOverlay.gd
extends Control

const MAP_ITEM_TRES := "res://items/MapItem.tres"

var _map_item: Item

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # still handles input while paused
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_map_item = load(MAP_ITEM_TRES)

func _unhandled_input(e: InputEvent) -> void:
	# Open/close on M only if player owns the map
	if e.is_action_pressed("map"):
		if _owns_map():
			if visible:
				_close()
			else:
				_open()
		accept_event()

	# Close on Esc
	if visible and e.is_action_pressed("Ui_cancel"):
		_close()
		accept_event()

func _owns_map() -> bool:
	# Prefer exact resource match (works if pickups add the same .tres)
	if ReferenceStash.inventory.has_item(_map_item):
		return true
	# Fallback by script type in case you duplicated the resource
	for box in ReferenceStash.inventory.get_item_boxes():
		if box.item and box.item.get_script() == _map_item.get_script():
			return true
	return false

func _open() -> void:
	visible = true
	_pause(true)
	focus_mode = FOCUS_ALL
	grab_focus()

func _close() -> void:
	visible = false
	_pause(false)

func _pause(b: bool) -> void:
	var pm := get_node_or_null("/root/PauseManager")
	if pm and pm.has_method("set_paused"):
		pm.set_paused(b, "map")
	else:
		get_tree().paused = b
