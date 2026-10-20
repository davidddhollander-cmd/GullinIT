extends SceneTree
## Rebuilds native-resolution transparent assets from the approved-style
## ImageGen concept sheets. Nearest-neighbour reduction and a fixed 16-colour
## palette remove the fine shading that made the previous art read too smooth.
const BUILDINGS := "res://assets/previews/beach-buildings-32bit-concept-v1.png"
const PROPS := "res://assets/previews/beach-props-32bit-concept-v1.png"
const PALETTE := [
	Color("183b4e"), Color("fff4da"), Color("408fa8"), Color("28667b"),
	Color("ef725c"), Color("b94d4e"), Color("aa7047"), Color("d59a5e"),
	Color("754a39"), Color("4b88b7"), Color("e8c58e"), Color("c69a68"),
	Color("68a65d"), Color("34745d"), Color("8e9b9e"), Color("617782")
]
const ITEMS := {
	"kiosk": {"sheet": "buildings", "box": Rect2i(0, 0, 540, 758), "size": Vector2i(52, 56)},
	"hotdog_stand": {"sheet": "buildings", "box": Rect2i(540, 0, 540, 758), "size": Vector2i(52, 56)},
	"tower": {"sheet": "buildings", "box": Rect2i(1080, 0, 500, 758), "size": Vector2i(56, 70)},
	"beach_hut": {"sheet": "buildings", "box": Rect2i(1580, 0, 496, 758), "size": Vector2i(40, 52)},
	"umbrella": {"sheet": "props", "box": Rect2i(0, 0, 410, 390), "size": Vector2i(38, 42)},
	"beach_parasol": {"sheet": "props", "box": Rect2i(0, 0, 410, 390), "size": Vector2i(40, 42)},
	"beach_parasol_blue": {"sheet": "props", "box": Rect2i(390, 0, 400, 390), "size": Vector2i(40, 42)},
	"beach_chair": {"sheet": "props", "box": Rect2i(790, 130, 360, 260), "size": Vector2i(24, 23)},
	"beach_chair_blue": {"sheet": "props", "box": Rect2i(1150, 130, 386, 260), "size": Vector2i(24, 23)},
	"beach_bench": {"sheet": "props", "box": Rect2i(0, 400, 410, 350), "size": Vector2i(42, 22)},
	"beach_palm": {"sheet": "props", "box": Rect2i(410, 330, 380, 430), "size": Vector2i(44, 62)},
	"beach_sign": {"sheet": "props", "box": Rect2i(790, 380, 360, 320), "size": Vector2i(34, 44)},
	"beach_castle": {"sheet": "props", "box": Rect2i(1150, 390, 386, 370), "size": Vector2i(30, 22)},
	"beach_rocks": {"sheet": "props", "box": Rect2i(0, 750, 410, 274), "size": Vector2i(44, 18)},
	"beach_boards": {"sheet": "props", "box": Rect2i(550, 760, 400, 264), "size": Vector2i(32, 44)},
	"beach_lamp": {"sheet": "props", "box": Rect2i(965, 705, 220, 319), "size": Vector2i(22, 58)},
	"bin": {"sheet": "props", "box": Rect2i(1250, 770, 286, 254), "size": Vector2i(16, 22)}
}

func _initialize() -> void:
	var building_sheet := Image.new()
	var prop_sheet := Image.new()
	if building_sheet.load(BUILDINGS) != OK or prop_sheet.load(PROPS) != OK:
		push_error("Could not load environment concept sheets")
		quit(1)
		return
	for kind: String in ITEMS:
		var spec: Dictionary = ITEMS[kind]
		var source: Image = building_sheet if spec.sheet == "buildings" else prop_sheet
		var bounds: Rect2i = _alpha_bounds(source, spec.box)
		if bounds.size.x <= 0 or bounds.size.y <= 0:
			push_error("Empty source crop for " + kind)
			continue
		var size: Vector2i = spec.size
		var scale_factor: float = minf(float(size.x) / bounds.size.x, float(size.y) / bounds.size.y)
		var output_w: int = maxi(1, floori(bounds.size.x * scale_factor))
		var output_h: int = maxi(1, floori(bounds.size.y * scale_factor))
		var reduced: Image = source.get_region(bounds)
		reduced.resize(output_w, output_h, Image.INTERPOLATE_NEAREST)
		_quantize(reduced)
		var output := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
		output.fill(Color.TRANSPARENT)
		output.blit_rect(reduced, Rect2i(0, 0, output_w, output_h), Vector2i((size.x - output_w) / 2, size.y - output_h))
		var path: String = "res://assets/sprites/retro-%s-32bit.png" % kind.replace("_", "-")
		var error: Error = output.save_png(path)
		if error == OK:
			print("Prepared %s from %s -> %d x %d" % [kind, bounds, size.x, size.y])
		else:
			push_error("Could not save " + path)
	quit()

static func _alpha_bounds(image: Image, partition: Rect2i) -> Rect2i:
	var min_x: int = partition.end.x
	var min_y: int = partition.end.y
	var max_x: int = partition.position.x - 1
	var max_y: int = partition.position.y - 1
	for y: int in range(partition.position.y, mini(partition.end.y, image.get_height())):
		for x: int in range(partition.position.x, mini(partition.end.x, image.get_width())):
			if image.get_pixel(x, y).a >= 0.65:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
	return Rect2i(min_x, min_y, maxi(0, max_x - min_x + 1), maxi(0, max_y - min_y + 1))

static func _quantize(image: Image) -> void:
	for y: int in image.get_height():
		for x: int in image.get_width():
			var source: Color = image.get_pixel(x, y)
			if source.a < 0.65:
				image.set_pixel(x, y, Color.TRANSPARENT)
				continue
			var closest: Color = PALETTE[0]
			var closest_distance: float = INF
			for colour: Color in PALETTE:
				var dr: float = source.r - colour.r
				var dg: float = source.g - colour.g
				var db: float = source.b - colour.b
				var distance: float = dr * dr + dg * dg + db * db
				if distance < closest_distance:
					closest_distance = distance
					closest = colour
			image.set_pixel(x, y, closest)
