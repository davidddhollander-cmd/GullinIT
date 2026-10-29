shader_type canvas_item;
// Recolours the daytime sky plate as a sunset: violet at the top, warm gold at the horizon.
// The colour blends between key rows one pixel row at a time, so there are no hard band lines.
// Sky, lit cloud and shaded cloud pixels are told apart by red value.
uniform float plate_top = 14.0; // screen row of the plate's first pixel
uniform float plate_height = 80.0;

vec3 band_color(float row) {
	// Key colours and their screen rows: violet, mauve, rose, salmon, orange, gold. Keep SKY_DUSK_TOP = the first.
	float rows[6] = float[6](14.0, 30.0, 46.0, 62.0, 78.0, 93.0);
	vec3 keys[6] = vec3[6](
		vec3(88.0, 66.0, 128.0), vec3(136.0, 86.0, 140.0), vec3(190.0, 104.0, 132.0),
		vec3(226.0, 128.0, 110.0), vec3(236.0, 150.0, 90.0), vec3(240.0, 168.0, 98.0));
	vec3 color = keys[0];
	for (int i = 0; i < 5; i++) {
		if (row >= rows[i]) {
			color = mix(keys[i], keys[i + 1], clamp((row - rows[i]) / (rows[i + 1] - rows[i]), 0.0, 1.0));
		}
	}
	return color / 255.0;
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
