# neutral_world.gd
extends Level

func _ready() -> void:
	super()  # Call parent _ready() to enable Y-sorting
	
	# Fade in from black when this level loads
	FadeLayer.fade_from_black(1.0)
