# res://bosses/blimbo/states/BlimboChasePulseState.gd
# Wraps chase with a periodic finished() so Decision can re-evaluate.
# We re-implement the chase logic to avoid the "hero is not Hero" type guard
# and any art-specific calls in your global EnemyChaseState.

extends EnemyChaseState
class_name BlimboChasePulseState

@export var reevaluate_interval: float = 0.35
var _t := 0.0

func enter() -> void:
	_t = 0.0

func physics_process(delta: float) -> void:
	_t += delta

	var enemy := actor as Enemy
	if enemy == null:
		return

	var hero := MainInstances.hero
	if hero == null:
		return

	if navigation_agent == null:
		return

	# Ensure nav map is valid before querying a path
	var map_rid := navigation_agent.get_navigation_map()
	if NavigationServer2D.map_get_iteration_id(map_rid) == 0:
		return

	# Update target and step path
	navigation_agent.target_position = hero.global_position
	var next_point := navigation_agent.get_next_path_position()

	# Direction toward the next path point
	var dir := enemy.global_position.direction_to(next_point)

	# Optional: play evolved walk if your boss exposes helpers
	if enemy.has_method("play_walk_animation"):
		if dir.length_squared() > 0.0001:
			enemy.play_walk_animation()
	elif enemy.has_node("AnimationPlayer"):
		var ap := enemy.get_node("AnimationPlayer") as AnimationPlayer
		if ap and ap.has_animation("evolved_walk") and ap.current_animation != "evolved_walk":
			ap.play("evolved_walk")

	# Move using your CharacterMover
	CharacterMover.accelerate_in_direction(enemy, dir, enemy.movement_stats, delta)
	CharacterMover.move(enemy)

	# Pulse back to Decision periodically so it can decide to attack/chase again
	if _t >= reevaluate_interval:
		_t = 0.0
		finished.emit()
