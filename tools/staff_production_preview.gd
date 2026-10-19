extends Node2D
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	get_window().content_scale_size = Vector2i(400,320)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().size = Vector2i(1600,1280)
	rng.seed = 19
	var rows := [
		[["pier_diner","idle",0],["picnic_family","idle",0],["kiosk_customer","idle",0],["lifeguard","idle",0]],
		[["kiosk_customer","walk",2],["kiosk_customer","run",2],["lifeguard","walk",1],["lifeguard","run",2]],
		[["kiosk_customer","warning",0],["kiosk_customer","angry",0],["lifeguard","whistle",0],["lifeguard","whistle",1]],
		[["kiosk_customer","windup",1],["kiosk_customer","swat",2],["lifeguard","windup",1],["lifeguard","swat",2]]
	]
	for row: int in rows.size():
		for column: int in 4:
			var item: Array = rows[row][column]
			var at := Vector2(50+column*100,82+row*72)
			var actor := BeachTarget.new()
			add_child(actor)
			actor.setup(item[0],at.x,rng,1.0,{"food_id":"ice_cream"})
			actor.position = at
			actor.sprite.play(StringName(item[1]))
			actor.sprite.pause()
			actor.sprite.frame = item[2]
			actor.food_sprite.visible = actor.kind=="kiosk_customer" and item[1] not in ["run","angry"]
			if actor.kind=="kiosk_customer":
				BeachgoerArt.align_food(actor)
	queue_redraw()
	call_deferred("_capture")

func _draw() -> void:
	draw_rect(Rect2(0,0,400,320),Color("a9d5ce"))
	draw_rect(Rect2(0,0,400,24),Color("183b4e"))
	var font := ThemeDB.fallback_font
	draw_string(font,Vector2(8,16),"SHOPPER + LIFEGUARD / PRODUCTION ART",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("fff4da"))
	var labels := [
		["DINER","MUM","NEW SHOPPER","LIFEGUARD"],
		["WALK","CHASE","PATROL","CHASE"],
		["WARNING","THEFT REACTION","WHISTLE EVENT","WHISTLE / WAVE"],
		["ANTICIPATION","SWAT CONTACT","ANTICIPATION","SWAT CONTACT"]
	]
	for row: int in 4:
		var baseline := 82+row*72
		draw_rect(Rect2(0,baseline,400,23),Color("e5c68c"))
		for column: int in 4:
			var text: String = labels[row][column]
			var width := font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,6).x
			draw_string(font,Vector2(50+column*100-width/2,baseline+15),text,HORIZONTAL_ALIGNMENT_LEFT,-1,6,Color("183b4e"))

func _capture() -> void:
	for i: int in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png("res://assets/previews/shopper-lifeguard-production-v1.png")==OK)
	get_tree().quit()
