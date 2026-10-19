extends Node2D
## Assessment only: production actors beside unused existing lifeguard artwork.
var rng := RandomNumberGenerator.new()
var source = preload("res://tools/diner_adult_atlas_source.gd").new()

func _ready() -> void:
	get_window().content_scale_size = Vector2i(400,290)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().size = Vector2i(1600,1160)
	rng.seed = 19
	_actor("pier_diner",Vector2(50,89),&"idle",0)
	_actor("kiosk_customer",Vector2(150,89),&"idle",0)
	_actor("lifeguard",Vector2(250,89),&"walk",0)
	var path := "res://assets/previews/lifeguard-motion-review-v1.png"
	var walk: Array[Image] = source._row(path,0,2,[80,80,80,80])
	var actions: Array[Image] = source._row(path,1,2,[80,80,80,80])
	_candidate(actions[0],Vector2(350,89))
	for i: int in 4:
		_actor("kiosk_customer",Vector2(50+i*100,173),&"walk",i)
	for i: int in 4:
		_candidate(walk[1] if i==1 else actions[0 if i==0 else (1 if i==2 else 3)],Vector2(50+i*100,260))
	queue_redraw()
	call_deferred("_capture")

func _actor(kind: String,at: Vector2,clip: StringName,frame: int) -> void:
	var actor := BeachTarget.new()
	add_child(actor)
	actor.setup(kind,at.x,rng,1.0)
	actor.position = at
	actor.sprite.play(clip)
	actor.sprite.pause()
	actor.sprite.frame = frame
	actor.sprite.reparent(self)
	actor.hide()

func _candidate(image: Image,at: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = ImageTexture.create_from_image(image)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE*0.5
	sprite.position = at-Vector2(0,26)
	add_child(sprite)

func _draw() -> void:
	draw_rect(Rect2(0,0,400,290),Color("a9d5ce"))
	draw_rect(Rect2(0,0,400,24),Color("183b4e"))
	var font := ThemeDB.fallback_font
	draw_string(font,Vector2(9,16),"SHOPPER + LIFEGUARD / EXISTING ART REVIEW",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("fff4da"))
	for y: int in [89,173,260]:
		draw_rect(Rect2(0,y,400,24),Color("e5c68c"))
	for i: int in 4:
		_label(font,50+i*100,103,["DINER / STYLE","SHOPPER / CURRENT","GUARD / IN GAME","GUARD / OLD REVIEW"][i])
		_label(font,50+i*100,187,"WALK FRAME "+str(i+1))
		_label(font,50+i*100,274,["READY","WALK","WHISTLE","POINT / WARNING"][i])
	draw_string(font,Vector2(9,40),"ACTUAL SIZES / OLD REVIEW FITTED TO 40 PX",HORIZONTAL_ALIGNMENT_LEFT,-1,7,Color("183b4e"))
	draw_string(font,Vector2(9,124),"SHOPPER: PAINTED WALK + UNEVEN FOOT BASELINE",HORIZONTAL_ALIGNMENT_LEFT,-1,7,Color("183b4e"))
	draw_string(font,Vector2(9,212),"LIFEGUARD: UNUSED MOTION SHEET / NO NEW ART",HORIZONTAL_ALIGNMENT_LEFT,-1,7,Color("183b4e"))

func _label(font: Font,x: float,y: float,text: String) -> void:
	var width := font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,6).x
	draw_string(font,Vector2(x-width/2,y),text,HORIZONTAL_ALIGNMENT_LEFT,-1,6,Color("183b4e"))

func _capture() -> void:
	for i: int in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png("res://assets/previews/shopper-lifeguard-assessment-v1.png")==OK)
	get_tree().quit()
