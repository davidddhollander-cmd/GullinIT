extends RefCounted
## Task 036: Realistic / Normal / Casual control modes (setting, picker slider, tap flapping, auto peck).
const FlightChecks: GDScript = preload("res://tests/flight_dynamics_checks.gd")
const DT: float = 1.0 / 60.0

static func _airborne(host: Node, mode: String) -> BeachGull:
	var gull: BeachGull = FlightChecks.gull_at(host, 100)
	gull.control_mode = mode
	return gull

## Runs `seconds` of physics; `taps` lists the times (s) of fresh presses, `hold` keeps the button down like update_player does.
static func _fly(gull: BeachGull, seconds: float, taps: Array[float], hold: bool) -> int:
	var strokes: int = 0
	var next: int = 0
	for i: int in int(round(seconds / DT)):
		var now: float = i * DT
		while next < taps.size() and taps[next] <= now + 0.0001:
			gull.flap_tap()
			next += 1
		gull.climb = hold
		gull.aim = gull.position
		gull.tick(DT, 0, 0.0)
		strokes += int(gull.stroke_started)
	return strokes

static func _setting(check: Callable) -> void:
	GameState.options.erase("control_mode")
	check.call(GameState.control_mode() == "normal", "control mode defaults to NORMAL")
	GameState.options.control_mode = "bogus"
	check.call(GameState.control_mode() == "normal", "an invalid saved control mode falls back to NORMAL")
	var saved_path: String = GameState.save_path
	GameState.save_path = "res://test-output/control-mode-save.json"
	GameState.set_control_mode("casual")
	GameState.options.erase("control_mode")
	GameState.load_progress()
	check.call(GameState.control_mode() == "casual", "control mode persists across save and load")
	GameState.set_control_mode("normal")
	GameState.save_path = saved_path

static func _picker(suite: Node, check: Callable) -> void:
	var main: Node = suite.main
	GameState.options.erase("control_mode")
	main._navigate("arcade")
	await suite.settle()
	var slider: HSlider = main.menus.find_child("ControlModeSlider", true, false) as HSlider
	check.call(slider != null and slider.min_value == 0 and slider.max_value == 2 and slider.step == 1 and slider.value == 1, "gull picker shows the 3-step slider at NORMAL by default")
	if slider == null:
		return
	check.call(slider.focus_mode == Control.FOCUS_ALL, "the control mode slider is reachable by keyboard and pad focus")
	suite.layout(main.menus)
	suite.menu_font_grid(main.menus)
	slider.value = 2
	check.call(GameState.control_mode() == "casual", "moving the slider to CASUAL saves the mode at once")
	slider.value = 0
	check.call(GameState.control_mode() == "realistic", "moving the slider to REALISTIC saves the mode at once")
	main._navigate("arcade")
	await suite.settle()
	slider = main.menus.find_child("ControlModeSlider", true, false) as HSlider
	check.call(slider.value == 0, "reopening the picker shows the saved mode")
	main.start_level(1)
	check.call(main.game.player.control_mode == "realistic", "the level applies the chosen mode to the player gull")
	main.clear_game()
	GameState.set_control_mode("normal")

static func _input(host: Node, check: Callable) -> void:
	var input: GullInput = GullInput.new()
	host.add_child(input)
	input.enabled = true
	var gull: BeachGull = _airborne(host, "realistic")
	var press: InputEventKey = InputEventKey.new()
	press.physical_keycode = KEY_SPACE
	press.pressed = true
	input._input(press)
	check.call(input.flap_tap, "a flap key press latches in _input")
	input.update_player(gull, 0.0)
	check.call(gull.flap_tap_pending and not input.flap_tap, "update_player hands the latched tap to the gull once")
	var echo: InputEventKey = press.duplicate() as InputEventKey
	echo.echo = true
	gull.flap_tap_pending = false
	input._input(echo)
	check.call(not input.flap_tap, "key repeat is not a new flap press")
	var touch: InputEventScreenTouch = InputEventScreenTouch.new()
	touch.pressed = true
	touch.index = 3
	touch.position = (GullInput.TOUCH_BUTTONS.flap as Rect2).get_center()
	input._input(touch)
	check.call(input.flap_tap, "a touch FLAP finger-down latches a tap")
	gull.queue_free()
	input.queue_free()

