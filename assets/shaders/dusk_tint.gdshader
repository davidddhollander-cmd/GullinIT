shader_type canvas_item;
// Recolours the daytime sky plate as a flat stepped sunset: violet at the top, gold at the horizon.
// Bands key on screen row; sky, lit cloud and shaded cloud pixels are told apart by red value.
uniform float plate_top = 14.0; // screen row of the plate's first pixel
uniform float plate_height = 80.0;

vec3 band_color(float row) {
	// Top to bottom: violet, mauve, rose, salmon, orange, gold, pale gold. Keep SKY_DUSK_TOP in sync.
	vec3 bands[7] = vec3[7](
		vec3(88.0, 66.0, 128.0), vec3(136.0, 86.0, 140.0), vec3(190.0, 104.0, 132.0),
		vec3(232.0, 134.0, 112.0), vec3(246.0, 164.0, 86.0), vec3(252.0, 196.0, 100.0),
		vec3(255.0, 224.0, 140.0));
	int index = int(row >= 18.0) + int(row >= 34.0) + int(row >= 48.0) + int(row >= 61.0) + int(row >= 74.0) + int(row >= 86.0);
	return bands[index] / 255.0;
}

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
