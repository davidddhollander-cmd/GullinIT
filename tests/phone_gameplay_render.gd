extends Node2D
## A fresh, full-resolution gameplay still with the touch controls visible.

func _ready() -> void:
	var game := BeachGame.new()
	add_child(game)
	game.setup(Config.levels[0],false)
	game.set_physics_process(false)
	game.intro = 0.0
	game.running = true
	game.elapsed = 18.0
	game.input.touch_visible = false
	game.player.position = Vector2(470,72)
	game.player.aim = game.player.position
	game.player.tick(0.016,0,0.0)
	game.spawner.apply_spacing(1.0)
	game.camera.position = Vector2(480,90)
	game.beach.camera_x = 480.0
	game.overlay.hide()
	call_deferred("_capture")

func _capture() -> void:
	for i: int in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://assets/previews/phone-scene-redraw-v2.png")
	get_tree().quit()
