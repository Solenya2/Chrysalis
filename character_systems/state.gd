# Base State class for a state machine system.
# This is designed to be extended by specific states (e.g., IdleState, AttackState, etc.).
# It uses RefCounted so states can be reused and safely reference counted across the game.

class_name State
extends RefCounted

# The node (usually a character or enemy) that this state is controlling.
# The setter allows chaining and setup from outside.
var actor: Node2D : set = set_actor

# Signal emitted when this state finishes its purpose and wants to switch to another.
signal finished()

# Setter function for assigning the actor to the state.
# Returns 'self' so the state can be configured fluently (e.g. state.set_actor(enemy)).
func set_actor(value: Node2D) -> State:
	actor = value
	return self

# Called once when the state is entered (activated).
# Use this to set up animations, variables, or state-specific logic.
func enter() -> void:
	pass

# Called every physics frame while this state is active.
# Put movement or other physics-based logic here.
func physics_process(delta: float) -> void:
	pass

# Called when the state receives input not handled by the main node.
# Useful for player-controlled states like jumping, attacking, etc.
func unhandled_input(event: InputEvent) -> void:
	pass

# Called once when this state is exited (deactivated).
# Use this to clean up or reset anything you set up in 'enter'.
func exit() -> void:
	pass
