# Level.gd — Base scene for levels, enabling Y-sorting for visual depth.
# All specific level scenes should inherit from this to maintain consistent behavior.

class_name Level
extends Node2D

func _ready() -> void:
	# Enables Y-sorting so objects are drawn based on vertical position.
	# This makes characters in front of others appear visually "closer."
	y_sort_enabled = true
