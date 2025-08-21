# ItemState.gd — Base FSM state for using items (healing, placing, rolling, weapons, etc.).
# Stores a reference to the item being used so it can be handled by specialized states.

class_name ItemState
extends State

# The item assigned to this state (must be set before entering the state).
var item: Item : set = set_item

# Setter method that returns self for method chaining.
# Example: state.set_item(my_potion).set_actor(hero)
func set_item(value: Item) -> ItemState:
	item = value
	return self
