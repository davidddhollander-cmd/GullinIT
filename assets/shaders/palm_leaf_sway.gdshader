shader_type canvas_item;
render_mode unshaded;

// Approved leaf sway for the complete 44 x 62 palm texture.
uniform float wind_strength : hint_range(0.0, 1.0) = 0.55;
uniform float wind_direction : hint_range(-1.0, 1.0) = 1.0;
uniform float phase : hint_range(0.0, 6.283185) = 0.0;
// Negative uses the live clock. Gameplay supplies its pausable beach clock;
// the standalone preview supplies exact times for capture.
uniform float preview_time = -1.0;

varying vec4 tint;
const vec2 SOURCE_SIZE = vec2(44.0, 62.0);
const float PADDING = 3.0;

void vertex() {
	tint = COLOR;
	// The source has leaves at its left edge. Expand the transparent drawing
	// area so moving tips survive, without modifying the original artwork.
	VERTEX *= (SOURCE_SIZE + 2.0 * PADDING) / SOURCE_SIZE;
}

void fragment() {
	vec2 pixel = UV * (SOURCE_SIZE + 2.0 * PADDING) - PADDING;
	vec2 from_hub = pixel - vec2(21.0, 25.0);
	// The hub and complete trunk stay fixed. Only the outer fronds can flex.
	float tip = smoothstep(3.0, 19.0, abs(from_hub.x));
	float crown = 1.0 - smoothstep(34.0, 40.0, pixel.y);
	float weight = tip * crown;
	float t = (preview_time < 0.0 ? TIME : preview_time) * TAU / 8.0;
	float frond_phase = phase + (from_hub.x < 0.0 ? 0.35 : -0.25)
		+ 0.025 * from_hub.y;
	// A slow bend, a smaller return ripple, and a tiny downward tip flex.
	// Harmonics share an eight-second cycle, so the review loop has no seam.
	float bend = 0.48 + 0.43 * sin(t + frond_phase)
		+ 0.09 * sin(2.0 * t + frond_phase + 1.2);
	float amplitude = 1.75 * clamp(wind_strength, 0.0, 1.0) * weight;
	vec2 motion = vec2(wind_direction * amplitude * bend,
		amplitude * 0.24 * sin(2.0 * t + frond_phase + 0.8));
	vec2 sample_uv = (pixel - motion) / SOURCE_SIZE;
	if (any(lessThan(sample_uv, vec2(0.0))) || any(greaterThanEqual(sample_uv, vec2(1.0)))) {
		COLOR = vec4(0.0);
	} else {
		COLOR = tint * texture(TEXTURE, sample_uv);
	}
}
