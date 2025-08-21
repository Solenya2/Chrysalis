class_name BossDecisionState
extends State

var fsm
var slam_state: State
var charge_state: State
var summon_state: State
var chase_state: State

# Cooldown durations
@export var slam_cooldown := 3.0
@export var charge_cooldown := 4.5
@export var summon_cooldown := 8.0

# Internal timers (start as ready)
var slam_timer := slam_cooldown
var charge_timer := charge_cooldown
var summon_timer := summon_cooldown

func enter():
	actor.velocity = Vector2.ZERO
	choose_attack()

func physics_process(delta: float):
	slam_timer += delta
	charge_timer += delta
	summon_timer += delta

func choose_attack() -> void:
	var hero = MainInstances.hero
	if hero == null:
		fsm.change_state(chase_state)
		return

	var dist = actor.global_position.distance_to(hero.global_position)

	match actor.phase:
		1:
			if dist <= 96 and actor.slam_timer >= actor.slam_cooldown:
				print("Choosing SLAM")
				actor.slam_timer = 0.0
				fsm.change_state(slam_state)
				return

			if actor.charge_timer >= actor.charge_cooldown:
				print("Choosing CHARGE")
				actor.charge_timer = 0.0
				fsm.change_state(actor.windup_state)
				return

			print("Choosing CHASE")
			fsm.change_state(chase_state)

		# same for phase 2 with actor.summon_timer
