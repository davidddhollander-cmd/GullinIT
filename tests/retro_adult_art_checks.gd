class_name RetroAdultArtChecks
extends RefCounted

static func run_checks(check: Callable) -> void:
	for appearance: Dictionary in [
		{"mum": true, "female": false, "blue": false},
		{"mum": false, "female": false, "blue": false},
		{"mum": false, "female": false, "blue": true},
		{"mum": false, "female": true, "blue": false},
		{"mum": false, "female": true, "blue": true}
	]:
		var label: String = "mum" if appearance.mum else ("female" if appearance.female else "male") + (" blue" if appearance.blue else " red")
		var path: String = AdultPixelArt.atlas_path(appearance.mum, appearance.female, appearance.blue)
		var texture: Texture2D = load(path) as Texture2D
		check.call(texture != null, "%s native pixel atlas loads" % label)
		if texture == null:
			continue
		var image: Image = texture.get_image()
		var colours: Dictionary = {}
		var binary_alpha: bool = true
		for y: int in image.get_height():
			for x: int in image.get_width():
				var pixel: Color = image.get_pixel(x, y)
				if pixel.a > 0.0 and pixel.a < 1.0:
					binary_alpha = false
				if pixel.a > 0.0:
					colours[pixel.to_html(false)] = true
		check.call(binary_alpha and colours.size() <= 16, "%s uses hard edges and at most 16 colours" % label)
		var frames: SpriteFrames = AdultPixelArt.frames(appearance.mum, appearance.female, appearance.blue)
		for clip: String in AdultPixelArt.clips(appearance.mum):
			check.call(frames.get_frame_count(StringName(clip)) == int(AdultPixelArt.clips(appearance.mum)[clip]), "%s %s has its authored frame count" % [label, clip])
		for clip: String in ["walk", "walk_left", "chase", "chase_left", "kick", "kick_left"]:
			var previous: PackedByteArray = PackedByteArray()
			for i: int in frames.get_frame_count(StringName(clip)):
				var atlas: AtlasTexture = frames.get_frame_texture(StringName(clip), i)
				var region := Rect2i(Vector2i(atlas.region.position), Vector2i(atlas.region.size))
				var pixels: PackedByteArray = image.get_region(region).get_data()
				if i > 0:
					check.call(pixels != previous, "%s %s frame %d changes silhouette" % [label, clip, i])
				previous = pixels
