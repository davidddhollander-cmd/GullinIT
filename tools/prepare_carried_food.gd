extends SceneTree
## Import preparation only. Crops and nearest-neighbour reduces the untouched
## generated sheet into native-size carried-food pixels; it never paints food art.

const SOURCE := "res://assets/reference/carried-food-v1/carried-food-source.png"
const OUTPUT := "res://assets/sprites/carried-food-v1.png"
const DATA := "res://data/carried_food_art.json"
const CELL := Vector2i(12, 12)

const ITEMS := [
	{"id": "crab", "source": [0, 0, 362, 362], "size": [10, 8], "offset": [2, 0]},
	{"id": "crumbs", "source": [362, 0, 362, 362], "size": [9, 6], "offset": [2, 1]},
	{"id": "single_chip", "source": [724, 0, 362, 362], "size": [10, 4], "offset": [3, 1]},
	{"id": "crisps_box", "source": [1086, 0, 362, 362], "size": [9, 8], "offset": [2, 1]},
	{"id": "ice_cream", "source": [0, 362, 362, 362], "size": [6, 10], "offset": [1, 2]},
	{"id": "crisps_bag", "source": [362, 362, 362, 362], "size": [8, 10], "offset": [2, 2]},
	{"id": "hotdog", "source": [724, 362, 362, 362], "size": [10, 6], "offset": [3, 1]},
	{"id": "fried_fish", "source": [1086, 362, 362, 362], "size": [10, 6], "offset": [3, 1]},
	{"id": "cookie", "source": [0, 724, 362, 362], "size": [8, 8], "offset": [2, 1]},
	{"id": "half_eaten_doughnut", "source": [362, 724, 362, 362], "size": [9, 8], "offset": [2, 1]},
	{"id": "half_eaten_sandwich", "source": [724, 724, 362, 362], "size": [10, 8], "offset": [3, 1]},
	{"id": "half_eaten_pizza", "source": [1086, 724, 362, 362], "size": [8, 10], "offset": [2, 2]}
]

func _initialize() -> void:
	var source := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	assert(source != null and source.get_size() == Vector2i(1448, 1086), "Missing untouched 1448x1086 carried-food source")
	source.convert(Image.FORMAT_RGBA8)
	var sheet := Image.create(CELL.x * 4, CELL.y * 3, false, Image.FORMAT_RGBA8)
	sheet.fill(Color.TRANSPARENT)
	var foods: Dictionary = {}
	for index: int in ITEMS.size():
		var spec: Dictionary = ITEMS[index]
		var source_values: Array = spec.source
		var source_rect := Rect2i(int(source_values[0]), int(source_values[1]), int(source_values[2]), int(source_values[3]))
		var part: Image = source.get_region(source_rect)
		_clean_alpha(part)
		var bounds := part.get_used_rect()
		assert(bounds.has_area(), "Generated source cell is empty: " + str(spec.id))
		part = part.get_region(bounds)
		var target_values: Array = spec.size
		var target := Vector2i(int(target_values[0]), int(target_values[1]))
		part.resize(target.x, target.y, Image.INTERPOLATE_NEAREST)
		_clean_alpha(part)
		assert(part.get_used_rect().has_area(), "Reduced sprite is empty: " + str(spec.id))
		var cell_origin := Vector2i(index % 4, index / 4) * CELL
		var inset := (CELL - target) / 2
		sheet.blit_rect(part, Rect2i(Vector2i.ZERO, target), cell_origin + inset)
		foods[str(spec.id)] = {
			"region": [cell_origin.x + inset.x, cell_origin.y + inset.y, target.x, target.y],
			"offset": spec.offset,
			"source_cell": source_values
		}
	assert(sheet.save_png(OUTPUT) == OK, "Could not save carried-food sheet")
	var metadata := {
		"file": OUTPUT,
		"source": SOURCE,
		"cell_size": [CELL.x, CELL.y],
		"foods": foods
	}
	FileAccess.open(DATA, FileAccess.WRITE).store_string(JSON.stringify(metadata, "  ", false) + "\n")
	print("Prepared %d native carried-food sprites in %s" % [ITEMS.size(), OUTPUT])
	quit()

func _clean_alpha(image: Image) -> void:
	for y: int in image.get_height():
		for x: int in image.get_width():
			var color := image.get_pixel(x, y)
			if color.a >= 0.5:
				color.a = 1.0
			else:
				color = Color.TRANSPARENT
			image.set_pixel(x, y, color)
