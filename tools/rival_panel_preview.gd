extends Node2D
var game: BeachGame

func _ready() -> void:
	GullInput.register_actions()
	Audio.music.stop()
	game = BeachGame.new()
	add_child(game)
	game.setup(Config.levels[6].duplicate(true),false)
	game.set_physics_process(false)
	game.running = true
	game.intro = 0
	if not game.pending_rivals.is_empty():
		game._release_rivals()
	for i: int in game.pilots.size():
		game.pilots[i].score = [125,85,240][i]
		game.pilots[i].gull.position = Vector2(80+i*70,55+i*13)
		game.pilots[i].gull.tick(0,0,0)
	game.player.position = Vector2(40,110)
	game.overlay._process(0)
	call_deferred("capture")

func capture() -> void:
	for frame: int in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var colours: Array[Color] = []
	for pilot: RivalPilot in game.pilots:
		assert(pilot.gull.rival_tint not in colours,"Rival colours must be unique")
		colours.append(pilot.gull.rival_tint)
	var rect: Rect2 = game.overlay.rival_score_panel.get_global_rect()
	assert(rect.end.x <= 320 and rect.end.y < 124,"Panel must remain inside HUD safe area")
	get_viewport().get_texture().get_image().save_png("res://assets/previews/rival-score-panel-small-v3.png")
	get_window().size = Vector2i(640,360)
	for frame: int in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://assets/previews/rival-score-panel-phone-small-v3.png")
	print("Rival panel: unique colours, safe bounds and desktop/phone renders passed")
	get_tree().quit()
