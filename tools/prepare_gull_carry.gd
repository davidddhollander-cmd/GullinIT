extends SceneTree
## Import preparation only: packs generated carry poses, measures their generated
## bill pixels and crops those same pixels into an upper-mandible overlay.
const SOURCE := "res://assets/reference/gull-carry-v1/"
const CELL := 256
const DISPLAY_SCALE := 0.375
const SOURCE_FRAMES := [1, 2, 3, 4, 5, 6, 7, 0, 8, 9, 10, 11, 12]
const SPECS := {
	"herring": {
		"source": "herring-carry-source.png",
		"base": "gull_herring",
		"targets": ["gull_herring", "player_gull"],
		"file": "gull-herring-carry-v1.png"
	},
	"kittiwake": {
		"source": "kittiwake-carry-source.png",
		"base": "gull_kittiwake",
		"targets": ["gull_kittiwake"],
		"file": "gull-kittiwake-carry-v1.png"
	},
	"great-black-backed": {
		"source": "great-black-backed-carry-source.png",
		"base": "gull_great_black_backed",
		"targets": ["gull_great_black_backed"],
		"file": "gull-great-black-backed-carry-v1.png"
	},
	"rival-tint-base": {
		"source": "rival-tint-base-carry-source.png",
		"base": "gull_great_black_backed",
		"targets": ["rival_gull"],
		"file": "gull-rival-tint-base-carry-v1.png"
	}
}

func _initialize() -> void:
	var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/gull_art.json"))
	assert(not metadata.is_empty(), "Missing gull art metadata")
	var carry_entries: Dictionary = {}
	for species: String in SPECS:
		var spec: Dictionary = SPECS[species]
		var carry: Dictionary = _prepare_species(species, spec, metadata[str(spec.base)])
		for target: String in spec.targets:
			carry_entries[target] = carry.duplicate(true)
	FileAccess.open("res://data/gull_carry_art.json", FileAccess.WRITE).store_string(JSON.stringify(carry_entries, "  ", false) + "\n")
	print("Prepared four generated gull carry atlases with measured anchors and overlays")
	quit()

func _prepare_species(species: String, spec: Dictionary, base: Dictionary) -> Dictionary:
	var source_path: String = SOURCE + str(spec.source)
	var source := Image.load_from_file(ProjectSettings.globalize_path(source_path))
	assert(source != null, "Missing generated gull carry source: " + source_path)
	source.convert(Image.FORMAT_RGBA8)
	var source_cell := Vector2i(source.get_width() / 4, source.get_height() / 4)
	var atlas := Image.create(SOURCE_FRAMES.size() * CELL, CELL, false, Image.FORMAT_RGBA8)
	var overlay := Image.create(SOURCE_FRAMES.size() * CELL, CELL, false, Image.FORMAT_RGBA8)
	atlas.fill(Color.TRANSPARENT)
	overlay.fill(Color.TRANSPARENT)
	var anchors: Array = []
	for index: int in SOURCE_FRAMES.size():
		var part: Image = source.get_region(Rect2i(Vector2i(index % 4, index / 4) * source_cell, source_cell))
		_clean_alpha(part)
		_keep_largest_component(part)
		var bounds: Rect2i = part.get_used_rect()
		assert(bounds.has_area(), "%s carry source cell %d is empty" % [species, index])
		var cropped: Image = part.get_region(bounds)
		var original: Array = base.frame_bounds[SOURCE_FRAMES[index]]
		var scale_factor: float = float(original[3]) / cropped.get_height()
		var size := Vector2i(maxi(1, roundi(cropped.get_width() * scale_factor)), int(original[3]))
		cropped.resize(size.x, size.y, Image.INTERPOLATE_NEAREST)
		_clean_alpha(cropped)
		var right: int = int(original[0]) + int(original[2])
		var x: int = right - size.x
		var y: int
		if index < 8:
			y = int(original[1]) + int(original[3]) - size.y
		else:
			y = roundi(float(original[1]) + float(original[3]) * 0.5 - size.y * 0.5)
		x = clampi(x, 2, CELL - size.x - 2)
		y = clampi(y, 2, CELL - size.y - 2)
		atlas.blit_rect(cropped, Rect2i(Vector2i.ZERO, size), Vector2i(index * CELL + x, y))
		var bill: Rect2i = _bill_bounds(cropped)
		assert(bill.has_area(), "%s carry pose %d has no generated yellow bill pixels" % [species, index])
		var anchor_px := Vector2i(
			x + bill.position.x + roundi(bill.size.x * 0.58),
			y + bill.position.y + roundi(bill.size.y * 0.52)
		)
		anchors.append([
			snappedf((anchor_px.x - CELL * 0.5) * DISPLAY_SCALE, 0.1875),
			snappedf((anchor_px.y - CELL * 0.5) * DISPLAY_SCALE, 0.1875)
		])
		# Preserve generated head/upper-mandible pixels above the snack. Runtime
		# draws this frame after the separate food sprite, creating the grip.
		var upper := Rect2i(
			maxi(0, bill.position.x - 3),
			maxi(0, bill.position.y - 3),
			mini(cropped.get_width(), bill.end.x + 3) - maxi(0, bill.position.x - 3),
			mini(cropped.get_height(), bill.position.y + roundi(bill.size.y * 0.55) + 2) - maxi(0, bill.position.y - 3)
		)
		overlay.blit_rect(cropped, upper, Vector2i(index * CELL + x, y) + upper.position)
	var output_path: String = "res://assets/sprites/" + str(spec.file)
	var overlay_path: String = output_path.trim_suffix(".png") + "-upper-beak.png"
	assert(atlas.save_png(output_path) == OK)
	assert(overlay.save_png(overlay_path) == OK)
	return {
		"file": output_path,
		"overlay_file": overlay_path,
		"source": source_path,
		"frame_w": CELL,
		"frame_h": CELL,
		"visual_scale": DISPLAY_SCALE,
		"frame_sources": SOURCE_FRAMES,
		"animations": {
			"walk": {"frames": range(0, 8), "fps": 8, "loop": true},
			"fly": {"frames": range(8, 12), "fps": 10, "loop": true},
			"glide": {"frames": [12], "fps": 1, "loop": true}
		},
		"beak_anchors": {
			"walk": anchors.slice(0, 8),
			"fly": anchors.slice(8, 12),
			"glide": anchors.slice(12, 13)
		},
		"overlay_frames": {
			"walk": range(0, 8),
			"fly": range(8, 12),
			"glide": [12]
		}
	}

