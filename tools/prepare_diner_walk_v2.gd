extends SceneTree
## Packs complete generated diner figures; it never paints or reconstructs anatomy.

const SOURCE := "res://assets/reference/diner-walk-v2/diner-walk-source-pass-1.png"
const OLD_ATLAS := "res://assets/sprites/pier-diner-motion-clean.png"
const OUTPUT := "res://assets/sprites/pier-diner-motion-v2.png"
const CELL := 400
const COLUMNS := 4
const WALK_FRAMES := 6
const TARGET_HEIGHT := 338
const BASELINE := 398

func _initialize() -> void:
	var source := Image.load_from_file(SOURCE)
	var old_atlas := Image.load_from_file(OLD_ATLAS)
	assert(not source.is_empty() and not old_atlas.is_empty())
	var actors := _complete_figures(source)
	assert(actors.size() == WALK_FRAMES, "Expected exactly six complete diner figures")
	actors.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.bounds.get_center().x < b.bounds.get_center().x)
	var output := Image.create(COLUMNS * CELL, 4 * CELL, false, Image.FORMAT_RGBA8)
	var source_cell_width := float(source.get_width()) / WALK_FRAMES
	for index: int in WALK_FRAMES:
		var bounds: Rect2i = actors[index].bounds
		# Retain only the complete connected figure. Generator fringe specks inside
		# the crop are not part of the character and must not enter the atlas.
		var figure := Image.create(bounds.size.x, bounds.size.y, false, Image.FORMAT_RGBA8)
		for pixel_index: int in actors[index].pixels:
			var point := Vector2i(pixel_index % source.get_width(), pixel_index / source.get_width())
			figure.set_pixelv(point - bounds.position, source.get_pixelv(point))
		var scale := float(TARGET_HEIGHT) / bounds.size.y
		var target_width := roundi(bounds.size.x * scale)
		figure.resize(target_width, TARGET_HEIGHT, Image.INTERPOLATE_NEAREST)
		var source_origin := (index + 0.5) * source_cell_width
		var local_left := roundi(CELL * 0.5 + (bounds.position.x - source_origin) * scale)
		local_left = clampi(local_left, 1, CELL - target_width - 1)
		var destination := Vector2i((index % COLUMNS) * CELL + local_left, (index / COLUMNS) * CELL + BASELINE - TARGET_HEIGHT)
		output.blit_rect(figure, Rect2i(Vector2i.ZERO, figure.get_size()), destination)
		print("walk ", index, " source=", bounds, " packed=", Rect2i(destination, figure.get_size()))
	# Preserve the already approved run and eat pixels exactly, only relocating cells.
	for old_index: int in range(4, 12):
		var new_index := old_index + 2
		var old_rect := Rect2i((old_index % COLUMNS) * CELL, (old_index / COLUMNS) * CELL, CELL, CELL)
		var new_position := Vector2i((new_index % COLUMNS) * CELL, (new_index / COLUMNS) * CELL)
		output.blit_rect(old_atlas, old_rect, new_position)
	assert(output.save_png(OUTPUT) == OK)
	quit()

func _complete_figures(source: Image) -> Array[Dictionary]:
	var width := source.get_width()
	var height := source.get_height()
	var data := source.get_data()
	var visited := PackedByteArray()
	visited.resize(width * height)
	var figures: Array[Dictionary] = []
	for start: int in width * height:
		if visited[start] or data[start * 4 + 3] < 64:
			continue
		var pixels := PackedInt32Array([start])
		visited[start] = 1
		var cursor := 0
		var bounds := Rect2i(start % width, start / width, 1, 1)
		while cursor < pixels.size():
			var point_index := pixels[cursor]
			cursor += 1
			var x := point_index % width
			var y := point_index / width
			bounds = bounds.expand(Vector2i(x, y))
			for next: int in [point_index - 1, point_index + 1, point_index - width, point_index + width]:
				if next < 0 or next >= visited.size() or absi(next % width - x) > 1:
					continue
				if not visited[next] and data[next * 4 + 3] >= 64:
					visited[next] = 1
					pixels.append(next)
		if pixels.size() > 10000:
			bounds.size += Vector2i.ONE
			figures.append({"pixels": pixels, "bounds": bounds})
	figures.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.pixels.size() > b.pixels.size())
	if figures.size() > WALK_FRAMES:
		figures.resize(WALK_FRAMES)
	return figures
