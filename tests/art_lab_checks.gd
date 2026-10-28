extends RefCounted
## Art Lab (task 044): data shape, self-test parity, key toggles and export exclusion.

const MOTIONS: Array[String] = ["fly_across", "dive", "walk_across", "idle", "on_sand", "in_beak", "static"]
const LAB_FILES: Array[String] = ["scenes/art_lab.tscn", "scripts/art_lab.gd", "data/art_lab.json"]

static func _image(path: String) -> Image:
	return (load(path) as Texture2D).get_image()

static func _hard_alpha(image: Image) -> bool:
	for y: int in image.get_height():
		for x: int in image.get_width():
			var alpha: float = image.get_pixel(x, y).a
			if alpha > 0.0 and alpha < 1.0:
				return false
	return true

static func _key(lab: Node, keycode: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	lab._unhandled_input(event)

static func run(host: Node, check: Callable) -> void:
	var data: Dictionary = Config.read_json("res://data/art_lab.json")
	var entries: Array = data.get("comparisons", [])
	check.call(not entries.is_empty(), "art lab data has comparisons")
	var shaped: bool = true
	for entry: Dictionary in entries:
		var current_valid: bool = (entry.current is String and Config.sprites.has(str(entry.current))) or (entry.current is Dictionary and ((entry.current as Dictionary).has("animations") or (entry.current as Dictionary).has("clone")))
		shaped = shaped and entry.has_all(["title", "description", "current", "candidate", "motion"]) and MOTIONS.has(str(entry.motion)) and current_valid
		shaped = shaped and ((entry.candidate as Dictionary).has("animations") or (entry.candidate as Dictionary).has("clone"))
	check.call(shaped, "every art lab comparison has a title, description, live current sprite, candidate and known motion")
	check.call(entries[0].current == "gull_herring" and entries[0].candidate.get("clone", "") == "gull_herring", "first art lab entry is the herring gull self-test")
	var live_ids: Array = Config.read_json("res://data/sprites.json").keys()
	check.call(not live_ids.any(func(id: String) -> bool: return id.begins_with("lab_") or id.begins_with("gull_lab_")), "lab candidates are never registered in data/sprites.json")

	var grid_fixes: Array = entries.filter(func(entry: Dictionary) -> bool: return str(entry.title).begins_with("GRID FIX"))
	check.call(grid_fixes.size() == 9, "task 049 provides nine separate art-grid comparisons")
	var expected_sizes: Dictionary = {
		"old-man-cast-grid-candidate-v1.png": Vector2i(1024, 2048),
		"crabs-pair-candidate-v1.png": Vector2i(144, 40),
		"stand-signs-candidate-v1.png": Vector2i(128, 100),
		"wheelie-bin-candidate-v1.png": Vector2i(22, 30),
		"feathers-candidate-v1.png": Vector2i(56, 14),
		"title-logo-candidate-v1.png": Vector2i(350, 52),
		"loading-backdrop-candidate-v1.png": Vector2i(640, 360),
		"score-digits-candidate-v1.png": Vector2i(337, 66),
		"beach-sign-composed-candidate-v1.png": Vector2i(34, 44),
	}
	var candidates_valid: bool = true
	for file: String in expected_sizes:
		var image: Image = _image("res://assets/sprites/" + file)
		candidates_valid = candidates_valid and image != null and image.get_size() == expected_sizes[file] and _hard_alpha(image)
	check.call(candidates_valid, "all nine art-grid candidates have expected dimensions and hard alpha")
	var old_man: Image = _image("res://assets/sprites/old-man-cast-grid-candidate-v1.png")
	var old_man_aligned: bool = true
	var first_pose: Rect2i = old_man.get_region(Rect2i(0, 0, 128, 128)).get_used_rect()
	for row: int in 16:
		for column: int in 8:
			var cell: Image = old_man.get_region(Rect2i(column * 128, row * 128, 128, 128))
			var used: Rect2i = cell.get_used_rect()
			if used.has_area():
				old_man_aligned = old_man_aligned and used.end.y == 116
	check.call(old_man_aligned and first_pose.size.y == 74, "old-man poses use the cast sole row and upright poses display at 37px")
	var live_json: String = FileAccess.get_file_as_string("res://data/sprites.json")
	check.call(not expected_sizes.keys().any(func(file: String) -> bool: return live_json.contains(file)), "task 049 candidates remain Art Lab-only")

	var presets: String = FileAccess.get_file_as_string("res://export_presets.cfg")
	var excluded: int = 0
	var presets_found: int = 0
	for line: String in presets.split("\n"):
		if line.begins_with("exclude_filter="):
			presets_found += 1
			excluded += 1 if LAB_FILES.all(func(path: String) -> bool: return line.contains(path)) else 0
	check.call(presets_found > 0 and excluded == presets_found, "every export preset excludes the art lab files")

	var lab: Node = load("res://scenes/art_lab.tscn").instantiate()
	host.add_child(lab)
	var left: BeachGull = lab.sides[0].gull
	var right: BeachGull = lab.sides[1].gull
	check.call(left != null and right != null and left.art_id == "gull_herring" and right.art_id == "gull_lab_0", "self-test plays the live herring art on both sides")
	var in_sync: bool = true
	var struck: bool = false
	var landed_or_climbed: bool = false
	for frame: int in 60 * 14:
		lab._advance(1.0 / 60.0)
		in_sync = in_sync and left.state == right.state and is_equal_approx(left.position.y, right.position.y) and left.sprite.animation == right.sprite.animation and left.sprite.frame == right.sprite.frame
		struck = struck or left.state == BeachGull.State.STRIKE
		landed_or_climbed = landed_or_climbed or (struck and left.state == BeachGull.State.GLIDE)
	check.call(in_sync, "self-test sides stay frame-for-frame identical through flight and dives")
	check.call(struck and landed_or_climbed, "self-test gulls fly, dive and pull up")
	check.call(is_equal_approx(right.position.x - left.position.x, 160.0), "sides sit one pane apart at real size")

	var stretch: Window.ContentScaleStretch = host.get_window().content_scale_stretch
	_key(lab, KEY_Z)
	check.call(lab.zoom == 4 and lab.camera.zoom == Vector2(4, 4), "Z zooms to 4x")
	_key(lab, KEY_Z)
	check.call(lab.zoom == 1, "Z returns to real size")
	_key(lab, KEY_F)
	check.call(lab.smooth and left.sprite.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR and right.sprite.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR, "F smooths both sprites")
	_key(lab, KEY_F)
	check.call(left.sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "F restores sharp filtering")
	_key(lab, KEY_I)
	check.call(host.get_window().content_scale_stretch != stretch, "I toggles the lab window's scale mode")
	_key(lab, KEY_I)
	check.call(host.get_window().content_scale_stretch == stretch, "I switches back")
	_key(lab, KEY_B)
	check.call(lab.blind and lab.side_labels[0].text == "" and lab.side_labels[1].text == "", "B hides the labels")
	_key(lab, KEY_B)
	check.call(not lab.blind and lab.side_labels[0].text != "", "B again reveals the labels")
	var before: float = lab.pair_x
	_key(lab, KEY_P)
	lab._process(0.0)
	check.call(lab.paused and is_equal_approx(lab.pair_x, before), "P pauses the motion")
	_key(lab, KEY_PERIOD)
	lab._process(0.0)
	check.call(lab.paused and not is_equal_approx(lab.pair_x, before), ". advances exactly one frame while paused")
	var count: int = lab.comparisons.size()
	_key(lab, KEY_RIGHT)
	check.call(lab.index == 1 % count, "right arrow picks the next comparison")
	_key(lab, KEY_LEFT)
	_key(lab, KEY_LEFT)
	check.call(lab.index == count - 1, "left arrow wraps to the last comparison")
	_key(lab, KEY_1)
	check.call(lab.index == 0, "1 picks the first comparison")

	# Every motion runs, so future entries are not first exercised in front of David.
	for motion: String in MOTIONS:
		var flying: bool = motion in ["fly_across", "dive"]
		var fake: Dictionary = {"title": "T", "description": "D", "current": "gull_herring" if flying else "crab_red", "candidate": {"clone": "gull_herring" if flying else "crab_blue"}, "motion": motion}
		lab.comparisons = [fake]
		lab.current_ids.assign([lab._register_side(0, fake.current, true)])
		lab.candidate_ids.assign([lab._register(0, fake)])
		lab._select(0)
		for frame: int in 30:
			lab._advance(1.0 / 60.0)
		check.call(lab.sides[0].node != null and lab.sides[1].node != null, "art lab motion '%s' builds both sides" % motion)
	for id: String in Config.sprites.keys():
		if not (id.begins_with("gull_lab_") or id.begins_with("lab_")):
			continue
		Config.sprites.erase(id)
		Config.frames_cache.erase(id)
	lab.queue_free()
