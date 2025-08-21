# gameover_menu.gd — Handles the game over screen. Lets the player retry or quit.

extends ColorRect

# UI button references
@onready var yes_button: Button = %YesButton
@onready var no_button: Button = %NoButton

func _ready() -> void:
	# Automatically focus the "Yes" button when menu opens
	yes_button.grab_focus()
	
	# "Yes" logic: reload from save if it exists, otherwise start a new game
	yes_button.pressed.connect(func():
		if SaveManager.has_save_file():
			SaveManager.load_game()
		else:
			get_tree().change_scene_to_file("res://world.tscn")
	)

	# "No" logic: exit the game entirely
	no_button.pressed.connect(get_tree().quit)
