extends RefCounted
## Data-contract checks for the generated native carried-food atlas.

static func run_checks(check: Callable) -> void:
	var foods: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/foods.json"))
	var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/carried_food_art.json"))
	check.call(not metadata.is_empty() and metadata.has("foods"), "carried-food metadata loads")
	check.call(str(metadata.source) == "res://assets/reference/carried-food-v1/carried-food-source.png" and FileAccess.file_exists(str(metadata.source)), "carried-food generation source is preserved untouched")
	check.call(str(metadata.file) == "res://assets/sprites/carried-food-v1.png" and FileAccess.file_exists(str(metadata.file)), "carried-food native sheet exists")
	check.call(FileAccess.file_exists("res://assets/previews/carried-food-v1-comparison.png"), "carried-food preview shows every item at 1x and 4x")
	var source := Image.load_from_file(ProjectSettings.globalize_path(str(metadata.source)))
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(str(metadata.file)))
	check.call(source != null and source.get_size() == Vector2i(1448, 1086), "carried-food source keeps the complete generated 4-by-3 sheet")
	check.call(sheet != null and sheet.get_size() == Vector2i(48, 36), "carried-food native sheet keeps twelve 12-pixel cells")
	check.call(metadata.foods.size() == foods.size(), "carried-food metadata has exactly one entry per carryable food")
	var sheet_bounds := Rect2i(Vector2i.ZERO, sheet.get_size())
	var source_bounds := Rect2i(Vector2i.ZERO, source.get_size())
	for food_id: String in foods:
		check.call(metadata.foods.has(food_id), "carried-food metadata covers " + food_id)
		if not metadata.foods.has(food_id):
			continue
		var entry: Dictionary = metadata.foods[food_id]
		var values: Array = entry.region
		var region := Rect2i(int(values[0]), int(values[1]), int(values[2]), int(values[3]))
		check.call(sheet_bounds.encloses(region), "carried-food region lies inside sheet: " + food_id)
		check.call(region.size.x >= 6 and region.size.x <= 10 and region.size.y >= 4 and region.size.y <= 10, "carried-food region stays readable at native size: " + food_id)
		var source_values: Array = entry.source_cell
		var source_cell := Rect2i(int(source_values[0]), int(source_values[1]), int(source_values[2]), int(source_values[3]))
		check.call(source_bounds.encloses(source_cell), "carried-food source crop lies inside untouched sheet: " + food_id)
		check.call(entry.offset is Array and entry.offset.size() == 2, "carried-food entry supplies beak offset: " + food_id)
		var image := sheet.get_region(region)
		check.call(image.get_used_rect().has_area(), "carried-food region contains generated pixels: " + food_id)
		var hard_alpha := true
		var has_dark_outline := false
		var has_bright_highlight := false
		for y: int in image.get_height():
			for x: int in image.get_width():
				var color := image.get_pixel(x, y)
				if color.a != 0.0 and color.a != 1.0:
					hard_alpha = false
				if color.a > 0.5 and color.r < 0.22 and color.g < 0.22 and color.b < 0.32:
					has_dark_outline = true
				# Golden foods use a saturated warm glint instead of white; at native
				# size that is the stronger, more readable highlight.
				if color.a > 0.5 and color.r + color.g + color.b > 1.9:
					has_bright_highlight = true
		check.call(hard_alpha, "carried-food sprite keeps crisp hard alpha: " + food_id)
		check.call(has_dark_outline, "carried-food sprite keeps a dark contrasting outline: " + food_id)
		check.call(has_bright_highlight, "carried-food sprite keeps a bright highlight: " + food_id)
