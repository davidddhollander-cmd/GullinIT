extends SceneTree
## Run with Godot --headless --path . --script tools/generate_retro_adults.gd.
## Prepare approved diner-style sources at 2x detail with unchanged gameplay size.
const AdultArt = preload("res://scripts/adult_pixel_art.gd")
const AtlasSource = preload("res://tools/diner_adult_atlas_source.gd")
const CELL := AdultArt.CELL

func _initialize() -> void:
	call_deferred("_generate")

func _generate() -> void:
	var review := Image.create(8 * CELL, 5 * CELL, false, Image.FORMAT_RGBA8)
	review.fill(Color("e4d2ae"))
	var row := 0
	var red_atlases: Dictionary = {}
	for appearance: Dictionary in [
		{"mum": true, "female": false, "blue": false},
		{"mum": false, "female": false, "blue": false},
		{"mum": false, "female": false, "blue": true},
		{"mum": false, "female": true, "blue": false},
		{"mum": false, "female": true, "blue": true}
	]:
		var path: String = AdultArt.atlas_path(appearance.mum, appearance.female, appearance.blue).trim_prefix("res://")
		var source := AtlasSource.new()
		var key := "mum" if appearance.mum else ("female" if appearance.female else "male")
		var image: Image
		if appearance.blue:
			image = AtlasSource.blue_variant(red_atlases[key])
		else:
			image = source.build(appearance.mum, appearance.female, AdultArt.clips(appearance.mum))
			red_atlases[key] = image
			if appearance.mum:
				var metadata := FileAccess.open("res://data/adult_art.json",FileAccess.WRITE)
				assert(metadata != null)
				metadata.store_string(JSON.stringify({"cell":CELL,"display_scale":AdultArt.DISPLAY_SCALE,"sole":116,"mum_food_anchors":source.food_anchors},"  ")+"\n")
				metadata.close()
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
			review.blit_rect(image, Rect2i(frame_index % 8 * CELL, frame_index / 8 * CELL, CELL, CELL), Vector2i(column * CELL, row * CELL))
		row += 1
	review.resize(review.get_width() * 2, review.get_height() * 2, Image.INTERPOLATE_NEAREST)
	assert(review.save_png("res://assets/archive/previews/adult-diner-production-review-v1.png") == OK)
	quit()
