shader_type canvas_item;

uniform vec4 feather_tint : source_color = vec4(0.65, 0.78, 0.90, 1.0);
uniform float flash : hint_range(0.0, 1.0) = 0.0; // hit flash: mix toward white

void fragment() {
    vec4 pixel = texture(TEXTURE, UV);
    if (pixel.a < 0.7) {
        discard;
    }
    float spread = max(max(pixel.r, pixel.g), pixel.b) - min(min(pixel.r, pixel.g), pixel.b);
    float feather = smoothstep(0.42, 0.72, pixel.b) * (1.0 - smoothstep(0.15, 0.35, spread));
    vec3 tinted = mix(pixel.rgb, pixel.rgb * feather_tint.rgb, feather * 0.9);
    COLOR = vec4(mix(tinted, vec3(1.0), flash), pixel.a);
}
