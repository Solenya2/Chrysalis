class_name BossDecisionState
extends State

var fsm
var slam_state: State
var charge_state: State
var summon_state: State
var chase_state: State

func enter():
	actor.velocity = Vector2.ZERO
	choose_attack()

func physics_process(delta: float):
	# Don't update timers here - they're already updated in the boss's _physics_process
	pass

func choose_attack() -> void:
	var hero = MainInstances.hero
	if hero == null:
		fsm.change_state(chase_state)
		return

	var dist = actor.global_position.distance_to(hero.global_position)
	var boss := actor as SamiBoss
	
	if not boss:
		fsm.change_state(chase_state)
		return

	match boss.phase:
		1:
			if dist <= 96 and boss.slam_timer >= boss.slam_cooldown:
				print("Choosing SLAM")
				boss.slam_timer = 0.0
				fsm.change_state(slam_state)
				return

			if boss.charge_timer >= boss.charge_cooldown:
				print("Choosing CHARGE")
				boss.charge_timer = 0.0
				fsm.change_state(boss.windup_state)
				return

			print("Choosing CHASE")
			fsm.change_state(chase_state)

		2:
			# Phase 2 logic - include summoning
			if dist <= 96 and boss.slam_timer >= boss.slam_cooldown:
				print("Choosing SLAM")
				boss.slam_timer = 0.0
				fsm.change_state(slam_state)
				return

			if boss.charge_timer >= boss.charge_cooldown:
				print("Choosing CHARGE")
				boss.charge_timer = 0.0
				fsm.change_state(boss.windup_state)
				return

			if boss.summon_timer >= boss.summon_cooldown:
				print("Choosing SUMMON")
				boss.summon_timer = 0.0
				boss._start_summon()
				return

			print("Choosing CHASE")
			fsm.change_state(chase_state)

		3, 4:
			# Add logic for phases 3 and 4 if needed
			print("Choosing CHASE (phase ", boss.phase, ")")
			fsm.change_state(chase_state)
