class_name FSM
extends RefCounted

# Active state and the one we came from
var state: State : set = set_state
var previous_state: State = null

func set_state(value: State) -> FSM:
	if state != null:
		state.exit()
	previous_state = state
	state = value
	if state != null:
		state.enter()
	return self

func change_state(new_state: State) -> void:
	set_state(new_state)

# Optional helper: go back to previous state
func revert_state() -> void:
	if previous_state != null:
		change_state(previous_state)
