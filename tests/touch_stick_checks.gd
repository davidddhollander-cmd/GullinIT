extends RefCounted
## Floating touch stick, touch-only aim assist and mouse-switch guard (task 018).

static func _touch(input: GullInput, index: int, pos: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = pos
	event.pressed = pressed
	input._input(event)

static func _drag(input: GullInput, index: int, pos: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = pos
	input._input(event)

static func _near(a: Vector2, b: Vector2) -> bool:
	return a.distance_to(b) < 0.05

static func _mouse_move(input: GullInput) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(50, 50)
	input._input(motion)

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
	var gull: BeachGull = game.player
	gull.position = Vector2(300, 100)
	gull.state = BeachGull.State.GLIDE
	gull.velocity = Vector2.ZERO
	var radius: float = float(Config.tuning.flight.cursor_radius)
	var stick_radius: float = float(Config.tuning.touch.stick_radius)
	# Stick geometry.
	_touch(input, 1, Vector2(100, 100), true)
	check.call(input.aim_finger == 1 and input.touch_active and input.stick_anchor == Vector2(100, 100), "touch on the beach starts the floating stick at the landing point")
	_drag(input, 1, Vector2(112, 100))
	input.update_player(gull, 160)
	check.call(_near(gull.aim, gull.position + Vector2(0.5, 0) * radius), "stick right gives half deflection aim (%s)" % gull.aim)
	_touch(input, 1, Vector2(112, 100), false)
	_touch(input, 1, Vector2(100, 100), true)
	_drag(input, 1, Vector2(88, 112))
	input.update_player(gull, 160)
	check.call(_near(gull.aim, gull.position + Vector2(-0.5, 0.5) * radius), "stick down-left aims down-left (%s)" % gull.aim)
	_drag(input, 1, Vector2(200, 100))
	input.update_player(gull, 160)
	check.call(_near(gull.aim, gull.position + Vector2(1, 0) * radius), "stick deflection is capped at the cursor radius")
	check.call(_near(input.stick_anchor, Vector2(200 - stick_radius, 100)), "anchor follows the finger past the stick radius")
	_drag(input, 1, Vector2(200 - stick_radius * 0.5, 100))
	input.update_player(gull, 160)
	check.call(_near(gull.aim, gull.position + Vector2(0.5, 0) * radius), "stick keeps responding after the anchor followed")
	# Deadzone and release use the gamepad no-input rules.
	_touch(input, 1, Vector2(0, 0), false)
	_touch(input, 1, Vector2(100, 100), true)
	_drag(input, 1, Vector2(102, 100))
	gull.aim = Vector2(5, 5)
	input.update_player(gull, 160)
	check.call(_near(gull.aim, gull.position + Vector2(gull.facing, 0) * radius), "stick inside the deadzone uses the no-input heading rule")
	_drag(input, 1, Vector2(124, 100))
	_touch(input, 1, Vector2(124, 100), false)
	check.call(input.aim_finger == -1 and input.touch_active, "releasing the stick keeps touch as the aim source")
	gull.velocity = Vector2(50, -50)
	input.update_player(gull, 160)
	check.call(_near(gull.aim, gull.position + Vector2(50, -50).normalized() * radius), "released stick in flight keeps the heading")
	gull.state = BeachGull.State.GROUNDED
	input.update_player(gull, 160)
	check.call(_near(gull.aim, gull.position), "released stick on the ground aims at the gull")
	gull.state = BeachGull.State.STRIKE
	gull.direction = Vector2(1, 1).normalized()
	input.update_player(gull, 160)
	check.call(_near(gull.aim, gull.position + gull.direction * radius), "released stick during a swoop keeps the swoop direction")
	# Two fingers: the stick plus the right-thumb buttons.
	gull.state = BeachGull.State.GLIDE
	gull.velocity = Vector2.ZERO
	_touch(input, 1, Vector2(100, 100), true)
	_drag(input, 1, Vector2(100, 112))
	for pair: Array in [["flap", "touch_climb"], ["dive", "touch_dive"], ["peck", "touch_peck"]]:
		_touch(input, 2, (GullInput.TOUCH_BUTTONS[pair[0]] as Rect2).get_center(), true)
		input.update_player(gull, 160)
		check.call(bool(input.get(pair[1])) and input.aim_finger == 1 and _near(gull.aim, gull.position + Vector2(0, 0.5) * radius), "stick and %s work with two fingers" % pair[0])
		_touch(input, 2, (GullInput.TOUCH_BUTTONS[pair[0]] as Rect2).get_center(), false)
	# Review capture: stick ring and knob, reticle ahead of the gull, and the buttons.
	_drag(input, 1, Vector2(118, 106))
	var saved_position: Vector2 = gull.position
	gull.position = Vector2(game.camera_x - 30, 80)
	input.touch_visible = true
	game.overlay.intro_panel.hide()
	input.update_player(gull, game.camera_x)
	game.overlay.queue_redraw()
	await host.snapshot("touch-stick")
	gull.position = saved_position
	_drag(input, 1, Vector2(100, 112))
	input.clear_touch()
	_touch(input, 1, Vector2(100, 20), true)
	check.call(input.aim_finger == -1, "touch in the top bar does not start the stick")
	_touch(input, 1, (GullInput.TOUCH_BUTTONS.flap as Rect2).get_center(), true)
	check.call(input.aim_finger == -1, "touch on a button does not start the stick")
	input.clear_touch()
	# Assist.
	var target: BeachTarget
	for candidate: BeachTarget in game.spawner.targets:
		if game.snatchable(candidate):
			target = candidate
			break
	check.call(target != null, "level has a snatchable target for assist checks")
	if target == null:
		host.main.clear_game()
		await host.settle()
		return
	for other: BeachTarget in game.spawner.targets + game.stalls.portions:
		if other != target:
			other.food = false
	gull.state = BeachGull.State.STRIKE
	gull.direction = Vector2(1, 0)
	gull.velocity = Vector2.ZERO
	_touch(input, 1, Vector2(100, 100), true)
	_drag(input, 1, Vector2(124, 100))
	var plain: Vector2 = gull.position + Vector2(1, 0) * radius
	var strength: float = float(Config.tuning.touch.assist_strength)
	_place_target(target, gull.position + Vector2(100, 20))
	input.update_player(gull, 160)
	var wanted: float = (target.food_position() - gull.position).angle() * strength
	check.call(absf((gull.aim - gull.position).angle() - wanted) < 0.02 and is_equal_approx((gull.aim - gull.position).length(), radius), "assist bends a swoop toward a target inside the cone")
	_place_target(target, gull.position + Vector2(100, 80))
	input.update_player(gull, 160)
	check.call(_near(gull.aim, plain), "target outside the cone is left alone")
	_place_target(target, gull.position + Vector2(150, 10))
	input.update_player(gull, 160)
	check.call(_near(gull.aim, plain), "target beyond assist range is left alone")
	_place_target(target, gull.position + Vector2(100, 20))
	Config.tuning.touch.assist_strength = 0.0
	input.update_player(gull, 160)
	check.call(_near(gull.aim, plain), "assist_strength 0 turns assist off")
	Config.tuning.touch.assist_strength = strength
	target.leaving = true
	input.update_player(gull, 160)
	check.call(_near(gull.aim, plain), "assist ignores a target that is leaving")
	target.leaving = false
	gull.rival = true
	input.update_player(gull, 160)
	check.call(_near(gull.aim, plain), "assist never applies to rivals")
	gull.rival = false
	gull.state = BeachGull.State.GLIDE
	input.update_player(gull, 160)
	check.call(_near(gull.aim, plain), "assist waits for the dive while gliding")
	input.touch_dive = true
	input.update_player(gull, 160)
	check.call(not _near(gull.aim, plain), "assist applies at dive start")
	input.touch_dive = false
	# Mouse and gamepad stay exact.
	gull.state = BeachGull.State.STRIKE
	input.clear_touch()
	input.touch_active = false
	input.update_player(gull, 210)
	check.call(_near(gull.aim, host.get_viewport().get_mouse_position() + Vector2(50, 0)), "mouse aim is the mouse position plus camera offset with no assist")
	gull.state = BeachGull.State.GLIDE
	gull.cooldown = 0.0
	gull.support = {}
	input.update_player(gull, 210)
	var mouse_dir: Vector2 = (gull.aim - gull.position).normalized()
	gull.dive(0)
	check.call(gull.state == BeachGull.State.WINDUP and gull.direction.is_equal_approx(mouse_dir), "right-click dive follows the mouse direction exactly")
	gull.state = BeachGull.State.STRIKE
	gull.direction = Vector2(1, 0)
	input.gamepad = true
	Input.action_press("aim_right")
	input.update_player(gull, 160)
	Input.action_release("aim_right")
	check.call(_near(gull.aim, plain), "gamepad aim is never assisted")
	input.gamepad = false
	# Emulated mouse events after touches must not switch the aim source.
	input.clear_touch()
	_touch(input, 1, Vector2(100, 100), true)
	_mouse_move(input)
	check.call(input.touch_active, "mouse motion while a finger is down is ignored")
	_touch(input, 1, Vector2(100, 100), false)
	_mouse_move(input)
	check.call(input.touch_active, "mouse motion just after a touch is ignored")
	input.touch_last_msec = Time.get_ticks_msec() - int(float(Config.tuning.touch.mouse_ignore_after_touch) * 1000.0) - 100
	_mouse_move(input)
	check.call(not input.touch_active and not input.gamepad, "mouse motion after the ignore window switches back to the mouse")
	host.main.clear_game()
	await host.settle()

static func _place_target(target: BeachTarget, at: Vector2) -> void:
	target.position += at - target.food_position()
