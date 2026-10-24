extends SceneTree
## Import-only preparation: crops, aligns, scales and quantizes generated artwork.
## It never paints or reconstructs the vendor or stall.
const SOURCE := "res://assets/reference/fish-chips-stand-v1/"
const CELL := 128
const SOLE := 116
const PALETTE := [
	Color("183b4e"), Color("fff4da"), Color("408fa8"), Color("28667b"),
	Color("ef725c"), Color("b94d4e"), Color("aa7047"), Color("d59a5e"),
	Color("754a39"), Color("4b88b7"), Color("e8c58e"), Color("c69a68"),
	Color("68a65d"), Color("34745d"), Color("8e9b9e"), Color("617782")
]

func _initialize() -> void:
	_prepare_stall()
	_prepare_sign()
	_prepare_vendor()
	print("Prepared fish-and-chips stall, sign and 12-pose full-body vendor atlas")
	quit()

func _prepare_stall() -> void:
	var source := _load_rgba(SOURCE + "fish-chips-stall-source.png")
	var bounds: Rect2i = source.get_used_rect()
	assert(bounds.has_area(), "Fish-and-chips stall source is empty")
	var cropped: Image = source.get_region(bounds)
	var target := Vector2i(52, 56)
	var scale_factor: float = minf(float(target.x) / cropped.get_width(), float(target.y) / cropped.get_height())
	var size := Vector2i(maxi(1, floori(cropped.get_width() * scale_factor)), maxi(1, floori(cropped.get_height() * scale_factor)))
	cropped.resize(size.x, size.y, Image.INTERPOLATE_NEAREST)
	_quantize(cropped)
	var output := Image.create(target.x, target.y, false, Image.FORMAT_RGBA8)
	output.fill(Color.TRANSPARENT)
	output.blit_rect(cropped, Rect2i(Vector2i.ZERO, size), Vector2i((target.x - size.x) / 2, target.y - size.y))
	assert(output.save_png("res://assets/sprites/retro-fish-chips-stand-32bit.png") == OK)

func _prepare_sign() -> void:
	var source := _load_rgba(SOURCE + "fish-chips-sign-source.png")
	_clean_alpha(source)
	var bounds: Rect2i = source.get_used_rect()
	assert(bounds.has_area(), "Fish-and-chips sign source is empty")
	var output: Image = source.get_region(bounds)
	var height: int = roundi(float(output.get_height()) * 256.0 / output.get_width())
	output.resize(256, height, Image.INTERPOLATE_NEAREST)
	assert(output.save_png("res://assets/sprites/stand-sign-fish-chips-runtime-v1.png") == OK)

func _prepare_vendor() -> void:
	var atlas := Image.create(12 * CELL, CELL, false, Image.FORMAT_RGBA8)
	atlas.fill(Color.TRANSPARENT)
	_append_vendor_sheet(atlas, SOURCE + "vendor-fish-chips-full-body-source.png", 4, 2, 0)
	var base: Image = atlas.get_region(Rect2i(0, 0, 8 * CELL, CELL))
	assert(base.save_png("res://assets/sprites/vendor-fish-chips-full-body-v1-base.png") == OK)
	_append_vendor_sheet(atlas, SOURCE + "vendor-fish-chips-turn-source.png", 2, 2, 8)
	assert(atlas.save_png("res://assets/sprites/vendor-fish-chips-full-body-v1.png") == OK)

func _append_vendor_sheet(atlas: Image, source_path: String, columns: int, rows: int, first_frame: int) -> void:
	var sheet := _load_rgba(source_path)
	var cell_size := Vector2i(sheet.get_width() / columns, sheet.get_height() / rows)
	for index: int in columns * rows:
		var frame: Image = sheet.get_region(Rect2i(Vector2i(index % columns, index / columns) * cell_size, cell_size))
		_clean_alpha(frame)
		var bounds: Rect2i = frame.get_used_rect()
		assert(bounds.has_area(), "Empty generated vendor cell %d in %s" % [index, source_path])
		var scale_factor: float = 80.0 / float(bounds.size.y)
		var foot_left: int = bounds.end.x
		var foot_right: int = bounds.position.x
		for y: int in range(bounds.end.y - maxi(1, roundi(bounds.size.y * 0.09)), bounds.end.y):
			for x: int in range(bounds.position.x, bounds.end.x):
				if frame.get_pixel(x, y).a > 0.5:
					foot_left = mini(foot_left, x)
					foot_right = maxi(foot_right, x)
		var shoe_centre: float = (foot_left + foot_right) * 0.5
		var cropped: Image = frame.get_region(bounds)
		var size := Vector2i(roundi(bounds.size.x * scale_factor), roundi(bounds.size.y * scale_factor))
		cropped.resize(size.x, size.y, Image.INTERPOLATE_NEAREST)
		var offset := Vector2i(64 - roundi((shoe_centre - bounds.position.x) * scale_factor), SOLE - size.y)
		assert(Rect2i(0, 0, CELL, CELL).encloses(Rect2i(offset, size)), "Vendor does not fit target cell")
		atlas.blit_rect(cropped, Rect2i(Vector2i.ZERO, size), Vector2i((first_frame + index) * CELL, 0) + offset)

func _load_rgba(path: String) -> Image:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	assert(image != null, "Missing generated source: " + path)
	image.convert(Image.FORMAT_RGBA8)
	return image

func _clean_alpha(image: Image) -> void:
	for y: int in image.get_height():
		for x: int in image.get_width():
			var color: Color = image.get_pixel(x, y)
			if color.a >= 0.75:
				color.a = 1.0
			else:
				color = Color.TRANSPARENT
			image.set_pixel(x, y, color)

func _quantize(image: Image) -> void:
	for y: int in image.get_height():
		for x: int in image.get_width():
			var source: Color = image.get_pixel(x, y)
			if source.a < 0.65:
				image.set_pixel(x, y, Color.TRANSPARENT)
				continue
			var closest: Color = PALETTE[0]
			var closest_distance: float = INF
			for colour: Color in PALETTE:
				var delta := Vector3(source.r - colour.r, source.g - colour.g, source.b - colour.b)
				var distance: float = delta.length_squared()
				if distance < closest_distance:
					closest_distance = distance
					closest = colour
			image.set_pixel(x, y, closest)
