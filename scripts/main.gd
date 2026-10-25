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
	# Only x >= ~207 shows beside the menu panel. Hut, castle and palm sit further back (y 142-148);
	# sunbathers and towels draw above every prop (z 3), so parasol poles stay behind them.
	background.setup([
		{"type":"beach_lamp","x":TitleFlyby.LAMP_X,"y":TitleFlyby.LAMP_BASE_Y},{"type":"beach_hut","x":240,"y":148},{"type":"beach_parasol","x":244,"y":152},
		{"type":"beach_parasol_blue","x":282,"y":162},{"type":"beach_castle","x":310,"y":175},{"type":"beach_palm","x":172,"y":142}
	])
	var lamp: AnimatedSprite2D = background.prop_sprites[0]
	lamp.scale = Vector2.ONE * TitleFlyby.LAMP_SCALE
	lamp.position.y = TitleFlyby.LAMP_BASE_Y - 90.0 * TitleFlyby.LAMP_SCALE * 0.5
	# Sandcastle in the foreground, in front of and below the sunbathers: smaller and smoothed so the downscale is less blocky.
	var castle: AnimatedSprite2D = background.prop_sprites[4]
	var castle_half: float = 175.0 - castle.position.y
	castle.scale *= 0.7
	castle.position.y = 175.0 - castle_half * 0.7
	castle.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	castle.z_index = 4
	background.prop_sprites[1].z_index = 1 # hut behind the red parasol (props are listed in setup order)
	for spec: Array in [[false,true,244.0,0.0],[true,false,282.0,10.0]]:
		var towel := SunbatherTowel.new()
		towel.blue = spec[0]
		towel.female = spec[1]
		towel.position = Vector2(spec[2],152.0 + spec[3])
		towel.z_index = 3
		background.add_child(towel)
		var sunbather: AnimatedSprite2D = AnimatedSprite2D.new()
		sunbather.sprite_frames = SunbatherArt.frames(spec[0],spec[1])
		sunbather.play(&"rest")
		sunbather.scale = Vector2.ONE * AdultPixelArt.DISPLAY_SCALE
		sunbather.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sunbather.position = Vector2(spec[2],126.0 + spec[3])
		sunbather.z_index = 3
		background.add_child(sunbather)
	var flyby := TitleFlyby.new()
	flyby.z_index = 4
	background.add_child(flyby)
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
			clear_game()
			screen = "pick"
			menus.show()
			menus.gull_picker()
			Audio.stop_music()  # selection screens: gull calls stay audible
		"gull":
			if Config.species.species.has(str(payload)) and GameState.gull_owned(str(payload)):
				GameState.options.gull = str(payload)
				GameState.save_progress()
				_navigate("select")
		"shop":
			if GameState.shop_open():
				clear_game()
				screen = "shop"
				menus.show()
				menus.shop()
				Audio.stop_music()  # selection screens: gull calls stay audible
		"buy":
			var id: String = str(payload)
			var price: int = int(Config.perks.perks[id].price) if Config.perks.perks.has(id) else (int(Config.species.species[id].price) if Config.species.species.has(id) else -1)
			if price > 0 and screen == "shop" and GameState.buy(id,price):
				menus.shop(true)
		"select":
			clear_game()
			screen = "select"
			menus.show()
			menus.level_select(casual)
			Audio.stop_music()  # selection screens: gull calls stay audible
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
	game.overlay.hide()
	Audio.stop_music()
	menus.show()
	menus.results(game.level,result)

## Touch drives the menus and the HUD pause button by replaying a finger as a left mouse click:
## mouse emulation is off so a beach touch never also counts as a FLAP click, which means
## GUI buttons would otherwise ignore touches (iPhone Safari: nothing responded). In play only
## the top bar strip is forwarded; the rest of the screen belongs to the stick and buttons.
const TOP_BAR_TOUCH_Y: float = 28.0
var gui_fingers: Dictionary = {}

func _touch_to_gui(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if screen == "game" and event.position.y > TOP_BAR_TOUCH_Y:
			return
		gui_fingers[event.index] = true
	elif not gui_fingers.erase(event.index):
		return
	var motion := InputEventMouseMotion.new()
	motion.position = event.position
	motion.global_position = event.position
	var click := InputEventMouseButton.new()
	click.position = event.position
	click.global_position = event.position
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = event.pressed
	click.button_mask = MOUSE_BUTTON_MASK_LEFT if event.pressed else 0
	if event.pressed:
		get_viewport().push_input(motion,true)
	get_viewport().push_input(click,true)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_touch_to_gui(event)
		return
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
