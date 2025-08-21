# Stats.gd — A Resource that holds and manages health values for a character or unit.
# Supports runtime changes, emits signals, and can be serialized for saving/loading.

class_name Stats
extends Resource

# Max health of the unit — default is 1.0 (placeholder, likely to be tuned per character).
# Changing this value will emit a signal and reset current health to new max.
# NOTE: This value is likely a placeholder and should be tuned for different unit types.
@export var max_health := 1.0 :  # ← Probably adjusted during balancing
	set(value):
		var change := value - max_health
		max_health = value
		# Whenever max health changes, health is reset to full.
		health = max_health
		if change != 0:
			max_health_changed.emit(max_health)

# Current health of the unit.
# Setter clamps it between 0 and max_health, emits signals when changed or depleted.
var health := max_health :
	set(value):
		var change := value - health
		# Clamp to avoid going below 0 or over max_health.
		health = clamp(value, 0, max_health)
		
		if change != 0:
			health_changed.emit(health)

		# If health hits zero, emit death event.
		if is_health_gone():
			no_health.emit()

# Signal emitted when max health changes (e.g., upgrade or item effect).
signal max_health_changed(new_max_health)

# Signal emitted when current health changes (e.g., damage or healing).
signal health_changed(new_health)

# Signal emitted when health reaches zero.
signal no_health()

# Helper function to check if the unit has died or been depleted.
func is_health_gone() -> bool:
	return health <= 0

# Serializes this Stats resource into a dictionary (for saving).
func serialize() -> Dictionary:
	var data := {}
	data.health = health
	data.max_health = max_health
	return data

# Loads stats from a saved dictionary.
# NOTE: Max health must be set first to ensure clamping logic works correctly.
func deserialize(data: Dictionary) -> Stats:
	max_health = data.max_health  # ← Set this first to avoid clamping errors
	health = data.health
	return self