static func _realistic(host: Node, check: Callable) -> void:
	var held: BeachGull = _airborne(host, "realistic")
	var held_strokes: int = _fly(held, 2.0, [0.0], true)
	check.call(held_strokes <= 1 and held.position.y > 100.0, "realistic: holding flap for 2 s gives one stroke at most and ends lower")
	var tapped: BeachGull = _airborne(host, "realistic")
	var spaced: Array[float] = []
	for i: int in 10:
		spaced.append(0.2 * i)
	var tap_strokes: int = _fly(tapped, 2.0, spaced, false)
	check.call(tap_strokes == 10 and tapped.position.y < 100.0, "realistic: 10 presses over 2 s give 10 strokes and gain height")
	var mashed: BeachGull = _airborne(host, "realistic")
	var burst: Array[float] = []
	for i: int in 10:
		burst.append(0.01 * i)
	var mash_strokes: int = _fly(mashed, 0.1, burst, false)
	check.call(mash_strokes == 1, "realistic: 10 presses inside 0.1 s give one stroke (tap interval)")
	# A press during a frame with no tick is latched, not lost.
	var latched: BeachGull = _airborne(host, "realistic")
	latched.flap_tap()
	var latched_strokes: int = _fly(latched, 0.05, [], false)
	check.call(latched_strokes == 1, "realistic: a press latched between ticks still becomes a stroke")
	# Rapid tapping (5 a second) climbs about as well as holding flap in Normal.
	var rapid: BeachGull = _airborne(host, "realistic")
	_fly(rapid, 2.0, spaced, false)
	var normal: BeachGull = _airborne(host, "normal")
	_fly(normal, 2.0, [], true)
	check.call(100.0 - rapid.position.y >= (100.0 - normal.position.y) * 0.75, "realistic: tapping 5 times a second gains height comparably to Normal's held flap")
	# Takeoff from the ground on one press, with no second stroke on the same tap.
	var grounded: BeachGull = _airborne(host, "realistic")
	grounded.position.y = grounded.ground_y()
	grounded.state = BeachGull.State.GROUNDED
	grounded.velocity = Vector2.ZERO
	grounded.flap_tap()
	grounded.aim = grounded.position
	grounded.tick(DT, 0, 0.0)
	check.call(grounded.state == BeachGull.State.GLIDE and grounded.velocity.y < 0.0 and not grounded.stroke_started, "realistic: one press takes off from the ground without a second stroke")
	grounded.tick(DT, 0, 0.0)
	check.call(not grounded.climb, "realistic: climb is true for the tap's tick only")
	# Climb animation plays once per stroke instead of looping while held.
	var anim: BeachGull = _airborne(host, "realistic")
	_fly(anim, 0.1, [0.0], true)
	var playing: bool = anim.sprite.animation == &"climb"
	_fly(anim, 0.6, [], true)
	check.call(playing and anim.sprite.animation == &"glide", "realistic: the climb animation plays once per stroke and returns to glide while held")
	# Pulling out of a dive works through a tap.
	var diver: BeachGull = _airborne(host, "realistic")
	diver.state = BeachGull.State.STRIKE
	diver.direction = Vector2.DOWN
	diver.dive_speed = 80.0
	diver.aim = diver.position + Vector2(0, 50)
	diver.tick(DT, 0, 0.0)
	check.call(diver.state == BeachGull.State.STRIKE, "realistic: a dive continues with no tap")
	diver.flap_tap()
	diver.tick(DT, 0, 0.0)
	check.call(diver.state == BeachGull.State.GLIDE, "realistic: a tap pulls out of a dive")
	for gull: BeachGull in [held, tapped, mashed, latched, rapid, normal, grounded, anim, diver]:
		gull.queue_free()

