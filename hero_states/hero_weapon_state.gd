class_name HeroWeaponState
extends ItemState

const KNOCKBACK_AMOUNT := 175
var started_at: float = 0.0

func enter() -> void:
	started_at = Time.get_ticks_msec() / 1000.0
	assert(item is WeaponItem)
	item = item as WeaponItem

	# Now this works correctly
	print("Emitting hero attack")
	Events.hero_attacked.emit(actor.global_position, actor.facing_direction)

	var hero := actor as Hero
	hero.hitbox.knockback = hero.facing_direction * item.knockback
	hero.hitbox.damage = item.damage

	Sound.play(Sound.swipe, randf_range(0.8, 1.0), -5.0)
	hero.play_animation(item.animation)

	await hero.animation_player.animation_finished
	finished.emit()

func physics_process(delta: float) -> void:
	var hero: = actor as Hero
	CharacterMover.decelerate(hero, hero.movement_stats, delta)
	CharacterMover.move(hero)

func exit() -> void:
	var hero: = actor as Hero
	hero.hitbox.clear_stored_targets()
