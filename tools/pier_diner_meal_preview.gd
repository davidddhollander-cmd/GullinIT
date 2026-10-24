extends Node2D
## Two staged real-game scenarios: receipt/return, then a counter dive theft.
const Checks = preload("res://tests/pier_diner_meal_checks.gd")
var game: BeachGame
var diner: BeachTarget

func _ready() -> void:
	GullInput.register_actions()
	Audio.stop_all()
	Config.tuning.juice.audio = false
	make_game()
	call_deferred("capture")

func make_game() -> void:
	game = Checks.fixture(self)
	diner = game.spawner.targets[0]
	game.overlay.hide()
	game.camera_x = 960
	game.camera.position = Vector2(960,90)
	game.beach.camera_x = 960
	Checks.empty(diner)

func step(seconds: float) -> void:
	Checks.step(game,seconds)
	game.score.tick(seconds)
	game.player.digestion.tick(seconds,false)
	game.effects.tick(seconds)
	game.beach.tick(seconds)

func shot(label: String) -> void:
	for frame: int in 2:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var capture_image: Image = get_viewport().get_texture().get_image()
	capture_image.save_png("res://test-output/pier-diner-meal-"+label+".png")
	capture_image.resize(640,360,Image.INTERPOLATE_NEAREST)
	capture_image.save_png("res://test-output/pier-diner-meal-"+label+"-phone.png")
	print(label," x=",diner.position.x," food=",diner.food," meal=",diner.diner_meal," pose=",diner.sprite.animation)

func counter() -> StallPortion:
	for frame: int in 1000:
		step(0.02)
		for portion: BeachTarget in game.stalls.portions:
			if portion.food:
				return portion as StallPortion
	return null

func capture() -> void:
	step(2.0)
	await shot("to-grill")
	var stand: FoodStall = game.stalls.find_stall(diner,"fish_chips_stand")
	for frame: int in 600:
		step(0.02)
		if diner.service_locked and stand.phase==FoodStall.Phase.PREPARE:
			break
	step(0.6)
	await shot("preparing")
	var portion: StallPortion = counter()
	if portion==null:
		push_error("Diner preview could not order fish")
		get_tree().quit(1)
		return
	await shot("counter")
	step(1.1)
	await shot("carrying-home")
	for frame: int in 600:
		step(0.02)
		if diner.diner_meal==BeachTarget.DinerMeal.DINING:
			break
	step(0.02)
	await shot("dining")
	var returned: bool = diner.food and is_equal_approx(diner.position.x,diner.diner_home) and diner.routine.anchor==diner.diner_home
	game.free()
	make_game()
	portion = counter()
	if portion==null:
		get_tree().quit(1)
		return
	var player: BeachGull = game.player
	player.state = BeachGull.State.STRIKE
	player.direction = Vector2(0.8,0.6)
	player.position = portion.food_position()-player.direction*float(Config.tuning.dive.beak_offset)
	player.tick(0,0,0)
	player.sweep_state = BeachGull.State.STRIKE
	player.peck_sweep_active = true
	player.grounded_sweep = false
	player.previous_beak = portion.food_position()-Vector2(20,15)
	player.sweep_beak = portion.food_position()+Vector2(20,15)
	BeachCollisions.resolve(player,game.stalls.portions,game.beach.props)
	await shot("counter-theft")
	player.digestion.tick(3.1,false)
	var expected: int = roundi(55.0*(1.0+float(Config.tuning.score.handover)))
	print("Pier diner preview: returned=",returned,", intercepted=",not diner.food,", score=",game.score.points)
	get_tree().quit(0 if returned and not diner.food and game.score.points==expected else 1)
