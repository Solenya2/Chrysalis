# InteractionDetector.gd — Detects and triggers nearby interactable areas (Interaction nodes).
# Attach to the player or a directional ray to handle "press button to interactxz"x mechanics.

class_name InteractionDetector
extends Area2D

# Triggers all nearby Interaction nodes by calling their 'run()' method.
# This will emit their 'interacted' signal and trigger their effect.
func trigger_interaction() -> void:
	var interactions = get_overlapping_areas()
	for interaction: Interaction in interactions:
		interaction.run()

# Returns true if there's at least one interactable object nearby.
# Can be used to show interaction prompts (e.g., "Press [E]").
func can_interact() -> bool:
	return not get_overlapping_areas().is_empty()
