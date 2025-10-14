extends StaticBody2D
class_name InteractSign

@export_multiline var text_block: String = "Line 1\n\nLine 2\n\nLine 3"
@export var page_delimiter: String = "\n\n"  # blank line = new page
@export var interaction_path: NodePath = NodePath("Interaction")

@onready var _interaction: Node = get_node_or_null(interaction_path)

func _ready() -> void:
	if _interaction and _interaction.has_signal("interacted"):
		_interaction.connect("interacted", Callable(self, "_on_interacted"))
	else:
		push_warning("Interaction node missing or has no 'interacted' signal.")

func _on_interacted() -> void:
	# Split the block into pages. Each page fills the dialog, player presses skip to advance.
	var pages: Array[String] = []
	for part in text_block.split(page_delimiter):
		var s := String(part).strip_edges()
		if s != "":
			pages.append(s)
	if pages.is_empty():
		return
	Events.request_show_lines.emit(pages)
