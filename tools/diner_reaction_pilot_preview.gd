extends Node2D
var rng := RandomNumberGenerator.new()
const STAGES: Array[Dictionary] = [
	{"clip":&"surprise","frame":1,"label":"EMPTY HAND"},
	{"clip":&"surprise","frame":3,"label":"RECOIL"},
	{"clip":&"run","frame":3,"label":"CHASE"},
	{"clip":&"fist_shake","frame":0,"label":"SHAKE 1"},
	{"clip":&"fist_shake","frame":1,"label":"SHAKE 2"},
	{"clip":&"idle","frame":0,"label":"RESUME"},
]

func _ready() -> void:
	Audio.music.stop()
	get_window().content_scale_size = Vector2i(480,270)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().size = Vector2i(1920,1080)
	rng.seed = 21
	for row: int in 2:
		for column: int in STAGES.size():
			var stage: Dictionary = STAGES[column]
			_pose(Vector2(42+column*79,72+row*60),stage.clip,int(stage.frame),row==1,1.0)
	_pose(Vector2(66,262),&"surprise",1,false,2.0)
	_pose(Vector2(182,262),&"surprise",3,true,2.0)
	_pose(Vector2(298,262),&"fist_shake",0,false,2.0)
	_pose(Vector2(414,262),&"fist_shake",1,true,2.0)
	queue_redraw()
	call_deferred("_capture")

func _pose(at: Vector2,clip: StringName,frame: int,left: bool,scale_multiplier: float) -> void:
	var actor := BeachTarget.new()
	add_child(actor)
	actor.setup("pier_diner",at.x,rng,1.0,{"food_id":"fish_chips"})
	actor.position = at
	actor.food = false
	actor.food_sprite.hide()
	actor.facing = -1.0 if left else 1.0
	actor.sprite.flip_h = left
	actor.sprite.play(clip)
	actor.sprite.pause()
	actor.sprite.frame = frame
	actor.sprite.scale *= scale_multiplier
	actor.sprite.position.y *= scale_multiplier

func _draw() -> void:
	draw_rect(Rect2(0,0,480,270),Color("a9d5ce"))
	draw_rect(Rect2(0,0,480,24),Color("183b4e"))
	var font: Font = ThemeDB.fallback_font
	draw_string(font,Vector2(10,17),"PIER DINER / THEFT REACTION PILOT",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("fff4da"))
	draw_string(font,Vector2(8,34),"ACTUAL GAMEPLAY SCALE / ESCAPE RIGHT",HORIZONTAL_ALIGNMENT_LEFT,-1,6,Color("183b4e"))
	draw_string(font,Vector2(8,94),"ACTUAL GAMEPLAY SCALE / ESCAPE LEFT",HORIZONTAL_ALIGNMENT_LEFT,-1,6,Color("183b4e"))
	for row: int in 2:
		var baseline: float = 72+row*60
		draw_rect(Rect2(0,baseline,480,16),Color("e5c68c"))
		for column: int in STAGES.size():
			var label: String = str(STAGES[column].label)
			var center: float = 42+column*79
			var width: float = font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,5).x
			draw_string(font,Vector2(center-width*0.5,baseline+11),label,HORIZONTAL_ALIGNMENT_LEFT,-1,5,Color("183b4e"))
			if column < STAGES.size()-1:
				draw_line(Vector2(center+25,baseline-24),Vector2(center+48,baseline-24),Color("28667b"),1.0)
	draw_rect(Rect2(0,153,480,117),Color("8fc6c2"))
	draw_rect(Rect2(0,153,480,18),Color("28667b"))
	draw_string(font,Vector2(10,166),"2X POSE INSPECTION / EMPTY HAND + RECOIL / TWO SHAKE PEAKS",HORIZONTAL_ALIGNMENT_LEFT,-1,7,Color("fff4da"))
	for item: Array in [[66,"EMPTY HAND"],[182,"RECOIL L"],[298,"SHAKE LOW"],[414,"SHAKE HIGH"]]:
		var label: String = str(item[1])
		var width: float = font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,6).x
		draw_string(font,Vector2(float(item[0])-width*0.5,181),label,HORIZONTAL_ALIGNMENT_LEFT,-1,6,Color("183b4e"))

func _capture() -> void:
	for i: int in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png("res://assets/previews/diner-reaction-pilot-v1.png")==OK)
	get_tree().quit()
