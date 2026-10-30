extends Node2D
## Review scene only: current and generated walks at identical game speeds.
const Motion = preload("res://tools/walk_pilot_motion.gd")
const Rig = preload("res://tools/walk_pilot_rig.gd")
var rig_metadata: Dictionary
var rigs: Array[Node2D] = []
var sprites: Array[AnimatedSprite2D] = []
var snacks: Array[Sprite2D] = []
var motions: Array = []
var clock: float = 0
var paused: bool = false
var recording: bool = false
var font: Font = preload("res://assets/fonts/gull_pixel.fnt")
const BASELINES := [90.0,166.0,243.0]
const SPEEDS := [0.0,9.0,20.0]
const DURATION: float = 6.4

func _ready() -> void:
	Audio.music.stop()
	get_window().content_scale_size = Vector2i(320,300)
	get_window().size = Vector2i(640,600)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	rig_metadata = JSON.parse_string(FileAccess.get_file_as_string("res://assets/archive/pilots/shopper-walk-v1/rig.json"))
	for row: int in 3:
		var motion := Motion.new()
		motion.stride = float(rig_metadata.stride_pixels)
		motions.append(motion)
		for column: int in 2:
			var actor := AnimatedSprite2D.new()
			actor.sprite_frames = Config.frames("kiosk_customer")
			actor.animation = &"walk"
			actor.scale = Vector2.ONE*0.5
			actor.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			add_child(actor)
			sprites.append(actor)
			var snack := Sprite2D.new()
			snack.texture = Config.frames("food_ice_cream").get_frame_texture(&"idle",0)
			snack.scale = Vector2(Config.foods.ice_cream.size[0],Config.foods.ice_cream.size[1])/snack.texture.get_size()
			snack.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			add_child(snack)
			snacks.append(snack)
			if column==1:
				actor.hide()
				var rig := Rig.new()
				add_child(rig)
				rig.setup(rig_metadata)
				rigs.append(rig)
				snack.z_index = 3
	recording = OS.get_cmdline_user_args().has("--record-pilot")
	pose(0)
	if recording:
		set_process(false)
		call_deferred("capture")

func _process(delta: float) -> void:
	if paused:
		return
	advance(delta)
	pose(clock)

func advance(delta: float) -> void:
	clock += delta
	for row: int in 3:
		# In-place row demonstrates the nominal eight-pose loop at eight fps.
		motions[row].advance_distance((float(rig_metadata.stride_pixels) if row==0 else SPEEDS[row])*delta)

func pose(time: float) -> void:
	var loop: float = fposmod(time,DURATION)
	var facing: float = 1 if loop<DURATION*0.5 else -1
	var travel_time: float = loop if facing>0 else DURATION-loop
	for row: int in 3:
		for column: int in 2:
			var index: int = row*2+column
			var root := Vector2(80+column*160 if row==0 else 40+column*160+SPEEDS[row]*travel_time,BASELINES[row])
			if column==1:
				var rig: Node2D = rigs[row]
				rig.position = root
				rig.pose(motions[row].phase,facing)
				snacks[index].position = root+Vector2(rig.palm.x*facing,rig.palm.y-float(Config.foods.ice_cream.size[1])*0.5)
				continue
			var actor: AnimatedSprite2D = sprites[index]
			actor.position = root+Vector2(0,-26)
			actor.flip_h = facing<0
			actor.frame = int(time*8)%6
			var anchor: Array = Config.sprites.kiosk_customer.food_anchors.walk[actor.frame]
			var food_at := Vector2(float(anchor[0])*facing,float(anchor[1]))
			snacks[index].position = root+food_at
	queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		paused = not paused
	elif event is InputEventKey and event.pressed and event.keycode==KEY_R:
		clock = 0
		for motion: RefCounted in motions:
			motion.phase = 0
		pose(0)

func _draw() -> void:
	draw_rect(Rect2(0,0,320,300),Color("a9d7d2"))
	draw_rect(Rect2(0,0,320,21),Color("183b4e"))
	draw_string(font,Vector2(32,14),"SHOPPER WALK / MOTION PILOT",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("fff4da"))
	draw_string(font,Vector2(48,34),"CURRENT",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("183b4e"))
	draw_string(font,Vector2(220,34),"PILOT",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("183b4e"))
	draw_line(Vector2(160,23),Vector2(160,260),Color("408fa8"),1)
	for row: int in 3:
		var label: String = ["IN PLACE / NOMINAL CYCLE","PATROL / 9 PIXELS PER SECOND","KIOSK / 20 PIXELS PER SECOND"][row]
		var ground: float = BASELINES[row]
		draw_rect(Rect2(0,ground,320,13),Color("e8c58e"))
		draw_line(Vector2(0,ground),Vector2(320,ground),Color("aa7047"),1)
		for x: int in range(8,320,16):
			draw_rect(Rect2(x,ground+5,2,1),Color("aa7047"))
		draw_string(font,Vector2(8,ground-45),label,HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("183b4e"))
	draw_string(font,Vector2(8,278),"TURNS LEFT / FOOD FOLLOWS HAND",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("183b4e"))
	draw_string(font,Vector2(8,293),"SPACE: PAUSE   R: REPLAY",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("183b4e"))

func capture() -> void:
	DirAccess.make_dir_recursive_absolute("res://test-output/walk-pilot-frames")
	for index: int in 128:
		if index>0:
			advance(0.05)
		pose(clock)
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var frame := get_viewport().get_texture().get_image()
		frame.save_png("res://test-output/walk-pilot-frames/%03d.png" % index)
		if index in [8,38,78]:
			frame.save_png("res://assets/previews/shopper-walk-pilot-%03d.png" % index)
	print("WALK PILOT: captured 128 frames, in-place/patrol/trip, both directions and separate food")
	# Bake eight key poses from the generated artwork for static pose review.
	var review := SubViewport.new()
	review.size = Vector2i(512,256)
	review.transparent_bg = true
	review.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(review)
	var source_scale := Node2D.new()
	source_scale.scale = Vector2.ONE*2
	review.add_child(source_scale)
	for index: int in 8:
		var rig := Rig.new()
		source_scale.add_child(rig)
		rig.setup(rig_metadata)
		rig.position = Vector2(32+index%4*64,58+index/4*64)
		rig.pose(float(index)/8,1)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	review.get_texture().get_image().save_png("res://assets/archive/pilots/shopper-walk-v1/rig-poses.png")
	for audio_player: Node in Audio.get_children():
		if audio_player is AudioStreamPlayer:
			audio_player.stop()
	await get_tree().create_timer(0.05).timeout
	get_tree().quit()
