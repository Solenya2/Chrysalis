# Flasher.gd — A visual effect that flashes a CanvasItem with a custom shader-based color.
# Uses a shared ShaderMaterial (color_flash.tres) to override visuals briefly, then restores the original.
# Inherits from Effector, so 'target' must be set before calling flash().

class_name Flasher
extends Effector

# Reference to the shared flash material that overrides the sprite's appearance.
# NOTE: This is the shader you wrote earlier (e.g., flashes white/red).
var FLASH_MATERIAL = load("res://effects/color_flash.tres")

# Holds the original material so it can be restored after flashing.
var previous_material: Material

# Flashes the target for a short duration using the flash shader, then restores the original material.
# - duration: how long the flash lasts (default: 0.2s)
# NOTE: The duration is visual and should be tweaked per use case.
func flash(duration: float = 0.2) -> void:
	assert(target is CanvasItem, "The target on your flasher isn't set.")
	
	# Save original material if it's not already the flash shader.
	if target.material != FLASH_MATERIAL:
		previous_material = target.material
	
	# Apply the flash shader material.
	target.material = FLASH_MATERIAL
	
	# Wait for the flash duration, then restore the original material.
	await target.get_tree().create_timer(duration).timeout
	
	# Restore only if target still exists (wasn't freed).
	if is_instance_valid(target):
		target.material = previous_material

# Sets a custom flash color by duplicating the flash shader and changing the flash_color uniform.
# Returns self for fluent chaining (e.g., flasher.set_color(Color.RED).flash())
func set_color(color: Color) -> Flasher:
	# Duplicate the base shader material so the color change doesn't affect all flashers globally.
	FLASH_MATERIAL = FLASH_MATERIAL.duplicate() as ShaderMaterial
	FLASH_MATERIAL.set_shader_parameter("flash_color", color)
	return self
