extends Node2D
## Review contact sheet through the real SpriteFrames and food-alignment path.
const IDS := ["kiosk_customer","shopper_mullet","shopper_sundress"]
const FONT = preload("res://assets/fonts/gull_pixel.fnt")
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	Audio.music.stop()
	get_window().content_scale_size = Vector2i(640,360)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().size = Vector2i(1920,1080)
	rng.seed = 6
	for row: int in 3:
		_actor(IDS[row],Vector2(76,108+row*100),&"idle",0,false)
		for frame: int in 3:
			_actor(IDS[row],Vector2(192+frame*96,108+row*100),&"bite",frame,false)
		_actor(IDS[row],Vector2(536,108+row*100),&"bite",1,true)
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
	assert(actor.sprite.sprite_frames.get_frame_count(&"bite") == 3)
	assert(not actor.sprite.sprite_frames.get_animation_loop(&"bite"))
	var anchor: Array = Config.sprites[appearance].food_anchors[String(clip)][frame]
	assert(actor.food_sprite.position == Vector2(anchor[0]*actor.facing,anchor[1]))

func _draw() -> void:
	draw_rect(Rect2(0,0,640,360),Color("a9d5ce"))
	draw_rect(Rect2(0,0,640,32),Color("183b4e"))
	draw_string(FONT,Vector2(12,22),"CUSTOMER BITE POSES",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("fff4da"))
	var columns := [76,192,288,384,536]
	var labels := ["EXISTING IDLE","RAISE","BITE","LOWER","BITE / LEFT"]
	for row: int in 3:
		var baseline := 108+row*100
		draw_rect(Rect2(0,baseline,640,36),Color("e5c68c"))
		for i: int in 5:
			var width := FONT.get_string_size(labels[i],HORIZONTAL_ALIGNMENT_LEFT,-1,8).x
			draw_string(FONT,Vector2(columns[i]-width/2,baseline+15),labels[i],HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("183b4e"))
		draw_string(FONT,Vector2(12,baseline+29),["ORIGINAL CUSTOMER","MULLET CUSTOMER","SUNDRESS CUSTOMER"][row],HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("183b4e"))
	draw_string(FONT,Vector2(12,350),"40PX ADULT SCALE / SEPARATE STEALABLE SNACK / 3 FRAMES AT 5 FPS",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("183b4e"))

func _capture() -> void:
	for i: int in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png("res://assets/previews/shopper-bite-production-v1.png") == OK)
	print("SHOPPER BITE PREVIEW: 45 registration/alignment assertions passed")
	get_tree().quit()
