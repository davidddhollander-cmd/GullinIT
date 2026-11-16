shader_type canvas_item;
// A variant of dusk_tint.gdshader for separate cloud sprites. The plate shader reads the sky row from UV;
// a cloud sprite covers only a few rows, so this one reads it from the sprite's position instead.
varying float sky_row;

#include "res://assets/shaders/dusk_bands.gdshaderinc"

void vertex() {
	sky_row = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).y;
}

void fragment() {
	vec3 band = band_color(floor(sky_row));
	float red = COLOR.r;
	vec3 result = band;
	if (red > 0.8) {
		result = mix(band, vec3(1.0, 0.93, 0.8), 0.6);
	} else if (red > 0.65) {
		result = mix(band, vec3(0.42, 0.28, 0.5), 0.4);
	} else if (red > 0.45) {
		result = mix(band, vec3(0.42, 0.28, 0.5), 0.2);
	}
	COLOR = vec4(result, COLOR.a);
}
