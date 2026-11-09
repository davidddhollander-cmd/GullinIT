shader_type canvas_item;
// Flash-only material for sprites that otherwise have none (native-alpha gulls and people). No alpha discard.
uniform float flash : hint_range(0.0, 1.0) = 0.0;
void fragment() {
    COLOR.rgb = mix(COLOR.rgb, vec3(1.0), flash);
}
