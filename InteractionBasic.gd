# InteractTextOrToggle.gd
# Toggleable interactable that:
# - In simple mode: shows a text popup on every interaction.
# - In toggle mode: asks a Yes/No question; only flips the sprite if the player picks "Yes".

extends StaticBody2D
class_name InteractTextOrToggle

# ---------- Basic (always-on) ----------
@export_multiline var message: String = "It's locked."

# ---------- Optional toggle mode ----------
@export var enable_toggle: bool = false
@export var start_open: bool = false
@export_multiline var message_when_open: String = "Close the cabinet?"    # shown when currently open
@export_multiline var message_when_closed: String = "Open the cabinet?"   # shown when currently closed

# Sprite (2-frame) used only in toggle mode
@export var sprite_path: NodePath = NodePath("Sprite2D")
@export var open_frame: int = 0     # frame used when open
@export var closed_frame: int = 1   # frame used when closed

# Interaction node that emits `interacted`
@export var interaction_path: NodePath = NodePath("Interaction")

# Optional: block re-clicks while waiting for the player's choice
@export var block_while_waiting_choice: bool = true

@onready var _interaction: Node = get_node_or_null(interaction_path)
@onready var _sprite: Sprite2D = get_node_or_null(sprite_path)

var _is_open: bool = false
var _awaiting_choice: bool = false
var _pending_target_open: bool = false

func _ready() -> void:
	_is_open = start_open
	if enable_toggle:
		_apply_frame()

	if _interaction and _interaction.has_signal("interacted"):
		_interaction.connect("interacted", Callable(self, "_on_interacted"))
	else:
		push_warning("Interaction node missing or has no 'interacted' signal.")

	# Listen for global dialog choice result
	if Events and not Events.dialog_choice_made.is_connected(_on_dialog_choice_made):
		Events.dialog_choice_made.connect(_on_dialog_choice_made)

func _exit_tree() -> void:
	if Events and Events.dialog_choice_made.is_connected(_on_dialog_choice_made):
		Events.dialog_choice_made.disconnect(_on_dialog_choice_made)

func _on_interacted() -> void:
	if block_while_waiting_choice and _awaiting_choice:
		return

	if enable_toggle:
		# Ask the question; only flip on "Yes" (index 0)
		var prompt := (message_when_open if _is_open else message_when_closed)
		Events.request_show_dialog.emit(prompt)              # show prompt text
		Events.request_dialog_choices.emit(["Yes", "No"])    # choices as Array (matches your signal)
		_awaiting_choice = true
		_pending_target_open = not _is_open
		return

	# Simple mode: just show the base message
	Events.request_show_dialog.emit(message)

func _on_dialog_choice_made(choice_idx: int) -> void:
	if not _awaiting_choice:
		return
	_awaiting_choice = false

	# Index 0 = "Yes"; any other index = "No"
	if choice_idx == 0:
		_is_open = _pending_target_open
		_apply_frame()

func _apply_frame() -> void:
	if not _sprite:
		return
	# Works with Sprite2D that uses hframes/vframes >= 2
	if _sprite.hframes > 1 or _sprite.vframes > 1:
		_sprite.frame = (open_frame if _is_open else closed_frame)
