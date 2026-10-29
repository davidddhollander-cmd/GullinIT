extends SceneTree

const PALETTE: Array[Color] = [
	Color8(24, 59, 78), Color8(40, 102, 123), Color8(64, 143, 168),
	Color8(75, 136, 183), Color8(97, 119, 130), Color8(142, 155, 158),
	Color8(117, 74, 57), Color8(155, 102, 80), Color8(170, 112, 71),
	Color8(185, 77, 78), Color8(213, 154, 94), Color8(198, 154, 104),
	Color8(238, 183, 127), Color8(232, 197, 142), Color8(239, 114, 92),
	Color8(255, 244, 218),
]
const NAVY := Color8(24, 59, 78)
const TRANSPARENT := Color(0, 0, 0, 0)

func _init() -> void:
	var root := ProjectSettings.globalize_path("res://")
	var ref_dir := root.path_join("assets/reference/pier-restaurant-props-v1")
	var sprite_dir := root.path_join("assets/sprites/pier-restaurant-props-v1")
	var preview_dir := root.path_join("assets/previews")
	DirAccess.make_dir_recursive_absolute(sprite_dir)
	DirAccess.make_dir_recursive_absolute(preview_dir)

	var table := prepare_majority(
		ref_dir.path_join("restaurant-table-chairs-v2-source.png"),
		Vector2i(60, 34), true, false
	)
	table.save_png(sprite_dir.path_join("restaurant-table-chairs-v2.png"))

	var fence := prepare_majority(
		ref_dir.path_join("pier-wire-fence-v2-source.png"),
		Vector2i(72, 24), false, true
	)
	fence.save_png(sprite_dir.path_join("pier-wire-fence-v2.png"))

	var repeat := Image.create(144, 24, false, Image.FORMAT_RGBA8)
	repeat.fill(TRANSPARENT)
	repeat.blit_rect(fence, Rect2i(0, 0, 72, 24), Vector2i.ZERO)
	repeat.blit_rect(fence, Rect2i(0, 0, 72, 24), Vector2i(72, 0))
	repeat.save_png(preview_dir.path_join("pier-wire-fence-v2-repeat-1x.png"))
	var repeat_4x := repeat.duplicate()
	repeat_4x.resize(576, 96, Image.INTERPOLATE_NEAREST)
	repeat_4x.save_png(preview_dir.path_join("pier-wire-fence-v2-repeat-4x.png"))

	var table_4x := table.duplicate()
	table_4x.resize(240, 136, Image.INTERPOLATE_NEAREST)
	table_4x.save_png(preview_dir.path_join("restaurant-table-chairs-v2-4x.png"))

	var measurement_paths := {
		"table_v2": sprite_dir.path_join("restaurant-table-chairs-v2.png"),
		"fence_v2": sprite_dir.path_join("pier-wire-fence-v2.png"),
		"table_v1": sprite_dir.path_join("restaurant-table-chairs-v1.png"),
		"fence_v1": sprite_dir.path_join("pier-wire-fence-v1.png"),
		"fish_chips_stand": root.path_join("assets/sprites/retro-fish-chips-stand-32bit.png"),
		"beach_chair": root.path_join("assets/sprites/retro-beach-chair-32bit.png"),
	}
	var report := {}
	for label in measurement_paths:
		var path: String = measurement_paths[label]
		if FileAccess.file_exists(path):
			report[label] = measure(Image.load_from_file(path))
	var json := JSON.stringify(report, "  ")
	var report_file := FileAccess.open(ref_dir.path_join("v2-measurements.json"), FileAccess.WRITE)
	report_file.store_string(json + "\n")
	print(json)
	quit()

func prepare_majority(path: String, target: Vector2i, preserve_aspect: bool, seam_edges: bool) -> Image:
	var source := Image.load_from_file(path)
	if source == null or source.is_empty():
		push_error("Cannot load source: " + path)
		return Image.create(target.x, target.y, false, Image.FORMAT_RGBA8)
	source.convert(Image.FORMAT_RGBA8)
	var bbox := alpha_bbox(source, 0.5)
	if bbox.size.x <= 0 or bbox.size.y <= 0:
		push_error("Source has no opaque pixels: " + path)
		return Image.create(target.x, target.y, false, Image.FORMAT_RGBA8)

	var dest_size := target - Vector2i(2, 2)
	var offset := Vector2i(1, 1)
	if preserve_aspect:
		var scale: float = min(float(dest_size.x) / bbox.size.x, float(dest_size.y) / bbox.size.y)
		dest_size = Vector2i(maxi(1, roundi(bbox.size.x * scale)), maxi(1, roundi(bbox.size.y * scale)))
		offset.x = (target.x - dest_size.x) / 2
		offset.y = target.y - dest_size.y - 1
	else:
		dest_size = Vector2i(target.x, target.y - 2)
		offset = Vector2i(0, 1)

	var output := Image.create(target.x, target.y, false, Image.FORMAT_RGBA8)
	output.fill(TRANSPARENT)
	for dy in range(dest_size.y):
		var sy0 := bbox.position.y + floori(float(dy) * bbox.size.y / dest_size.y)
		var sy1 := bbox.position.y + ceili(float(dy + 1) * bbox.size.y / dest_size.y)
		for dx in range(dest_size.x):
			var sx0 := bbox.position.x + floori(float(dx) * bbox.size.x / dest_size.x)
			var sx1 := bbox.position.x + ceili(float(dx + 1) * bbox.size.x / dest_size.x)
			var counts := PackedInt32Array()
			counts.resize(PALETTE.size())
			var samples := 0
			var opaque := 0
			for sy in range(sy0, mini(sy1, source.get_height())):
				for sx in range(sx0, mini(sx1, source.get_width())):
					samples += 1
					var color := source.get_pixel(sx, sy)
					if color.a < 0.5:
						continue
					opaque += 1
					counts[nearest_palette_index(color)] += 1
			if samples == 0 or float(opaque) / samples < 0.28:
				continue
			var best_index := 0
			for i in range(1, counts.size()):
				if counts[i] > counts[best_index]:
					best_index = i
			output.set_pixel(offset.x + dx, offset.y + dy, PALETTE[best_index])

	cleanup_lone_pixels(output)
	if seam_edges:
		make_horizontal_seam(output)
	return output

