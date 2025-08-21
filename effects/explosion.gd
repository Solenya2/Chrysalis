extends Node2D
class_name Explosion

@onready var anim := $AnimationPlayer

func _ready() -> void:
	anim.play("explode")
	anim.animation_finished.connect(_on_animation_finished)

func _on_animation_finished(_name: String) -> void:
	queue_free()
