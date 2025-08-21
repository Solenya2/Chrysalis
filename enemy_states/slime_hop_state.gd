# SlimeHopState.gd
class_name SlimeHopState
extends State

var navigation_agent: NavigationAgent2D : set = set_navigation_agent
func set_navigation_agent(v: NavigationAgent2D) -> SlimeHopState:
	navigation_agent = v
	return self

@export var hop_speed: float = 140.0
@export var hop_air_time: float = 0.22
@export var hop_rest_time: float = 0.26
@export var min_stop_distance: float = 24.0

@export var slam_range: float = 28.0
@export var slam_cooldown: float = 1.1
@export var slam_lock_time: float = 0.45

enum Phase { AIR, REST }
var _phase: Phase = Phase.REST
var _t: float = 0.0
var _slam_cd: float = 0.0
var _slamming: bool = false

func enter() -> void:
	_phase = Phase.REST
	_t = hop_rest_time
	_slam_cd = 0.0
	_slamming = false

func physics_process(delta: float) -> void:
	var slime := actor as Enemy
	var hero := MainInstances.hero as Hero
	if hero is not Hero:
		return

	_t = maxf(0.0, _t - delta)
	_slam_cd = maxf(0.0, _slam_cd - delta)

	if _slamming:
		CharacterMover.move(slime)
		return

	var target_pos := hero.global_position
	if navigation_agent:
		var map := navigation_agent.get_navigation_map()
		if NavigationServer2D.map_get_iteration_id(map) != 0:
			navigation_agent.target_position = hero.global_position
			target_pos = navigation_agent.get_next_path_position()

	var to_target := slime.global_position.direction_to(target_pos)
	var dist := slime.global_position.distance_to(target_pos)

	if to_target.x != 0.0:
		slime.sprite_2d.scale.x = sign(to_target.x)

	if _phase == Phase.REST and dist <= slam_range and _slam_cd <= 0.0:
		_do_ground_slam(slime)
		CharacterMover.move(slime)
		return

	match _phase:
		Phase.AIR:
			slime.velocity = to_target * hop_speed
			if _t <= 0.0:
				_phase = Phase.REST
				_t = hop_rest_time
		Phase.REST:
			slime.velocity.x = move_toward(slime.velocity.x, 0.0, 900.0 * delta)
			slime.velocity.y = move_toward(slime.velocity.y, 0.0, 900.0 * delta)
			if dist > min_stop_distance and _t <= 0.0:
				_phase = Phase.AIR
				_t = hop_air_time

	CharacterMover.move(slime)

func _do_ground_slam(slime: Enemy) -> void:
	_slamming = true
	_slam_cd = slam_cooldown
	slime.velocity = Vector2.ZERO
	if slime.animation_player.has_animation("ground_slam"):
		slime.animation_player.play("ground_slam")
	await slime.get_tree().create_timer(slam_lock_time, false).timeout
	_slamming = false
