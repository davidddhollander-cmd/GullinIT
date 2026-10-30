extends RefCounted
## Offline atlas preparation. Review sources stay untouched; runtime loads PNGs only.
const CELL := 64
const PALETTE := [Color("183b4e"), Color("ffc17c"), Color("df8b58"), Color("713d31"), Color("a85d3b"), Color("fff4da"), Color("ef725c"), Color("b94d4e"), Color("408fa8"), Color("28667b"), Color("854b32"), Color("4d2c26"), Color("dc4050"), Color("a32d41")]
const SOURCE := "res://assets/reference/adult-replacement-v3/"
var poses: Array[Image] = []
var walk_right: Array[Image] = []
var walk_left: Array[Image] = []
var carry_right: Array[Image] = []
var carry_left: Array[Image] = []
var rise: Array[Image] = []
var pickup: Array[Image] = []
var handover: Array[Image] = []
var is_sunbather := false
var standing: Image

func _read(path: String) -> Image:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	assert(image != null, "Missing adult animation source: " + path)
	image.convert(Image.FORMAT_RGBA8)
	return image

func _isolate_actor(part: Image) -> void:
	var width := part.get_width()
	var height := part.get_height()
	var labels := PackedInt32Array()
	labels.resize(width * height)
	var label := 0
	var largest := 0
	var largest_count := 0
	var queue := PackedInt32Array()
	for y: int in height:
		for x: int in width:
			var start := y * width + x
			if labels[start] != 0 or part.get_pixel(x, y).a == 0:
				continue
			label += 1
			queue.clear()
			queue.append(start)
			labels[start] = label
			var cursor := 0
			while cursor < queue.size():
				var index := queue[cursor]
				cursor += 1
				var px := index % width
				var py := index / width
				for delta: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var nx := px + delta.x
					var ny := py + delta.y
					if nx < 0 or nx >= width or ny < 0 or ny >= height:
						continue
					var next := ny * width + nx
					if labels[next] == 0 and part.get_pixel(nx, ny).a > 0:
						labels[next] = label
						queue.append(next)
			if queue.size() > largest_count:
				largest = label
				largest_count = queue.size()
	for y: int in height:
		for x: int in width:
			if labels[y * width + x] != largest:
				part.set_pixel(x, y, Color.TRANSPARENT)

func _pose(source: Image, rect: Rect2i, height: int, blue: bool = false) -> Image:
	var part := source.get_region(rect)
	# Generated alpha fringes and disconnected reaction effects are not actor pixels.
	for y: int in part.get_height():
		for x: int in part.get_width():
			var c := part.get_pixel(x, y)
			if c.a < 0.75:
				part.set_pixel(x, y, Color.TRANSPARENT)
	_isolate_actor(part)
	var bounds := part.get_used_rect()
	assert(bounds.has_area(), "Empty source pose")
	part = part.get_region(bounds)
	var width := roundi(float(part.get_width()) * height / part.get_height())
	if width > 58:
		height = roundi(float(height) * 58 / width)
		width = 58
	part.resize(width, height, Image.INTERPOLATE_NEAREST)
	var result := Image.create(CELL, CELL, false, Image.FORMAT_RGBA8)
	result.fill(Color.TRANSPARENT)
	var offset := Vector2i((CELL - width) / 2, 58 - height)
	for y: int in height:
		for x: int in width:
			var c := part.get_pixel(x, y)
			if c.a < 0.75:
				continue
			var nearest := 0
			var distance := INF
			for i: int in PALETTE.size():
				# Keep warm brown hair/skin out of the swimsuit colour slots.
				if is_sunbather and i >= 6:
					continue
				var p: Color = PALETTE[i]
				var d := Vector3(c.r - p.r, c.g - p.g, c.b - p.b).length_squared()
				if d < distance:
					distance = d
					nearest = i
			var color: Color = PALETTE[nearest]
			if is_sunbather and c.r > 0.4 and c.g < 0.38 and c.b > c.g * 0.65 and c.r > c.g * 2.0:
				nearest = 12 if c.r > 0.65 else 13
				color = PALETTE[nearest]
			if blue and nearest in [12, 13]:
				color = Color("4b88b7") if nearest == 12 else Color("30618d")
			result.set_pixelv(offset + Vector2i(x, y), color)
	return result

func _row(source: Image, row: int, rows: int, heights: Array, blue: bool = false, boundaries: Array = []) -> Array[Image]:
	var result: Array[Image] = []
	for i: int in heights.size():
		var x0 := roundi(float(i) * source.get_width() / heights.size()) if boundaries.is_empty() else int(boundaries[i])
		var x1 := roundi(float(i + 1) * source.get_width() / heights.size()) if boundaries.is_empty() else int(boundaries[i + 1])
		var y0 := roundi(float(row) * source.get_height() / rows)
		var y1 := roundi(float(row + 1) * source.get_height() / rows)
		result.append(_pose(source, Rect2i(x0, y0, x1 - x0, y1 - y0), heights[i], blue))
	return result

