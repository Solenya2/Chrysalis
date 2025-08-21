class_name BossChaseState
extends EnemyChaseState

@export var chase_time := 1.5
var timer := 0.0
var has_finished := false

func enter() -> void:
	timer = 0.0
	has_finished = false
	print("✅ Entering BossChaseState")

	var boss := actor as SamiBoss
	if boss and boss.has_method("play_walk_animation"):
		boss.play_walk_animation()

func physics_process(delta: float) -> void:
	if has_finished:
		return

	timer += delta
	print("⏱️ Chase timer:", timer)

	if timer >= chase_time:
		has_finished = true
		print("🏁 BossChaseState finished, returning to decision.")
		emit_signal("finished")
		return

	var boss := actor as SamiBoss
	var hero := MainInstances.hero
	if not boss or not hero:
		return

	var map_rid := boss.navigation_agent_2d.get_navigation_map()
	if NavigationServer2D.map_get_iteration_id(map_rid) == 0:
		return

	boss.navigation_agent_2d.target_position = hero.global_position
	var next_point := boss.navigation_agent_2d.get_next_path_position()
	var dir := boss.global_position.direction_to(next_point)

	if dir.x != 0:
		boss.sprite_2d.scale.x = sign(dir.x)

	boss.play_walk_animation()
	CharacterMover.accelerate_in_direction(boss, dir, boss.movement_stats, delta)
	CharacterMover.move(boss)
