extends SceneTree
## Builds a compact review board from the runtime atlas only.

const OldMan = preload("res://scripts/old_man_art.gd")
const OUT := "res://assets/archive/previews/old-man-stick-v1-comparison.png"
const SAMPLES := [
	["idle", 0], ["walk", 1], ["walk_left", 4], ["chase", 2],
	["alert", 1], ["block", 1], ["pickup", 2], ["carry", 3],
	["swat", 3], ["kick", 3], ["stick_hit", 1], ["stick_hit", 4],
	["stick_hit_left", 1], ["stick_hit_left", 3], ["rise", 2], ["handover", 2]
]

func _initialize() -> void:
	var frames := OldMan.frames()
	var canvas := Image.create(8 * OldMan.CELL, 2 * OldMan.CELL, false, Image.FORMAT_RGBA8)
	canvas.fill(Color("d8cfb4"))
	canvas.fill_rect(Rect2i(0, OldMan.CELL, canvas.get_width(), OldMan.CELL), Color("b9d9d0"))
	for index: int in SAMPLES.size():
		var sample: Array = SAMPLES[index]
		var texture: AtlasTexture = frames.get_frame_texture(StringName(sample[0]), int(sample[1])) as AtlasTexture
		var cell: Image = texture.atlas.get_image().get_region(Rect2i(texture.region))
		canvas.blend_rect(cell, Rect2i(Vector2i.ZERO, cell.get_size()), Vector2i(index % 8 * OldMan.CELL, index / 8 * OldMan.CELL))
	canvas.resize(canvas.get_width() * 2, canvas.get_height() * 2, Image.INTERPOLATE_NEAREST)
	assert(canvas.save_png(OUT) == OK)
	print("Saved old-man comparison to ", OUT)
	quit()
