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
		check.call(binary_alpha, "%s keeps hard alpha at the approved higher detail" % label)
		check.call(image.get_width() == 8 * AdultPixelArt.CELL and AdultPixelArt.CELL == 128, "%s uses the approved 128-pixel source grid" % label)
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
		var walk: AtlasTexture = frames.get_frame_texture(&"walk",0)
		var chase: AtlasTexture = frames.get_frame_texture(&"chase",0)
		check.call(image.get_region(Rect2i(walk.region)).get_data() != image.get_region(Rect2i(chase.region)).get_data(), "%s chase has distinct running artwork" % label)
	for female: bool in [false,true]:
		var red: PackedByteArray = (load(AdultPixelArt.atlas_path(false,female,false)) as Texture2D).get_image().get_data()
		var blue: PackedByteArray = (load(AdultPixelArt.atlas_path(false,female,true)) as Texture2D).get_image().get_data()
		var same_mask := red.size() == blue.size()
		var anatomy_unchanged := same_mask
		var changed := 0
		for p: int in range(0,mini(red.size(),blue.size()),4):
			if red[p+3] != blue[p+3]:
				same_mask = false
			if red[p+3] == 0:
				continue
			var differs := red[p] != blue[p] or red[p+1] != blue[p+1] or red[p+2] != blue[p+2]
			if differs:
				changed += 1
			# Warm orange skin and brown hair pixels must survive the garment swap.
			if red[p] > 80 and red[p+1] > 30 and red[p+1] > red[p+2]*1.5 and differs:
				anatomy_unchanged = false
		check.call(same_mask,"red and blue sunbathers share the exact same silhouette")
		check.call(anatomy_unchanged and changed > 100,"blue swimwear preserves skin and hair while changing garment colours")
