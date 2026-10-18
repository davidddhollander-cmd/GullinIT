shader_type canvas_item;

uniform vec4 feather_tint : source_color = vec4(0.65, 0.78, 0.90, 1.0);

void fragment() {
    vec4 pixel = texture(TEXTURE, UV);
    if (pixel.a < 0.7) {
        discard;
    }
    float spread = max(max(pixel.r, pixel.g), pixel.b) - min(min(pixel.r, pixel.g), pixel.b);
    float feather = smoothstep(0.42, 0.72, pixel.b) * (1.0 - smoothstep(0.15, 0.35, spread));
    COLOR = vec4(mix(pixel.rgb, pixel.rgb * feather_tint.rgb, feather * 0.9), pixel.a);
}
