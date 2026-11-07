extends RefCounted
## Task 063: open sky above the old ceiling, vertical camera follow, aim conversion with a raised camera.

static func _fresh(suite: Node, level: int = 1) -> BeachGame:
	suite.main.start_level(level)
	var game: BeachGame = suite.main.game
	game.set_physics_process(false)
	game.running = true
	game.intro = 0.0
	game.player.state = BeachGull.State.GLIDE
	game.player.velocity = Vector2.ZERO
	return game

static func _settle(game: BeachGame, y: float) -> void:
	for i: int in 240:
		game.player.position.y = y
		game.player.velocity = Vector2.ZERO
		game._physics_process(1.0 / 60.0)

static func run(suite: Node, check: Callable) -> void:
	var world: Dictionary = Config.tuning.world
	var sky: float = float(world.sky_extra)
	check.call(is_equal_approx(float(Config.tuning.flight.min_y), 20.0 - sky), "flight ceiling is the old ceiling minus sky_extra (%s)" % Config.tuning.flight.min_y)
	var game: BeachGame = _fresh(suite)
	var gull: BeachGull = game.player
	var start: float = float(world.camera_follow_start_y)
	_settle(game, start + 10.0)
	await suite.snapshot("sky-layer-normal")
	check.call(game.camera_y == 90.0 and game.camera.position.y == 90.0 and game.camera_target_y() == 90.0, "camera y stays 90 with the gull below the follow start")
	_settle(game, start)
	check.call(game.camera_y == 90.0, "camera y stays 90 at the follow start height")
	_settle(game, 50.0)
	check.call(absf(game.camera_y - (90.0 + 50.0 - start)) < 1.0 and game.camera_target_y() < 90.0 and game.camera.position.y == roundf(game.camera_y), "camera rises with the gull above the follow start (%.1f)" % game.camera_y)
	# Climb into the ceiling: the gull is clamped and the view top stops at -sky_extra.
	gull.position.y = -500.0
	gull.state = BeachGull.State.GLIDE
	gull.tick(1.0 / 60.0, 0.0, 0.0)
	check.call(is_equal_approx(gull.position.y, float(Config.tuning.flight.min_y)), "gull stops at y = %s (%s)" % [Config.tuning.flight.min_y, gull.position.y])
	_settle(game, float(Config.tuning.flight.min_y))
	check.call(absf(game.camera_y - (90.0 - sky)) < 1.0 and game.camera.position.y - 90.0 >= -sky, "camera clamps so the view top is not above -sky_extra (%.1f)" % game.camera_y)
	await suite.snapshot("sky-layer-raised")
	game.player.position.y = -500.0
	check.call(is_equal_approx(game.camera_target_y(), 90.0 - sky), "camera target clamps at 90 - sky_extra")
	# Aim: a fixed screen point maps to the point plus the full camera offset.
	var input: GullInput = game.input
	input.enabled = true
	input.clear_touch()
	input.touch_active = false
	input.gamepad = false
	input.key_aim = false
	game.get_viewport().warp_mouse(Vector2(100, 50))
	input.update_player(gull, 200.0, 50.0)
	var mouse: Vector2 = game.get_viewport().get_mouse_position()
	check.call(gull.aim.is_equal_approx(mouse + Vector2(40.0, -40.0)), "mouse aim adds the vertical camera offset (%s from %s)" % [gull.aim, mouse])
	# The gull at the ceiling stays comfortably on screen.
	check.call(float(Config.tuning.flight.min_y) + sky >= 16.0, "gull at min_y sits at least 16 px below the view top")
	# Touch dive steering scale.
	check.call(is_equal_approx(GameState.dive_steer(), 0.55), "dive_steer defaults to 0.55 when the option is missing")
	var saved_path: String = GameState.save_path
	GameState.save_path = "res://test-output/dive-steer-save.json"
	var f := FileAccess.open(GameState.save_path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": GameState.SAVE_VERSION, "options": {"Master": 0.5}}))
	f.close()
	GameState.load_progress()
	check.call(is_equal_approx(GameState.dive_steer(), 0.55), "old save without dive_steer loads with the default")
	GameState.save_path = saved_path
	GameState.options["dive_steer"] = 0.4
	input.touch_active = true
	input.update_player(gull, 200.0, 50.0)
	check.call(is_equal_approx(gull.dive_turn_scale, 0.4), "touch active: dive_turn_scale equals the option (%s)" % gull.dive_turn_scale)
	input.touch_active = false
	input.update_player(gull, 200.0, 50.0)
	check.call(is_equal_approx(gull.dive_turn_scale, 1.0), "mouse/keyboard: dive_turn_scale is 1.0")
	var rival := BeachGull.new()
	check.call(is_equal_approx(rival.dive_turn_scale, 1.0), "rivals default to 1.0")
	rival.free()
	GameState.options.erase("dive_steer")
	# Squall rain follows the raised camera.
	game.camera_y = 50.0
	var rain := BeachRain.new()
	rain.tick(0.016, 0.5, 0.0, 200.0, 50.0)
	check.call(is_equal_approx(rain.position.y, -40.0) and is_equal_approx(rain.position.x, 40.0), "rain band follows the camera y (%s)" % rain.position)
	rain.free()
	suite.main.clear_game()
	await suite.get_tree().process_frame
