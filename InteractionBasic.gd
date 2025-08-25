extends StaticBody2D
class_name InteractTextOrToggle

# ---------- Basic (always-on) ----------
@export_multiline var message: String = "It's locked."

# ---------- Optional toggle mode ----------
@export var enable_toggle: bool = false
@export var start_open: bool = false
@export_multiline var message_when_open: String = "Take the milk?"
@export_multiline var message_when_closed: String = "Open the cabinet?"

# Sprite (2-frame) used only in toggle mode
@export var sprite_path: NodePath = NodePath("Sprite2D")
@export var open_frame: int = 0     # 0 = open
@export var closed_frame: int = 1   # 1 = closed

# Interaction node that emits `interacted`
@export var interaction_path: NodePath = NodePath("Interaction")

@onready var _interaction: Node = get_node_or_null(interaction_path)
@onready var _sprite: Sprite2D = get_node_or_null(sprite_path)

var _is_open: bool = false

func _ready() -> void:
	_is_open = start_open
	if enable_toggle:
		_apply_frame()

	if _interaction and _interaction.has_signal("interacted"):
		_interaction.connect("interacted", Callable(self, "_on_interacted"))
	else:
		push_warning("Interaction node missing or has no 'interacted' signal.")

func _on_interacted() -> void:
	if enable_toggle:
		# In toggle mode, DO NOT show the base message.
		var msg: String = message_when_open if _is_open else message_when_closed
		Events.request_show_dialog.emit(msg)
		_is_open = not _is_open
		_apply_frame()
		return

	# Simple mode: infinite popup of the base message
	Events.request_show_dialog.emit(message)

func _apply_frame() -> void:
	if not _sprite:
		return
	# Works with Sprite2D that has hframes/vframes >= 2 (spritesheet)
	if _sprite.hframes > 1 or _sprite.vframes > 1:
		_sprite.frame = open_frame if _is_open else closed_frame
