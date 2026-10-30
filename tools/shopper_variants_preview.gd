extends Node2D
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	Audio.music.stop()
	get_window().content_scale_size = Vector2i(400,300)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().size = Vector2i(1600,1200)
	rng.seed = 19
	_actor("pier_diner","",Vector2(50,88),&"idle",0)
	_actor("kiosk_customer","kiosk_customer",Vector2(150,88),&"idle",0)
	_actor("kiosk_customer","shopper_mullet",Vector2(250,88),&"idle",0)
	_actor("kiosk_customer","shopper_sundress",Vector2(350,88),&"idle",0)
	for row: int in 2:
		for column: int in 4:
			var appearance: String = "shopper_mullet" if column%2==0 else "shopper_sundress"
			var clip: StringName = (&"walk" if column<2 else &"run") if row==0 else (&"windup" if column<2 else &"swat")
			_actor("kiosk_customer",appearance,Vector2(50+column*100,177+row*88),clip,2 if clip in [&"walk",&"run",&"swat"] else 1,column>=2 and row==0)
	queue_redraw()
	call_deferred("_capture")

func _actor(kind: String,appearance: String,at: Vector2,clip: StringName,frame: int,left: bool = false) -> void:
	var actor := BeachTarget.new()
	add_child(actor)
	actor.setup(kind,at.x,rng,1.0,{"appearance":appearance,"food_id":"ice_cream"})
	actor.position = at
	actor.facing = -1 if left else 1
	actor.sprite.flip_h = left
	actor.sprite.play(clip)
	actor.sprite.pause()
	actor.sprite.frame = frame
	actor.food_sprite.visible = kind=="kiosk_customer" and clip in [&"idle",&"walk",&"windup",&"swat"]
	if kind=="kiosk_customer":
		BeachgoerArt.align_food(actor)

func _draw() -> void:
	draw_rect(Rect2(0,0,400,300),Color("a9d5ce"))
	draw_rect(Rect2(0,0,400,25),Color("183b4e"))
	var font: Font = ThemeDB.fallback_font
	draw_string(font,Vector2(9,17),"TWO NEW SHOPPERS / PRODUCTION ART",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("fff4da"))
	var labels: Array = [
		["DINER / STYLE","ORIGINAL SHOPPER","MULLET + CAP","FLORAL SUNDRESS"],
		["WALK","WALK","CHASE / LEFT","CHASE / LEFT"],
		["WINDUP","WINDUP","SWAT CONTACT","SWAT CONTACT"]
	]
	for row: int in 3:
		var baseline: int = [88,177,265][row]
		draw_rect(Rect2(0,baseline,400,24),Color("e5c68c"))
		for column: int in 4:
			var label: String = labels[row][column]
			var width: float = font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,6).x
			draw_string(font,Vector2(50+column*100-width/2,baseline+15),label,HORIZONTAL_ALIGNMENT_LEFT,-1,6,Color("183b4e"))

func _capture() -> void:
	for i: int in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png("res://assets/archive/previews/shopper-variants-production-v1.png")==OK)
	get_tree().quit()
