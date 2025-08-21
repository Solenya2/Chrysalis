# HeroHealState.gd
class_name HeroHealState
extends ItemState

func enter() -> void:
	assert(item is HealingItem, "HealState item isn’t HealingItem")
	item = item as HealingItem

	var hero := actor as Hero
	var inv := ReferenceStash.inventory as Inventory

	if not inv.has_item(item):
		finished.emit()
		return

	# consume first so we can't double-trigger on failure
	inv.remove_item(item)

	# apply heal (clamp if you track max hp elsewhere)
	hero.stats.health += item.heal_amount

	# CANDY HOOK
	if item.is_candy:
		ReferenceStash.add_candies(1)  # this will flip dimension_flags.candy when threshold hits

	finished.emit()
