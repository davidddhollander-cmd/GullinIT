extends Node2D
## Capture the real attack, tumble, feather trail and recovered pose at game scale.
var game: BeachGame
var frame_number: int = 0
var caption: Label

func _ready() -> void:
	Audio.music.stop()
	Audio.music.stream = null
	game = BeachGame.new()
	add_child(game)
	var definition: Dictionary = Config.levels[2].duplicate(true)
	definition.spawns = []
	definition.rivals = []
	definition.props = []
	definition.zones = [{"name":"BEACH","from":0,"to":320}]
	game.setup(definition,false)
	game.set_physics_process(false)
	game.overlay.hide()
	game.camera.position = Vector2(160,90)
	game.player.position = Vector2(155,154)
	game.player.land()
	game.player.aim = game.player.position
	game.player.tick(0,0,0)
	game.effects.feather_rng.seed = 145
	var adult := game.spawner.create("kiosk_customer",140,{"food_id":"hotdog","appearance":"shopper_mullet"})
	adult.update_art_pose(false)
	adult.reaction.focus = game.player
	var layer := CanvasLayer.new()
	add_child(layer)
	caption = Label.new()
	caption.position = Vector2(8,8)
	caption.add_theme_font_override("font",preload("res://assets/fonts/gull_pixel.fnt"))
	caption.add_theme_font_size_override("font_size",8)
	layer.add_child(caption)
	call_deferred("capture",adult)

func capture(adult: BeachTarget) -> void:
	DirAccess.make_dir_recursive_absolute("res://test-output/gull-tumble")
	for sample: int in 36:
		if sample==4:
			adult.reaction._hit(adult)
			adult.update_art_pose(false)
		if sample>4:
			for step: int in 3:
				game.player.tick(1.0/60,0,0)
				game.effects.tick(1.0/60)
				adult.action_pose_time = maxf(0.0,adult.action_pose_time-1.0/60)
				adult.update_art_pose(false)
				# Keep the recovered bird still for an easy-to-read ending.
				if game.player.state==BeachGull.State.GROUNDED:
					game.player.aim = game.player.position
					game.player.velocity = Vector2.ZERO
		caption.text = "KICK -> TUMBLE -> RECOVER  /  %.2f S" % maxf(0,(sample-4)*0.05)
		for settle: int in 2:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://test-output/gull-tumble/%03d.png" % sample)
	for player: Node in Audio.get_children():
		if player is AudioStreamPlayer:
			player.stop()
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()
