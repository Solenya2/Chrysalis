extends State
class_name BlimboDecisionState

var fsm: FSM
var chase_state: State
var attack_state: BlimboDirectionalAttackState

@export var attack_range: float = 64.0
@export var attack_cooldown: float = 0.8  # seconds

var _next_attack_time: float = 0.0

func _now() -> float:
	return float(Time.get_ticks_msec()) / 1000.0

func enter() -> void:
	# nothing to reset; we use absolute time
	pass

func physics_process(_delta: float) -> void:
	var boss := actor as Node2D
	var hero := MainInstances.hero
	if boss == null or hero == null:
		return

	var now := _now()
	var dist := boss.global_position.distance_to(hero.global_position)

	if dist <= attack_range and now >= _next_attack_time:
		attack_state.choose_direction_from(boss.global_position, hero.global_position)
		_next_attack_time = now + attack_cooldown
		fsm.change_state(attack_state)
	else:
		# Re-enter chase; your BlimboChasePulseState will emit finished()
		# every ~0.35s so we bounce back here to reassess.
		fsm.change_state(chase_state)

func exit() -> void:
	# no stamping; we keep absolute time
	pass
