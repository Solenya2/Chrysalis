# Item.gd — Base resource representing a generic item (usable, equippable, collectible).
# All item types (weapons, potions, armor, keys) should extend this class.

class_name Item
extends Resource

# The item's name shown in UI (e.g., "Potion")
@export var name: String

# Plural version of the name (e.g., "Potions"), used for stack displays or quantity messages
@export var plural_name: String

# Icon used to represent this item in inventory UI or shops
@export var icon: Texture

# Description shown in tooltips, menus, or item detail views
@export_multiline var description: String

# If true, this item is equippable (e.g., weapon, armor)
# If false, it's consumable, quest-related, or miscellaneous
@export var is_equipment := false
