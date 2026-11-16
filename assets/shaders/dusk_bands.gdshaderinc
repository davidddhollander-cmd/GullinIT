// Sunset sky colours shared by dusk_tint.gdshader (the sky plate) and cloud_dusk.gdshader (cloud sprites).
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
