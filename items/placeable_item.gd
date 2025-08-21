# PlaceableItem.gd — An item that, when used, spawns a scene into the world.
# Ideal for placing objects like traps, decorations, turrets, or summons.

class_name PlaceableItem
extends Item

# The scene that will be placed when this item is used.
# This should be a PackedScene (e.g., a .tscn object).
@export var scene: PackedScene
