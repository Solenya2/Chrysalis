class_name EnemyShootProjectileState
extends State

@export var projectile_scene: PackedScene
@export var shoot_animation := "spit"
@export var fire_delay := 0.2
@export var projectile_speed := 100.0
@export var shoot_marker_path: NodePath

var _shoot_marker: Node2D

func _ready() -> void:
	print("✅ EnemyShootProjectileState: _ready called")

func enter() -> void:
	print("🔁 Shoot state entered")
	var enemy := actor as Enemy

	if enemy == null:
		print("❌ ERROR: Actor is not set!")
		return

	# Play animation if valid
	if enemy.animation_player.has_animation(shoot_animation):
		print("🎬 Playing animation:", shoot_animation)
		enemy.animation_player.play(shoot_animation)
		await enemy.animation_player.animation_finished
	else:
		print("⚠️ No animation found:", shoot_animation)

	# Delay before shooting
	print("⏳ Waiting", fire_delay, "seconds")
	await enemy.get_tree().create_timer(fire_delay).timeout

	# Find shoot marker or use self
	if shoot_marker_path.is_empty():
		_shoot_marker = enemy
	else:
		if enemy.has_node(shoot_marker_path):
			_shoot_marker = enemy.get_node(shoot_marker_path)
		else:
			print("❌ ERROR: Shoot marker path not found")
			finished.emit()
			return

	var spawn_pos := _shoot_marker.global_position
	print("📍 Spawn position:", spawn_pos)

	var hero := MainInstances.hero
	if not hero:
		print("❌ ERROR: Hero is missing")
		finished.emit()
		return

	var base_direction := spawn_pos.direction_to(hero.global_position).normalized()
	print("🎯 Base direction to hero:", base_direction)

	print("💥 Spawning 1000 SPORES")
	for i in 50:
		var spore := projectile_scene.instantiate() as Projectile
		if spore == null:
			print("❌ Failed to instantiate spore")
			continue

		var offset := Vector2(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5)).normalized()
		var dir := (base_direction + offset).normalized()

		spore.set_direction(dir).set_speed(projectile_speed)
		spore.global_position = spawn_pos

		# Safely add to scene
		enemy.get_tree().current_scene.call_deferred("add_child", spore)

		if i % 100 == 0:
			print("🧪 Spawned", i, "spores")

	print("✅ All spores spawned. Ending state.")
	await enemy.get_tree().create_timer(0.2).timeout
	finished.emit()
