extends Node2D
## Review the generated clips at real in-game scale through SpriteFrames and food anchors.
const IDS := ["kiosk_customer","shopper_mullet","shopper_sundress"]
const FONT = preload("res://assets/fonts/gull_pixel.fnt")
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	Audio.music.stop()
	get_window().content_scale_size = Vector2i(640,360)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().size = Vector2i(1920,1080)
	rng.seed = 41
	for row: int in IDS.size():
		_actor(IDS[row],Vector2(92,105+row*100),&"idle",0,false)
		_actor(IDS[row],Vector2(252,105+row*100),&"look_up",row%2,false)
		_actor(IDS[row],Vector2(420,105+row*100),&"panic_run",row,false)
		_actor(IDS[row],Vector2(560,105+row*100),&"panic_run",row+3,true)
	queue_redraw()
	call_deferred("_capture")

func _actor(appearance: String,at: Vector2,clip: StringName,frame: int,left: bool) -> void:
	var actor := BeachTarget.new()
	add_child(actor)
	actor.setup("kiosk_customer",at.x,rng,1.0,{"appearance":appearance,"food_id":"ice_cream"})
	actor.set_physics_process(false)
	actor.position = at
	actor.facing = -1 if left else 1
	actor.sprite.flip_h = left
	actor.sprite.play(clip)
	actor.sprite.pause()
	actor.sprite.frame = frame
	BeachgoerArt.align_food(actor)
	assert(actor.sprite.sprite_frames.get_frame_count(&"look_up")==2)
	assert(actor.sprite.sprite_frames.get_frame_count(&"panic_run")==6)

func _draw() -> void:
	draw_rect(Rect2(0,0,640,360),Color("a9d5ce"))
	draw_rect(Rect2(0,0,640,32),Color("183b4e"))
	draw_string(FONT,Vector2(12,22),"SHOPPER GANG PANIC POSES",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("fff4da"))
	var columns := [92,252,420,560]
	var labels := ["CURRENT IDLE","LOOK UP","PANIC RUN","PANIC / LEFT"]
	for row: int in IDS.size():
		var baseline := 105+row*100
		draw_rect(Rect2(0,baseline,640,36),Color("e5c68c"))
		for i: int in labels.size():
			var width := FONT.get_string_size(labels[i],HORIZONTAL_ALIGNMENT_LEFT,-1,8).x
			draw_string(FONT,Vector2(columns[i]-width/2,baseline+15),labels[i],HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("183b4e"))
		draw_string(FONT,Vector2(12,baseline+29),["ORIGINAL CUSTOMER","MULLET CUSTOMER","SUNDRESS CUSTOMER"][row],HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("183b4e"))
	draw_string(FONT,Vector2(12,350),"40PX ADULT SCALE / 2 LOOK-UP FRAMES / 6-FRAME PANIC LOOP / FOOD ANCHORS",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("183b4e"))

func _capture() -> void:
	for i: int in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png("res://assets/previews/shopper-panic-v1.png")==OK)
	print("SHOPPER PANIC PREVIEW: production clips and food anchors rendered")
	get_tree().quit()
