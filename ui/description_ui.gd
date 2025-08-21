# DescriptionUI.gd — A UI panel for displaying a title and a rich-text description.
# Responds to global Events.request_description(title, description) to show/hide as needed.

class_name DescriptionUI
extends PanelContainer

# UI components
@onready var title_label: Label = %TitleLabel
@onready var description_label: RichTextLabel = %DescriptionLabel

func _ready() -> void:
	# Connects to global event that requests a UI description update.
	Events.request_description.connect(_update_description)

# Updates the UI content or hides it if both fields are empty.
func _update_description(title: String, description: String) -> void:
	if title.is_empty() and description.is_empty():
		hide()
	else:
		show()
		title_label.text = title
		description_label.text = description
