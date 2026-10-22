extends Node2D
## Staged real-game habitat/catch review using supplied character artwork.
var game: BeachGame
var crab: BeachCrab

func _ready() -> void:
	GullInput.register_actions()
	Audio.music.stop()
	Config.tuning.juice.audio = false
	game = BeachGame.new()
	add_child(game)
	var level: Dictionary = Config.levels[2].duplicate(true)
	level.world = {"width":1280,"promenade_start":640,"pier_start":960,"start_x":50,"start_y":70}
	level.spawns = [{"type":"sunbather","x":270,"appearance":"female_blue"}]
	level.props = [{"type":"beach_palm","x":40,"y":148}]
	level.zones = [{"name":"QUIET BEACH","from":0,"to":640}]
	level.rivals = []
	level.crabs = {"enabled":false}
	game.setup(level,false)
	game.set_physics_process(false)
	game.set_process_unhandled_input(false)
	game.running = true
	game.intro = 0
	game.overlay.hide()
	game.camera_x = 160
	game.camera.position.x = 160
	game.beach.camera_x = 160
	game.player.position = Vector2(50,70)
	call_deferred("capture")

func step(delta: float) -> void:
	game.crabs.tick(delta,160,true,game.gulls)
	game.player.tick(0,0,0)
	game.player.digestion.tick(delta,game.player.state==BeachGull.State.GROUNDED)
	game.score.tick(delta)
	game.effects.tick(delta)
	game.beach.tick(delta)

func shot(label: String) -> void:
	for frame: int in 2:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var capture_image: Image = get_viewport().get_texture().get_image()
	capture_image.save_png("res://test-output/crab-habitat-"+label+".png")
	capture_image.resize(640,360,Image.INTERPOLATE_NEAREST)
	capture_image.save_png("res://test-output/crab-habitat-"+label+"-phone.png")
	if is_instance_valid(crab):
		print(label," crab=",crab.position," phase=",crab.phase," activity=",crab.activity)
	else:
		print(label," collected")

func capture() -> void:
	crab = game.crabs.spawn("sea",160)
	step(0.4)
	await shot("arrival")
	step(0.61)
	await shot("rear-lane")
	for frame: int in 180:
		step(0.05)
		if crab.position.y==crab.front_y:
			break
	await shot("front-lane")
	game.player.state = BeachGull.State.GROUNDED
	game.player.facing = 1
	game.player.position = Vector2(crab.position.x-float(Config.tuning.dive.beak_offset),game.player.ground_y())
	game._peck()
	await shot("ground-catch")
	game.player.digestion.tick(5.1,false)
	game.player.state = BeachGull.State.GLIDE
	game.player.position = Vector2(50,70)
	crab = game.crabs.spawn("sea",160,true)
	step(1.01)
	var side: float = -1.0 if crab.home_bounds.y-crab.position.x>crab.position.x-crab.home_bounds.x else 1.0
	game.player.position = Vector2(crab.position.x+side*20.0,140)
	step(0.05)
	await shot("notice")
	for frame: int in 6:
		step(0.05)
	step(0.15)
	await shot("escape")
	for frame: int in 60:
		game.player.position = Vector2(crab.position.x+side*10.0,140)
		step(0.05)
		if crab.phase==BeachCrab.Phase.EXIT:
			break
	step(0.25)
	await shot("retreat")
	step(0.5)
	game.player.position = Vector2(50,70)
	crab = game.crabs.spawn("sea",160,true)
	step(1.01)
	game.player.state = BeachGull.State.STRIKE
	game.player.sweep_state = BeachGull.State.STRIKE
	game.player.peck_sweep_active = true
	game.player.grounded_sweep = false
	game.player.direction = Vector2(0.8,0.6)
	game.player.position = crab.food_position()-game.player.direction*float(Config.tuning.dive.beak_offset)
	game.player.previous_beak = crab.food_position()-Vector2(20,15)
	game.player.sweep_beak = crab.food_position()+Vector2(20,15)
	BeachCollisions.resolve(game.player,game.crabs.targets,game.beach.props)
	await shot("dive-catch")
	game.player.digestion.tick(3.1,false)
	print("Habitat preview: ",game.score.items," catches, ",game.score.points," points")
	get_tree().quit(0 if game.score.items==2 and game.score.points==200 else 1)
