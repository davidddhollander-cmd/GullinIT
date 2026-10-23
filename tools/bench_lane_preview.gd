extends Node2D
var groups: Array[BeachSpawner] = []

func _ready() -> void:
	Audio.music.stop()
	get_window().content_scale_size = Vector2i(320,200)
	get_window().size = Vector2i(1280,800)
	call_deferred("run")

func run() -> void:
	for row: int in 2:
		var base: float = 78+row*86
		var props: Array = [{"type":"beach_bench","x":160,"y":base}]
		var backdrop := BeachBackdrop.new()
		add_child(backdrop)
		backdrop.setup(props)
		backdrop.hide()
		for prop: AnimatedSprite2D in backdrop.prop_sprites:
			prop.reparent(self)
		var spawner := BeachSpawner.new()
		spawner.setup(self,{"id":3,"seed":42,"awareness_mult":1.0,"props":props,"spawns":[]})
		var holder := spawner.create("kiosk_customer",160,{"appearance":"kiosk_customer","food_id":"ice_cream"})
		holder.position.y = base+7
		if row == 1:
			holder.position.y = base
			holder.bench_visit.seat = spawner.benches.reserve(holder,Vector2(0,320))
			holder.bench_visit.phase = BenchVisit.Phase.REST
			holder.update_art_pose(false)
		var walker := spawner.create("kiosk_customer",112,{"appearance":"shopper_sundress","food_id":"ice_cream"})
		walker.position.y = base+7
		groups.append(spawner)
	for row: int in 2:
		var title := Label.new()
		title.text = "EMPTY BENCH / WALKERS PASS IN FRONT" if row == 0 else "OCCUPIED BENCH / SEAT STAYS ANCHORED"
		title.add_theme_font_override("font",preload("res://assets/fonts/gull_pixel.fnt"))
		title.add_theme_font_size_override("font_size",8)
		title.position = Vector2(6,6+row*96)
		add_child(title)
	for frame: int in 100:
		for row: int in groups.size():
			var spawner: BeachSpawner = groups[row]
			spawner.reset_spacing()
			var walker: BeachTarget = spawner.targets[1]
			walker.position.x = 110+frame if row == 0 else 210-frame
			walker.facing = 1 if row == 0 else -1
			walker.update_art_pose(true)
			spawner.apply_spacing(1.0/60.0)
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		if frame in [28,50,72]:
			get_viewport().get_texture().get_image().save_png("res://assets/previews/bench-lanes-%02d.png" % frame)
	get_tree().quit()

func _draw() -> void:
	draw_rect(Rect2(0,0,320,200),Color("abd6d0"))
	for base: float in [78,164]:
		draw_rect(Rect2(0,base+1,320,15),Color("e8c58e"))
