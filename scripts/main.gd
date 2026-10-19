extends Node
var game: BeachGame
var menus: BeachMenus
var background: BeachBackdrop
var casual: bool = false
var current_level: int = 1
var screen: String = "title"

func _ready() -> void:
	GullInput.register_actions()
	background = BeachBackdrop.new()
	add_child(background)
	background.setup([])
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	menus = BeachMenus.new()
	layer.add_child(menus)
	menus.requested.connect(_navigate)
	menus.title()
	get_tree().auto_accept_quit = true
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
		"arcade", "casual":
			casual = action == "casual"
			_navigate("select")
		"select":
			clear_game()
			screen = "select"
			menus.show()
			menus.level_select(casual)
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
		"resume":
			if is_instance_valid(game):
				game.input.touch_visible = DisplayServer.is_touchscreen_available() or bool(GameState.options.touch)
				game.set_paused(false)
				screen = "game"
				menus.hide()
		"options", "options_pause":
			screen = action
			menus.options(action == "options_pause")
		"fullscreen":
			var full: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)
		"quit":
			get_tree().quit()
		"feedback":
			var url: String = GameState.feedback_url()
			if not url.is_empty():
				OS.shell_open(url)

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

func clear_game() -> void:
	if is_instance_valid(game):
		remove_child(game)
		game.queue_free()
	game = null
	Config.apply_level_world({})
	background.show()

func _finished(result: Dictionary) -> void:
	screen = "results"
	game.set_paused(true)
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
