extends SceneTree
## Import-only preparation: crop, harden alpha, nearest-resize and align ImageGen poses.
## No character anatomy, clothing or broom pixels are drawn by this script.

const CELL := 128
const SOLE := 116
const HEIGHT := 80
const SOURCE := "res://assets/stage2/market-cleaner/reference/"
const OUTPUT := "res://assets/stage2/market-cleaner/market-cleaner-v1.png"

func _read(name: String) -> Image:
	var image := Image.load_from_file(ProjectSettings.globalize_path(SOURCE + name))
	assert(image != null, "Missing generated seafood vendor source: " + name)
	image.convert(Image.FORMAT_RGBA8)
	return image

func _prepare(part: Image) -> Image:
	# Preserve every generated figure-and-broom component; remove only alpha fringe.
	for y: int in part.get_height():
		for x: int in part.get_width():
			var color := part.get_pixel(x, y)
			if color.a < 0.75:
				part.set_pixel(x, y, Color.TRANSPARENT)
			else:
				color.a = 1.0
				part.set_pixel(x, y, color)
	var bounds := part.get_used_rect()
	assert(bounds.has_area(), "Empty seafood vendor source pose")
	part = part.get_region(bounds)
	var height := HEIGHT
	var width := roundi(float(part.get_width()) * height / part.get_height())
	if width > 116:
		height = roundi(float(height) * 116.0 / width)
		width = 116
	part.resize(width, height, Image.INTERPOLATE_NEAREST)
	var result := Image.create(CELL, CELL, false, Image.FORMAT_RGBA8)
	result.fill(Color.TRANSPARENT)
	result.blit_rect(part, Rect2i(0, 0, width, height), Vector2i((CELL - width) / 2, SOLE - height))
	return result

func _row(source: Image, row: int, rows: int, count: int) -> Array[Image]:
	var y0 := roundi(float(row) * source.get_height() / rows)
	var y1 := roundi(float(row + 1) * source.get_height() / rows)
	var strip := source.get_region(Rect2i(0, y0, source.get_width(), y1 - y0))
	var width := strip.get_width()
	var height := strip.get_height()
	var seen := PackedByteArray()
	seen.resize(width * height)
	var components: Array[Dictionary] = []
	for first: int in width * height:
		if seen[first] or strip.get_pixel(first % width, first / width).a < 0.75:
			continue
		var pixels := PackedInt32Array([first])
		seen[first] = 1
		var cursor := 0
		var bounds := Rect2i(first % width, first / width, 1, 1)
		while cursor < pixels.size():
			var index := pixels[cursor]
			cursor += 1
			var x := index % width
			var y := index / width
			bounds = bounds.expand(Vector2i(x, y))
			for next: int in [index - 1, index + 1, index - width, index + width]:
				if next < 0 or next >= seen.size() or absi(next % width - x) > 1:
					continue
				if not seen[next] and strip.get_pixel(next % width, next / width).a >= 0.75:
					seen[next] = 1
					pixels.append(next)
		bounds.size += Vector2i.ONE
		components.append({"pixels":pixels,"bounds":bounds})
	components.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.pixels.size() > b.pixels.size())
	assert(components.size() >= count, "Missing complete seafood vendor figures in row %d" % row)
	components.resize(count)
	components.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.bounds.get_center().x < b.bounds.get_center().x)
	var result: Array[Image] = []
	for component: Dictionary in components:
		var bounds: Rect2i = component.bounds
		var part := Image.create(bounds.size.x, bounds.size.y, false, Image.FORMAT_RGBA8)
		part.fill(Color.TRANSPARENT)
		for index: int in component.pixels:
			var point := Vector2i(index % width, index / width)
			part.set_pixelv(point - bounds.position, strip.get_pixelv(point))
		result.append(_prepare(part))
	return result

func _scaled_cell(atlas: Image, frame: int, frame_size: int, scale: float) -> Image:
	var columns := atlas.get_width() / frame_size
	var cell := atlas.get_region(Rect2i(frame % columns * frame_size, frame / columns * frame_size, frame_size, frame_size))
	cell.resize(roundi(frame_size * scale), roundi(frame_size * scale), Image.INTERPOLATE_NEAREST)
	return cell

func _preview(atlas: Image) -> void:
	var preview := Image.create(384, 140, false, Image.FORMAT_RGBA8)
	preview.fill(Color("a8d7d1"))
	preview.fill_rect(Rect2i(0, 72, 384, 28), Color("5aabc0"))
	preview.fill_rect(Rect2i(0, 100, 384, 40), Color("bd7a45"))
	for y: int in [108, 124]:
		preview.fill_rect(Rect2i(0, y, 384, 2), Color("8b5438"))
	var fish_vendor := Image.load_from_file("res://assets/sprites/vendor-fish-chips-full-body-v1.png")
	var diner := Image.load_from_file("res://assets/sprites/pier-diner-b-base-v1.png")
	assert(fish_vendor != null and diner != null)
	var actors: Array[Image] = [
		_scaled_cell(fish_vendor, 0, CELL, 0.5),
		_scaled_cell(atlas, 0, CELL, 0.5),
		_scaled_cell(diner, 0, CELL, 0.5)
	]
	for index: int in actors.size():
		var actor := actors[index]
		var centre_x := 64 + index * 128
		preview.blend_rect(actor, Rect2i(Vector2i.ZERO, actor.get_size()), Vector2i(centre_x - actor.get_width() / 2, 104 - actor.get_height()))
	assert(preview.save_png("res://assets/stage2/market-cleaner/market-cleaner-v1-comparison.png") == OK)

func _initialize() -> void:
	var actions := _read("seafood-vendor-actions-source.png")
	var frames: Array[Image] = []
	for row: int in 3:
		frames.append_array(_row(actions, row, 3, 4))
	var walk := _read("seafood-vendor-walk-source.png")
	for row: int in 2:
		frames.append_array(_row(walk, row, 2, 3))
	var atlas := Image.create(8 * CELL, 3 * CELL, false, Image.FORMAT_RGBA8)
	atlas.fill(Color.TRANSPARENT)
	for index: int in frames.size():
		atlas.blit_rect(frames[index], Rect2i(0, 0, CELL, CELL), Vector2i(index % 8 * CELL, index / 8 * CELL))
	assert(atlas.save_png(OUTPUT) == OK)
	_preview(atlas)
	print("Prepared seafood vendor: 4 idle, 2 alert, 2 angry, 2 windup, 2 swat, 6 walk frames")
	quit()
