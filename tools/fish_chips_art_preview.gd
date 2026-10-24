extends SceneTree
## Composes generated sprites at their actual in-game dimensions, then enlarges
## the complete 320x180 frame with nearest-neighbour sampling for review.
const OUT := "res://assets/previews/fish-chips-stand-v1-comparison.png"
const STALLS := [
	{"x": 54, "stall": "res://assets/sprites/retro-kiosk-32bit.png", "vendor": "res://assets/sprites/vendor-ice-cream-full-body-v3.png", "sign": "res://assets/sprites/stand-sign-ice-cream-runtime-v2.png"},
	{"x": 160, "stall": "res://assets/sprites/retro-hotdog-stand-32bit.png", "vendor": "res://assets/sprites/vendor-hotdog-full-body-v3.png", "sign": "res://assets/sprites/stand-sign-hot-dogs-runtime-v2.png"},
	{"x": 266, "stall": "res://assets/sprites/retro-fish-chips-stand-32bit.png", "vendor": "res://assets/sprites/vendor-fish-chips-full-body-v1.png", "sign": "res://assets/sprites/stand-sign-fish-chips-runtime-v1.png"}
]

func _initialize() -> void:
	var canvas := Image.create(320, 180, false, Image.FORMAT_RGBA8)
	canvas.fill(Color("a9d7d2"))
	canvas.fill_rect(Rect2i(0, 94, 320, 36), Color("408fa8"))
	canvas.fill_rect(Rect2i(0, 103, 320, 27), Color("56b7ae"))
	canvas.fill_rect(Rect2i(0, 130, 320, 50), Color("e8c58e"))
	canvas.fill_rect(Rect2i(0, 130, 320, 3), Color("fff1cc"))
	for spec: Dictionary in STALLS:
		_compose_stall(canvas, spec)
	canvas.resize(960, 540, Image.INTERPOLATE_NEAREST)
	assert(canvas.save_png(OUT) == OK)
	print("Saved fish-and-chips in-game-scale comparison to ", OUT)
	quit()

func _compose_stall(canvas: Image, spec: Dictionary) -> void:
	var x: int = int(spec.x)
	var stall := Image.load_from_file(ProjectSettings.globalize_path(str(spec.stall)))
	canvas.blit_rect(stall, Rect2i(0, 0, 52, 56), Vector2i(x - 26, 104))
	var atlas := Image.load_from_file(ProjectSettings.globalize_path(str(spec.vendor)))
	var vendor: Image = atlas.get_region(Rect2i(0, 0, 128, 128))
	vendor.resize(64, 64, Image.INTERPOLATE_NEAREST)
	# Runtime clips the complete full-body frame to this 38x23 serving window.
	canvas.blit_rect(vendor, Rect2i(13, 18, 38, 23), Vector2i(x - 19, 120))
	var sign := Image.load_from_file(ProjectSettings.globalize_path(str(spec.sign)))
	var sign_height: int = roundi(float(sign.get_height()) * 64.0 / sign.get_width())
	sign.resize(64, sign_height, Image.INTERPOLATE_NEAREST)
	canvas.blit_rect(sign, Rect2i(0, 0, 64, sign_height), Vector2i(x - 32, 113 - sign_height))
