extends RefCounted
## Crops and aligns the generated source sheets without redrawing the character.

const CELL := 128
const COLUMNS := 6
const SOLE := 116
const SOURCE_CELL_SCALE := 0.4
const SOURCE := "res://assets/reference/old-man-stick-v1/"
const Extractor = preload("res://tools/adult_atlas_source.gd")

var groups: Dictionary = {}
var extractor := Extractor.new()
var rect_cache: Dictionary = {}

func _read(path: String) -> Image:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	assert(image != null, "Missing old-man source: " + path)
	image.convert(Image.FORMAT_RGBA8)
	return image

func _cell(source: Image, region: Rect2i) -> Image:
	var part := source.get_region(region)
	part.resize(roundi(part.get_width() * SOURCE_CELL_SCALE), roundi(part.get_height() * SOURCE_CELL_SCALE), Image.INTERPOLATE_NEAREST)
	for y: int in part.get_height():
		for x: int in part.get_width():
			var colour := part.get_pixel(x, y)
			if colour.a < 0.75:
				part.set_pixel(x, y, Color.TRANSPARENT)
			else:
				colour.a = 1.0
				part.set_pixel(x, y, colour)
	# Long cane poses overlap adjacent nominal columns in the source sheet. Keep
	# only this pose's connected actor so those neighbours cannot leak in.
	extractor._isolate_actor(part)
	var bounds := part.get_used_rect()
	assert(bounds.has_area(), "Empty old-man source crop")
	part = part.get_region(bounds)
	var fit := minf(1.0, minf(float(CELL - 4) / part.get_width(), float(SOLE) / part.get_height()))
	if fit < 1.0:
		part.resize(roundi(part.get_width() * fit), roundi(part.get_height() * fit), Image.INTERPOLATE_NEAREST)
	var result := Image.create(CELL, CELL, false, Image.FORMAT_RGBA8)
	result.fill(Color.TRANSPARENT)
	result.blit_rect(part, Rect2i(Vector2i.ZERO, part.get_size()), Vector2i((CELL - part.get_width()) / 2, SOLE - part.get_height()))
	return result

func _actor_rows(source: Image, rows: int) -> Array:
	var width := source.get_width()
	var height := source.get_height()
	var seen := PackedByteArray()
	seen.resize(width * height)
	var components: Array = []
	for first: int in width * height:
		var first_x := first % width
		var first_y := first / width
		if seen[first] or source.get_pixel(first_x, first_y).a < 0.75:
			continue
		var queue := PackedInt32Array([first])
		seen[first] = 1
		var cursor := 0
		var left := first_x
		var right := first_x
		var top := first_y
		var bottom := first_y
		while cursor < queue.size():
			var point := queue[cursor]
			cursor += 1
			var x := point % width
			var y := point / width
			left = mini(left, x)
			right = maxi(right, x)
			top = mini(top, y)
			bottom = maxi(bottom, y)
			for next: int in [point - 1 if x > 0 else -1, point + 1 if x < width - 1 else -1, point - width if y > 0 else -1, point + width if y < height - 1 else -1]:
				if next < 0 or seen[next]:
					continue
				var next_x := next % width
				var next_y := next / width
				if source.get_pixel(next_x, next_y).a >= 0.75:
					seen[next] = 1
					queue.append(next)
		components.append({
			"size": queue.size(),
			"rect": Rect2i(maxi(0, left - 2), maxi(0, top - 2), mini(width, right + 3) - maxi(0, left - 2), mini(height, bottom + 3) - maxi(0, top - 2))
		})
	components.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.size) > int(b.size))
	var actor_count := rows * COLUMNS
	assert(components.size() >= actor_count, "Missing complete old-man actors in source sheet")
	components.resize(actor_count)
	components.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_rect: Rect2i = a.rect
		var b_rect: Rect2i = b.rect
		return a_rect.get_center().y < b_rect.get_center().y
	)
	var result: Array = []
	for row: int in rows:
		var actors: Array[Rect2i] = []
		for index: int in COLUMNS:
			actors.append(components[row * COLUMNS + index].rect)
		actors.sort_custom(func(a: Rect2i, b: Rect2i) -> bool: return a.position.x < b.position.x)
		result.append(actors)
	return result

func _row(path: String, row: int, rows: int) -> Array[Image]:
	var source := _read(path)
	var cache_key := "%s:%d" % [path, rows]
	if not rect_cache.has(cache_key):
		rect_cache[cache_key] = _actor_rows(source, rows)
	var result: Array[Image] = []
	for region: Rect2i in rect_cache[cache_key][row]:
		result.append(_cell(source, region))
	return result

func _setup() -> void:
	var locomotion := SOURCE + "old-man-locomotion.png"
	var actions := SOURCE + "old-man-actions.png"
	var utility := SOURCE + "old-man-utility.png"
	var carry := SOURCE + "old-man-carry-handover.png"
	for row: int in 4:
		groups[["walk", "walk_left", "chase", "chase_left"][row]] = _row(locomotion, row, 4)
	for row: int in 4:
		groups[["swat", "kick", "kick_left", "stick_hit"][row]] = _row(actions, row, 4)
	for row: int in 4:
		groups[["stick_hit_left", "rise", "pickup", "utility"][row]] = _row(utility, row, 4)
	for row: int in 3:
		groups[["carry", "carry_left", "handover"][row]] = _row(carry, row, 3)

func build(clips: Dictionary) -> Image:
	_setup()
	var total := 0
	for count: int in clips.values():
		total += count
	var atlas := Image.create(8 * CELL, ceili(float(total) / 8.0) * CELL, false, Image.FORMAT_RGBA8)
	atlas.fill(Color.TRANSPARENT)
	var index := 0
	for clip: String in clips:
		for frame: int in int(clips[clip]):
			var cell := _frame(clip, frame)
			atlas.blit_rect(cell, Rect2i(Vector2i.ZERO, Vector2i(CELL, CELL)), Vector2i(index % 8 * CELL, index / 8 * CELL))
			index += 1
	return atlas

func _frame(clip: String, frame: int) -> Image:
	var idle: Image = groups.utility[0]
	if clip in ["walk", "walk_left", "chase", "chase_left", "swat", "kick", "kick_left", "carry", "carry_left", "stick_hit", "stick_hit_left"]:
		return groups[clip][frame]
	if clip in ["run", "run_left"]:
		var left := clip.ends_with("_left")
		return groups["walk_left" if left else "walk"][2] if frame == 0 else groups["chase_left" if left else "chase"][frame - 1]
	match clip:
		"rest": return idle
		"rise": return groups.rise[frame] if frame < 6 else idle
		"idle": return idle
		"eat": return groups.utility[[0, 1, 2, 0][frame]]
		"alert": return groups.utility[[0, 3, 3, 0][frame]]
		"block": return groups.utility[[0, 4, 4, 0][frame]]
		"shield": return groups.utility[[0, 5, 5, 0][frame]]
		"pickup": return groups.pickup[[0, 1, 2, 3, 5][frame]]
		"handover": return groups.handover[[0, 1, 2, 3, 5][frame]]
	return idle
