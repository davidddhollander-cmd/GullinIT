extends SceneTree
## Prepare ImageGen artwork as native food sprites, without changing bin rules.
const VARIANTS := ["doughnut", "sandwich", "pizza"]
const PALETTE := [
	Color("183b4e"), Color("fff4da"), Color("ffc65c"), Color("d59a5e"),
	Color("aa7047"), Color("ef725c"), Color("b94d4e"), Color("68a65d")
]

func _initialize() -> void:
	var atlas := Image.create(48, 16, false, Image.FORMAT_RGBA8)
	atlas.fill(Color.TRANSPARENT)
	var review := Image.create(60, 20, false, Image.FORMAT_RGBA8)
	review.fill(Color.TRANSPARENT)
	for index: int in VARIANTS.size():
		var kind: String = VARIANTS[index]
		var source := Image.new()
		var source_path: String = "res://assets/reference/bin-leftovers/half-eaten-%s-source-v1.png" % kind
		if source.load(source_path) != OK:
			push_error("Could not load " + source_path)
			quit(1)
			return
		var bounds: Rect2i = _solid_bounds(source)
		if not bounds.has_area():
			push_error("No solid artwork in " + source_path)
			quit(1)
			return
		var factor: float = minf(14.0 / bounds.size.x, 14.0 / bounds.size.y)
		var width: int = maxi(1, roundi(bounds.size.x * factor))
		var height: int = maxi(1, roundi(bounds.size.y * factor))
		var reduced: Image = source.get_region(bounds)
		reduced.resize(width, height, Image.INTERPOLATE_NEAREST)
		_quantize(reduced)
		var output := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		output.fill(Color.TRANSPARENT)
		output.blit_rect(reduced, Rect2i(0, 0, width, height), Vector2i((16-width)/2, 15-height))
		var path: String = "res://assets/sprites/retro-food-half-eaten-%s-32bit.png" % kind
		if output.save_png(path) != OK:
			push_error("Could not save " + path)
			quit(1)
			return
		# Validate the saved PNG rather than only the working image.
		var saved := Image.new()
		assert(saved.load(path) == OK)
		assert(saved.get_size() == Vector2i(16, 16))
		var colors: Dictionary = {}
		var opaque: int = 0
		for y: int in 16:
			for x: int in 16:
				var pixel: Color = saved.get_pixel(x, y)
				assert(pixel.a == 0.0 or pixel.a == 1.0, "Alpha must be binary")
				if pixel.a == 1.0:
					assert(pixel in PALETTE, "Color must match food palette")
					colors[pixel.to_html()] = true
					opaque += 1
		assert(opaque > 30 and opaque < 16*16, "Expected isolated food silhouette")
		assert(colors.size() <= 8, "Expected eight-color maximum")
		atlas.blit_rect(output, Rect2i(0, 0, 16, 16), Vector2i(index*16, 0))
		review.blit_rect(output, Rect2i(0, 0, 16, 16), Vector2i(2+index*20, 2))
		print("%s: saved 16x16, silhouette %dx%d, %d opaque pixels, %d colors, binary alpha" % [kind, width, height, opaque, colors.size()])
	assert(atlas.save_png("res://assets/sprites/retro-food-bin-leftovers-atlas-32bit.png") == OK)
	review.resize(720, 240, Image.INTERPOLATE_NEAREST)
	assert(review.save_png("res://assets/archive/previews/bin-leftovers-review-v1.png") == OK)
	quit()

func _solid_bounds(source: Image) -> Rect2i:
	var low := Vector2i(source.get_width(), source.get_height())
	var high := Vector2i(-1, -1)
	for y: int in source.get_height():
		for x: int in source.get_width():
			if source.get_pixel(x, y).a >= 0.9:
				low = Vector2i(mini(low.x, x), mini(low.y, y))
				high = Vector2i(maxi(high.x, x), maxi(high.y, y))
	return Rect2i(low, high-low+Vector2i.ONE)

func _quantize(image: Image) -> void:
	for y: int in image.get_height():
		for x: int in image.get_width():
			var source: Color = image.get_pixel(x, y)
			if source.a < 0.9:
				image.set_pixel(x, y, Color.TRANSPARENT)
				continue
			var closest: Color = PALETTE[0]
			var distance: float = INF
			for color: Color in PALETTE:
				var delta := Vector3(source.r-color.r, source.g-color.g, source.b-color.b)
				if delta.length_squared() < distance:
					distance = delta.length_squared()
					closest = color
			image.set_pixel(x, y, closest)
