# HeroCentipedeState.gd
class_name HeroCentipedeState
extends HeroWeaponState

var target_enemy: Node2D = null
var original_facing: Vector2
var original_modulate: Color

func enter() -> void:
	started_at = Time.get_ticks_msec() / 1000.0
	assert(item is WeaponItem)
	item = item as WeaponItem

	var hero := actor as Hero
	original_facing = hero.facing_direction
	
	# Find the nearest enemy
	target_enemy = find_nearest_enemy()
	
	# If we found an enemy, face toward it and make it glow red
	if target_enemy:
		var direction_to_enemy = (target_enemy.global_position - hero.global_position).normalized()
		hero.facing_direction = direction_to_enemy
		
		# Make enemy glow red for targeting
		if target_enemy.has_method("get_sprite"):
			var enemy_sprite = target_enemy.get_sprite()
			original_modulate = enemy_sprite.modulate
			enemy_sprite.modulate = Color.RED
	
	# Set up attack properties
	hero.hitbox.knockback = hero.facing_direction * item.knockback
	hero.hitbox.damage = item.damage

	Sound.play(Sound.swipe, randf_range(0.8, 1.0), -5.0)
	
	# Play animation with stretching effect if target exists
	if target_enemy:
		play_stretching_animation()
	else:
		hero.play_animation(item.animation)

	await hero.animation_player.animation_finished
	finished.emit()

func find_nearest_enemy() -> Node2D:
	var hero := actor as Hero
	var enemies = hero.get_tree().get_nodes_in_group("enemies")
	var nearest_enemy: Node2D = null
	var min_distance = INF
	
	for enemy in enemies:
		var distance = hero.global_position.distance_squared_to(enemy.global_position)
		if distance < min_distance:
			min_distance = distance
			nearest_enemy = enemy
	
	return nearest_enemy

func play_stretching_animation() -> void:
	var hero := actor as Hero
	
	# Calculate distance to target
	var distance = hero.global_position.distance_to(target_enemy.global_position)
	var max_stretch = min(distance / 50.0, 3.0)  # Limit stretch factor
	
	# Store original scale
	var original_scale = hero.active_sprite.scale
	
	# Create stretching tween using hero's create_tween
	var stretch_tween = hero.create_tween()
	stretch_tween.set_parallel(true)
	
	# Stretch horizontally based on distance to enemy
	stretch_tween.tween_property(hero.active_sprite, "scale:x", 
								original_scale.x * max_stretch, 0.1)
	
	# Compress vertically slightly for a stretching effect
	stretch_tween.tween_property(hero.active_sprite, "scale:y", 
								original_scale.y * (1.0 - (max_stretch - 1.0) * 0.2), 0.1)
	
	# Play the animation
	hero.play_animation(item.animation)
	
	# After a short delay, return to normal scale
	await hero.get_tree().create_timer(0.2).timeout
	
	var return_tween = hero.create_tween()
	return_tween.set_parallel(true)
	return_tween.tween_property(hero.active_sprite, "scale", original_scale, 0.2)

func exit() -> void:
	var hero := actor as Hero
	
	# Restore enemy's original color if we targeted one
	if target_enemy and target_enemy.has_method("get_sprite"):
		var enemy_sprite = target_enemy.get_sprite()
		enemy_sprite.modulate = original_modulate
	
	# Restore original facing direction if needed
	hero.facing_direction = original_facing
	hero.hitbox.clear_stored_targets()
