class_name AdultPixelArt
extends RefCounted
## Native 64x64, palette-limited sprites. The figure itself is about 40 pixels tall.
## This is the editable source for the adult cast's pixel atlas, not a scaled render.

const CELL := 64
const COLUMNS := 8
const MUM_CLIPS := {
	"idle": 4, "eat": 4, "walk": 6, "walk_left": 6,
	"alert": 4, "block": 4, "shield": 4, "swat": 6,
	"chase": 6, "chase_left": 6, "kick": 6, "kick_left": 6,
	"carry": 6, "carry_left": 6, "handover": 5
}
const SUN_CLIPS := {
	"rest": 4, "rise": 7, "idle": 4, "eat": 4,
	"walk": 6, "walk_left": 6, "alert": 4, "block": 4,
	"swat": 6, "chase": 6, "chase_left": 6,
	"kick": 6, "kick_left": 6, "pickup": 5, "run": 7, "run_left": 7
}
const INK := Color("183b4e")
const SKIN := Color("ffc17c")
const SKIN_SHADE := Color("df8b58")
const HAIR := Color("713d31")
const HAIR_LIGHT := Color("a85d3b")
const CREAM := Color("fff4da")
const CORAL := Color("ef725c")
const CORAL_SHADE := Color("b94d4e")
const TEAL := Color("408fa8")
const TEAL_SHADE := Color("28667b")
const SANDAL := Color("854b32")
const RED := Color("dc4050")
const RED_SHADE := Color("a32d41")
const BLUE := Color("4b88b7")
const BLUE_SHADE := Color("30618d")

static func clips(mum: bool) -> Dictionary:
	return MUM_CLIPS if mum else SUN_CLIPS

static func atlas_path(mum: bool, female: bool = false, blue: bool = false) -> String:
	if mum:
		return "res://assets/sprites/retro-mum-32bit.png"
	return "res://assets/sprites/retro-sunbather-%s-%s-32bit.png" % ["female" if female else "male", "blue" if blue else "red"]

static func frames(mum: bool, female: bool = false, blue: bool = false) -> SpriteFrames:
	var texture: Texture2D = load(atlas_path(mum, female, blue)) as Texture2D
	var result := SpriteFrames.new()
	result.remove_animation(&"default")
	var index := 0
	for name: String in clips(mum):
		var count: int = clips(mum)[name]
		var animation := StringName(name)
		result.add_animation(animation)
		result.set_animation_loop(animation, name in ["idle", "eat", "walk", "walk_left", "chase", "chase_left", "carry", "carry_left", "rest", "run", "run_left"])
		result.set_animation_speed(animation, 12.0 if name in ["chase", "chase_left", "run", "run_left"] else (10.0 if name in ["walk", "walk_left", "carry", "carry_left"] else (4.0 if name == "rest" else (6.0 if name == "idle" else 8.0))))
		for frame: int in count:
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2((index % COLUMNS) * CELL, (index / COLUMNS) * CELL, CELL, CELL)
			atlas.filter_clip = true
			result.add_frame(animation, atlas)
			index += 1
	return result

static func generate_atlas(mum: bool, female: bool = false, blue: bool = false) -> Image:
	var total := 0
	for count: int in clips(mum).values():
		total += count
	var result := Image.create(COLUMNS * CELL, ceili(float(total) / COLUMNS) * CELL, false, Image.FORMAT_RGBA8)
	result.fill(Color.TRANSPARENT)
	var index := 0
	for name: String in clips(mum):
		for frame: int in int(clips(mum)[name]):
			var cell := Image.create(CELL, CELL, false, Image.FORMAT_RGBA8)
			cell.fill(Color.TRANSPARENT)
			_draw_actor(cell, mum, female, blue, name, frame)
			result.blit_rect(cell, Rect2i(0, 0, CELL, CELL), Vector2i((index % COLUMNS) * CELL, (index / COLUMNS) * CELL))
			index += 1
	return result

static func _rect(image: Image, x: int, y: int, width: int, height: int, color: Color, direction: int) -> void:
	if direction < 0:
		x = CELL - x - width
	image.fill_rect(Rect2i(x, y, width, height), color)

static func _line(image: Image, start: Vector2i, end: Vector2i, width: int, color: Color, direction: int) -> void:
	var steps: int = maxi(absi(end.x - start.x), absi(end.y - start.y))
	for i: int in range(steps + 1):
		var fraction: float = float(i) / float(maxi(steps, 1))
		var x: int = roundi(lerpf(float(start.x), float(end.x), fraction))
		var y: int = roundi(lerpf(float(start.y), float(end.y), fraction))
		_rect(image, x - width / 2, y - width / 2, width, width, color, direction)

