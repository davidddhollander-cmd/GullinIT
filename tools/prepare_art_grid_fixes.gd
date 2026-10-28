extends SceneTree
## Task 049 import-only preparation.
## Character handling is limited to cropping/resizing/alignment of supplied artwork.

const SOURCE := "res://assets/reference/art-grid-fixes-v1/"
const SPRITES := "res://assets/sprites/"
const CELL := 128
const SOLE := 116
const OLD_MAN_HEIGHT := 74 # 37 px on screen at 0.5

const BIN_PALETTE: Array[Color] = [
	Color("061019"), Color("0d2630"), Color("183b4e"), Color("244b4c"),
	Color("315f58"), Color("47766a"), Color("659080"), Color("86aa93"),
	Color("abc2a5"), Color("d3d1ad"), Color("6d5140"), Color("b28b63"),
]

func _read(name: String) -> Image:
	var image := Image.load_from_file(ProjectSettings.globalize_path(SOURCE + name))
	assert(image != null, "Missing untouched source: " + name)
	image.convert(Image.FORMAT_RGBA8)
	return image

func _save(image: Image, name: String) -> void:
	assert(image.save_png(SPRITES + name) == OK, "Could not save " + name)

func _hard_alpha(image: Image, threshold: float = 0.75) -> void:
	for y: int in image.get_height():
		for x: int in image.get_width():
			var color := image.get_pixel(x, y)
			if color.a < threshold:
				image.set_pixel(x, y, Color.TRANSPARENT)
			else:
				color.a = 1.0
				image.set_pixel(x, y, color)

func _nearest(source: Image, width: int, height: int, hard_alpha: bool = true) -> Image:
	var result := source.duplicate()
	result.resize(width, height, Image.INTERPOLATE_NEAREST)
	if hard_alpha:
		_hard_alpha(result)
	return result

func _old_man() -> void:
	var source := _read("retro-old-man-stick-32bit.png")
	var atlas := Image.create(source.get_width(), source.get_height(), false, Image.FORMAT_RGBA8)
	atlas.fill(Color.TRANSPARENT)
	var columns := source.get_width() / CELL
	var rows := source.get_height() / CELL
	for frame: int in columns * rows:
		var cell := source.get_region(Rect2i(frame % columns * CELL, frame / columns * CELL, CELL, CELL))
		_hard_alpha(cell)
		var bounds := cell.get_used_rect()
		if not bounds.has_area():
			continue
		var pose := cell.get_region(bounds)
		var height := OLD_MAN_HEIGHT
		var width := roundi(float(pose.get_width()) * height / pose.get_height())
		if width > 116:
			height = roundi(float(height) * 116.0 / width)
			width = 116
		pose.resize(width, height, Image.INTERPOLATE_NEAREST)
		atlas.blit_rect(pose, Rect2i(0, 0, width, height), Vector2i(frame % columns * CELL + (CELL - width) / 2, frame / columns * CELL + SOLE - height))
	_save(atlas, "old-man-cast-grid-candidate-v1.png")

func _crabs() -> void:
	var red := _read("crab-red-v2.png")
	var blue := _read("crab-blue-v2.png")
	var current := Image.create(288, 80, false, Image.FORMAT_RGBA8)
	current.fill(Color.TRANSPARENT)
	current.blit_rect(red, Rect2i(0, 0, 288, 40), Vector2i.ZERO)
	current.blit_rect(blue, Rect2i(0, 0, 288, 40), Vector2i(0, 40))
	_save(current, "crabs-pair-current-v1.png")
	var candidate := Image.create(144, 40, false, Image.FORMAT_RGBA8)
	candidate.fill(Color.TRANSPARENT)
	for frame: int in 6:
		for species: int in 2:
			var sheet := red if species == 0 else blue
			var pose := sheet.get_region(Rect2i(frame * 48, 0, 48, 40))
			pose = _nearest(pose, 24, 20)
			candidate.blit_rect(pose, Rect2i(0, 0, 24, 20), Vector2i(frame * 24, species * 20))
	_save(candidate, "crabs-pair-candidate-v1.png")

func _stand_signs() -> void:
	var names: Array[String] = ["stand-sign-hot-dogs-runtime-v2.png", "stand-sign-ice-cream-runtime-v2.png", "stand-sign-fish-chips-runtime-v1.png"]
	var current := Image.create(256, 200, false, Image.FORMAT_RGBA8)
	current.fill(Color.TRANSPARENT)
	var candidate := Image.create(128, 100, false, Image.FORMAT_RGBA8)
	candidate.fill(Color.TRANSPARENT)
	var current_y := 0
	var candidate_y := 0
	for name: String in names:
		var sign := _read(name)
		current.blit_rect(sign, Rect2i(Vector2i.ZERO, sign.get_size()), Vector2i(0, current_y))
		var crisp := _nearest(sign, 128, roundi(sign.get_height() * 0.5))
		candidate.blit_rect(crisp, Rect2i(Vector2i.ZERO, crisp.get_size()), Vector2i(0, candidate_y))
		current_y += sign.get_height()
		candidate_y += crisp.get_height()
	_save(current, "stand-signs-current-v1.png")
	_save(candidate, "stand-signs-candidate-v1.png")

