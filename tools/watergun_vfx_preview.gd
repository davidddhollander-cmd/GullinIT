extends Node2D
## Real level composition using the runtime shot and one-shot effect methods.

func _ready() -> void:
	GullInput.register_actions()
	Audio.stop_all()
	Config.tuning.juice.audio = false
	var game := BeachGame.new()
	add_child(game)
	var level: Dictionary = Config.levels[3].duplicate(true)
	level.rivals = []
	game.setup(level,false)
	game.set_physics_process(false)
	game.set_process_unhandled_input(false)
	game.running = true
	game.intro = 0.0
	game.overlay.hide()

	var teen: WatergunTeen = game.teens[0]
	teen.position = Vector2(640.0,float(Config.tuning.world.ground))
	teen.facing = 1.0
	teen.state = WatergunTeen.State.FIRE
	teen.aim_clip = &"shoot_level"
	teen._animate(&"idle")
	game.player.position = Vector2(730.0,teen.muzzle_level_y())
	game.player.velocity = Vector2.ZERO
	game.player.state = BeachGull.State.GLIDE
	teen.target = game.player
	teen._fire()

	var shot: BeachWaterShot = teen.shots[0]
	var muzzle: AnimatedSprite2D = game.effects.water_muzzle(teen.muzzle(),Vector2.RIGHT)
	var splash: AnimatedSprite2D = game.effects.water_splash(teen.muzzle()+Vector2(72.0,4.0))
	shot.position = teen.muzzle()+Vector2(34.0,0.0)
	shot.stream.frame = 1
	shot.stream.pause()
	muzzle.frame = 1
	muzzle.pause()
	splash.frame = 2
	splash.pause()

	game.camera_x = teen.position.x
	game.camera.position = Vector2(teen.position.x,90.0)
	game.beach.camera_x = teen.position.x
	call_deferred("_capture")

func _capture() -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	assert(image.save_png("res://assets/previews/watergun-teen-v1/watergun-vfx-v1-game.png") == OK)
	get_tree().quit()