static func _limb(image: Image, a: Vector2i, b: Vector2i, c: Vector2i, direction: int) -> void:
	_line(image, a, b, 6, INK, direction)
	_line(image, b, c, 6, INK, direction)
	_line(image, a, b, 4, SKIN_SHADE, direction)
	_line(image, b, c, 4, SKIN, direction)

static func _draw_actor(image: Image, mum: bool, female: bool, blue: bool, clip: String, frame: int) -> void:
	var direction := -1 if clip.ends_with("_left") else 1
	var action := clip.trim_suffix("_left")
	var cloth: Color = CORAL if mum else (BLUE if blue else RED)
	var shade: Color = CORAL_SHADE if mum else (BLUE_SHADE if blue else RED_SHADE)
	if action == "rest" or (action == "rise" and frame <= 2):
		_draw_reclining(image, female, blue, action, frame, direction)
		return
	var walk: bool = action in ["walk", "carry", "chase", "run"]
	var running: bool = action in ["chase", "run"]
	var phase: int = (frame - 1) % 6 if action == "run" else frame % 6
	var strides: Array = [8, 4, 0, -8, -4, 0] if running else [6, 3, 0, -6, -3, 0]
	var step: int = strides[phase] if walk else 0
	var bounce: int = 1 if walk and phase in [1, 4] else 0
	var crouch: int = 0
	if action == "rise":
		crouch = [0, 0, 0, 8, 5, 2, 0][frame]
	elif action == "pickup":
		crouch = [0, 3, 7, 8, 8][frame]
	var top: int = 18 + crouch - bounce + ([0, -1, 0, 1][frame] if action == "idle" else 0)
	var hip_y: int = 46 + crouch / 3 - bounce
	var foot_y: int = 57
	# The distant leg and arm sit behind the torso.
	var far_lift: int = [2, 3, 2, 0, 0, 1][phase] if walk else 0
	var near_lift: int = [0, 0, 1, 2, 3, 2][phase] if walk else 0
	var far_foot := Vector2i(37 - step, foot_y - far_lift)
	var far_knee := Vector2i(37 - step / 2, 51 + crouch / 4 - bounce)
	_limb(image, Vector2i(37, hip_y), far_knee, far_foot, direction)
	_draw_foot(image, far_foot, mum, direction)
	var back_hand := Vector2i(24 + (step / 2 if walk else 0), 43 + crouch / 3)
	_limb(image, Vector2i(27, 34 + crouch - bounce), Vector2i(23, 39 + crouch / 2), back_hand, direction)
	# Shorts / lower torso.  The mum's split shorts have a readable hem.
	_rect(image, 26, 41 + crouch - bounce, 14, 8, INK, direction)
	_rect(image, 27, 42 + crouch - bounce, 12, 6, cloth if not mum else TEAL, direction)
	_rect(image, 27, 46 + crouch - bounce, 6, 2, shade if not mum else TEAL_SHADE, direction)
	if mum:
		_rect(image, 34, 45 + crouch - bounce, 2, 4, INK, direction)
		_rect(image, 35, 42 + crouch - bounce, 4, 2, TEAL_SHADE, direction)
		_rect(image, 28, 43 + crouch - bounce, 4, 2, TEAL_SHADE, direction)
		_rect(image, 27, 47 + crouch - bounce, 5, 1, TEAL_SHADE, direction)
	if female:
		_rect(image, 29, 42 + crouch - bounce, 7, 7, cloth, direction)
	# Torso, neckline and large readable arms.
	if mum:
		# Stepped shoulders and a tapered waist replace the old square blouse.
		_rect(image, 28, 30 + crouch - bounce, 11, 3, INK, direction)
		_rect(image, 25, 33 + crouch - bounce, 17, 7, INK, direction)
		_rect(image, 27, 40 + crouch - bounce, 14, 6, INK, direction)
		_rect(image, 29, 31 + crouch - bounce, 9, 3, CORAL, direction)
		_rect(image, 26, 34 + crouch - bounce, 15, 6, CORAL, direction)
		_rect(image, 28, 40 + crouch - bounce, 12, 5, CORAL, direction)
		_rect(image, 27, 37 + crouch - bounce, 3, 5, CORAL_SHADE, direction)
		_rect(image, 30, 43 + crouch - bounce, 10, 2, CORAL_SHADE, direction)
		_rect(image, 32, 31 + crouch - bounce, 4, 2, SKIN, direction)
		_rect(image, 34, 35 + crouch - bounce, 2, 6, CORAL_SHADE, direction)
		_rect(image, 33, 42 + crouch - bounce, 3, 4, CORAL, direction)
		_rect(image, 35, 44 + crouch - bounce, 2, 4, CORAL_SHADE, direction)
	else:
		_rect(image, 25, 30 + crouch - bounce, 16, 15, INK, direction)
		_rect(image, 26, 31 + crouch - bounce, 14, 13, cloth if female else SKIN, direction)
		_rect(image, 27, 39 + crouch - bounce, 11, 4, shade if female else SKIN_SHADE, direction)
		if female:
			_rect(image, 30, 31 + crouch - bounce, 7, 2, SKIN, direction)
		else:
			_rect(image, 31, 36 + crouch - bounce, 5, 1, SKIN_SHADE, direction)
	# The near leg remains independently posed through the complete cycle.
	var near_foot := Vector2i(29 + step, foot_y - near_lift)
	if action == "kick":
		near_foot = [Vector2i(30, 57), Vector2i(37, 49), Vector2i(39, 44), Vector2i(49, 43), Vector2i(41, 49), Vector2i(31, 57)][frame]
	var near_knee := Vector2i(29 + step / 2, 51 + crouch / 4 - bounce)
	if action == "kick" and frame in [1, 2, 3, 4]:
		near_knee = Vector2i(39 if frame != 3 else 43, 46)
	_limb(image, Vector2i(29, hip_y), near_knee, near_foot, direction)
	_draw_foot(image, near_foot, mum, direction)
	# Neck, face and hair use the same eye and jaw line in every standing clip.
	_rect(image, 30, 28 + crouch - bounce, 7, 5, INK, direction)
	_rect(image, 31, 28 + crouch - bounce, 5, 5, SKIN, direction)
	if mum:
		# Hairline, cheek and ponytail step in broad native-pixel clusters.
		_rect(image, 28, top + 2, 13, 11, INK, direction)
		_rect(image, 30, top + 3, 11, 9, SKIN, direction)
		_rect(image, 31, top + 12, 8, 2, INK, direction)
		_rect(image, 32, top + 12, 7, 1, SKIN_SHADE, direction)
		_rect(image, 27, top, 13, 5, INK, direction)
		_rect(image, 28, top + 1, 11, 3, HAIR, direction)
		_rect(image, 30, top + 1, 7, 2, HAIR_LIGHT, direction)
		_rect(image, 27, top + 4, 5, 5, HAIR, direction)
		_rect(image, 23, top + 2, 6, 5, INK, direction)
		_rect(image, 21, top + 6, 7, 5, INK, direction)
		_rect(image, 19, top + 10, 8, 5, INK, direction)
		_rect(image, 20, top + 14, 5, 3, INK, direction)
		_rect(image, 22, top + 7, 5, 4, HAIR, direction)
		_rect(image, 20, top + 11, 6, 3, HAIR, direction)
		_rect(image, 21, top + 14, 4, 2, HAIR, direction)
		_rect(image, 22, top + 11, 4, 2, HAIR_LIGHT, direction)
		_rect(image, 25, top + 5, 2, 2, TEAL, direction)
		_rect(image, 31, top + 10, 2, 2, SKIN_SHADE, direction)
	else:
		_rect(image, 26, top + 3, 14, 13, INK, direction)
		_rect(image, 27, top + 4, 12, 11, SKIN, direction)
		_rect(image, 27, top + 12, 4, 2, SKIN_SHADE, direction)
		_rect(image, 26, top, 14, 6, INK, direction)
		_rect(image, 27, top + 1, 12, 4, HAIR, direction)
		_rect(image, 29, top + 1, 7, 2, HAIR_LIGHT, direction)
		_rect(image, 26, top + 4, 4, 5, HAIR, direction)
		if female:
			_rect(image, 21, top + 1, 6, 6, INK, direction)
			_rect(image, 22, top + 2, 5, 4, HAIR, direction)
			_rect(image, 23, top + 2, 3, 2, HAIR_LIGHT, direction)
	if mum:
		_rect(image, 35, top + 6, 5, 1, HAIR, direction)
		_rect(image, 36, top + 7, 4, 4, CREAM, direction)
		_rect(image, 38, top + 7, 2, 3 if action != "idle" or frame != 2 else 2, INK, direction)
		_rect(image, 40, top + 9, 2, 2, SKIN, direction)
		_rect(image, 39, top + 12, 3, 1, INK, direction)
		_rect(image, 40, top + 12, 2, 1, CORAL_SHADE, direction)
	else:
		_rect(image, 31, top + 8, 9, 3, INK, direction)
		_rect(image, 32, top + 8, 3, 1, CREAM, direction)
		_rect(image, 37, top + 12, 2, 1, INK, direction)
	# Action silhouettes are differentiated by elbow, hand and held contact pose.
	var elbow := Vector2i(43, 39 + crouch / 2 - bounce)
	var hand := Vector2i(44 - (step / 2 if walk else 0), 43 + crouch / 2)
	match action:
		"idle":
			hand = [Vector2i(44, 43), Vector2i(43, 42), Vector2i(44, 44), Vector2i(45, 43)][frame]
		"eat":
			hand = [Vector2i(43, 38), Vector2i(40, 29), Vector2i(39, 28), Vector2i(44, 41)][frame]
			elbow = Vector2i(44, 34)
		"alert":
			hand = [Vector2i(45, 41), Vector2i(47, 35), Vector2i(47, 30), Vector2i(47, 31)][frame]
		"block", "shield":
			hand = [Vector2i(44, 40), Vector2i(39, 34), Vector2i(33, 31), Vector2i(35, 32)][frame]
			elbow = Vector2i(45, 34)
		"swat":
			hand = [Vector2i(42, 42), Vector2i(37, 32), Vector2i(34, 27), Vector2i(49, 32), Vector2i(52, 36), Vector2i(44, 42)][frame]
			elbow = Vector2i(41, 33)
		"kick":
			hand = Vector2i(45, 37)
		"handover":
			hand = [Vector2i(44, 39), Vector2i(47, 37), Vector2i(51, 37), Vector2i(51, 38), Vector2i(44, 40)][frame]
		"carry":
			hand = Vector2i(45, 35)
		"pickup":
			hand = Vector2i(45 + (2 if frame == 4 else 0), 48 + crouch / 3)
		"rise":
			hand = Vector2i(45, 47 - crouch / 2)
	_limb(image, Vector2i(39, 34 + crouch - bounce), elbow, hand, direction)
	if action == "swat" and frame in [3, 4]:
		_rect(image, hand.x + 1, hand.y - 2, 3, 5, SKIN, direction)

