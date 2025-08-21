# UI.gd — Root UI layer for the game's interface, tied to pause and inventory behavior.
# Listens to the PauseManager and manages visibility + focus control.

class_name UI
extends CanvasLayer

# Reference to the PauseManager, set via the Inspector.
@export var pause_manager: PauseManager

# UI nodes
@onready var pause: ColorRect = %Pause
@onready var hero_inventory_manager: HeroInventoryManager = %HeroInventoryManager

func _ready() -> void:
	pause.hide()  # Ensure pause UI is hidden on game start
	show()        # Ensure the UI layer is visible

	# When game is paused, show pause overlay and give inventory UI focus
	pause_manager.paused.connect(func():
		pause.show()
		hero_inventory_manager.grab_inventory_ui_focus()
	)

	# When game is unpaused, hide pause overlay and release inventory focus
	pause_manager.unpaused.connect(func():
		pause.hide()
		hero_inventory_manager.release_focus()
	)
