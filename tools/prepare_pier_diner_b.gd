extends SceneTree
## Import-only preparation: crop, isolate, nearest-resize and align ImageGen poses.
## No character anatomy or clothing is drawn by this script.

const CELL := 128
const SOLE := 116
const HEIGHT := 80
const SOURCE := "res://assets/reference/pier-diner-b-v1/"
const SPRITES := "res://assets/sprites/"
const Extractor = preload("res://tools/adult_atlas_source.gd")

var extractor := Extractor.new()

func _read(name: String) -> Image:
	var image := Image.load_from_file(ProjectSettings.globalize_path(SOURCE + name))
	assert(image != null, "Missing generated source: " + name)
	image.convert(Image.FORMAT_RGBA8)
	return image

func _pose(source: Image, column: int, row: int, columns: int, rows: int) -> Image:
	var x0 := roundi(float(column) * source.get_width() / columns)
	var x1 := roundi(float(column + 1) * source.get_width() / columns)
	var y0 := roundi(float(row) * source.get_height() / rows)
	var y1 := roundi(float(row + 1) * source.get_height() / rows)
	var part := source.get_region(Rect2i(x0, y0, x1 - x0, y1 - y0))
	# Hard alpha removes only generated fringe pixels; the connected figure stays intact.
	for y: int in part.get_height():
		for x: int in part.get_width():
			var color := part.get_pixel(x, y)
			if color.a < 0.75:
				part.set_pixel(x, y, Color.TRANSPARENT)
			else:
				color.a = 1.0
				part.set_pixel(x, y, color)
	extractor._isolate_actor(part)
	var bounds := part.get_used_rect()
	assert(bounds.has_area(), "Empty diner source cell %d,%d" % [column, row])
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

func _pack(frames: Array[Image], output_name: String) -> Image:
	var atlas := Image.create(8 * CELL, ceili(float(frames.size()) / 8.0) * CELL, false, Image.FORMAT_RGBA8)
	atlas.fill(Color.TRANSPARENT)
	for index: int in frames.size():
		atlas.blit_rect(frames[index], Rect2i(0, 0, CELL, CELL), Vector2i(index % 8 * CELL, index / 8 * CELL))
	assert(atlas.save_png(SPRITES + output_name) == OK)
	return atlas

func _scaled_cell(atlas: Image, frame: int, frame_size: int, scale: float) -> Image:
	var columns := atlas.get_width() / frame_size
	var cell := atlas.get_region(Rect2i(frame % columns * frame_size, frame / columns * frame_size, frame_size, frame_size))
	cell.resize(roundi(frame_size * scale), roundi(frame_size * scale), Image.INTERPOLATE_NEAREST)
	return cell

func _preview(new_base: Image) -> void:
	var preview := Image.create(256, 128, false, Image.FORMAT_RGBA8)
	preview.fill(Color("a8d7d1"))
	preview.fill_rect(Rect2i(0, 92, 256, 36), Color("e9ca89"))
	var original := Image.load_from_file("res://assets/sprites/pier-diner-retro-clean.png")
	assert(original != null)
	var original_cell := _scaled_cell(original, 0, 400, 0.11)
	var new_cell := _scaled_cell(new_base, 0, CELL, 0.5)
	preview.blend_rect(original_cell, Rect2i(Vector2i.ZERO, original_cell.get_size()), Vector2i(64 - original_cell.get_width() / 2, 92 - original_cell.get_height()))
	preview.blend_rect(new_cell, Rect2i(Vector2i.ZERO, new_cell.get_size()), Vector2i(192 - new_cell.get_width() / 2, 92 - new_cell.get_height()))
	assert(preview.save_png("res://assets/previews/pier-diner-b-v1-comparison.png") == OK)

func _initialize() -> void:
	var base_source := _read("pier-diner-b-base-source.png")
	var base: Array[Image] = []
	for row: int in 3:
		for column: int in 4:
			base.append(_pose(base_source, column, row, 4, 3))
	var base_atlas := _pack(base, "pier-diner-b-base-v1.png")

	var locomotion := _read("pier-diner-b-locomotion-source.png")
	var motion: Array[Image] = []
	for column: int in 5:
		motion.append(_pose(locomotion, column, 0, 5, 2))
	motion.append(_pose(locomotion, 0, 1, 5, 2))
	for column: int in range(1, 5):
		motion.append(_pose(locomotion, column, 1, 5, 2))
	var eating := _read("pier-diner-b-eat-source.png")
	for column: int in 4:
		motion.append(_pose(eating, column, 0, 4, 1))
	_pack(motion, "pier-diner-b-motion-v1.png")

	var reaction_source := _read("pier-diner-b-reactions-source.png")
	var reactions: Array[Image] = []
	for row: int in 2:
		for column: int in 6:
			reactions.append(_pose(reaction_source, column, row, 6, 2))
	_pack(reactions, "pier-diner-b-reactions-v1.png")
	_preview(base_atlas)
	print("Prepared pier diner B: 12 base, 14 motion, 12 reaction frames")
	quit()
