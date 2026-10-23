extends Node2D
const FONT = preload("res://assets/fonts/gull_pixel.fnt")
const CLIPS: Array[StringName] = [&"run",&"leap",&"catch",&"idle",&"sniff"]
var checks := 0
var failures := 0

func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func _ready() -> void:
	Audio.music.stop()
	get_window().content_scale_size = Vector2i(800,480)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().size = Vector2i(2000,1200)
	var frames := Config.frames("off_lead_dog")
	preload("res://tests/isolated_sprite_checks.gd").run(Callable(self,"check"),frames,"off-lead terrier")
	var image: Image = frames.get_frame_texture(&"idle",0).atlas.get_image()
	var hard_alpha := true
	var pixels := image.get_data()
	for offset: int in range(3,pixels.size(),4):
		if pixels[offset] not in [0,255]:
			hard_alpha = false
	check(hard_alpha and image.get_mipmap_count()==0,"Hard alpha without mipmaps")
	check(frames.get_frame_count(&"bite")==6,"Bite alias is ready for the chase controller")
	var rng := RandomNumberGenerator.new()
	var owner := BeachTarget.new()
	add_child(owner)
	owner.setup("dog_owner",72,rng,1.0)
	owner.position = Vector2(72,100)
	owner.sprite.play(&"idle")
	owner.sprite.pause()
	owner.food_sprite.visible = false
	_dog(Vector2(240,100),&"idle",0)
	for row: int in CLIPS.size():
		var clip := CLIPS[row]
		check(frames.get_frame_count(clip)==6,"Six frames for "+String(clip))
		for frame: int in 6:
			_dog(Vector2(120+frame*120,165+row*57),clip,frame)
	for i: int in 5:
		_dog(Vector2(120+i*144,455),CLIPS[i],2,true)
	queue_redraw()
	call_deferred("_capture")

func _dog(at: Vector2,clip: StringName,frame: int,left: bool = false) -> void:
	var sprite := AnimatedSprite2D.new()
	add_child(sprite)
	sprite.sprite_frames = Config.frames("off_lead_dog")
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE*float(Config.sprites.off_lead_dog.visual_scale)
	sprite.position = at+Vector2(0,float(Config.sprites.off_lead_dog.sprite_offset_y))
	sprite.flip_h = left
	sprite.play(clip)
	sprite.pause()
	sprite.frame = frame

func _draw() -> void:
	draw_rect(Rect2(0,0,800,480),Color("a9d5ce"))
	draw_rect(Rect2(0,0,800,30),Color("183b4e"))
	draw_string(FONT,Vector2(12,21),"OFF-LEAD TERRIER / SAME PIXEL CAST",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("fff4da"))
	draw_rect(Rect2(0,100,800,24),Color("e5c68c"))
	draw_string(FONT,Vector2(12,116),"WALKER + LEASHED DOG",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("183b4e"))
	draw_string(FONT,Vector2(180,116),"OFF-LEAD / IDLE",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("183b4e"))
	draw_string(FONT,Vector2(370,67),"SAME SANDY TERRIER + TEAL COLLAR",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("183b4e"))
	draw_string(FONT,Vector2(370,83),"16PX DOG / 40PX ADULT / 30 DRAWN POSES",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("183b4e"))
	for row: int in 5:
		var baseline := 165+row*57
		draw_rect(Rect2(0,baseline,800,19),Color("e5c68c"))
		var name := "CATCH / BITE" if row==2 else String(CLIPS[row]).to_upper()
		draw_string(FONT,Vector2(8,baseline+12),name,HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("183b4e"))
		for frame: int in 6:
			draw_string(FONT,Vector2(120+frame*120,baseline+12),str(frame+1),HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("183b4e"))
	draw_rect(Rect2(0,455,800,25),Color("e5c68c"))
	draw_string(FONT,Vector2(8,470),"LEFT",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("183b4e"))
	for i: int in 5:
		draw_string(FONT,Vector2(94+i*144,470),String(CLIPS[i]).to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("183b4e"))

func _capture() -> void:
	for i: int in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	check(get_viewport().get_texture().get_image().save_png("res://assets/previews/off-lead-dog-production-v1.png")==OK,"Save preview")
	print("OFF-LEAD ART: %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)