func _setup(mum: bool, female: bool, blue: bool) -> void:
	is_sunbather = not mum
	var name: String = "mum" if mum else ("sunbather-female" if female else "sunbather-male")
	var review := _read("res://assets/previews/%s-retro-review-v1.png" % name)
	for row: int in 3:
		var heights: Array = [40, 40, 40, 40]
		var bounds: Array = []
		if not mum and row == 0:
			heights = [18, 29, 40, 36]
			bounds = [0, 435, 785, 1110, 1445]
		poses.append_array(_row(review, row, 3, heights, blue, bounds))
	standing = poses[0]
	if not mum:
		var cast := _read("res://assets/archive/previews/adult-cast-32bit-style-review-v2.png")
		standing = _pose(cast, Rect2i(1190 if female else 610, 0, 584 if female else 580, 887), 40, blue)
	if female:
		var motion := _read(SOURCE + "female-motion.png")
		walk_right = _row(motion, 0, 4, [40, 40, 40, 40, 40, 40], blue)
		walk_left = _row(motion, 1, 4, [40, 40, 40, 40, 40, 40], blue)
		rise = _row(motion, 2, 4, [18, 25, 29, 33, 36, 40], blue, [0, 348, 610, 842, 1065, 1328, 1536])
		pickup = _row(motion, 3, 4, [40, 36, 32, 29, 36, 40], blue)
	else:
		var motion := _read("res://assets/previews/%s-walk-review-v1.png" % ("mum" if mum else "sunbather-male"))
		walk_right = _row(motion, 0, 2, [40, 40, 40, 40, 40, 40], blue)
		walk_left = _row(motion, 1, 2, [40, 40, 40, 40, 40, 40], blue)
		if mum:
			var carry := _read(SOURCE + "mum-carry-handover.png")
			carry_right = _row(carry, 0, 3, [40, 40, 40, 40, 40, 40])
			carry_left = _row(carry, 1, 3, [40, 40, 40, 40, 40, 40])
			handover = _row(carry, 2, 3, [40, 36, 33, 33, 36, 40])
		else:
			var transitions := _read(SOURCE + "male-transitions.png")
			rise = _row(transitions, 0, 2, [18, 25, 29, 33, 36, 40], blue, [0, 500, 900, 1250, 1600, 1930, 2172])
			pickup = _row(transitions, 1, 2, [40, 36, 32, 29, 36, 40], blue)

func build(mum: bool, female: bool, blue: bool, clips: Dictionary) -> Image:
	_setup(mum, female, blue)
	var total := 0
	for count: int in clips.values():
		total += count
	var image := Image.create(8 * CELL, ceili(float(total) / 8) * CELL, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var index := 0
	for clip: String in clips:
		for frame: int in int(clips[clip]):
			var cell := _frame(mum, clip, frame)
			image.blit_rect(cell, Rect2i(0, 0, CELL, CELL), Vector2i(index % 8 * CELL, index / 8 * CELL))
			index += 1
	return image

func _frame(mum: bool, clip: String, frame: int) -> Image:
	var left := clip.ends_with("_left")
	var action := clip.trim_suffix("_left")
	var idle: Image = standing
	var cell: Image = idle
	match action:
		"walk", "chase", "run":
			var cycle: Array[Image] = walk_left if left else walk_right
			cell = cycle[frame % 6]
			if action in ["chase", "run"] and frame % 6 in [2, 5]:
				cell = poses[8 if mum else 7].duplicate()
				if left:
					cell.flip_x()
				if frame % 6 == 5:
					cell = cycle[frame % 6]
		"carry":
			cell = (carry_left if left else carry_right)[frame]
		"handover":
			cell = handover[[0, 1, 2, 2, 5][frame]]
		"rest":
			cell = poses[0]
		"rise":
			cell = rise[[0, 1, 2, 3, 4, 5, 5][frame]] if frame < 6 else idle
		"pickup":
			cell = pickup[frame]
		"eat":
			cell = poses[1 if mum else 2] if frame in [1, 2] else idle
		"alert":
			cell = poses[2 if mum else 3] if frame > 0 else idle
		"block", "shield":
			cell = poses[3 if mum else 8] if frame in [1, 2] else idle
		"swat":
			cell = poses[[2 if mum else 3, 9, 9, 10, 10, 0 if mum else 2][frame]]
		"kick":
			cell = poses[[0 if mum else 2, 8 if mum else 7, 9, 11, 8 if mum else 7, 0 if mum else 2][frame]].duplicate()
			if left:
				cell.flip_x()
	return cell
