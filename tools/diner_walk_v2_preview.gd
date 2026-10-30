extends Node2D

var rng := RandomNumberGenerator.new()
var old_texture: Texture2D

func _ready() -> void:
	Audio.music.stop()
	get_window().content_scale_size = Vector2i(640, 360)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().size = Vector2i(1920, 1080)
	rng.seed = 210
	old_texture = load("res://assets/sprites/pier-diner-motion-clean.png")
	for index: int in 4:
		_old_pose(Vector2(80 + index * 118, 86), index)
	for index: int in 6:
		_new_pose(Vector2(62 + index * 103, 151), index, false, 1.0, true)
		_new_pose(Vector2(62 + index * 103, 217), index, true, 1.0, true)
		_new_pose(Vector2(62 + index * 103, 354), index, index >= 3, 2.15, false)
	queue_redraw()
	call_deferred("_capture")

func _old_pose(at: Vector2, frame: int) -> void:
	var region := AtlasTexture.new()
	region.atlas = old_texture
	region.region = Rect2(frame * 400, 0, 400, 400)
	region.filter_clip = true
	var sprite := Sprite2D.new()
	add_child(sprite)
	sprite.texture = region
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * 0.11
	sprite.position = at + Vector2(0, -22)

func _new_pose(at: Vector2, frame: int, left: bool, scale_multiplier: float, with_food: bool) -> void:
	var actor := BeachTarget.new()
	add_child(actor)
	actor.setup("pier_diner", at.x, rng, 1.0, {"food_id":"fish_chips"})
	actor.position = at
	actor.facing = -1.0 if left else 1.0
	actor.sprite.flip_h = left
	actor.sprite.play(&"walk")
	actor.sprite.pause()
	actor.sprite.frame = frame
	actor.sprite.scale *= scale_multiplier
	actor.sprite.position.y *= scale_multiplier
	actor.food_sprite.visible = with_food
	if with_food:
		PierDinerArt.align_food(actor)
	else:
		actor.food_sprite.hide()

func _draw() -> void:
	var ink := Color("17394b")
	var paper := Color("fff1d1")
	var accent := Color("2b7180")
	var sand := Color("e6c284")
	draw_rect(Rect2(0, 0, 640, 360), Color("a9d5ce"))
	draw_rect(Rect2(0, 0, 640, 24), ink)
	draw_rect(Rect2(0, 24, 640, 68), paper)
	draw_rect(Rect2(0, 92, 640, 66), Color("c7e2da"))
	draw_rect(Rect2(0, 158, 640, 66), Color("96c9c4"))
	draw_rect(Rect2(0, 224, 640, 136), accent)
	draw_line(Vector2(0, 86), Vector2(640, 86), sand, 2)
	draw_line(Vector2(0, 151), Vector2(640, 151), sand, 2)
	draw_line(Vector2(0, 217), Vector2(640, 217), sand, 2)
	draw_line(Vector2(0, 354), Vector2(640, 354), sand, 2)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(10, 17), "PIER DINER / WALK V2 REVIEW", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("fff4da"))
	draw_string(font, Vector2(10, 36), "OLD 4-FRAME WALK / ACTUAL GAMEPLAY SCALE", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, ink)
	draw_string(font, Vector2(470, 74), "LIMITED WEIGHT SHIFT", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, ink)
	draw_string(font, Vector2(10, 105), "NEW 6-PHASE CARRY WALK / RIGHT / FOOD ANCHORED / ACTUAL SCALE", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, ink)
	draw_string(font, Vector2(10, 171), "NEW 6-PHASE CARRY WALK / LEFT / FOOD ANCHORED / ACTUAL SCALE", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, ink)
	draw_string(font, Vector2(10, 239), "2.15X POSE INSPECTION / CONTACT - DOWN - PASSING - OPPOSITE CONTACT - DOWN - PASSING", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("fff4da"))
	for index: int in 6:
		var label: String = ["CONTACT", "DOWN", "PASS", "CONTACT", "DOWN", "PASS"][index]
		var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 6).x
		draw_string(font, Vector2(62 + index * 103 - width * 0.5, 252), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color("fff4da"))

func _capture() -> void:
	for index: int in 5:
		await get_tree().process_frame
	assert(get_viewport().get_texture().get_image().save_png("res://assets/archive/previews/diner-walk-v2.png") == OK)
	get_tree().quit()
