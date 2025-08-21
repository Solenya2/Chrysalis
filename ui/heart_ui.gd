# HeartUI.gd — A single heart UI element that displays health using quarter-heart frames.
# Converts fractional health (0.0–1.0) into a sprite frame index (0–4 by default).

class_name HeartUI
extends CenterContainer

# Total number of heart segments (e.g., 4 = quarter hearts)
const FINAL_FRAME := 4  # NOTE: and this is used for quarter hearts Adjust if using different divisions (e.g., halves = 2)

# Sprite displaying the heart frame
@onready var sprite_2d: Sprite2D = %Sprite2D

# Updates the sprite frame based on leftover fractional health in this heart slot.
# Example input: 0.75 health → frame 3, 0.5 → frame 2, 0 → frame 0
func update_quarter_hearts(leftover_health: float) -> void:
	var quarter_heart_frame := leftover_health * FINAL_FRAME
	var clamped_quarter_heart_frame: int = clamp(quarter_heart_frame, 0, FINAL_FRAME)
	sprite_2d.frame = clamped_quarter_heart_frame
