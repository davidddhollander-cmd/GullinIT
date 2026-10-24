class_name OldManArtChecks
extends RefCounted

static func run_checks(check: Callable) -> void:
	var texture: Texture2D = load(OldManArt.ATLAS_PATH) as Texture2D
	check.call(texture != null, "old man native pixel atlas loads")
	if texture == null:
		return
	var total := 0
	for count: int in OldManArt.CLIPS.values():
		total += count
	var expected_size := Vector2i(OldManArt.COLUMNS * OldManArt.CELL, ceili(float(total) / OldManArt.COLUMNS) * OldManArt.CELL)
	check.call(Vector2i(texture.get_size()) == expected_size, "old man atlas uses aligned 128-pixel cells")
	check.call(is_equal_approx(OldManArt.DISPLAY_SCALE, AdultPixelArt.DISPLAY_SCALE), "old man uses the normal adult display scale")
	var image := texture.get_image()
	var binary_alpha := true
	for y: int in image.get_height():
		for x: int in image.get_width():
			var alpha := image.get_pixel(x, y).a
			if alpha > 0.0 and alpha < 1.0:
				binary_alpha = false
	check.call(binary_alpha, "old man runtime atlas keeps hard pixel alpha")
	var frames := OldManArt.frames()
	for clip: String in OldManArt.CLIPS:
		check.call(frames.get_frame_count(StringName(clip)) == int(OldManArt.CLIPS[clip]), "old man %s has its authored frame count" % clip)
	for clip: StringName in [&"walk", &"walk_left", &"chase", &"chase_left", &"stick_hit", &"stick_hit_left"]:
		var previous := PackedByteArray()
		for frame: int in frames.get_frame_count(clip):
			var atlas: AtlasTexture = frames.get_frame_texture(clip, frame) as AtlasTexture
			var pixels := image.get_region(Rect2i(atlas.region)).get_data()
			if frame > 0:
				check.call(pixels != previous, "old man %s frame %d changes silhouette" % [clip, frame])
			previous = pixels
	check.call(frames.get_animation_loop_mode(&"stick_hit") == SpriteFrames.LOOP_NONE and frames.get_animation_loop_mode(&"stick_hit_left") == SpriteFrames.LOOP_NONE, "stick hits are one-shot animations")
	check.call(OldManArt.hit_frame(&"stick_hit") == 4 and OldManArt.hit_frame(&"stick_hit_left") == 3, "stick hits expose their authored impact frames")
	check.call(OldManArt.hit_animation(1.0) == &"stick_hit" and OldManArt.hit_animation(-1.0) == &"stick_hit_left", "stick hit chooses directional artwork")
