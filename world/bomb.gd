# Bomb.gd — A simple timed bomb that flashes red before triggering an explosion.
# Plays 3 slow flashes followed by 3 fast flashes, then spawns an explosion effect.

extends Node2D

# Custom red color used for flashing effect (you can change this for different bomb types)
const CUSTOM_RED := Color("e64539")

# Node references
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var timer: Timer = $Timer

# Flasher used to change material color temporarily (via shader)
@onready var flasher: Flasher = Flasher.new().set_target(sprite_2d).set_color(CUSTOM_RED)

func _ready() -> void:
	# First phase: 3 slower red flashes (warning stage)
	for i in 3:
		timer.start(0.33)
		await timer.timeout
		await flasher.flash(0.33)

	# Second phase: 3 faster red flashes (final warning)
	for i in 3:
		timer.start(0.16)
		await timer.timeout
		await flasher.flash(0.16)

	# Spawn the explosion scene at the bomb’s position
	Utils.instantiate_scene_on_level(load("res://world/bomb_explosion.tscn"), global_position)

	# Remove bomb node after detonation
	queue_free()