func alpha_bbox(image: Image, threshold: float) -> Rect2i:
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a >= threshold:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
	if max_x < min_x:
		return Rect2i()
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)

func nearest_palette_index(color: Color) -> int:
	var best := 0
	var best_distance := INF
	for i in range(PALETTE.size()):
		var p := PALETTE[i]
		var dr := color.r - p.r
		var dg := color.g - p.g
		var db := color.b - p.b
		var distance := 2.0 * dr * dr + 4.0 * dg * dg + 3.0 * db * db
		if distance < best_distance:
			best_distance = distance
			best = i
	return best

func cleanup_lone_pixels(image: Image) -> void:
	var original: Image = image.duplicate()
	var directions: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	for y in range(1, image.get_height() - 1):
		for x in range(1, image.get_width() - 1):
			var color: Color = original.get_pixel(x, y)
			if color.a < 0.5 or color.to_rgba32() == NAVY.to_rgba32():
				continue
			var same_neighbor := false
			var neighbor_counts := {}
			for direction in directions:
				var neighbor: Color = original.get_pixelv(Vector2i(x, y) + direction)
				if neighbor.a < 0.5:
					continue
				if neighbor.to_rgba32() == color.to_rgba32():
					same_neighbor = true
				var key: int = neighbor.to_rgba32()
				neighbor_counts[key] = int(neighbor_counts.get(key, 0)) + 1
			if same_neighbor:
				continue
			var replacement_key := -1
			var replacement_count := 0
			for key in neighbor_counts:
				if neighbor_counts[key] > replacement_count:
					replacement_key = key
					replacement_count = neighbor_counts[key]
			if replacement_count >= 2:
				image.set_pixel(x, y, Color.hex(replacement_key))

func make_horizontal_seam(image: Image) -> void:
	var last_x := image.get_width() - 1
	for y in range(image.get_height()):
		var left := image.get_pixel(0, y)
		var right := image.get_pixel(last_x, y)
		var chosen := left if left.a >= 0.5 else right
		if left.a >= 0.5 or right.a >= 0.5:
			image.set_pixel(0, y, chosen)
			image.set_pixel(last_x, y, chosen)

func measure(image: Image) -> Dictionary:
	image.convert(Image.FORMAT_RGBA8)
	var opaque := 0
	var isolated := 0
	var colors := {}
	var bbox := alpha_bbox(image, 0.5)
	var directions: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color: Color = image.get_pixel(x, y)
			if color.a < 0.5:
				continue
			opaque += 1
			var key: int = color.to_rgba32()
			colors[key] = true
			if key == NAVY.to_rgba32():
				continue
			var has_same := false
			for direction in directions:
				var point: Vector2i = Vector2i(x, y) + direction
				if point.x < 0 or point.y < 0 or point.x >= image.get_width() or point.y >= image.get_height():
					continue
				if image.get_pixelv(point).to_rgba32() == key:
					has_same = true
					break
			if not has_same:
				isolated += 1
	var largest_area := largest_flat_area(image)
	return {
		"canvas": [image.get_width(), image.get_height()],
		"extent": [bbox.size.x, bbox.size.y],
		"opaque_pixels": opaque,
		"isolated_non_outline_pixels": isolated,
		"isolated_share_percent": snappedf(100.0 * isolated / maxf(1.0, opaque), 0.1),
		"color_count": colors.size(),
		"largest_flat_color_area": largest_area,
	}

func largest_flat_area(image: Image) -> int:
	var visited := {}
	var largest := 0
	var width := image.get_width()
	var height := image.get_height()
	var directions: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	for y in range(height):
		for x in range(width):
			var start := Vector2i(x, y)
			var start_key := y * width + x
			if visited.has(start_key):
				continue
			var color: Color = image.get_pixelv(start)
			if color.a < 0.5:
				visited[start_key] = true
				continue
			var rgba: int = color.to_rgba32()
			var queue: Array[Vector2i] = [start]
			visited[start_key] = true
			var cursor := 0
			while cursor < queue.size():
				var point: Vector2i = queue[cursor]
				cursor += 1
				for direction in directions:
					var next: Vector2i = point + direction
					if next.x < 0 or next.y < 0 or next.x >= width or next.y >= height:
						continue
					var key: int = next.y * width + next.x
					if visited.has(key):
						continue
					if image.get_pixelv(next).to_rgba32() == rgba:
						visited[key] = true
						queue.append(next)
			largest = maxi(largest, queue.size())
	return largest