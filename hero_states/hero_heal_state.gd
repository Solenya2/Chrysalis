# HeroHealState.gd
class_name HeroHealState
extends ItemState

func enter() -> void:
	assert(item is HealingItem, "HealState item isn't HealingItem")
	item = item as HealingItem

	var hero := actor as Hero
	var inv := ReferenceStash.inventory as Inventory

	if not inv.has_item(item):
		finished.emit()
		return

	# Play the healing animation
	hero.play_animation(item.animation)
	
	# Wait for the animation to finish before consuming the item
	await hero.animation_player.animation_finished

	# Now consume the item and apply effects
	inv.remove_item(item)
	hero.stats.health += item.heal_amount

	# CANDY HOOK
	if item.is_candy:
		ReferenceStash.add_candies(1)

	finished.emit()

func physics_process(delta: float) -> void:
	var hero: = actor as Hero
	# Optional: Add movement deceleration during healing
	CharacterMover.decelerate(hero, hero.movement_stats, delta)
	CharacterMover.move(hero)
