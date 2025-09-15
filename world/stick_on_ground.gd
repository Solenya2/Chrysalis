# SwordInTheStone.gd — A one-time interactable that gives the player a sword and shows a dialog.
# Uses Stasher for persistence, Interaction for triggering, and Inventory to add the item.

extends StaticBody2D

# Child nodes
@onready var interaction: Interaction = $Interaction
@onready var sprite_2d: Sprite2D = $Sprite2D

# Used to persist collection state across sessions
@onready var stasher := Stasher.new().set_target(self)

func _ready() -> void:
	# If the sword was already collected, update state visually and disable interaction
	if stasher.retrieve_property("collected"):
		set_collected()

	# Connect interaction event to collect logic
	interaction.interacted.connect(collect_sword)

func collect_sword() -> void:
	var stick := load("res://items/StickItem.tres")
	var inventory := ReferenceStash.inventory as Inventory

	# Add the sword to inventory
	inventory.add_item(stick)
	var stick_index := inventory.get_item_index(stick)

	# If something went wrong, abort
	if stick_index == -1: return

	# Mark this interaction as completed
	stasher.stash_property("collected", true)
	set_collected()

	# Show dialog with item name
	Events.request_show_dialog.emit("You found a " + stick.name + ".")

func set_collected() -> void:
	# Visually mark sword as collected (e.g. switch to empty pedestal sprite)
	sprite_2d.frame = 0

	# Disable further interaction
	interaction.queue_free()
