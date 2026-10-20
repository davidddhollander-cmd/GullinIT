shader_type canvas_item;
// A small local contrast boost keeps the reduced bin's panel and lid pixels clear.
uniform float strength : hint_range(0.0, 0.5) = 0.18;

varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec4 center = texture(TEXTURE, UV);
	vec3 detail = vec3(0.0);
	vec4 left = texture(TEXTURE, UV - vec2(TEXTURE_PIXEL_SIZE.x, 0.0));
	vec4 right = texture(TEXTURE, UV + vec2(TEXTURE_PIXEL_SIZE.x, 0.0));
	vec4 up = texture(TEXTURE, UV - vec2(0.0, TEXTURE_PIXEL_SIZE.y));
	vec4 down = texture(TEXTURE, UV + vec2(0.0, TEXTURE_PIXEL_SIZE.y));
	// Ignore transparent neighbours so the silhouette gets no bright/dark halo.
	detail += (center.rgb - left.rgb) * left.a;
	detail += (center.rgb - right.rgb) * right.a;
	detail += (center.rgb - up.rgb) * up.a;
	detail += (center.rgb - down.rgb) * down.a;
	COLOR = tint * vec4(clamp(center.rgb + detail * strength, 0.0, 1.0), center.a);
}
