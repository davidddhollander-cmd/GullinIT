extends SceneTree
## Native export of the three ImageGen picnic bag variations, matching the
## existing environment asset preparation. Does not change gameplay mappings.
const VARIANTS := ["coral", "teal", "woven"]
const PALETTE := [
	Color("183b4e"), Color("fff4da"), Color("408fa8"), Color("28667b"),
	Color("ef725c"), Color("b94d4e"), Color("aa7047"), Color("d59a5e"),
	Color("754a39"), Color("4b88b7"), Color("e8c58e"), Color("c69a68"),
	Color("68a65d"), Color("34745d"), Color("8e9b9e"), Color("617782")
]

func _initialize() -> void:
	var review := Image.create(112, 32, false, Image.FORMAT_RGBA8)
	review.fill(Color.TRANSPARENT)
	for index: int in VARIANTS.size():
		var kind: String = VARIANTS[index]
		var source := Image.new()
		var source_path: String = "res://assets/reference/picnic-bags/%s-source-v1.png" % kind
		if source.load(source_path) != OK:
			push_error("Could not load " + source_path)
			quit(1)
			return
		# Ignore faint generation fringes and keep genuine solid bag pixels.
		var bounds: Rect2i = _solid_bounds(source)
		if not bounds.has_area():
			push_error("No solid artwork in " + source_path)
			quit(1)
			return
		var factor: float = minf(28.0 / bounds.size.x, 21.0 / bounds.size.y)
		var width: int = maxi(1, roundi(bounds.size.x * factor))
		var height: int = maxi(1, roundi(bounds.size.y * factor))
		var reduced: Image = source.get_region(bounds)
		reduced.resize(width, height, Image.INTERPOLATE_NEAREST)
		_quantize(reduced)
		var output := Image.create(32, 24, false, Image.FORMAT_RGBA8)
		output.fill(Color.TRANSPARENT)
		output.blit_rect(reduced, Rect2i(0, 0, width, height), Vector2i((32-width)/2, 23-height))
		var path: String = "res://assets/sprites/retro-picnic-bag-%s-32bit.png" % kind
		if output.save_png(path) != OK:
			push_error("Could not save " + path)
			quit(1)
			return
		var colors: Dictionary = {}
		var opaque: int = 0
		for y: int in 24:
			for x: int in 32:
				var pixel: Color = output.get_pixel(x, y)
				assert(pixel.a == 0.0 or pixel.a == 1.0, "Alpha must be binary")
				if pixel.a == 1.0:
					colors[pixel.to_html()] = true
					opaque += 1
		assert(opaque > 100 and opaque < 32*24, "Expected an isolated bag silhouette")
		assert(colors.size() <= 16, "Expected the shared environment palette")
		review.blit_rect(output, Rect2i(0, 0, 32, 24), Vector2i(4+index*36, 4))
		print("%s: 32x24, silhouette %dx%d, %d opaque pixels, %d colors, binary alpha" % [kind, width, height, opaque, colors.size()])
	review.resize(896, 256, Image.INTERPOLATE_NEAREST)
	if review.save_png("res://assets/archive/previews/picnic-bags-review-v1.png") != OK:
		push_error("Could not save review sheet")
		quit(1)
		return
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
				var delta: Vector3 = Vector3(source.r-color.r, source.g-color.g, source.b-color.b)
				if delta.length_squared() < distance:
					distance = delta.length_squared()
					closest = color
			image.set_pixel(x, y, closest)
