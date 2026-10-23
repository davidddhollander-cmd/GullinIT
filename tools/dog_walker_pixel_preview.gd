extends Node2D
const FONT = preload("res://assets/fonts/gull_pixel.fnt")
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	Audio.music.stop()
	get_window().content_scale_size = Vector2i(640,360)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().size = Vector2i(1920,1080)
	rng.seed = 8
	_actor("kiosk_customer","kiosk_customer",Vector2(64,100),&"idle",0)
	_actor("kiosk_customer","shopper_mullet",Vector2(208,100),&"idle",0)
	_actor("kiosk_customer","shopper_sundress",Vector2(352,100),&"idle",0)
	_actor("dog_owner","",Vector2(496,100),&"idle",0)
	for frame: int in 4:
		_actor("dog_owner","",Vector2(64+frame*144,202),&"walk",frame)
	for i: int in 4:
		_actor("dog_owner","",Vector2(64+i*144,304),[&"idle",&"alert",&"bark",&"angry"][i],1 if i==2 else 0,i==0)
	queue_redraw()
	call_deferred("_capture")

func _actor(kind: String,appearance: String,at: Vector2,clip: StringName,frame: int,left: bool = false) -> void:
	var actor := BeachTarget.new()
	add_child(actor)
	actor.setup(kind,at.x,rng,1.0,{"appearance":appearance,"food_id":"hotdog" if kind=="dog_owner" else "ice_cream"})
	actor.position = at
	actor.facing = -1 if left else 1
	actor.sprite.flip_h = left
	actor.sprite.play(clip)
	actor.sprite.pause()
	actor.sprite.frame = frame
	BeachgoerArt.align_food(actor)

func _draw() -> void:
	draw_rect(Rect2(0,0,640,360),Color("a9d5ce"))
	draw_rect(Rect2(0,0,640,30),Color("183b4e"))
	draw_string(FONT,Vector2(12,21),"PIXEL DOG WALKER + TERRIER",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("fff4da"))
	var labels := [["ORIGINAL SHOPPER","MULLET SHOPPER","SUNDRESS SHOPPER","NEW DOG WALKER"],["WALK 1","WALK 2","WALK 3","WALK 4"],["IDLE / LEFT","ALERT","BARK","ANGRY"]]
	for row: int in 3:
		var baseline := 100+row*102
		draw_rect(Rect2(0,baseline,640,28),Color("e5c68c"))
		for col: int in 4:
			var label: String = labels[row][col]
			var width := FONT.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,8).x
			draw_string(FONT,Vector2(64+col*144-width/2,baseline+16),label,HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("183b4e"))
	draw_string(FONT,Vector2(12,350),"40PX ADULT / HARD PIXELS / ORIGINAL IDENTITIES / SEPARATE SNACK",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("183b4e"))

func _capture() -> void:
	for i: int in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png("res://assets/previews/dog-walker-pixel-v1.png")==OK)
	get_tree().quit()
