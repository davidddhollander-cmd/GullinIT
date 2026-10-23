extends Node
var game: BeachGame
var menus: BeachMenus
var background: BeachBackdrop
var casual: bool = false
var current_level: int = 1
var screen: String = "title"
var quitting: bool = false

func _ready() -> void:
	GullInput.register_actions()
	background = BeachBackdrop.new()
	add_child(background)
	background.sunset = true
	background.setup([
		{"type":"beach_lamp","x":190},{"type":"beach_hut","x":212},{"type":"beach_parasol","x":244},
		{"type":"beach_parasol_blue","x":282},{"type":"beach_castle","x":305},{"type":"beach_palm","x":317}
	])
	for spec: Array in [[false,true,244.0],[true,false,282.0]]:
		var towel := SunbatherTowel.new()
		towel.blue = spec[0]
		towel.female = spec[1]
		towel.position = Vector2(spec[2],160)
		background.add_child(towel)
		var sunbather: AnimatedSprite2D = AnimatedSprite2D.new()
		sunbather.sprite_frames = SunbatherArt.frames(spec[0],spec[1])
		sunbather.play(&"rest")
		sunbather.scale = Vector2.ONE * AdultPixelArt.DISPLAY_SCALE
		sunbather.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sunbather.position = Vector2(spec[2],134)
		background.add_child(sunbather)
	background.add_child(TitleFlyby.new())
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	menus = BeachMenus.new()
	layer.add_child(menus)
	menus.requested.connect(_navigate)
	menus.title()
	Analytics.track("session_start")
	Audio.play_music("title", 0.0)
	get_tree().auto_accept_quit = false
	get_tree().root.close_requested.connect(_quit)
	if OS.get_cmdline_user_args().has("--smoke"):
		_navigate("start",1)

func _process(delta: float) -> void:
	if background.visible:
		background.tick(delta)

func _navigate(action: String, payload: Variant = null) -> void:
	match action:
		"title":
			clear_game()
			screen = "title"
			menus.show()
			menus.title()
			Audio.play_music("title")
		"arcade", "casual":
			casual = action == "casual"
			_navigate("select")
		"select":
			clear_game()
			screen = "select"
			menus.show()
			menus.level_select(casual)
			Audio.play_music("title")
		"start":
			if GameState.unlocked(int(payload)):
				# The Training Day card always opens lessons, even on a completed save.
				var replay_training: bool = int(payload) == 1 and bool(GameState.entry(1).get("training_complete",false))
				start_level(int(payload),replay_training)
		"train_again":
			start_level(1, true)
		"restart":
			var replaying_training: bool = is_instance_valid(game) and game.training and bool(GameState.entry(1).get("training_complete", false))
			start_level(current_level, replaying_training)
		"pause":
			if is_instance_valid(game):
				game.set_paused(true)
				screen = "pause"
				menus.show()
				menus.pause()
				Audio.duck_music(true)
		"resume":
			if is_instance_valid(game):
				game.input.touch_visible = DisplayServer.is_touchscreen_available() or bool(GameState.options.touch)
				game.set_paused(false)
				screen = "game"
				menus.hide()
				Audio.duck_music(false)
		"options", "options_pause":
			screen = action
			menus.options(action == "options_pause")
		"fullscreen":
			var full: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)
		"quit":
			_quit()
		"feedback":
			Analytics.track("feedback_click", {"screen": "results" if screen == "results" else "level_select"})
			var url: String = GameState.feedback_url()
			if not url.is_empty():
				OS.shell_open(url)

func _quit() -> void:
	if quitting:
		return
	quitting = true
	Audio.stop_all()
	# Playback releases on the audio thread; give it time before engine teardown.
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()

func start_level(id: int, force_training: bool = false) -> void:
	clear_game()
	current_level = id
	screen = "game"
	background.hide()
	menus.hide()
	game = BeachGame.new()
	game.name = "Game"
	add_child(game)
	game.setup(Config.levels[id-1],casual,force_training)
	game.level_finished.connect(_finished)
	game.pause_requested.connect(func() -> void: _navigate("pause"))
	Audio.play_music("beach")

func clear_game() -> void:
	if is_instance_valid(game):
		game.track_end("quit")
		remove_child(game)
		game.queue_free()
	game = null
	Config.apply_level_world({})
	background.show()

func _finished(result: Dictionary) -> void:
	screen = "results"
	var passed: bool = bool(result.get("success", false)) or int(result.stars) > 0 or bool(result.casual)
	game.track_end("completed" if passed else "failed", result)
	game.set_paused(true)
	Audio.stop_music()
	menus.show()
	menus.results(game.level,result)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("fullscreen"):
		_navigate("fullscreen")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("restart") and is_instance_valid(game):
		_navigate("restart")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause"):
		if screen == "game":
			_navigate("pause")
		elif screen == "pause":
			_navigate("resume")
		elif screen == "options_pause":
			_navigate("pause")
		elif screen != "title":
			_navigate("title")
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and screen == "game":
		_navigate("pause")