static func _dive_takes_food(suite: Node, mode: String, press_peck: bool) -> bool:
	var game: BeachGame = suite.main.game
	var gull: BeachGull = game.player
	gull.control_mode = mode
	var target: BeachTarget = game.spawner.create("kiosk_customer", 80)
	target.food_id = "hotdog"
	target.food = true
	target.refresh_art()
	var at: Vector2 = target.food_position()
	gull.state = BeachGull.State.STRIKE
	gull.direction = Vector2.DOWN
	gull.dive_speed = 90.0
	gull.velocity = Vector2.ZERO
	gull.peck_used = false
	gull.peck_time = 0.0
	gull.peck_near_target = null
	gull.position = at - Vector2(0, float(Config.tuning.dive.beak_offset) + 30.0)
	for i: int in 90:
		if press_peck and not gull.peck_used and gull.beak().distance_to(at) < 12.0:
			gull.attempt_peck()
		gull.aim = gull.position + Vector2(0, 50)
		gull.tick(DT, 0, 0.0)
		BeachCollisions.resolve(gull, [target], [])
		if gull.state != BeachGull.State.STRIKE or not target.food:
			break
	return not target.food

static func _casual(suite: Node, check: Callable) -> void:
	suite.main.start_level(1)
	var game: BeachGame = suite.main.game
	game.set_physics_process(false)
	game.intro = 0
	game.running = true
	check.call(_dive_takes_food(suite, "casual", false), "casual: a dive whose beak crosses food takes it with no peck call")
	suite.eat_pending(game)
	check.call(not _dive_takes_food(suite, "normal", false), "normal: the same dive without a peck does not take the food")
	suite.eat_pending(game)
	check.call(_dive_takes_food(suite, "normal", true), "normal: the same dive with a timed peck still takes the food")
	suite.eat_pending(game)
	var gull: BeachGull = game.player
	gull.control_mode = "casual"
	gull.state = BeachGull.State.STRIKE
	gull.peck_used = false
	check.call(not gull.attempt_peck() and not gull.peck_used and gull.peck_window_open(), "casual: pressing peck mid-dive is harmless and the window stays open")
	# A near miss waits for the end of the strike before it knocks food.
	var target: BeachTarget = game.spawner.create("kiosk_customer", 80)
	target.food_id = "hotdog"
	target.food = true
	target.refresh_art()
	var at: Vector2 = target.food_position()
	gull.sweep_state = BeachGull.State.STRIKE
	gull.peck_sweep_active = true
	gull.previous_beak = at + Vector2(-15, 10)
	gull.sweep_beak = at + Vector2(15, 10)
	BeachCollisions.resolve(gull, [target], [])
	check.call(target.food and is_instance_valid(gull.peck_near_target), "casual: a grazing pass is held provisional, not knocked on the first frame")
	gull.state = BeachGull.State.GLIDE
	BeachCollisions.resolve(gull, [target], [])
	check.call(not target.food and target.dropped_pending, "casual: the near miss knocks the food loose once the strike ends")
	gull.control_mode = "normal"
	suite.main.clear_game()

static func _rivals(host: Node, check: Callable) -> void:
	var rival: BeachGull = _airborne(host, "casual")
	rival.rival = true
	check.call(not rival.auto_peck() and not rival.peck_window_open(), "rivals ignore casual auto peck")
	rival.control_mode = "realistic"
	var strokes: int = _fly(rival, 2.0, [], true)
	check.call(strokes >= 5, "rivals keep held-flap wingbeats whatever the mode string says")
	rival.queue_free()

static func run(suite: Node, check: Callable) -> void:
	_setting(check)
	await _picker(suite, check)
	_input(suite, check)
	_realistic(suite, check)
	await _casual(suite, check)
	_rivals(suite, check)
