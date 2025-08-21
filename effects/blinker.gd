# Blinker.gd — An effect that makes a CanvasItem flash by toggling visibility.
# Inherits from Effector, so it must have its 'target' set before calling blink().
# Often used for hit feedback, warnings, or attention-drawing animations.

class_name Blinker
extends Effector

# Blinks the target a given number of times over a total duration.
# - duration: total time the blinking effect lasts (default: 1.0s)
# - blinks: how many visibility flips happen in that time (default: 8)
# NOTE: These values are purely visual and will likely be adjusted per use case.
func blink(duration: float = 1.0, blinks: int = 8) -> void:
	assert(target is CanvasItem, "The target on your blinker isn't set.")

	# Duration for each individual blink (on/off cycle).
	var blink_duration = duration / blinks

	# Perform the blinking loop.
	for i in blinks:
		if not is_instance_valid(target):
			return
		# Toggle visibility.
		target.visible = not target.visible
		# Wait before next toggle.
		await target.get_tree().create_timer(blink_duration).timeout

	# Ensure target is visible at the end of the effect.
	if not is_instance_valid(target):
		return
	target.visible = true
