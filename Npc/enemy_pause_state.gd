# EnemyPauseState.gd — FSM state that pauses the enemy for a fixed amount of time before continuing.
# Useful for creating pacing, attack windups, or staggered movement between markers.

class_name EnemyPauseState
extends State

# How long to pause (in seconds) before resuming the next state.
# NOTE: Can be adjusted per use case — e.g., for timing between shots or idle moments.
var pause_time := 2.0 : set = set_pause_time

# Setter for chaining and customization (e.g., .set_pause_time(1.5))
func set_pause_time(value: float) -> EnemyPauseState:
	pause_time = value
	return self

# Called when entering the state — starts a timer, then emits 'finished' when time is up.
func enter() -> void:
	var enemy := actor as Enemy
	
	# Waits for the pause time (non-blocking) before signaling that the pause is over.
	await enemy.get_tree().create_timer(pause_time).timeout
	finished.emit()