func _wheelie_bin() -> void:
	var candidate := _nearest(_read("retro-wheelie-bin-green-32bit.png"), 22, 30)
	for y: int in candidate.get_height():
		for x: int in candidate.get_width():
			var color := candidate.get_pixel(x, y)
			if is_zero_approx(color.a):
				continue
			var best := BIN_PALETTE[0]
			var distance := INF
			for sample: Color in BIN_PALETTE:
				var delta := Vector3(color.r - sample.r, color.g - sample.g, color.b - sample.b)
				var test := delta.length_squared()
				if test < distance:
					distance = test
					best = sample
			candidate.set_pixel(x, y, best)
	_save(candidate, "wheelie-bin-candidate-v1.png")

func _feathers() -> void:
	var names: Array[String] = ["feather-down-v1.png", "feather-gray-v1.png", "feather-tip-v1.png", "feather-fluff-v1.png"]
	var current := Image.create(112, 28, false, Image.FORMAT_RGBA8)
	current.fill(Color.TRANSPARENT)
	var candidate := Image.create(56, 14, false, Image.FORMAT_RGBA8)
	candidate.fill(Color.TRANSPARENT)
	for frame: int in names.size():
		var feather := _read(names[frame])
		current.blit_rect(feather, Rect2i(0, 0, 28, 28), Vector2i(frame * 28, 0))
		var crisp := _nearest(feather, 14, 14)
		candidate.blit_rect(crisp, Rect2i(0, 0, 14, 14), Vector2i(frame * 14, 0))
	_save(current, "feathers-current-v1.png")
	_save(candidate, "feathers-candidate-v1.png")

func _logo_and_backdrop() -> void:
	_save(_nearest(_read("title-logo.png"), 350, 52), "title-logo-candidate-v1.png")
	_save(_nearest(_read("loading-backdrop-v2.png"), 640, 360, false), "loading-backdrop-candidate-v1.png")

func _score_digits() -> void:
	var blue := _read("beach-arcade-font-sprite-sheet-v2.png").get_region(Rect2i(198, 381, 1685, 166))
	var hot := _read("beach-arcade-font-sprite-sheet-v3.png").get_region(Rect2i(198, 381, 1685, 166))
	var current := Image.create(1685, 332, false, Image.FORMAT_RGBA8)
	current.fill(Color.TRANSPARENT)
	current.blit_rect(blue, Rect2i(Vector2i.ZERO, blue.get_size()), Vector2i.ZERO)
	current.blit_rect(hot, Rect2i(Vector2i.ZERO, hot.get_size()), Vector2i(0, 166))
	_save(current, "score-digits-current-v1.png")
	_save(_nearest(current, 337, 66), "score-digits-candidate-v1.png")

func _compose_board(left_end: Image, middle: Image, arrow_end: Image, left: bool) -> Image:
	var board := Image.create(34, 8, false, Image.FORMAT_RGBA8)
	board.fill(Color.TRANSPARENT)
	board.blit_rect(left_end, Rect2i(0, 0, 4, 8), Vector2i.ZERO)
	for x: int in range(4, 26):
		board.blit_rect(middle, Rect2i(0, 0, 1, 8), Vector2i(x, 0))
	board.blit_rect(arrow_end, Rect2i(0, 0, 8, 8), Vector2i(26, 0))
	if left:
		board.flip_x()
	return board

func _beach_sign() -> void:
	var native := _nearest(_read("beach-sign-arrow-v4.png"), 40, 8)
	var left_end := native.get_region(Rect2i(0, 0, 4, 8))
	var middle := native.get_region(Rect2i(20, 0, 1, 8))
	var arrow_end := native.get_region(Rect2i(32, 0, 8, 8))
	var post := _nearest(_read("beach-sign-post-v1.png"), 3, 50)
	_save(left_end, "beach-sign-piece-left-end-v1.png")
	_save(middle, "beach-sign-piece-middle-v1.png")
	_save(arrow_end, "beach-sign-piece-arrow-end-v1.png")
	_save(post, "beach-sign-piece-post-v1.png")
	var composed := Image.create(34, 44, false, Image.FORMAT_RGBA8)
	composed.fill(Color.TRANSPARENT)
	composed.blit_rect(post, Rect2i(0, 0, 3, 44), Vector2i(15, 0))
	var right_board := _compose_board(left_end, middle, arrow_end, false)
	var left_board := _compose_board(left_end, middle, arrow_end, true)
	composed.blit_rect(right_board, Rect2i(0, 0, 34, 8), Vector2i(0, 4))
	composed.blit_rect(left_board, Rect2i(0, 0, 34, 8), Vector2i(0, 13))
	_save(composed, "beach-sign-composed-candidate-v1.png")

func _initialize() -> void:
	_old_man()
	_crabs()
	_stand_signs()
	_wheelie_bin()
	_feathers()
	_logo_and_backdrop()
	_score_digits()
	_beach_sign()
	print("Prepared task 049 art-grid candidates")
	quit()
