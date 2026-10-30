extends RefCounted
## Art Lab (task 044): data shape, self-test parity, key toggles and export exclusion.

const MOTIONS: Array[String] = ["fly_across", "dive", "walk_across", "idle", "on_sand", "in_beak", "static"]
const LAB_FILES: Array[String] = ["scenes/art_lab.tscn", "scripts/art_lab.gd", "data/art_lab.json"]

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
		shaped = shaped and entry.has_all(["title", "description", "current", "candidate", "motion"]) and MOTIONS.has(str(entry.motion)) and Config.sprites.has(str(entry.current))
		shaped = shaped and ((entry.candidate as Dictionary).has("animations") or (entry.candidate as Dictionary).has("clone"))
		shaped = shaped and (not entry.has("reference") or Config.sprites.has(str(entry.reference)))
	check.call(shaped, "every art lab comparison has a title, description, live current sprite, candidate and known motion")
	check.call(entries[0].current == "gull_herring" and entries[0].candidate.get("clone", "") == "gull_herring", "first art lab entry is the herring gull self-test")
	var live_ids: Array = Config.read_json("res://data/sprites.json").keys()
	check.call(not live_ids.any(func(id: String) -> bool: return id.begins_with("lab_") or id.begins_with("gull_lab_")), "lab candidates are never registered in data/sprites.json")

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
	check.call(lab.backdrop.background_art == null, "the lab opens on the live drawn sky")
	_key(lab, KEY_G)
	_key(lab, KEY_D)
	var art: BeachBackgroundArt = lab.backdrop.background_art
	check.call(art != null and lab.backdrop.sunset and art.sky.material != null and art.sea.modulate == BeachBackgroundArt.SEA_DUSK, "G shows the generated sky and D its dusk version")
	check.call(art.sun.position.y < BeachBackgroundArt.HORIZON_Y and art.sun.position.y + art.sun.texture.get_height() > BeachBackgroundArt.HORIZON_Y and art.sun.modulate == BeachBackgroundArt.SUN_DUSK, "the dusk sun sits on the horizon, partly under the sea")
	art.birds.update(20.0)
	var flock_before: PackedVector2Array = art.birds.pixels
	art.birds.update(24.0)
	check.call(not flock_before.is_empty() and not art.birds.pixels.is_empty() and flock_before != art.birds.pixels, "background birds fly across the generated sky with the clock")
	lab._advance(1.0)
	check.call(art.sea.frame == int(1.0 / BeachBackgroundArt.SEA_FRAME_TIME) % BeachBackgroundArt.SEA_FRAMES, "the generated sea follows the beach clock")
	_key(lab, KEY_G)
	_key(lab, KEY_D)
	check.call(lab.backdrop.background_art == null and not lab.backdrop.sunset, "G and D switch back")
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
	_key(lab, KEY_TAB)
	check.call(lab._category(lab.index) != lab._category(0) and lab.index > 0 and lab._category(lab.index - 1) == lab._category(0), "Tab jumps to the first entry of the next category")
	var categories: Array = []
	for i: int in count:
		if not categories.has(lab._category(i)):
			categories.append(lab._category(i))
	for _i: int in categories.size() - 2: # one Tab is already done above; the last one wraps
		_key(lab, KEY_TAB)
	check.call(lab.index != 0, "Tab stays on the last category until it wraps")
	_key(lab, KEY_TAB)
	check.call(lab.index == 0, "Tab wraps from the last category back to the first")
	check.call(lab._group_position().begins_with("TEST 1/"), "HUD shows the position within the category")
	var diner_entry_index: int = -1
	for i: int in entries.size():
		if entries[i].has("reference"):
			diner_entry_index = i
			break
	check.call(diner_entry_index >= 0, "art lab accepts a cast reference beside an A/B pair")
	if diner_entry_index >= 0:
		lab._select(diner_entry_index)
		check.call(not lab.reference_side.is_empty() and lab.reference_side.node is AnimatedSprite2D, "cast reference builds as a third sprite")
	var diner_candidates: Array = entries.filter(func(entry: Dictionary) -> bool: return str(entry.title).begins_with("DINER A "))
	check.call(diner_candidates.size() == 4, "diner A has idle, walk, swat and reaction candidate comparisons")
	var expected_sheets: Dictionary = {
		"pier-diner-a-base-candidate-v1.png": 12,
		"pier-diner-a-motion-candidate-v1.png": 14,
		"pier-diner-a-reactions-candidate-v1.png": 12,
	}
	for file: String in expected_sheets:
		var image: Image = Image.load_from_file("res://assets/sprites/" + file)
		check.call(image != null and image.get_size() == Vector2i(1024, 256), "%s is an 8x2 atlas of 128px cells" % file)
		var hard_alpha: bool = true
		var aligned: bool = true
		for frame: int in int(expected_sheets[file]):
			var cell: Image = image.get_region(Rect2i(frame % 8 * 128, frame / 8 * 128, 128, 128))
			var bounds: Rect2i = cell.get_used_rect()
			aligned = aligned and bounds.has_area() and bounds.end.y == 116
			for y: int in cell.get_height():
				for x: int in cell.get_width():
					var alpha: float = cell.get_pixel(x, y).a
					hard_alpha = hard_alpha and (is_zero_approx(alpha) or is_equal_approx(alpha, 1.0))
		check.call(hard_alpha, "%s uses hard alpha only" % file)
		check.call(aligned, "%s keeps every pose on one-based sole row 116" % file)

	# Every motion runs, so future entries are not first exercised in front of David.
	for motion: String in MOTIONS:
		var flying: bool = motion in ["fly_across", "dive"]
		var fake: Dictionary = {"title": "T", "description": "D", "current": "gull_herring" if flying else "crab_red", "candidate": {"clone": "gull_herring" if flying else "crab_blue"}, "motion": motion}
		lab.comparisons = [fake]
		lab.candidate_ids.assign([lab._register(0, fake)])
		lab._select(0)
		for frame: int in 30:
			lab._advance(1.0 / 60.0)
		check.call(lab.sides[0].node != null and lab.sides[1].node != null, "art lab motion '%s' builds both sides" % motion)
	for id: String in ["gull_lab_0", "lab_0"]:
		Config.sprites.erase(id)
		Config.frames_cache.erase(id)
	lab.queue_free()
