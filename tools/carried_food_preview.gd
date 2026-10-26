extends SceneTree
## Composes the real herring-gull carry body, native carried-food region and
## generated upper-beak overlay. Every card shows the same pose at 1x and 4x.

const OUT := "res://assets/previews/carried-food-v1-comparison.png"
const ORDER := [
	"crab", "crumbs", "single_chip", "crisps_box",
	"ice_cream", "crisps_bag", "hotdog", "fried_fish",
	"cookie", "half_eaten_doughnut", "half_eaten_sandwich", "half_eaten_pizza"
]

func _initialize() -> void:
	var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/carried_food_art.json"))
	var carries: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/gull_carry_art.json"))
	var carry: Dictionary = carries.gull_herring
	var canvas := Image.create(640, 300, false, Image.FORMAT_RGBA8)
	canvas.fill(Color("9dcfd0"))
	for index: int in ORDER.size():
		var card := Vector2i(index % 4 * 160, index / 4 * 100)
		canvas.fill_rect(Rect2i(card, Vector2i(160, 100)), Color("c7e5d0") if (index + index / 4) % 2 == 0 else Color("a9d7d2"))
		canvas.fill_rect(Rect2i(card + Vector2i(49, 10), Vector2i(1, 80)), Color("6f9ea2"))
		var composed := _compose(carry, metadata, ORDER[index])
		var bounds := composed.get_used_rect()
		bounds = Rect2i(
			Vector2i(maxi(0, bounds.position.x - 2), maxi(0, bounds.position.y - 2)),
			Vector2i(mini(composed.get_width(), bounds.end.x + 2), mini(composed.get_height(), bounds.end.y + 2)) - Vector2i(maxi(0, bounds.position.x - 2), maxi(0, bounds.position.y - 2))
		)
		var one_x := composed.get_region(bounds)
		canvas.blend_rect(one_x, Rect2i(Vector2i.ZERO, one_x.get_size()), card + Vector2i(24, 50) - one_x.get_size() / 2)
		var four_x := one_x.duplicate()
		four_x.resize(one_x.get_width() * 4, one_x.get_height() * 4, Image.INTERPOLATE_NEAREST)
		canvas.blend_rect(four_x, Rect2i(Vector2i.ZERO, four_x.get_size()), card + Vector2i(104, 50) - four_x.get_size() / 2)
	assert(canvas.save_png(OUT) == OK, "Could not save carried-food review preview")
	print("Saved carried-food 1x/4x comparison to ", OUT)
	quit()

func _compose(carry: Dictionary, metadata: Dictionary, food_id: String) -> Image:
	var result := Image.create(96, 96, false, Image.FORMAT_RGBA8)
	result.fill(Color.TRANSPARENT)
	var body_sheet := Image.load_from_file(ProjectSettings.globalize_path(str(carry.file)))
	var upper_sheet := Image.load_from_file(ProjectSettings.globalize_path(str(carry.overlay_file)))
	var frame := 7
	var body := body_sheet.get_region(Rect2i(frame * 256, 0, 256, 256))
	var upper := upper_sheet.get_region(Rect2i(frame * 256, 0, 256, 256))
	body.resize(96, 96, Image.INTERPOLATE_NEAREST)
	upper.resize(96, 96, Image.INTERPOLATE_NEAREST)
	result.blend_rect(body, Rect2i(Vector2i.ZERO, body.get_size()), Vector2i.ZERO)
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(str(metadata.file)))
	var entry: Dictionary = metadata.foods[food_id]
	var values: Array = entry.region
	var region := Rect2i(int(values[0]), int(values[1]), int(values[2]), int(values[3]))
	var food := sheet.get_region(region)
	var anchor_values: Array = carry.beak_anchors.walk[frame]
	var anchor := Vector2i(roundi(float(anchor_values[0])), roundi(float(anchor_values[1])))
	var offset_values: Array = entry.offset
	var offset := Vector2i(int(offset_values[0]), int(offset_values[1]))
	var food_at := Vector2i(48, 48) + anchor + offset - food.get_size() / 2
	result.blend_rect(food, Rect2i(Vector2i.ZERO, food.get_size()), food_at)
	result.blend_rect(upper, Rect2i(Vector2i.ZERO, upper.get_size()), Vector2i.ZERO)
	return result
