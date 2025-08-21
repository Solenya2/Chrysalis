# bomb_explosion.gd — Handles visual and audio effects for a bomb detonation.
# Spawns explosion and smoke VFX, plays sound, and removes itself after a timer.

extends Node2D

@onready var timer: Timer = $Timer

func _ready() -> void:
	# Spawn explosion VFX
	Utils.instantiate_scene_on_level(load("res://effects/explosion_effect.tscn"), global_position)

	# Spawn smoke effect at the same position
	Utils.instantiate_scene_on_level(load("res://effects/smoke_effect.tscn"), global_position)

	# Automatically free this node when the timer finishes
	timer.timeout.connect(queue_free)

	# Play explosion sound effect
	Sound.play(Sound.explosion)
