# HealthUI.gd — Manages and updates heart icons based on the hero's Stats resource.
# Automatically adjusts visible hearts and their fill level when health changes.

class_name HealthUI
extends HBoxContainer

# Reference to the hero's Stats resource (assumes it's globally stashed)
var stats := ReferenceStash.hero_stats as Stats

# Node that contains all heart slots (children of type HeartUI)
@onready var hearts: HBoxContainer = $Hearts

func _ready() -> void:
	# Connect health and max health changes to update the UI dynamically
	stats.max_health_changed.connect(update_max_hearts)
	stats.health_changed.connect(update_hearts)

	# Initialize UI on load
	update_max_hearts(stats.max_health)
	update_hearts(stats.health)

# Updates which hearts are visible based on max health.
# Only enables the number of hearts equal to max_health.
func update_max_hearts(max_health_amount: int) -> void:
	for i in hearts.get_child_count():
		var heart_ui := hearts.get_child(i)
		heart_ui.visible = (i < max_health_amount)

# Updates the fill state of each visible heart.
func update_hearts(health_amount: float) -> void:
	for i in hearts.get_child_count():
		var heart_ui := hearts.get_child(i) as HeartUI
		if not heart_ui.visible:
			break

		# Subtract the heart index from the total health to determine how full this heart should be.
		var leftover_health := health_amount - i
		heart_ui.update_quarter_hearts(leftover_health)
