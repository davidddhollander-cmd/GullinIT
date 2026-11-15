extends RefCounted
## Task 089: independent screech atlas loads without disturbing the base sheet.
static func run(check: Callable) -> void:
	var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/gull_art.json"))
	var id := "gull_kittiwake"
	var entry: Dictionary = Config.sprites[id]
	check.call(entry.animations.has("screech"), "kittiwake registers screech")
	if not entry.animations.has("screech"):
		return
	var clip: Dictionary = entry.animations.screech
	check.call(clip == metadata[id].animations.screech, "kittiwake screech registries agree")
	check.call(PackedInt32Array(clip.frames) == PackedInt32Array([0,1,2,3,4,5]) and clip.fps == 7 and not clip.loop and not clip.source_left, "kittiwake screech has the six right-facing timed poses")
	var frames := Config.frames(id)
	check.call(frames.get_frame_count(&"screech") == 6 and frames.get_animation_speed(&"screech") == 7 and not frames.get_animation_loop(&"screech"), "kittiwake screech loads through production SpriteFrames")
	var idle := frames.get_frame_texture(&"idle",0) as AtlasTexture
	var baseline: int = idle.atlas.get_image().get_region(Rect2i(idle.region)).get_used_rect().end.y
	var idle_image := idle.atlas.get_image().get_region(Rect2i(idle.region))
	var idle_feet := _foot_center(idle_image, baseline)
	var poses: Dictionary = {}
	for index: int in 6:
		var texture := frames.get_frame_texture(&"screech",index) as AtlasTexture
		check.call(texture.atlas.resource_path == clip.file and texture.atlas.get_size() == Vector2(768,512) and texture.region == Rect2((index%3)*256,(index/3)*256,256,256), "kittiwake screech frame %d uses its own 3x2 atlas cell" % index)
		var image := texture.atlas.get_image().get_region(Rect2i(texture.region))
		check.call(image.get_used_rect().has_area() and image.get_used_rect().end.y == baseline, "kittiwake screech frame %d feet match idle baseline" % index)
		check.call(absf(_foot_center(image, baseline) - idle_feet) <= 1.0, "kittiwake screech frame %d keeps planted feet horizontally stable" % index)
		poses[hash(image.get_data())] = true
	check.call(poses.size() == 6, "kittiwake screech has six distinct authored poses")
	var peak := frames.get_frame_texture(&"screech",4) as AtlasTexture
	var peak_image := peak.atlas.get_image().get_region(Rect2i(peak.region))
	check.call(peak_image.get_used_rect().position.y < idle_image.get_used_rect().position.y - 4, "kittiwake held peak visibly stretches above idle")
	check.call(FileAccess.file_exists("res://assets/reference/gull-kittiwake-screech-v1/source.png") and FileAccess.file_exists("res://assets/reference/gull-kittiwake-screech-v1/prompt.txt") and FileAccess.file_exists("res://assets/previews/gull-kittiwake-screech-v1.png"), "kittiwake screech preserves source, prompt and idle comparison preview")

static func _foot_center(image: Image, baseline: int) -> float:
	var feet := image.get_region(Rect2i(0,baseline-3,256,3)).get_used_rect()
	return feet.position.x + feet.size.x * 0.5

