extends Node2D
var game: BeachGame
var collected: int = 0
var checks: int = 0

func verify(ok: bool, message: String) -> void:
	checks += 1
	assert(ok,message)

func _ready() -> void:
	GullInput.register_actions()
	Audio.music.stop()
	var frames: SpriteFrames = Config.frames("food_crumbs")
	verify(frames.get_frame_count(&"idle")==3,"Three crumb art variants")
	for index: int in 3:
		var image: Image = frames.get_frame_texture(&"idle",index).get_image()
		verify(image.get_size()==Vector2i(5,3) and image.get_used_rect().has_area(),"Native chunky crumb art")
	for level: Dictionary in Config.levels:
		Config.apply_level_world(level)
		var scraps := BeachScraps.new()
		add_child(scraps)
		var variants: Dictionary = {}
		for crumb: Dictionary in scraps.crumbs:
			if crumb.food_id == "crumbs":
				variants[crumb.variant] = true
		verify(variants.size()==3,"Every level uses all three varieties")
		var gull := BeachGull.new()
		add_child(gull)
		gull.state = BeachGull.State.GROUNDED
		gull.position = Vector2(float(scraps.crumbs[0].x)-float(Config.tuning.dive.beak_offset),gull.ground_y())
		scraps.collected.connect(func(_at: Vector2,food_id: String) -> void:
			verify(food_id=="crumbs","Pickup retains crumb food identity")
			collected += 1)
		var before: int = collected
		scraps.tick(0,gull)
		verify(collected==before+1,"Crumb collected normally")
		scraps.tick(0,gull)
		verify(collected==before+1,"Collected crumb cannot be collected twice")
		scraps.tick(float(Config.tuning.world.scrap_respawn),gull)
		scraps.tick(0,gull)
		verify(collected==before+2,"Crumb respawns normally")
		scraps.queue_free()
		gull.queue_free()
		await get_tree().process_frame
	verify(int(Config.foods.crumbs.points)==5,"Crumb score unchanged")
	game = BeachGame.new()
	add_child(game)
	game.setup(Config.levels[2].duplicate(true),false)
	game.set_physics_process(false)
	game.overlay.hide()
	game.player.position = Vector2(120,65)
	var image := Image.load_from_file("res://assets/sprites/food-crumbs-retro-v2.png")
	image.resize(480,96,Image.INTERPOLATE_NEAREST)
	var review := Image.create(480,96,false,Image.FORMAT_RGBA8)
	review.fill(Color("183b4e"))
	review.blend_rect(image,Rect2i(0,0,480,96),Vector2i.ZERO)
	review.save_png("res://assets/previews/crumb-varieties-v2.png")
	for frame: int in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://assets/previews/crumbs-beach-v2.png")
	print("Crumb checks: ",checks," passed across all six levels")
	get_tree().quit()
