# GameDesignStats.gd — Editor-accessible container for prototyping or organizing balance values.
# Holds lists of stat templates used for characters, enemies, etc.

class_name GameDesignStats
extends Resource

# List of base stat configurations (e.g., health, etc.)
@export var character_stats: Array[Stats]

# List of movement-related stat configurations (e.g., speed, accel, friction)
@export var character_movement_stats: Array[MovementStats]
