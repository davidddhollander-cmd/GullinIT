shader_type canvas_item;
// Gradient-maps the daytime sky and sun to peach dusk by luminance, keeping every pixel cluster.
uniform vec3 tint = vec3(1.4, 1.0, 0.78);

void fragment() {
	vec4 color = COLOR; // already texture * modulate
	float value = dot(color.rgb, vec3(0.3, 0.59, 0.11));
	COLOR = vec4(min(vec3(1.0), value * tint), color.a);
}
