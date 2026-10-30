extends Node2D
## Fixed-rate visual review using actual shopper sprites and food anchors.
var actors: Array[BeachTarget] = []
var legs: Array[Sprite2D] = []
var font: Font = preload("res://assets/fonts/gull_pixel.fnt")

func _ready() -> void:
	Audio.music.stop()
	get_window().content_scale_size = Vector2i(360,270)
	get_window().size = Vector2i(1080,810)
	var old: Dictionary = Config.sprites.shopper_sundress.duplicate(true)
	old.file = "res://assets/archive/sprites/shopper-sundress-diner-style.png"
	var old_anchors: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/reference/sundress-walk-v2/previous-entry.json")).food_anchors.walk
	old.food_anchors.walk = old_anchors
	Config.sprites.sundress_previous = old
	Config.sprites.shopper_sundress = JSON.parse_string(FileAccess.get_file_as_string("res://data/sundress_walk_v2.json")).shopper_sundress
	Config.frames_cache.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 17
	for i: int in 5:
		var actor := BeachTarget.new()
		add_child(actor)
		var appearance: String = "kiosk_customer" if i==0 else "shopper_sundress"
		actor.setup("kiosk_customer",60+i%3*120,rng,1,{"appearance":appearance,"food_id":"ice_cream"})
		actor.position = Vector2(60+i*120,96) if i<3 else Vector2(90+(i-3)*180,244)
		if i==1:
			actor.info.sprite = "sundress_previous"
			actor.sprite.sprite_frames = Config.frames("sundress_previous")
		actor.facing = -1 if i==4 else 1
		if i>=3:
			actor.patrol_home = actor.position.x+actor.facing*35
			actor.patrol_radius = 12
		actor.update_art_pose(true)
		actor.sprite.pause()
		actors.append(actor)
		if i<3:
			var inset := Sprite2D.new()
			inset.position = Vector2(60+i*120,157)
			inset.scale = Vector2.ONE*1.5
			inset.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			add_child(inset)
			legs.append(inset)
	queue_redraw()
	call_deferred("capture")

func _draw() -> void:
	draw_rect(Rect2(0,0,360,270),Color("a9d7d2"))
	draw_rect(Rect2(0,0,360,24),Color("183b4e"))
	draw_string(font,Vector2(8,16),"OLDER WOMAN / WALK COMPARISON",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("fff4da"))
	for i: int in 3:
		draw_string(font,Vector2(20+i*120,43),["ORIGINAL","PREVIOUS LADY","NEW LADY"][i],HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("183b4e"))
	for y: int in [96,174,244]:
		draw_rect(Rect2(0,y,360,5),Color("e8c58e"))
	draw_string(font,Vector2(8,122),"LOWER LEGS / ENLARGED",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("183b4e"))
	draw_string(font,Vector2(8,198),"PATROL RETURN / BOTH DIRECTIONS",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("183b4e"))
	draw_string(font,Vector2(8,264),"6 FULL DRAWN POSES / 8 FPS / 40 PX",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("183b4e"))

func capture() -> void:
	DirAccess.make_dir_recursive_absolute("res://test-output/sundress-walk-frames")
	for sample: int in 36:
		var index: int = sample/3%6
		for i: int in actors.size():
			var actor := actors[i]
			actor.sprite.frame = index
			BeachgoerArt.align_food(actor)
			if i>=3:
				actor.tick(1.0/24.0,[])
				actor.sprite.pause()
				actor.sprite.frame = index
				BeachgoerArt.align_food(actor)
			else:
				var full := actor.sprite.sprite_frames.get_frame_texture(&"walk",index) as AtlasTexture
				var inset := AtlasTexture.new()
				inset.atlas = full.atlas
				inset.region = Rect2(full.region.position+Vector2(28,94),Vector2(72,22))
				legs[i].texture = inset
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://test-output/sundress-walk-frames/%03d.png" % sample)
		if sample==6:
			get_viewport().get_texture().get_image().save_png("res://assets/previews/sundress-walk-v2.png")
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()
