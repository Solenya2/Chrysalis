# ReferenceStash.gd — Autoload
extends Node

# Existing data (yours)
var hero_stats: Stats = load("res://hero/hero_stats.tres")
var alignment: AlignmentData = load("res://Alignment/alignment_data.tres")
var inventory: Inventory = (
	Inventory.new()
	.set_size(16)
	.add_item(load("res://items/apple_item.tres"), 5)
	.add_item(load("res://items/apple_item.tres"), 5)
	.add_item(load("res://items/SunbeamItem.tres"), 1)
	.add_item(load("res://items/roll_ring_item.tres"), 3)
	.add_item(load("res://items/bomb_item.tres"), 9)
	.add_item(load("res://items/gold_item.tres"), 50)
	.add_item(load("res://items/CentipedeItem.tres"))
	
)

# --- Minimal additions for routing ---

# Generic counters you can grow over time (keep keys simple)
var stats := {
	"candies_eaten": 0,
}

# Persistent “was-triggered” flags for dimensions
var dimension_flags := {
	"slime": false,
	"candy": false,
}

# Optional: faction scores if you want Mori flavor text later
var faction_scores := {
	"slimes": {
		"friendly": 0,
		"hostile": 0,
	}
}

# -------- Helpers (tiny and reusable) --------

func add_candies(amount: int) -> void:
	stats.candies_eaten += amount
	# Example milestone → set flag once
	if stats.candies_eaten >= 1 and not dimension_flags.candy:
		dimension_flags.candy = true

func befriend_slime() -> void:
	faction_scores.slimes.friendly += 1
	# Example trigger rule — tweak to taste
	if faction_scores.slimes.friendly >= 1:
		dimension_flags.slime = true

func anger_slime() -> void:
	faction_scores.slimes.hostile += 1
	# If you want to cancel slime flag on hostility, do it here
	# dimension_flags.slime = false

func set_dimension_flag(id: String, value: bool = true) -> void:
	dimension_flags[id] = value

func has_dimension_flag(id: String) -> bool:
	return bool(dimension_flags.get(id, false))

func consume_dimension_flag(id: String) -> bool:
	var had := has_dimension_flag(id)
	if had:
		dimension_flags[id] = false
	return had
