shader_type canvas_item;
// Lab copy of dusk_tint.gdshader for separate cloud sprites (task 095). The plate shader reads the sky row from UV;
// a cloud sprite covers only a few rows, so this one reads it from the sprite's position instead.
// KEEP IN SYNC with dusk_tint.gdshader's band_color(); task 096 should share one include.
varying float sky_row;

vec3 band_color(float row) {
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
