extends Area2D
class_name CutsceneTrigger

signal cutscene_requested

@export var one_shot := true
var _active := true

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	

func _on_body_entered(body: Node2D) -> void:
	var hero := MainInstances.hero
	print("working")
	if not _active or body != hero:
		return
	_active = not one_shot
	cutscene_requested.emit(self)
