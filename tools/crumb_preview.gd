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
	verify(frames.get_frame_count(&"idle")==1,"Original crumb art restored")
	for index: int in 1:
		var image: Image = frames.get_frame_texture(&"idle",index).get_image()
		verify(image.get_size()==Vector2i(275,216) and image.get_used_rect().has_area(),"Original finer crumb art")
	for level: Dictionary in Config.levels:
		Config.apply_level_world(level)
		var scraps := BeachScraps.new()
		add_child(scraps)
		verify(not scraps.crumbs.is_empty(),"Every level has ground scraps")
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
	for frame: int in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://assets/previews/crumbs-beach-original-restored.png")
	print("Crumb checks: ",checks," passed across all six levels")
	get_tree().quit()
