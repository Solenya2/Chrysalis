# Interaction.gd — A generic Area2D used to detect and trigger interactable events.
# Can be used for talking to NPCs, opening doors, reading signs, etc.

class_name Interaction
extends Area2D

# Designated collision layer for interactions (custom Layer 6).
# NOTE: This must match the layer setup in project settings for proper filtering.
const INTERACTION_LAYER_NUMBER := 6

# Emitted when the player triggers this interaction (e.g., presses a button nearby).
signal interacted

func _ready() -> void:
	# Disable default collision layer/mask (Layer 1) to avoid unintended physics overlap.
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)

	# Enable interaction-specific layer so only the correct systems pick it up.
	set_collision_layer_value(INTERACTION_LAYER_NUMBER, true)

func run() -> void:
	# Call this method when interaction is triggered (e.g., by player input).
	# This emits the signal to whatever's listening.
	interacted.emit()
