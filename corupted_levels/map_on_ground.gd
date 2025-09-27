extends StaticBody2D

@onready var interaction: Interaction = $Interaction
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var stasher := Stasher.new().set_target(self)

func _ready() -> void:
	if stasher.retrieve_property("collected"):
		set_collected()
		return
	interaction.interacted.connect(_collect_map)

func _collect_map() -> void:
	var map_item: Item = load("res://items/MapItem.tres")
	var inventory := ReferenceStash.inventory as Inventory
	inventory.add_item(map_item)

	# Confirm it landed in inventory (optional guard)
	if inventory.get_item_index(map_item) == -1:
		return

	stasher.stash_property("collected", true)
	set_collected()
	Events.request_show_dialog.emit("You found a " + map_item.name + ".")

func set_collected() -> void:
	# Optional: swap sprite/frame to “empty”
	if "frame" in sprite_2d:
		sprite_2d.frame = 0
	interaction.queue_free()