func _clean_alpha(image: Image) -> void:
	for y: int in image.get_height():
		for x: int in image.get_width():
			var color: Color = image.get_pixel(x, y)
			if color.a >= 0.75:
				color.a = 1.0
			else:
				color = Color.TRANSPARENT
			image.set_pixel(x, y, color)

func _bill_bounds(image: Image) -> Rect2i:
	var min_x: int = image.get_width()
	var min_y: int = image.get_height()
	var max_x: int = -1
	var max_y: int = -1
	for y: int in image.get_height():
		for x: int in range(image.get_width() / 2, image.get_width()):
			var color: Color = image.get_pixel(x, y)
			var yellow_or_orange: bool = color.a > 0.5 and color.r > 0.55 and color.g > 0.25 and color.b < color.g * 0.72 and color.r > color.g * 1.05
			if yellow_or_orange:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
	return Rect2i(min_x, min_y, maxi(0, max_x - min_x + 1), maxi(0, max_y - min_y + 1))

func _keep_largest_component(image: Image) -> void:
	var width: int = image.get_width()
	var height: int = image.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)
	var largest := PackedInt32Array()
	for y: int in height:
		for x: int in width:
			var start: int = y * width + x
			if visited[start] != 0 or image.get_pixel(x, y).a <= 0.5:
				continue
			var queue := PackedInt32Array([start])
			var points := PackedInt32Array()
			visited[start] = 1
			var cursor: int = 0
			while cursor < queue.size():
				var point: int = queue[cursor]
				cursor += 1
				points.append(point)
				var px: int = point % width
				var py: int = floori(float(point) / width)
				for neighbour: Vector2i in [Vector2i(px - 1, py), Vector2i(px + 1, py), Vector2i(px, py - 1), Vector2i(px, py + 1)]:
					if neighbour.x < 0 or neighbour.x >= width or neighbour.y < 0 or neighbour.y >= height:
						continue
					var next: int = neighbour.y * width + neighbour.x
					if visited[next] == 0 and image.get_pixel(neighbour.x, neighbour.y).a > 0.5:
						visited[next] = 1
						queue.append(next)
			if points.size() > largest.size():
				largest = points
	var keep := PackedByteArray()
	keep.resize(width * height)
	for point: int in largest:
		keep[point] = 1
	for y: int in height:
		for x: int in width:
			if image.get_pixel(x, y).a > 0.0 and keep[y * width + x] == 0:
				image.set_pixel(x, y, Color.TRANSPARENT)
