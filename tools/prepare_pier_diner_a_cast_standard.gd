extends SceneTree
## Import-only preparation of the existing generated diner A artwork.
## Crops complete source poses, hardens alpha, nearest-resizes and aligns them.
## No character anatomy, face, clothing or limbs are drawn by this script.

const CELL := 128
const SOLE := 116
const HEIGHT := 80
const SOURCE := "res://assets/reference/pier-diner-a-cast-standard-v1/"
const SPRITES := "res://assets/sprites/"
const PREVIEWS := "res://assets/previews/"

func _read(name: String) -> Image:
	var image := Image.load_from_file(ProjectSettings.globalize_path(SOURCE + name))
	assert(image != null, "Missing supplied source: " + name)
	image.convert(Image.FORMAT_RGBA8)
	return image

func _pose(source: Image, frame: int, columns: int) -> Image:
	var x := frame % columns * 400
	var y := frame / columns * 400
	var part := source.get_region(Rect2i(x, y, 400, 400))
	for py: int in part.get_height():
		for px: int in part.get_width():
			var color := part.get_pixel(px, py)
			if color.a < 0.75:
				part.set_pixel(px, py, Color.TRANSPARENT)
			else:
				color.a = 1.0
				part.set_pixel(px, py, color)
	var bounds := part.get_used_rect()
	assert(bounds.has_area(), "Empty diner A source frame %d" % frame)
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

func _pack(source: Image, frame_count: int, columns: int, output_name: String) -> Image:
	var atlas := Image.create(8 * CELL, ceili(float(frame_count) / 8.0) * CELL, false, Image.FORMAT_RGBA8)
	atlas.fill(Color.TRANSPARENT)
	for frame: int in frame_count:
		var pose := _pose(source, frame, columns)
		atlas.blit_rect(pose, Rect2i(0, 0, CELL, CELL), Vector2i(frame % 8 * CELL, frame / 8 * CELL))
	assert(atlas.save_png(SPRITES + output_name) == OK)
	return atlas

func _scaled_cell(atlas: Image, frame: int, frame_size: int, scale: float) -> Image:
	var columns := atlas.get_width() / frame_size
	var cell := atlas.get_region(Rect2i(frame % columns * frame_size, frame / columns * frame_size, frame_size, frame_size))
	cell.resize(roundi(frame_size * scale), roundi(frame_size * scale), Image.INTERPOLATE_NEAREST)
	return cell

func _preview(candidate: Image) -> void:
	var preview := Image.create(384, 128, false, Image.FORMAT_RGBA8)
	preview.fill(Color("a8d7d1"))
	preview.fill_rect(Rect2i(0, 92, 384, 36), Color("e9ca89"))
	var current := Image.load_from_file("res://assets/sprites/pier-diner-retro-clean.png")
	var diner_b := Image.load_from_file("res://assets/sprites/pier-diner-b-base-v1.png")
	assert(current != null and diner_b != null)
	var cells: Array[Image] = [
		_scaled_cell(current, 0, 400, 0.11),
		_scaled_cell(candidate, 0, CELL, 0.5),
		_scaled_cell(diner_b, 0, CELL, 0.5),
	]
	for i: int in cells.size():
		var cell := cells[i]
		preview.blend_rect(cell, Rect2i(Vector2i.ZERO, cell.get_size()), Vector2i(64 + i * 128 - cell.get_width() / 2, 92 - cell.get_height()))
	assert(preview.save_png(PREVIEWS + "pier-diner-a-cast-standard-v1-comparison.png") == OK)

func _initialize() -> void:
	var base := _pack(_read("pier-diner-a-base-source.png"), 12, 4, "pier-diner-a-base-candidate-v1.png")
	_pack(_read("pier-diner-a-motion-source.png"), 14, 4, "pier-diner-a-motion-candidate-v1.png")
	_pack(_read("pier-diner-a-reactions-source.png"), 12, 6, "pier-diner-a-reactions-candidate-v1.png")
	_preview(base)
	print("Prepared pier diner A candidate: 12 base, 14 motion, 12 reaction frames")
	quit()
