# EnemyWindUpState.gd — FSM state for charging enemies that flash and pause before attacking.
class_name EnemyWindUpState
extends State

# How long the wind-up lasts
@export var windup_duration := 0.5

# Name of the animation to play
@export var windup_animation := "windup"

# Should the enemy flash visually?
@export var use_flash := true

# Optional callback to run when wind-up ends (used for chaining into charge or other states)
var on_windup_finished: Callable = func() -> void: pass

# Internal timer
var timer := 0.0

func enter() -> void:
	var enemy := actor as Enemy
	timer = 0.0

	if use_flash:
		enemy.flasher.flash()

	if enemy.animation_player.has_animation(windup_animation):
		enemy.animation_player.play(windup_animation)

func physics_process(delta: float) -> void:
	timer += delta
	if timer >= windup_duration:
		on_windup_finished.call()

func set_on_finish(callback: Callable) -> EnemyWindUpState:
	on_windup_finished = callback
	return self
