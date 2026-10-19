extends SceneTree
## Run with Godot --headless --path . --script tools/generate_retro_adults.gd.
## Prepare selected review art and supplemental animation sources on the native grid.
const AdultArt = preload("res://scripts/adult_pixel_art.gd")
const AtlasSource = preload("res://tools/adult_atlas_source.gd")

func _initialize() -> void:
	call_deferred("_generate")

func _generate() -> void:
	var review := Image.create(8 * 64, 5 * 64, false, Image.FORMAT_RGBA8)
	review.fill(Color("e4d2ae"))
	var row := 0
	for appearance: Dictionary in [
		{"mum": true, "female": false, "blue": false},
		{"mum": false, "female": false, "blue": false},
		{"mum": false, "female": false, "blue": true},
		{"mum": false, "female": true, "blue": false},
		{"mum": false, "female": true, "blue": true}
	]:
		var path: String = AdultArt.atlas_path(appearance.mum, appearance.female, appearance.blue).trim_prefix("res://")
		var image: Image = AtlasSource.new().build(appearance.mum, appearance.female, appearance.blue, AdultArt.clips(appearance.mum))
		var error: Error = image.save_png(path)
		if error != OK:
			push_error("Failed to save %s: %s" % [path, error_string(error)])
		else:
			print("Generated %s (%d x %d)" % [path, image.get_width(), image.get_height()])
		var samples: Array = [["idle", 0], ["walk", 0], ["walk", 1], ["walk_left", 2], ["swat", 3], ["kick", 3], ["handover" if appearance.mum else "rest", 2], ["carry_left" if appearance.mum else "pickup", 3]]
		for column: int in samples.size():
			var frame_index := 0
			for clip: String in AdultArt.clips(appearance.mum):
				if clip == samples[column][0]:
					break
				frame_index += int(AdultArt.clips(appearance.mum)[clip])
			frame_index += int(samples[column][1])
			review.blit_rect(image, Rect2i(frame_index % 8 * 64, frame_index / 8 * 64, 64, 64), Vector2i(column * 64, row * 64))
		row += 1
	review.resize(review.get_width() * 4, review.get_height() * 4, Image.INTERPOLATE_NEAREST)
	assert(review.save_png("res://assets/previews/adult-replacement-review-v3.png") == OK)
	quit()
