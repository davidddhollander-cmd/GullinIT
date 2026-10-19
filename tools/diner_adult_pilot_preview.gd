extends Node2D
## Isolated visual review: actual production references plus separately loaded pilots.
const PILOT := "res://assets/pilots/adult-diner-v1/"
const OUTPUT := "res://assets/previews/adult-diner-pilot-v1/"
var panel: Node2D
var captions: Array = []
var comparison := true
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = 19
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	call_deferred("_review")

func _window(logical: Vector2i, physical: Vector2i) -> void:
	get_window().content_scale_size = logical
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	get_window().size = physical

func _pilot(id: String, x: float, baseline: float, parent: Node2D = panel) -> Sprite2D:
	var image := Image.load_from_file(ProjectSettings.globalize_path(PILOT + id + ".png"))
	assert(image != null and image.get_size() == Vector2i(128,128))
	var sprite := Sprite2D.new()
	sprite.texture = ImageTexture.create_from_image(image)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * 0.5
	sprite.position = Vector2(x, baseline - 26)
	parent.add_child(sprite)
	return sprite

func _current(kind: String, x: float, baseline: float, appearance: String = "", pose: StringName = &"idle", parent: Node2D = panel) -> AnimatedSprite2D:
	var actor := BeachTarget.new()
	parent.add_child(actor)
	actor.setup(kind, x, rng, 1.0, {"appearance":appearance})
	actor.position = Vector2(x, baseline)
	actor.food = false
	actor.food_sprite.hide()
	actor.sprite.play(pose)
	actor.sprite.pause()
	actor.sprite.frame = 0
	actor.sprite.reparent(parent)
	actor.hide()
	return actor.sprite

func _caption(x: float, y: float, text: String) -> void:
	captions.append({"x":x,"y":y,"text":text})

func _review() -> void:
	_window(Vector2i(320,270), Vector2i(1280,1080))
	panel = Node2D.new()
	add_child(panel)
	for x: int in [40,120,200,280]:
		var index := [40,120,200,280].find(x)
		if index == 0:
			_current("picnic_family", x, 82)
			_pilot("mum-idle", x, 166)
		elif index in [1,2]:
			_current("sunbather", x, 82, "male_red" if index == 1 else "female_red")
			_pilot("male-idle" if index == 1 else "female-idle", x, 166)
		else:
			_current("pier_diner", x, 82)
			_current("pier_diner", x, 166)
		_caption(x, 94, ["MUM","MAN","WOMAN","DINER"][index])
		_caption(x, 178, ["MUM PILOT","MAN PILOT","WOMAN PILOT","UNCHANGED"][index])
	_pilot("mum-walk", 40, 251)
	_pilot("mum-swat", 120, 251)
	_current("pier_diner", 200, 251, "", &"walk")
	_current("pier_diner", 280, 251, "", &"swat")
	_caption(40,263,"MUM WALK")
	_caption(120,263,"MUM SWAT")
	_caption(200,263,"DINER WALK")
	_caption(280,263,"DINER SWAT")
	queue_redraw()
	await _save("comparison.png")
	# Verify the same comparison at a narrower phone-sized portrait display.
	_window(Vector2i(320,270), Vector2i(720,608))
	await _save("comparison-phone.png")
	panel.queue_free()
	await get_tree().process_frame
	comparison = false
	queue_redraw()
	await _gameplay()
	get_tree().quit()

func _draw() -> void:
	if not comparison:
		return
	draw_rect(Rect2(0,0,320,270),Color("a9d5ce"))
	for y: int in [82,166,251]:
		draw_rect(Rect2(0,y,320,19),Color("e5c68c"))
	draw_rect(Rect2(0,0,320,20),Color("183b4e"))
	var font := ThemeDB.fallback_font
	draw_string(font,Vector2(6,14),"DINER STYLE PILOT / SAME GAMEPLAY SIZE",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("fff4da"))
	for spec: Dictionary in [{"y":31,"text":"CURRENT ADULTS + APPROVED DINER"},{"y":115,"text":"NEW PILOTS + SAME DINER"},{"y":200,"text":"ACTION POSES / STYLE CHECK"}]:
		draw_string(font,Vector2(6,spec.y),spec.text,HORIZONTAL_ALIGNMENT_LEFT,-1,7,Color("183b4e"))
	for caption: Dictionary in captions:
		var width := font.get_string_size(caption.text,HORIZONTAL_ALIGNMENT_LEFT,-1,6).x
		draw_string(font,Vector2(caption.x-width/2,caption.y),caption.text,HORIZONTAL_ALIGNMENT_LEFT,-1,6,Color("183b4e"))

func _gameplay() -> void:
	_window(Vector2i(320,180),Vector2i(1280,720))
	var game := BeachGame.new()
	add_child(game)
	game.setup(Config.levels[2].duplicate(true), false)
	game.set_physics_process(false)
	game.running = false
	game.intro = 0
	game.input.enabled = false
	for actor: Node in game.actors.get_children():
		if actor is CanvasItem:
			actor.hide()
	for pilot: RivalPilot in game.pilots:
		pilot.gull.hide()
	game.camera_x = 560
	game.camera.position = Vector2(560,90)
	game.camera.reset_smoothing()
	game.beach.camera_x = 560
	game.beach.queue_redraw()
	game.player.position = Vector2(445,65)
	game.overlay.queue_redraw()
	_pilot("mum-idle",445,160,game.actors)
	_pilot("male-idle",520,160,game.actors)
	_pilot("female-idle",595,160,game.actors)
	_current("pier_diner",670,160,"",&"idle",game.actors)
	var overlay := CanvasLayer.new()
	game.add_child(overlay)
	var label := Label.new()
	label.position = Vector2(6,30)
	label.text = "PILOT PREVIEW / DINER UNCHANGED"
	label.add_theme_font_override("font",preload("res://assets/fonts/gull_pixel.fnt"))
	label.add_theme_font_size_override("font_size",8)
	label.add_theme_color_override("font_color",Color("183b4e"))
	overlay.add_child(label)
	await _save("gameplay.png")
	_window(Vector2i(320,180),Vector2i(844,390))
	await _save("gameplay-phone.png")
	game.queue_free()
	await get_tree().process_frame

func _save(file: String) -> void:
	for i: int in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	assert(image.save_png(OUTPUT + file) == OK)
	print("PILOT REVIEW: " + file + " " + str(image.get_size()))
