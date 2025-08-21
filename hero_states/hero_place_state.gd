# HeroPlaceState.gd — FSM state where the hero uses a placeable item.
# Validates, removes the item from inventory, and spawns its scene in the world.

class_name HeroPlaceState
extends ItemState  # Assumes ItemState provides a reference to 'item' and 'actor'

func enter() -> void:
	# Ensure the item being used is a PlaceableItem (prevents logic errors).
	assert(item is PlaceableItem, "The item in your place state is not a placeable item.")
	item = item as PlaceableItem

	var hero := actor as Hero
	var inventory = ReferenceStash.inventory as Inventory

	# If the item is available in inventory, remove one and place it in the world.
	if inventory.has_item(item):
		inventory.remove_item(item)

		# Instantiate the scene defined by the PlaceableItem at the hero’s position.
		Utils.instantiate_scene_on_level(item.scene, hero.global_position)

	# Immediately finish the state after placing the item.
	finished.emit()
