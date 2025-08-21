# HeroHurtFlash.gd — A screen-space red flash effect when the hero takes damage.
# Should be placed on a CanvasLayer to ensure it renders on top of gameplay.
# Uses an AnimationPlayer to animate a red border or overlay.

extends CanvasLayer

# Reference to the AnimationPlayer that runs the flash animation.
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# The red border texture (or fullscreen overlay) that flashes on screen.
@onready var red_border: TextureRect = $RedBorder

func _ready() -> void:
	# Connects to the global hero_hurt event.
	# When the hero is hurt, this plays the "flash" animation (defined in the AnimationPlayer).
	Events.hero_hurt.connect(animation_player.play.bind("flash"))
