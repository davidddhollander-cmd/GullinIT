extends SceneTree
## Run with Godot --headless --path . --script tools/generate_old_man_art.gd.

const OldMan = preload("res://scripts/old_man_art.gd")
const AtlasSource = preload("res://tools/old_man_atlas_source.gd")

func _initialize() -> void:
	call_deferred("_generate")

func _generate() -> void:
	var source := AtlasSource.new()
	var atlas: Image = source.build(OldMan.CLIPS)
	var atlas_path := OldMan.ATLAS_PATH.trim_prefix("res://")
	assert(atlas.save_png(atlas_path) == OK)
	var metadata := {
		"cell": OldMan.CELL,
		"columns": OldMan.COLUMNS,
		"display_scale": OldMan.DISPLAY_SCALE,
		"sole": AtlasSource.SOLE,
		"clips": OldMan.CLIPS,
		"hit_frames": OldMan.HIT_FRAMES,
		"source": AtlasSource.SOURCE
	}
	var file := FileAccess.open("res://data/old_man_art.json", FileAccess.WRITE)
	assert(file != null)
	file.store_string(JSON.stringify(metadata, "  ") + "\n")
	file.close()
	print("Generated %s (%d x %d)" % [atlas_path, atlas.get_width(), atlas.get_height()])
	quit()
