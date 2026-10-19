extends Node2D
## Frozen production sprites at their actual presentation scale, with the diner reference.
var captions: Array = []
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	get_window().content_scale_size = Vector2i(400,240)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().size = Vector2i(1600,960)
	rng.seed = 19
	var variants: Array = ["mum","male_red","male_blue","female_red","female_blue","diner"]
	for row: int in 3:
		for column: int in variants.size():
			var id: String = variants[column]
			var x := 34+column*66
			var baseline := 77+row*70
			var actor := BeachTarget.new()
			add_child(actor)
			actor.setup("picnic_family" if id=="mum" else ("pier_diner" if id=="diner" else "sunbather"),float(x),rng,1.0,{"appearance":id})
			actor.position = Vector2(x,baseline)
			var clip: StringName = &"idle" if row==0 else (&"walk" if row==1 else &"swat")
			actor.sprite.play(clip)
			actor.sprite.pause()
			actor.sprite.frame = 0 if row==0 or id=="diner" else mini(1 if row==1 else 3,actor.sprite.sprite_frames.get_frame_count(clip)-1)
			actor.sprite.reparent(self)
			actor.hide()
			if row==0:
				captions.append({"x":x,"text":id.replace("_"," ").to_upper()})
	queue_redraw()
	call_deferred("_capture")

func _draw() -> void:
	draw_rect(Rect2(0,0,400,240),Color("a9d5ce"))
	draw_rect(Rect2(0,0,400,20),Color("183b4e"))
	var font := ThemeDB.fallback_font
	draw_string(font,Vector2(6,14),"APPROVED ADULT CAST / PRODUCTION ART",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("fff4da"))
	for row: int in 3:
		var baseline := 77+row*70
		draw_rect(Rect2(0,baseline,400,20),Color("e5c68c"))
		draw_string(font,Vector2(6,32+row*70),["IDLE / DINER REFERENCE AT RIGHT","WALK / SAME ON-SCREEN HEIGHT","SWAT CONTACT / SEPARATE GAMEPLAY TIMING"][row],HORIZONTAL_ALIGNMENT_LEFT,-1,7,Color("183b4e"))
	for caption: Dictionary in captions:
		var width := font.get_string_size(caption.text,HORIZONTAL_ALIGNMENT_LEFT,-1,6).x
		draw_string(font,Vector2(caption.x-width/2,89),caption.text,HORIZONTAL_ALIGNMENT_LEFT,-1,6,Color("183b4e"))

func _capture() -> void:
	for i: int in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png("res://assets/previews/adult-diner-production-cast-v1.png")==OK)
	get_tree().quit()
