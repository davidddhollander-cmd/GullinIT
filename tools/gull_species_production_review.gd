extends Node2D
const IDS := ["gull_herring","gull_kittiwake","gull_great_black_backed"]
const NAMES := ["HERRING / CHIP THIEF","KITTIWAKE / SEA DART","GREAT BLACK-BACKED / BRUISER"]
const CLIPS := [&"idle",&"walk",&"climb",&"dive"]
var sprites: Array[AnimatedSprite2D] = []

func _ready() -> void:
	get_window().content_scale_size = Vector2i(480,410)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().size = Vector2i(1440,1230)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for row: int in 3:
		for col: int in 4:
			var actor := AnimatedSprite2D.new()
			actor.sprite_frames = Config.frames(IDS[row])
			actor.animation = CLIPS[col]
			actor.position = Vector2(106+col*112,110+row*90)
			actor.scale = Vector2.ONE
			add_child(actor)
			sprites.append(actor)
		var small := AnimatedSprite2D.new()
		small.sprite_frames = Config.frames(IDS[row])
		small.animation = &"idle"
		small.position = Vector2(150+row*135,380)
		small.scale = Vector2.ONE*.5
		add_child(small)
	call_deferred("_capture")

func _draw() -> void:
	draw_rect(Rect2(0,0,480,410),Color("a9d5ce"))
	draw_rect(Rect2(0,0,480,30),Color("183b4e"))
	var font := ThemeDB.fallback_font
	draw_string(font,Vector2(12,20),"APPROVED GULLS / PRODUCTION ANIMATION",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("fff4da"))
	for col: int in 4:
		draw_string(font,Vector2(72+col*112,47),["STAND","WALK","WINGBEAT","DIVE"][col],HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("183b4e"))
	for row: int in 3:
		draw_rect(Rect2(0,122+row*90,480,24),Color("e5c68c"))
		draw_string(font,Vector2(12,139+row*90),NAMES[row],HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("183b4e"))
	draw_rect(Rect2(0,386,480,24),Color("e5c68c"))
	draw_string(font,Vector2(12,354),"GAME SIZE",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("183b4e"))
	draw_string(font,Vector2(12,369),"22 / 17 / 28 PX",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("183b4e"))
	draw_string(font,Vector2(12,402),"ABOVE: 2X GAME SIZE   /   BELOW: ACTUAL SIZE",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("183b4e"))

func _capture() -> void:
	for frame: int in 24:
		for index: int in sprites.size():
			var actor := sprites[index]
			var count := actor.sprite_frames.get_frame_count(actor.animation)
			actor.frame = frame%count
		for settle: int in 3:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		image.save_png("res://test-output/gull-production-%02d.png"%frame)
		if frame==0:
			image.save_png("res://assets/archive/previews/gull-species-production-v1.png")
	# Release the autoload's music playback before closing this short review run.
	for player: Node in Audio.get_children():
		if player is AudioStreamPlayer:
			player.stop()
	await get_tree().create_timer(.1).timeout
	get_tree().quit()
