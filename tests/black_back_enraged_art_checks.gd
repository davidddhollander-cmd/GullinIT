extends RefCounted
## Task 069: pilot clips reuse normal cell indices and contact anchors.
static func beak(image: Image) -> Vector2i:
	var right := -1
	var total := 0
	var count := 0
	for y: int in image.get_height():
		for x: int in image.get_width():
			var c := image.get_pixel(x,y)
			if c.a < 128.0/255.0 or c.r <= 160.0/255.0 or c.g <= 100.0/255.0 or c.b >= 130.0/255.0 or c.r <= c.g:
				continue
			if x > right:
				right = x
				total = 0
				count = 0
			if x == right:
				total += y
				count += 1
	return Vector2i(right,roundi(float(total)/maxi(1,count)))

static func run(check: Callable) -> void:
	var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/gull_art.json"))
	var entry: Dictionary = Config.sprites.gull_great_black_backed
	var frames := Config.frames("gull_great_black_backed")
	var normal := Image.load_from_file(ProjectSettings.globalize_path(entry.file))
	var baseline: int = normal.get_region(Rect2i(0,0,256,256)).get_used_rect().end.y
	for clip: String in ["idle_enraged","walk_enraged"]:
		check.call(entry.animations.has(clip),"black-back registers "+clip)
		if not entry.animations.has(clip):
			continue
		var details: Dictionary = entry.animations[clip]
		var expected := PackedInt32Array([0] if clip == "idle_enraged" else [1,2,3,4,5,6,7,0])
		check.call(details == metadata.gull_great_black_backed.animations[clip],clip+" matches both registries")
		check.call(PackedInt32Array(details.frames) == expected and details.fps == (1 if clip == "idle_enraged" else 8) and details.loop and not details.source_left,clip+" preserves production pose order, timing and direction")
		check.call(frames.get_frame_count(clip) == expected.size() and frames.get_animation_loop(clip) and frames.get_animation_speed(clip) == details.fps,clip+" loads through normal SpriteFrames")
	var seen: Dictionary = {}
	for i: int in 8:
		var clip := "idle_enraged" if i == 0 else "walk_enraged"
		if not frames.has_animation(clip):
			return
		var texture := frames.get_frame_texture(clip,0 if i == 0 else i-1) as AtlasTexture
		check.call(texture.atlas.resource_path == "res://assets/sprites/gull-great-black-backed-enraged-v1.png" and texture.atlas.get_size() == Vector2(1024,512) and texture.region == Rect2((i%4)*256,(i/4)*256,256,256),"enraged cell %d retains its production index" % i)
		var image := texture.atlas.get_image().get_region(Rect2i(texture.region))
		var reference := normal.get_region(Rect2i((i%4)*256,(i/4)*256,256,256))
		check.call(image.get_used_rect().end.y == baseline,"enraged cell %d feet match normal idle" % i)
		var tip := beak(image)
		var target := beak(reference)
		check.call(tip.x >= 0 and target.x >= 0 and Vector2(tip).distance_to(Vector2(target)) <= 2,"enraged cell %d bill stays within two source pixels" % i)
		seen[hash(image.get_data())] = true
	check.call(seen.size() == 8,"enraged pilot has eight distinct generated poses")
	for path: String in ["assets/reference/gull-great-black-backed-enraged-v1/source.png","assets/reference/gull-great-black-backed-enraged-v1/prompt.txt","assets/previews/gull-great-black-backed-enraged-v1.png","assets/previews/gull-great-black-backed-enraged-v1-walk.gif"]:
		check.call(FileAccess.file_exists("res://"+path),"enraged pilot preserves "+path)
