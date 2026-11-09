shader_type canvas_item;
// Suppress faint extraction fringes without altering the source sheet.
uniform float flash : hint_range(0.0, 1.0) = 0.0; // hit flash: mix toward white
void fragment() {
    if (texture(TEXTURE, UV).a < 0.7) {
        discard;
    }
    COLOR.rgb = mix(COLOR.rgb, vec3(1.0), flash);
}
