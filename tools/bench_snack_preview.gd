extends Node2D
var spawner := BeachSpawner.new()
var actors: Array[BeachTarget] = []
var gull: BeachGull
var elapsed: float = 0.0
var label := Label.new()

func _ready() -> void:
	Audio.music.stop()
	get_window().content_scale_size = Vector2i(640,280)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().size = Vector2i(1280,560)
	call_deferred("run")

func run() -> void:
	var props: Array = []
	var count: int = 1 if OS.get_cmdline_user_args().has("--yellow") else 3
	for row: int in count:
		for col: int in 2:
			props.append({"type":"beach_bench","x":170+col*300,"y":83+row*85})
	var backdrop := BeachBackdrop.new()
	add_child(backdrop)
	backdrop.setup(props)
	backdrop.visible = false
	# Show the production prop sprite geometry without the camera-sized backdrop drawing.
	for prop: AnimatedSprite2D in backdrop.prop_sprites:
		prop.reparent(self)
	spawner.setup(self,{"id":3,"seed":451,"awareness_mult":1.0,"props":props,"spawns":[]})
	for row: int in count:
		for col: int in 2:
			var bench_x: float = 170+col*300
			var actor := spawner.create("kiosk_customer",bench_x+(-48 if col==0 else 48),{"appearance":ShopperArt.APPEARANCES[row],"food_id":"ice_cream"})
			actor.position.y = 83+row*85
			actor.routine.bounds = Vector2(20,620)
			actor.bench_visit.consider(actor,true)
			actors.append(actor)
	gull = BeachGull.new()
	add_child(gull)
	gull.hide()
	gull.position = Vector2(550,50)
	gull.direction = Vector2.RIGHT
	gull.velocity = Vector2(180,-60)
	add_child(label)
	label.position = Vector2(12,8)
	label.add_theme_font_size_override("font_size",12)
	DirAccess.make_dir_recursive_absolute("res://test-output/bench-frames")
	for frame: int in 220:
		elapsed = frame*0.08
		spawner.reset_spacing()
		if frame == 83:
			for i: int in range(1,actors.size(),2):
				actors[i].take(gull)
		for actor: BeachTarget in actors:
			actor.tick(0.08,[])
		spawner.apply_spacing(0.08)
		label.text = "BENCH SNACK / natural rest left / theft then stand and chase right / %.1fs" % elapsed
		queue_redraw()
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var picture := get_viewport().get_texture().get_image()
		picture.save_png("res://test-output/bench-frames/%03d.png" % frame)
		if frame == 80:
			picture.save_png("res://assets/previews/bench-snack-yellow-proof-v1.png" if count == 1 else "res://assets/previews/bench-snack-v1.png")
	print("Bench preview captured 220 production simulation frames")
	get_tree().quit()

func _draw() -> void:
	draw_rect(Rect2(0,0,640,280),Color("abd6d0"))
	for row: int in 3:
		var y: float = 83+row*85
		draw_rect(Rect2(0,y,640,20),Color("e8c58e"))
