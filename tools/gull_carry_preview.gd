extends SceneTree
## Uses generated carry frames, measured anchors, separate food art and the
## generated upper-beak overlays at the game's native 0.375 visual scale.
const OUT := "res://assets/previews/gull-carry-v1-comparison.png"
const ROWS := ["gull_herring", "gull_kittiwake", "gull_great_black_backed", "rival_gull"]
const FOODS := ["single_chip", "ice_cream", "hotdog"]
const FRAMES := [0, 8, 12]
const CLIPS := ["walk", "fly", "glide"]

func _initialize() -> void:
	var gulls: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/gull_art.json"))
	var foods: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/foods.json"))
	var sprites: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/sprites.json"))
	var canvas := Image.create(320, 180, false, Image.FORMAT_RGBA8)
	canvas.fill(Color("a9d7d2"))
	for row: int in ROWS.size():
		canvas.fill_rect(Rect2i(0, row * 45, 320, 45), Color("c8e4ce") if row % 2 == 0 else Color("a9d7d2"))
		for column: int in FOODS.size():
			_compose(canvas, gulls[ROWS[row]].carry, foods, sprites, FOODS[column], FRAMES[column], CLIPS[column], Vector2i(54 + column * 106, 22 + row * 45))
	canvas.resize(960, 540, Image.INTERPOLATE_NEAREST)
	assert(canvas.save_png(OUT) == OK)
	print("Saved gull carry comparison to ", OUT)
	quit()

func _compose(canvas: Image, carry: Dictionary, foods: Dictionary, sprites: Dictionary, food_id: String, frame: int, clip: String, centre: Vector2i) -> void:
	var atlas := Image.load_from_file(ProjectSettings.globalize_path(str(carry.file)))
	var overlay_atlas := Image.load_from_file(ProjectSettings.globalize_path(str(carry.overlay_file)))
	var bird: Image = atlas.get_region(Rect2i(frame * 256, 0, 256, 256))
	var upper: Image = overlay_atlas.get_region(Rect2i(frame * 256, 0, 256, 256))
	bird.resize(96, 96, Image.INTERPOLATE_NEAREST)
	upper.resize(96, 96, Image.INTERPOLATE_NEAREST)
	var top_left := centre - Vector2i(48, 48)
	canvas.blend_rect(bird, Rect2i(0, 0, 96, 96), top_left)
	var definition: Dictionary = foods[food_id]
	var sprite: Dictionary = sprites[str(definition.sprite)]
	var source := Image.load_from_file(ProjectSettings.globalize_path(str(sprite.file)))
	var region: Array = sprite.regions[0].region
	var food: Image = source.get_region(Rect2i(int(region[0]), int(region[1]), int(region[2]), int(region[3])))
	var food_size := Vector2i(int(definition.size[0]), int(definition.size[1]))
	food.resize(food_size.x, food_size.y, Image.INTERPOLATE_NEAREST)
	var sequence: Array = carry.beak_anchors[clip]
	var local_frame: int = frame if clip == "walk" else (frame - 8 if clip == "fly" else 0)
	var anchor: Array = sequence[local_frame]
	var food_at := centre + Vector2i(roundi(float(anchor[0])), roundi(float(anchor[1]))) - food_size / 2
	canvas.blend_rect(food, Rect2i(Vector2i.ZERO, food_size), food_at)
	canvas.blend_rect(upper, Rect2i(0, 0, 96, 96), top_left)
