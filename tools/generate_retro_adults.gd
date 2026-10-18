extends SceneTree
## Run with Godot --headless --path . --script tools/generate_retro_adults.gd.
## Each output pixel is authored at native resolution; there is no resampling.
const AdultArt = preload("res://scripts/adult_pixel_art.gd")

func _initialize() -> void:
	for appearance: Dictionary in [
		{"mum": true, "female": false, "blue": false},
		{"mum": false, "female": false, "blue": false},
		{"mum": false, "female": false, "blue": true},
		{"mum": false, "female": true, "blue": false},
		{"mum": false, "female": true, "blue": true}
	]:
		var path: String = AdultArt.atlas_path(appearance.mum, appearance.female, appearance.blue).trim_prefix("res://")
		var image: Image = AdultArt.generate_atlas(appearance.mum, appearance.female, appearance.blue)
		var error: Error = image.save_png(path)
		if error != OK:
			push_error("Failed to save %s: %s" % [path, error_string(error)])
		else:
			print("Generated %s (%d x %d)" % [path, image.get_width(), image.get_height()])
	quit()
