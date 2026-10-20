extends Node2D
## Reproduce two crowded walking lanes crossing both kinds of food stand.
var game: BeachGame
var rear_walkers: Array[BeachTarget] = []

func _ready() -> void:
	Audio.music.stop()
	game = BeachGame.new()
	add_child(game)
	var definition: Dictionary = Config.levels[2].duplicate(true)
	definition.spawns = []
	definition.rivals = []
	definition.props = [{"type":"kiosk","x":85},{"type":"hotdog_stand","x":240}]
	definition.zones = []
	game.setup(definition,false)
	game.set_physics_process(false)
	game.overlay.hide()
	game.player.position = Vector2(160,96)
	game.player.tick(0,0,0)
	for x: float in [59.0,214.0]:
		var front := game.spawner.create("kiosk_customer",x,{"food_id":"ice_cream","appearance":"shopper_mullet"})
		var rear := game.spawner.create("kiosk_customer",x+18,{"food_id":"ice_cream","appearance":"shopper_sundress"})
		front.update_art_pose(true)
		rear.update_art_pose(true)
		front.sprite.pause()
		rear.sprite.pause()
		rear_walkers.append(rear)
	game.spawner.apply_spacing(1.0)
	call_deferred("_capture")

func frame() -> Image:
	for i: int in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()

func _capture() -> void:
	var rear_image: Image = await frame()
	rear_image.save_png("res://assets/previews/stall-rear-lane-fixed.png")
	for walker: BeachTarget in rear_walkers:
		walker.hide()
	var baseline: Image = await frame()
	# A passer-by must not replace the vendor/counter pixels inside either booth.
	var scale_x: float = float(baseline.get_width())/320.0
	var scale_y: float = float(baseline.get_height())/180.0
	for stall: FoodStall in game.beach.stalls:
		var box := Rect2i(roundi((stall.position.x-12)*scale_x),roundi((stall.position.y-34)*scale_y),roundi(24*scale_x),roundi(21*scale_y))
		if rear_image.get_region(box).get_data()!=baseline.get_region(box).get_data():
			push_error("rear walker covers serving window/counter")
			get_tree().quit(1)
			return
	print("STALL DEPTH: both serving windows and counters remain unobstructed by rear walkers")
	for walker: BeachTarget in rear_walkers:
		walker.show()
	for player: Node in Audio.get_children():
		if player is AudioStreamPlayer:
			player.stop()
	await get_tree().create_timer(0.05).timeout
	get_tree().quit()
