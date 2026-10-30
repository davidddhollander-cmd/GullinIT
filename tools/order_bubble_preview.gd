extends Node2D
## Actual service simulation: approach, tiny order bubble, preparation, collection.
const Checks = preload("res://tests/stall_service_checks.gd")
var game: BeachGame

func _ready() -> void:
	Audio.music.stop()
	game = BeachGame.new()
	add_child(game)
	var level: Dictionary = Config.levels[2].duplicate(true)
	level.spawns = []
	level.rivals = []
	level.props = [{"type":"kiosk","x":90,"customer_x":138},{"type":"hotdog_stand","x":246,"customer_x":198}]
	level.zones = [{"name":"SNACK STALLS","from":0,"to":320}]
	game.setup(level,false)
	game.set_physics_process(false)
	game.set_process_unhandled_input(false)
	game.running = true
	game.intro = 0
	game.overlay.hide()
	game.player.hide()
	for order: Dictionary in [{"x":125,"id":"ice_cream","appearance":"shopper_mullet"},{"x":211,"id":"hotdog","appearance":"shopper_sundress"}]:
		var buyer := game.spawner.create("kiosk_customer",float(order.x),{"food_id":order.id,"appearance":order.appearance})
		buyer.food = false
		buyer.food_sprite.hide()
		buyer.respawn = 0
	call_deferred("capture")

func capture() -> void:
	var output: String = "res://test-output/order-bubble-frames"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	for frame: int in 80:
		for refresh: int in 2:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var image: Image = get_viewport().get_texture().get_image()
		if frame==16:
			image.save_png("res://assets/archive/previews/order-bubble-desktop.png")
		image.resize(640,360,Image.INTERPOLATE_NEAREST)
		if frame==16:
			image.save_png("res://assets/archive/previews/order-bubble-phone.png")
		image.save_png(output+"/frame-%03d.png" % frame)
		Checks.step(game,0.05)
	get_tree().quit()
