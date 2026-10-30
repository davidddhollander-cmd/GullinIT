extends Node2D
## Display the actual runtime frames, scales and independent food overlays.
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	get_window().content_scale_size = Vector2i(400,250)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().size = Vector2i(1600,1000)
	rng.seed = 19
	_actor("pier_diner",Vector2(50,85),&"idle",0)
	_actor("picnic_family",Vector2(145,85),&"idle",0)
	var old := Sprite2D.new()
	var texture := AtlasTexture.new()
	texture.atlas = load("res://assets/sprites/toddler_polished.png")
	texture.region = Rect2(80,18,233,337)
	texture.margin = Rect2(80,25,129,25)
	old.texture = texture
	old.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	old.scale = Vector2.ONE*0.0525
	old.position = Vector2(245,85-19.005/2.0)
	add_child(old)
	_actor("toddler",Vector2(345,85),&"idle",0)
	for column: int in 4:
		var group := Node2D.new()
		group.position = Vector2(50+column*100,219)
		group.scale = Vector2.ONE*2.0
		add_child(group)
		var clip: StringName = [&"eat",&"walk",&"cry",&"cry_run"][column]
		var actor := _actor("toddler",Vector2.ZERO,clip,1)
		actor.reparent(group,false)
	queue_redraw()
	call_deferred("_capture")

func _actor(kind: String, at: Vector2, clip: StringName, frame: int) -> BeachTarget:
	var actor := BeachTarget.new()
	add_child(actor)
	actor.setup(kind,at.x,rng,1.0)
	actor.position = at
	actor.sprite.play(clip)
	actor.sprite.pause()
	actor.sprite.frame = frame
	actor.food_sprite.visible = kind=="toddler" and clip in [&"eat",&"walk"]
	if kind == "toddler":
		ToddlerArt.align_food(actor)
	return actor

func _draw() -> void:
	draw_rect(Rect2(0,0,400,250),Color("a9d5ce"))
	draw_rect(Rect2(0,0,400,24),Color("183b4e"))
	var font := ThemeDB.fallback_font
	draw_string(font,Vector2(10,16),"TODDLER / DINER STYLE / SLIGHTLY TALLER",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("fff4da"))
	draw_string(font,Vector2(10,39),"ACTUAL GAME SIZES",HORIZONTAL_ALIGNMENT_LEFT,-1,7,Color("183b4e"))
	draw_rect(Rect2(0,85,400,26),Color("e5c68c"))
	draw_rect(Rect2(0,219,400,31),Color("e5c68c"))
	for i: int in 4:
		_label(font,50+i*100,100,["DINER","MUM","OLD / ~18 PX","NEW / 22 PX"][i])
		_label(font,50+i*100,236,["EAT","WALK","CRY","CRYING RUN"][i])
	draw_string(font,Vector2(10,131),"POSE DETAIL / 2X GAME SIZE",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("183b4e"))

func _label(font: Font,x: float,y: float,text: String) -> void:
	var width := font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,7).x
	draw_string(font,Vector2(x-width/2,y),text,HORIZONTAL_ALIGNMENT_LEFT,-1,7,Color("183b4e"))

func _capture() -> void:
	for i: int in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png("res://assets/archive/previews/toddler-diner-comparison-v1.png")==OK)
	get_tree().quit()
