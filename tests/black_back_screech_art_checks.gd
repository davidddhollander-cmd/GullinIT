extends RefCounted
## Task 065: independent screech atlas loads without disturbing the base sheet.
static func run(check: Callable) -> void:
	var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/gull_art.json"))
	var id := "gull_great_black_backed"
	var entry: Dictionary = Config.sprites[id]
	check.call(entry.animations.has("screech"), "black-back registers screech")
	if not entry.animations.has("screech"):
		return
	var clip: Dictionary = entry.animations.screech
	check.call(clip == metadata[id].animations.screech, "black-back screech registries agree")
	check.call(PackedInt32Array(clip.frames) == PackedInt32Array([0,1,2,3,4,5]) and clip.fps == 7 and not clip.loop and not clip.source_left, "black-back screech has the six right-facing timed poses")
	var frames := Config.frames(id)
	check.call(frames.get_frame_count(&"screech") == 6 and frames.get_animation_speed(&"screech") == 7 and not frames.get_animation_loop(&"screech"), "black-back screech loads through production SpriteFrames")
	var idle := frames.get_frame_texture(&"idle",0) as AtlasTexture
	var baseline: int = idle.atlas.get_image().get_region(Rect2i(idle.region)).get_used_rect().end.y
	var poses: Dictionary = {}
	for index: int in 6:
		var texture := frames.get_frame_texture(&"screech",index) as AtlasTexture
		check.call(texture.atlas.resource_path == clip.file and texture.atlas.get_size() == Vector2(768,512) and texture.region == Rect2((index%3)*256,(index/3)*256,256,256), "black-back screech frame %d uses its own 3x2 atlas cell" % index)
		var image := texture.atlas.get_image().get_region(Rect2i(texture.region))
		check.call(image.get_used_rect().has_area() and image.get_used_rect().end.y == baseline, "black-back screech frame %d feet match idle baseline" % index)
		poses[hash(image.get_data())] = true
	check.call(poses.size() == 6, "black-back screech has six distinct authored poses")
	check.call(FileAccess.file_exists("res://assets/reference/gull-great-black-backed-screech-v1/source.png") and FileAccess.file_exists("res://assets/reference/gull-great-black-backed-screech-v1/prompt.txt") and FileAccess.file_exists("res://assets/previews/gull-great-black-backed-screech-v1.png"), "black-back screech preserves source, prompt and idle comparison preview")
