extends Node2D
## Real level 6: a pier diner is served at the fish & chips stand (prepare, counter).
const Checks = preload("res://tests/pier_diner_meal_checks.gd")
var game: BeachGame

func _ready() -> void:
	GullInput.register_actions()
	Audio.stop_all()
	Config.tuning.juice.audio = false
	game = BeachGame.new()
	add_child(game)
	var level: Dictionary = Config.levels[5].duplicate(true)
	level.rivals = []
	level.crabs = {"enabled":false}
	game.setup(level,false)
	game.set_physics_process(false)
	game.set_process_unhandled_input(false)
	game.running = true
	game.intro = 0.0
	game.overlay.hide()
	game.player.position = Vector2(100,50)
	game.camera_x = 960
	game.camera.position = Vector2(960,90)
	game.beach.camera_x = 960
	for target: BeachTarget in game.spawner.targets:
		if target.kind == "pier_diner":
			Checks.empty(target)
	call_deferred("capture")

func shot(label: String) -> void:
	for frame: int in 2:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://test-output/fish-chips-l6-"+label+".png")

func capture() -> void:
	var stand: FoodStall = game.stalls.find_stall(game.spawner.targets[0],"fish_chips_stand")
	var done: bool = false
	for frame: int in 3000:
		Checks.step(game,0.02)
		game.beach.tick(0.02)
		if stand.phase == FoodStall.Phase.PREPARE and not done:
			done = true
			await shot("prepare")
		if stand.phase == FoodStall.Phase.COUNTER:
			await shot("counter")
			get_tree().quit(0)
			return
	get_tree().quit(1)
