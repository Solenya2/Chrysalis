extends StaticBody2D
class_name ToggleInteractable

@export var start_open: bool = false
@export var anim_name_closed: String = "closed"
@export var anim_name_open: String = "open"

@export var prompt_when_closed: String = "Open the cabinet?"
@export var prompt_when_open: String = "Take the milk? i pinky promise its not rotten"

# If true, once opened it won’t close again.
@export var disable_after_open: bool = false

@onready var interaction: Node = $Interaction
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sprite2d: Sprite2D = get_node_or_null("Sprite2D")

var _is_open: bool

func _ready() -> void:
	_is_open = start_open
	_apply_visual()
	interaction.connect("interacted", _on_interacted)

func _on_interacted() -> void:
	if disable_after_open and _is_open:
		Events.request_show_dialog.emit(prompt_when_open)
		return

	# Show context text (Python-style ternary)
	var msg: String = prompt_when_open if _is_open else prompt_when_closed
	Events.request_show_dialog.emit(msg)

	_is_open = not _is_open
	_apply_visual()

func _apply_visual() -> void:
	# Prefer AnimationPlayer if the clips exist
	if anim:
		var want: String = anim_name_open if _is_open else anim_name_closed
		if anim.has_animation(want):
			anim.play(want)
			return

	# Fallback: Sprite2D 2-frame sheet (0=closed, 1=open)
	if sprite2d:
		if sprite2d.hframes > 1 or sprite2d.vframes > 1:
			sprite2d.frame = 1 if _is_open else 0
