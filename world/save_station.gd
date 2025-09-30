# SaveStation.gd — A static save point that allows the player to manually save their progress.
# Uses Interaction to trigger save logic and UI feedback.

extends StaticBody2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Reference to child interaction zone
@onready var interaction: Interaction = $Interaction

func _ready() -> void:
	# When interacted with (via player), trigger save logic and show confirmation dialog
	animation_player.play("idle")
	interaction.interacted.connect(func():
		SaveManager.save_game()
		Events.request_show_dialog.emit("You recorded your progress in the journal.")
	)
