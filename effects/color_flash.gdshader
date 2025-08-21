// hit_flash.shader
// CanvasItem shader used to flash a character or sprite with a solid color on hit
// Overlays the entire sprite with 'flash_color' but keeps its original transparency

shader_type canvas_item;

// Color to flash the sprite with (e.g., white for hit, red for damage).
// Set from GDScript using `material.set_shader_parameter("flash_color", Color(...))`
uniform vec4 flash_color : source_color;

void fragment() {
    // Sample the original texture color at the current UV.
    vec4 input_color = texture(TEXTURE, UV);

    // Override the RGB with the flash color but preserve the alpha from the texture.
    COLOR = vec4(flash_color.rgb, input_color.a);
}
