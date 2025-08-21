class_name HeroLaserState

extends State

@export var projectile_scene: PackedScene
@export var fire_delay := 0.1

var has_fired := false
var item: Item  # ✅ Needed so we can assign item from Hero.gd

func enter() -> void:
	has_fired = false
	actor.play_animation("idle")  # optional

func physics_process(delta: float) -> void:
	if !has_fired:
		print("Laser: state active but not yet fired.")
	if has_fired:
		return

	if Input.is_action_just_pressed("shoot_sunbeam"):
		shoot_laser()
		has_fired = true
		await actor.get_tree().create_timer(fire_delay).timeout
		finished.emit()

func shoot_laser() -> void:
	print("Laser fired!")

	if projectile_scene == null:
		push_warning("Laser projectile scene is not assigned!")
		return

	var muzzle := actor.get_node_or_null("SunbeamMuzzle") as Node2D
	if muzzle == null:
		push_error("SunbeamMuzzle node not found on hero.")
		return

	var direction: Vector2 = actor.facing_direction
	var nearest_enemy := find_nearest_enemy(muzzle.global_position)
	if nearest_enemy:
		direction = (nearest_enemy.global_position - muzzle.global_position).normalized()

	var laser = Utils.instantiate_scene_on_level(projectile_scene, muzzle.global_position)
	laser.set_direction(direction)
	laser.set_speed(200.0)

	# 🔁 Rotate the laser to match its movement direction
	laser.rotation = direction.angle() + deg_to_rad(90)



func find_nearest_enemy(origin: Vector2) -> Node2D:
	var enemies: Array = actor.get_tree().get_nodes_in_group("enemies")
	var closest: Node2D = null
	var closest_dist := INF

	for enemy in enemies:
		if not enemy is Node2D:
			continue
		var dist := origin.distance_to(enemy.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = enemy

	return closest
