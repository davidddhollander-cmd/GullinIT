extends RefCounted
## Task 087: keyboard flight lock. WASD flips mouse_role to dive_aim; the mouse then only aims dives.

static func _motion(input: GullInput, pos: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = pos
	input._input(motion)

static func _key(input: GullInput, keycode: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	event.pressed = true
	input._input(event)

static func _right_click(input: GullInput, pos: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_RIGHT
	event.position = pos
	event.pressed = true
	input._input(event)

static func run(host: Node, check: Callable) -> void:
	host.main.start_level(1)
	var game: BeachGame = host.main.game
	game.set_physics_process(false)
	game.intro = 0
	game.running = true
	var input: GullInput = game.input
	input.enabled = true
	input.clear_touch()
	input.touch_active = false
	input.gamepad = false
	input.key_aim = false
	input.mouse_dive = false
	var saved_path: String = GameState.save_path
	GameState.save_path = "res://test-output/mouse-role-save.json"
	GameState.options.erase("mouse_role")
	var gull: BeachGull = game.player
	gull.position = Vector2(300,100)
	gull.state = BeachGull.State.GLIDE
	gull.velocity = Vector2(50,0)
	gull.facing = 1
	check.call(GameState.mouse_role() == "steer", "fresh save: mouse_role is steer")
	_motion(input,Vector2(20,20))
	check.call(GameState.mouse_role() == "steer" and not input.key_aim, "mouse motion alone leaves steer mode")
	input.update_player(gull,300,90)
	check.call(gull.aim.distance_to(host.get_viewport().get_mouse_position() + Vector2(140,0)) < 0.5, "steer mode: the mouse still sets the aim")
	var pad: InputEventJoypadButton = InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_A
	input._input(pad)
	check.call(GameState.mouse_role() == "steer", "a gamepad press never changes mouse_role")
	input.gamepad = false
	_key(input,KEY_W)
	check.call(GameState.mouse_role() == "dive_aim", "first WASD press switches to dive_aim")
	GameState.key_flight = false
	GameState.load_progress()
	check.call(GameState.mouse_role() == "steer", "a key switch to dive_aim is never saved")
	GameState.key_flight = true
	# Glide: mouse far away never moves the heading.
	input.key_aim = true
	_motion(input,Vector2(300,10))
	check.call(input.key_aim, "mouse motion does not clear key_aim in dive_aim")
	input.update_player(gull,300,90)
	var expected: Vector2 = gull.position + Vector2(1,0) * float(Config.tuning.flight.cursor_radius)
	check.call(gull.aim.distance_to(expected) < 0.5, "dive_aim glide: heading ignores the mouse (%s)" % gull.aim)
	input.key_aim = false
	_motion(input,Vector2(10,170))
	input.update_player(gull,300,90)
	check.call(gull.aim.distance_to(expected) < 0.5, "dive_aim glide: heading holds even without key_aim")
	# Dive with a fresh mouse aims at the cursor.
	gull.state = BeachGull.State.WINDUP
	_motion(input,Vector2(100,150))
	input.update_player(gull,160,90)
	check.call(gull.aim.distance_to(Vector2(100,150) + Vector2(0,0)) < 0.5, "dive_aim dive with a fresh mouse chases the cursor (%s)" % gull.aim)
	# Stale mouse, Shift dive: keyboard dive keeps its direction.
	gull.state = BeachGull.State.GLIDE
	input.update_player(gull,160,90) # dive over
	input.mouse_move_msec = Time.get_ticks_msec() - 5000
	input.mouse_dive = false
	gull.state = BeachGull.State.STRIKE
	gull.direction = Vector2(0,1)
	input.update_player(gull,160,90)
	check.call(gull.aim.distance_to(gull.position + Vector2(0,60)) < 0.5, "stale mouse + Shift dive keeps the keyboard dive")
	# Mouse 2 dive aims at the cursor even if the mouse is stale.
	gull.state = BeachGull.State.GLIDE
	input.update_player(gull,160,90)
	input.mouse_move_msec = Time.get_ticks_msec() - 5000
	_right_click(input,Vector2(60,160))
	gull.state = BeachGull.State.WINDUP
	input.update_player(gull,160,90)
	check.call(input.mouse_dive and gull.aim.distance_to(Vector2(60,160)) < 0.5, "a mouse 2 dive aims at the cursor even when the mouse is still")
	# A held key overrides the cursor mid-dive.
	Input.action_press("aim_left")
	input.update_player(gull,160,90)
	Input.action_release("aim_left")
	check.call(gull.aim.x < gull.position.x and gull.aim.distance_to(Vector2(60,160)) > 1.0, "a held key overrides the cursor during the dive")
	# Dive end clears the mouse dive flag.
	gull.state = BeachGull.State.GLIDE
	input.update_player(gull,160,90)
	check.call(not input.mouse_dive, "the mouse dive flag clears when the dive ends")
	# Moving the mouse outside a dive hands flight back to it.
	var shove := InputEventMouseMotion.new()
	shove.position = Vector2(120,80)
	shove.relative = Vector2(6,0)
	input._input(shove)
	check.call(GameState.mouse_role() == "steer" and not GameState.key_flight, "real mouse motion outside a dive returns the mouse to steering")
	GameState.key_flight = true
	# Options row toggles both ways and persists.
	host.main._navigate("options")
	await host.settle()
	var row: Button = host.main.menus.find_child("MouseRoleButton",true,false) as Button
	check.call(row != null and row.text == "MOUSE: AIMS DIVES", "options row shows MOUSE: AIMS DIVES")
	if row != null:
		row.pressed.emit()
		await host.settle()
		check.call(GameState.mouse_role() == "steer", "options row flips back to steer")
		row = host.main.menus.find_child("MouseRoleButton",true,false) as Button
		check.call(row != null and row.text == "MOUSE: STEERS FLIGHT", "options row then reads MOUSE: STEERS FLIGHT")
		row.pressed.emit()
		await host.settle()
		check.call(GameState.mouse_role() == "dive_aim", "options row flips to dive_aim")
	GameState.options.erase("mouse_role")
	GameState.options.erase("mouse_role_set")
	GameState.key_flight = false
	GameState.save_path = saved_path
