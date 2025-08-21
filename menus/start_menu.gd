# start_menu.gd — Handles logic for the main menu screen: continue, new game, and quit options.

extends ColorRect

# UI button references
@onready var continue_button: Button = %ContinueButton
@onready var new_game_button: Button = %NewGameButton
@onready var quit_button: Button = %QuitButton

func _ready() -> void:
	# Check if a save file exists — only then show the Continue button
	if SaveManager.has_save_file():
		continue_button.show()
		continue_button.grab_focus()  # Autofocus Continue
	else:
		continue_button.hide()
		new_game_button.grab_focus()  # Autofocus New Game when no save

	# Connect button presses to their respective actions
	continue_button.pressed.connect(SaveManager.load_game)
	new_game_button.pressed.connect(get_tree().change_scene_to_file.bind("res://world.tscn"))
	quit_button.pressed.connect(get_tree().quit)
