# AnimatedSpriteEffect.gd — Temporary visual effect using an AnimatedSprite2D.
# Plays a one-shot animation (like an explosion or impact) and then deletes itself.

class_name AnimatedSpriteEffect
extends AnimatedSprite2D

func _ready() -> void:
	# Once the animation finishes, automatically remove this node from the scene.
	# This keeps things clean and prevents manual cleanup.
	animation_finished.connect(queue_free)


#this is smokeeffect at least thats the name
