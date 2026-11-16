shader_type canvas_item;
// Recolours the daytime sky plate as a sunset: violet at the top, warm gold at the horizon.
// The colour blends between key rows one pixel row at a time, so there are no hard band lines.
// Sky, lit cloud and shaded cloud pixels are told apart by red value.
uniform float plate_top = 14.0; // screen row of the plate's first pixel
uniform float plate_height = 80.0;

#include "res://assets/shaders/dusk_bands.gdshaderinc"

void fragment() {
	float row = plate_top + floor(UV.y * plate_height);
	vec3 band = band_color(row);
	float red = COLOR.r;
	vec3 result = band;
	if (red > 0.8) {
		result = mix(band, vec3(1.0, 0.93, 0.8), 0.6); // warm lit cloud top
	} else if (red > 0.65) {
		result = mix(band, vec3(0.42, 0.28, 0.5), 0.4); // cooler cloud underside
	} else if (red > 0.45) {
		result = mix(band, vec3(0.42, 0.28, 0.5), 0.2); // soft edge between the two
	}
	COLOR = vec4(result, COLOR.a);
}
