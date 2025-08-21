# HeroRollState.gd — FSM state for performing a roll (evade/dodge) action.
# Temporarily grants invincibility, plays roll animation and sound, and moves the hero.

class_name HeroRollState
extends ItemState  # Assumes 'item' is set externally to a RollItem (or will be removed later)

func enter() -> void:
	# Ensure item is a RollItem; this may be removed when rolling becomes a player stat instead.
	assert(item is RollItem, "The item in your roll state is not a roll item.")
	item = item as RollItem

	var hero := actor as Hero

	# Enable invincibility frames.
	hero.hurtbox.is_invincible = true

	# Play roll animation defined by the RollItem.
	hero.play_animation(item.animation)

	# Play dodge/evade sound with slight pitch variation.
	Sound.play(Sound.evade, randf_range(0.8, 1.0))

	# Wait until the roll animation finishes before exiting state.
	await hero.animation_player.animation_finished

	# Done — emit signal to return to previous or default state.
	finished.emit()

func physics_process(delta: float) -> void:
	var hero := actor as Hero

	# Apply movement in current direction using roll-specific movement stats.
	CharacterMover.accelerate_in_direction(hero, hero.direction, hero.roll_movement_stats, delta)
	CharacterMover.move(hero)

func exit() -> void:
	var hero := actor as Hero

	# Disable invincibility when leaving roll state.
	hero.hurtbox.is_invincible = false
