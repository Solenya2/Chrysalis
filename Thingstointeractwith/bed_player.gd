extends StaticBody2D
class_name SimpleInteractText

@export var message: String = "hmm yup defintly a bed "
@export var one_shot: bool = false  # if true, only shows once

@onready var interaction: Node = $Interaction
var _used := false

func _ready() -> void:
	interaction.connect("interacted", _on_interacted)

func _on_interacted() -> void:
	if one_shot and _used:
		return
	_used = true
	Events.request_show_dialog.emit(message)