static func _draw_foot(image: Image, point: Vector2i, mum: bool, direction: int) -> void:
	if mum:
		_rect(image, point.x - 4, point.y - 2, 9, 4, INK, direction)
		_rect(image, point.x - 3, point.y - 1, 7, 3, SANDAL, direction)
		_rect(image, point.x - 2, point.y - 1, 3, 1, SKIN, direction)
		_rect(image, point.x + 2, point.y - 1, 2, 1, SKIN, direction)
	else:
		_rect(image, point.x - 3, point.y - 1, 8, 3, INK, direction)
		_rect(image, point.x - 2, point.y, 6, 2, SKIN_SHADE, direction)

static func _draw_reclining(image: Image, female: bool, blue: bool, action: String, frame: int, direction: int) -> void:
	var cloth: Color = BLUE if blue else RED
	var shade: Color = BLUE_SHADE if blue else RED_SHADE
	var lift: int = frame if action == "rest" else frame * 3
	# A separate low, wide silhouette; no towel is baked into the character.
	_rect(image, 12, 48 - lift, 14, 9, INK, direction)
	_rect(image, 13, 49 - lift, 12, 7, SKIN, direction)
	_rect(image, 11, 46 - lift, 14, 5, INK, direction)
	_rect(image, 13, 47 - lift, 11, 3, HAIR, direction)
	_rect(image, 20, 51 - lift, 5, 2, INK, direction)
	_rect(image, 25, 48 - lift / 2, 17, 9, INK, direction)
	_rect(image, 26, 49 - lift / 2, 15, 7, cloth if female else SKIN, direction)
	_rect(image, 37, 50 - lift / 2, 9, 7, shade if female else cloth, direction)
	_rect(image, 45, 52, 14, 5, INK, direction)
	_rect(image, 46, 53, 12, 3, SKIN, direction)
	_rect(image, 27, 56, 9, 2, SKIN_SHADE, direction)
	if frame % 2 == 1:
		_rect(image, 16, 53 - lift, 5, 2, SKIN_SHADE, direction)
