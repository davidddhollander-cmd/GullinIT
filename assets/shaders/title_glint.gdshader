shader_type canvas_item;
uniform float period = 4.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float front = clamp(fract(TIME / period) * 4.0, 0.0, 1.0) * 1.6 - 0.3;
	float d = abs((UV.x + UV.y * 0.5) / 1.5 - front * 0.9);
	c.rgb += smoothstep(0.06, 0.0, d) * 0.8 * c.a;
	COLOR = c;
}
