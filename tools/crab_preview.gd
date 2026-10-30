extends Node2D
var game: BeachGame
var red: BeachCrab
var blue: BeachCrab

func _ready() -> void:
	GullInput.register_actions()
	Audio.music.stop()
	Config.tuning.juice.audio = false
	game = BeachGame.new()
	add_child(game)
	var level: Dictionary = Config.levels[2].duplicate(true)
	level.spawns = []
	level.rivals = []
	level.props = [{"type":"beach_palm","x":350,"y":148},{"type":"beach_lamp","x":610,"y":151}]
	level.zones = [{"name":"CRAB BEACH","from":320,"to":640}]
	level.crabs = {"enabled":false}
	game.setup(level,false)
	game.set_physics_process(false)
	game.set_process_unhandled_input(false)
	game.running = true
	game.intro = 0
	game.overlay.hide()
	game.camera_x = 480
	game.camera.position.x = 480
	game.beach.camera_x = 480
	game.player.position = Vector2(385,85)
	game.player.tick(0,0,0)
	red = game.crabs.spawn("sea",480)
	red.position.x = 420
	red.start.x = 420
	blue = game.crabs.spawn("right",480,true)
	call_deferred("capture")

func capture() -> void:
	var path: String = "res://test-output/crab-frames"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))
	for frame: int in 164:
		game.crabs.tick(0.05,480)
		if frame==36:
			game.player.state = BeachGull.State.GROUNDED
			game.player.facing = 1
			game.player.position = Vector2(red.position.x-float(Config.tuning.dive.beak_offset),game.player.ground_y())
			game._peck()
			game.crabs.spawn("left",480)
		if frame>=88 and frame<=98:
			game.player.state = BeachGull.State.STRIKE
			game.player.direction = Vector2(0.8,0.6)
			game.player.position = blue.food_position()-game.player.direction*(100-(frame-88)*9)
		elif frame==103:
			game.player.state = BeachGull.State.GLIDE
			game.player.position = Vector2(510,95)
		game.player.tick(0,0,0)
		if frame==98:
			game.player.peck_sweep_active = true
			game.player.grounded_sweep = false
			game.player.previous_beak = blue.food_position()-Vector2(18,12)
			game.player.sweep_beak = blue.food_position()+Vector2(18,12)
			BeachCollisions.resolve(game.player,game.crabs.targets,game.beach.props)
		game.score.tick(0.05)
		game.player.digestion.tick(0.05,game.player.state==BeachGull.State.GROUNDED)
		game.effects.tick(0.05)
		game.beach.tick(0.05)
		for refresh: int in 2:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var image: Image = get_viewport().get_texture().get_image()
		if frame==30:
			image.save_png("res://assets/archive/previews/crab-desktop-v3.png")
		image.resize(640,360,Image.INTERPOLATE_NEAREST)
		if frame==30:
			image.save_png("res://assets/archive/previews/crab-phone-v3.png")
		image.save_png(path+"/frame-%03d.png" % frame)
	print("Crab preview scored ",game.score.points," from ",game.score.items," catches")
	get_tree().quit()
