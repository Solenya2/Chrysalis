# HealingItem.gd — A simple consumable item that restores health when used.
# Extends the base Item class and adds a healing-specific stat.

class_name HealingItem
extends Item

# How much health this item restores when used.
# NOTE: This can be tuned per item (e.g., potion = 25, mega_potion = 100).
@export var heal_amount := 1.0  # ← Placeholder, adjust for real values
@export var is_candy: bool = true   # <-- toggle this on the candy item
@export_enum("eat") var animation: String = "eat" 
