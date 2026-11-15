extends RefCounted
## Task 092: one ASSIST option (auto-peck plus touch aim assist) and touch pull-up with the dive stick held. Analytics keys are checked in analytics_checks.gd.
const FlightChecks: GDScript = preload("res://tests/flight_dynamics_checks.gd")

static func _setting(check: Callable) -> void:
	for key: String in ["assist","control_mode"]:
		GameState.options.erase(key)
	GameState.options.touch = false
	var touchscreen: bool = DisplayServer.is_touchscreen_available()
	check.call(GameState.assist() == touchscreen and (GameState.control_mode() == "casual") == touchscreen,"a fresh desktop save has ASSIST off and unchanged controls")
	GameState.options.touch = true
	check.call(GameState.assist() and GameState.control_mode() == "casual","a fresh touch save has ASSIST on, which means auto-peck")
	GameState.options.control_mode = "realistic"
	check.call(GameState.control_mode() == "realistic","ASSIST does not override an explicit REALISTIC choice")
	GameState.options.erase("control_mode")
	GameState.options.assist = false
	check.call(not GameState.assist() and GameState.control_mode() == "normal","ASSIST off on touch turns auto-peck and aim assist off")
	GameState.options.touch = false
	GameState.options.assist = true
	check.call(GameState.assist() and GameState.control_mode() == "casual","a desktop player can switch ASSIST on")
	GameState.options.control_mode = "casual" # an old save
	GameState.options.assist = false
	check.call(GameState.control_mode() == "casual","an old save holding casual still loads as casual")
	var saved_path: String = GameState.save_path
	GameState.save_path = "res://test-output/assist-save.json"
	GameState.options.erase("control_mode")
	GameState.set_assist(true)
	GameState.options.erase("assist")
	GameState.load_progress()
	check.call(GameState.assist(),"ASSIST persists across save and load")
	GameState.set_assist(false)
	GameState.save_path = saved_path
	for key: String in ["assist","control_mode"]:
		GameState.options.erase(key)
	GameState.options.touch = false

static func _touch_climb(host: Node, check: Callable) -> void:
	var input: GullInput = GullInput.new()
	host.add_child(input)
	input.enabled = true
	var gull: BeachGull = FlightChecks.gull_at(host,100)
	var radius: float = float(Config.tuning.touch.stick_radius)
	var fly: InputEventScreenTouch = InputEventScreenTouch.new()
	fly.index = 1
	fly.pressed = true
	fly.position = GullInput.FLY_STICK_CENTER
	input._input(fly)
	var drag: InputEventScreenDrag = InputEventScreenDrag.new()
	drag.index = 1
	drag.position = GullInput.FLY_STICK_CENTER + Vector2(0,-radius)
	input._input(drag)
	var dive: InputEventScreenTouch = InputEventScreenTouch.new()
	dive.index = 2
	dive.pressed = true
	dive.position = GullInput.DIVE_STICK_CENTER
	input._input(dive)
	input.update_player(gull,160.0)
	check.call(input.dive_finger == 2 and input.touch_climb and gull.climb,"FLY up still pulls up while a thumb holds the DIVE stick")
	input.queue_free()
	gull.queue_free()

static func run(host: Node, check: Callable) -> void:
	_setting(check)
	_touch_climb(host,check)
