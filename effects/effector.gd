# Effector.gd — Base class for visual/UI effects that act on a specific CanvasItem.
# Designed to be extended (e.g., Blinker, Fader, Shaker, etc.).
# Keeps effect logic modular and reusable across different targets.

class_name Effector
extends RefCounted

# The node this effect will act on — must be a CanvasItem (e.g., Sprite2D, Label, Control).
var target: CanvasItem : set = set_target

# Sets the target and returns self for chaining.
# NOTE: This doesn't apply any effects — subclasses will implement that.
func set_target(value: CanvasItem) -> Effector:
	target = value
	return self
