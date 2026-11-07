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
	var hint: Callable = Callable(host.main,"should_show_rotate_hint")
	check.call(hint.call(Vector2i(390,844),true) and not hint.call(Vector2i(844,390),true) and not hint.call(Vector2i(390,844),false),"rotate hint shows for portrait touch only")
	await _rework_checks(host, check)
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
	var approach: float = float(Config.tuning.touch.approach_assist_strength)
	Config.tuning.touch.approach_assist_strength = 0.0 # keep the plain stick checks exact; restored for the approach checks
	# Stick geometry.
	_touch(input, 1, Vector2(100, 100), true)
	check.call(input.aim_finger == 1 and input.touch_active and input.stick_anchor == Vector2(100, 100), "touch on the beach starts the floating stick at the landing point")
	_drag(input, 1, Vector2(100 + stick_radius * 0.5, 100))
	input.update_player(gull, 160)
	check.call(_near(gull.aim, gull.position + Vector2(0.5, 0) * radius), "stick right gives half deflection aim (%s)" % gull.aim)
	_touch(input, 1, Vector2(100 + stick_radius * 0.5, 100), false)
	_touch(input, 1, Vector2(100, 100), true)
	_drag(input, 1, Vector2(100 - stick_radius * 0.5, 100 + stick_radius * 0.5))
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
	check.call(input.aim_finger == GullInput.NO_FINGER and input.touch_active, "releasing the stick keeps touch as the aim source")
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
	_drag(input, 1, Vector2(100, 100 + stick_radius * 0.5))
	for pair: Array in [["peck", "touch_peck"]]:
		_touch(input, 2, (GullInput.TOUCH_BUTTONS[pair[0]] as Rect2).get_center(), true)
		input.update_player(gull, 160)
		check.call(bool(input.get(pair[1])) and input.aim_finger == 1 and _near(gull.aim, gull.position + Vector2(0, 0.5) * radius), "stick and %s work with two fingers" % pair[0])
		_touch(input, 2, (GullInput.TOUCH_BUTTONS[pair[0]] as Rect2).get_center(), false)
	# Right-thumb dive stick: push starts the dive aim, owns aim, release ends it.
	input.touch_dive = false
	var circle: Vector2 = GullInput.DIVE_STICK_CENTER
	var dive_radius: float = float(Config.tuning.touch.dive_stick_radius)
	_touch(input, 2, circle, true)
	input.update_player(gull, 160)
	check.call(input.dive_finger == 2 and not input.touch_dive and not input.dive_held, "dive circle touch inside the deadzone does not dive")
	_drag(input, 2, circle + Vector2(-dive_radius, 0))
	input.update_player(gull, 160)
	check.call(input.touch_dive and input.dive_held and _near(gull.aim, gull.position + Vector2(-1, 0) * radius), "pushing the dive stick starts a dive aimed that way")
	input.touch_dive = false
	_drag(input, 1, Vector2(100, 90))
	input.update_player(gull, 160)
	check.call(_near(gull.aim, gull.position + Vector2(-1, 0) * radius) and not input.touch_dive, "left stick does not change aim while the dive stick is held")
	_drag(input, 2, circle)
	input.update_player(gull, 160)
	check.call(input.dive_held and not _near(gull.aim, gull.position + Vector2(0, -1) * radius), "recentring the dive stick keeps its ownership of the aim")
	_touch(input, 2, circle, false)
	input.update_player(gull, 160)
	check.call(not input.dive_held and input.dive_finger == GullInput.NO_FINGER and _near(gull.aim, gull.position + Vector2(0, -10.0 / stick_radius) * radius), "releasing the dive stick returns aim to the left stick")
	_drag(input, 1, Vector2(100, 112))
	_touch(input, 3, circle, true)
	check.call(input.aim_finger == 1 and input.dive_finger == 3, "dive circle touch never starts the left stick")
	input.clear_touch()
	# iOS WebKit reports large negative touch indices; they must still count as real fingers.
	var ios_a: int = -26663660
	var ios_b: int = -26663662
	var fly_c: Vector2 = GullInput.FLY_STICK_CENTER
	_touch(input, ios_a, fly_c, true)
	_drag(input, ios_a, fly_c + Vector2(stick_radius * 0.5, -stick_radius * 0.5))
	input.update_player(gull, 160)
	check.call(input.aim_finger == ios_a and input.touch_stick() != Vector2.ZERO and gull.aim.x > gull.position.x and gull.aim.y < gull.position.y, "a large negative iOS touch index drives the FLY stick")
	_touch(input, ios_a, fly_c, false)
	check.call(input.aim_finger == GullInput.NO_FINGER, "releasing an iOS-index finger frees the FLY stick")
	_touch(input, ios_b, circle, true)
	_touch(input, ios_b, circle, false)
	check.call(input.touch_dive and input.dive_finger == GullInput.NO_FINGER, "a quick iOS-index tap on the DIVE circle dives")
	input.touch_dive = false
	var peck_c: Vector2 = (GullInput.TOUCH_BUTTONS.peck as Rect2).get_center()
	_touch(input, ios_b, peck_c, true)
	var held_down: bool = input.peck_held
	_touch(input, ios_b, peck_c, false)
	check.call(held_down and not input.peck_held, "an iOS-index finger holds and releases PECK")
	input.clear_touch()
	_touch(input, 1, Vector2(100, 100), true)
	_drag(input, 1, Vector2(100, 112))
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
	check.call(input.aim_finger == GullInput.NO_FINGER, "touch in the top bar does not start the stick")
	_touch(input, 1, (GullInput.TOUCH_BUTTONS.peck as Rect2).get_center(), true)
	check.call(input.aim_finger == GullInput.NO_FINGER, "touch on a button does not start the stick")
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
	_drag(input, 1, Vector2(140, 100))
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
	# Approach assist: gliding down with the left stick bends the aim by approach_assist_strength.
	Config.tuning.touch.approach_assist_strength = approach
	check.call(is_equal_approx(approach, 0.25), "approach assist strength is 0.25")
	_touch(input, 1, Vector2(100, 100), false)
	_touch(input, 1, Vector2(100, 100), true)
	_drag(input, 1, Vector2(118, 106))
	gull.state = BeachGull.State.GLIDE
	var stick_angle: float = Vector2(18, 6).angle()
	var toward: float = (target.food_position() - gull.position).angle()
	input.update_player(gull, 160)
	check.call(absf((gull.aim - gull.position).angle() - lerpf(stick_angle, toward, approach)) < 0.02, "approach assist bends a downward glide toward a target at 0.25")
	_drag(input, 1, Vector2(118, 94))
	input.update_player(gull, 160)
	check.call(absf((gull.aim - gull.position).angle() - Vector2(18, -6).angle()) < 0.001, "no approach assist while gliding upward")
	_drag(input, 1, Vector2(140, 100))
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
	# Prompts follow the last device used; WASD/arrows never count as a pad (player feedback F2).
	var key := InputEventKey.new()
	key.physical_keycode = KEY_A
	key.pressed = true
	input._input(key)
	Input.action_press("aim_left")
	input.update_player(gull, 160)
	Input.action_release("aim_left")
	check.call(not input.gamepad and input.key_aim, "WASD steering keeps keyboard prompts")
	gull.state = BeachGull.State.GLIDE
	gull.velocity = Vector2(30, 0)
	input.update_player(gull, 160)
	check.call(_near(gull.aim, gull.position + Vector2(radius, 0)), "released keys hold the heading, not the stale mouse position")
	var drift := InputEventJoypadMotion.new()
	drift.axis = JOY_AXIS_LEFT_X
	drift.axis_value = 0.1
	input._input(drift)
	check.call(not input.gamepad, "pad stick drift never switches prompts to the pad")
	var pad := InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_A
	pad.pressed = true
	input._input(pad)
	check.call(input.gamepad, "a pad button switches prompts to the pad")
	input._input(key)
	check.call(not input.gamepad, "a key press switches prompts back to the keyboard")
	_mouse_move(input)
	check.call(not input.key_aim, "mouse motion hands aim back to the mouse")
	host.main.clear_game()
	await host.settle()
	# Mouse emulation is off, so a finger must still press menu buttons (iPhone: nothing responded).
	host.main._navigate("title")
	await host.settle()
	var arcade: Button = null
	for button: Node in host.main.menus.find_children("*","Button",true,false):
		if (button as Button).text.begins_with("ARCADE"):
			arcade = button as Button
	check.call(arcade != null,"title menu has an ARCADE button to tap")
	if arcade != null:
		var tap: Vector2 = arcade.get_global_rect().get_center()
		var press := InputEventScreenTouch.new()
		press.index = 0
		press.position = tap
		press.pressed = true
		host.main._input(press)
		await host.settle()
		var release := InputEventScreenTouch.new()
		release.index = 0
		release.position = tap
		release.pressed = false
		host.main._input(release)
		await host.settle()
		check.call(host.main.screen == "pick","a touch tap presses the ARCADE button and opens the gull picker")
	host.main._navigate("title")
	await host.settle()

static func _place_target(target: BeachTarget, at: Vector2) -> void:
	target.position += at - target.food_position()


static func _push(host: Node, event: InputEvent) -> void:
	host.get_viewport().push_input(event)

static func _vtouch(host: Node, index: int, pos: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = pos
	event.pressed = pressed
	_push(host, event)

static func _vdrag(host: Node, index: int, pos: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = pos
	_push(host, event)

## Task 064: FLY stick (steer + flap-up), DIVE tap vs drag, the explainer card, and the "cannot steer" root cause.
static func _rework_checks(host: Node, check: Callable) -> void:
	var sr: float = float(Config.tuning.touch.stick_radius)
	var thr: float = float(Config.tuning.touch.flap_up_threshold)
	var rest: Vector2 = GullInput.FLY_STICK_CENTER
	# Layout: the resting ring and every button fit the 320x180 canvas, clear of the HUD bar, DIVE circle and each other.
	var ring := Rect2(rest - Vector2(sr, sr), Vector2(sr, sr) * 2.0)
	check.call(Rect2(8, 28, 304, 144).encloses(ring), "FLY ring fits the canvas with margin below the HUD bar: %s" % ring)
	var dive_ring := Rect2(GullInput.DIVE_STICK_CENTER - Vector2(20, 20), Vector2(40, 40))
	var boxes: Array[Rect2] = [GullInput.SLOWMO_BUTTON]
	for kind: String in GullInput.TOUCH_BUTTONS:
		boxes.append(GullInput.TOUCH_BUTTONS[kind])
	for index: int in boxes.size():
		check.call(boxes[index].size.x >= 52 and boxes[index].size.y >= 30 and not boxes[index].intersects(ring) and not boxes[index].intersects(dive_ring) and Rect2(0, 28, 320, 152).encloses(boxes[index]), "touch button %d is thumb sized and clear of both circles" % index)
	check.call(boxes.size() == 2 and not boxes[0].intersects(boxes[1]) and not GullInput.TOUCH_BUTTONS.has("flap"), "no FLAP button; SLOW-MO and PECK do not overlap")
	check.call(not ring.intersects(dive_ring), "the FLY and DIVE circles never overlap")
	BeachGame.trainer_cards = false
	host.main.start_level(2)
	await host.settle()
	var game: BeachGame = host.main.game
	game.set_physics_process(false)
	game.intro = 0
	game.running = true
	var input: GullInput = game.input
	input.enabled = true
	input.touch_visible = true
	input.clear_touch()
	var gull: BeachGull = game.player
	gull.position = Vector2(200, 80)
	gull.state = BeachGull.State.GLIDE
	gull.velocity = Vector2.ZERO
	var radius: float = float(Config.tuning.flight.cursor_radius)
	# Root cause of "cannot steer with the left thumb": a finger on the stick lost to stale key/pad/mouse state and to a dive stick latch.
	input.gamepad = true
	input.key_aim = true
	input.dive_held = true
	input.touch_active = false
	_vtouch(host, 1, Vector2(100, 100), true)
	_vdrag(host, 1, Vector2(100 + sr, 100))
	input.update_player(gull, 160)
	check.call(input.aim_finger == 1 and gull.aim.x > gull.position.x + radius * 0.9, "left drag steers even with stale pad, key and dive-latch state (aim %s)" % gull.aim)
	_vdrag(host, 1, Vector2(100 - sr, 100))
	input.update_player(gull, 160)
	check.call(gull.aim.x < gull.position.x - radius * 0.9, "left drag back the other way turns the aim")
	# Flap-up: threshold, tap, leaving the zone.
	_vtouch(host, 1, Vector2(100, 100), false)
	input.flap_tap = false
	_vtouch(host, 1, Vector2(100, 100), true)
	_vdrag(host, 1, Vector2(100, 100 - sr * (thr - 0.1)))
	input.update_player(gull, 160)
	check.call(not gull.climb and not input.flap_tap and not gull.flap_tap_pending, "FLY below the up threshold does not flap")
	_vdrag(host, 1, Vector2(100, 100 - sr * (thr + 0.2)))
	check.call(input.flap_tap and input.touch_climb, "FLY past the up threshold latches a flap tap")
	input.update_player(gull, 160)
	check.call(gull.climb and gull.flap_tap_pending and not input.flap_tap, "FLY up climbs and hands the tap to the gull")
	gull.flap_tap_pending = false
	_vdrag(host, 1, Vector2(100, 100 - sr * (thr + 0.3)))
	input.update_player(gull, 160)
	check.call(not gull.flap_tap_pending, "staying in the zone is one tap, not a stream")
	_vdrag(host, 1, Vector2(100 + sr, 100))
	input.update_player(gull, 160)
	check.call(not gull.climb, "pointing sideways stops climbing")
	_vtouch(host, 1, Vector2(100 + sr, 100), false)
	check.call(input.stick_anchor == rest and input.aim_finger == GullInput.NO_FINGER and not input.touch_climb, "release returns the ring to rest")
	# Starting inside the resting ring measures from its centre; outside re-anchors.
	_vtouch(host, 2, rest + Vector2(sr * 0.5, 0), true)
	check.call(input.stick_anchor == rest and input.touch_stick().x > 0.45, "a touch inside the ring measures from its centre")
	_vtouch(host, 2, rest, false)
	_vtouch(host, 2, Vector2(120, 60), true)
	check.call(input.stick_anchor == Vector2(120, 60), "a touch elsewhere in the left zone re-anchors the ring")
	_vtouch(host, 2, Vector2(120, 60), false)
	_vtouch(host, 2, Vector2(160, 100), true)
	check.call(input.aim_finger == GullInput.NO_FINGER, "the right side of the screen does not grab the FLY stick")
	_vtouch(host, 2, Vector2(160, 100), false)
	# A finger that landed while input was off (a card closing) still steers once it drags.
	_vdrag(host, 5, Vector2(90, 100))
	check.call(input.aim_finger == 5, "a drag from an unseen finger in the left zone grabs the stick")
	_vtouch(host, 5, Vector2(90, 100), false)
	# DIVE circle: a tap dives along the heading with assist; a drag aims; a slow press does nothing.
	var circle: Vector2 = GullInput.DIVE_STICK_CENTER
	input.touch_dive = false
	_vtouch(host, 3, circle, true)
	_vtouch(host, 3, circle, false)
	check.call(input.touch_dive and not input.dive_held, "a quick tap in the DIVE circle starts a dive")
	gull.velocity = Vector2(60, 0)
	input.update_player(gull, 160)
	check.call(absf((gull.aim - gull.position).angle()) < 0.01, "a tap dive follows the current heading")
	input.touch_dive = false
	_vtouch(host, 3, circle, true)
	input.dive_down_msec -= int(float(Config.tuning.touch.dive_tap_time) * 1000.0) + 100
	_vtouch(host, 3, circle, false)
	check.call(not input.touch_dive, "a slow press in the DIVE circle is not a tap")
	_vtouch(host, 3, circle, true)
	_vdrag(host, 3, circle + Vector2(0, 20))
	input.update_player(gull, 160)
	_vtouch(host, 3, circle + Vector2(0, 20), false)
	check.call(input.touch_dive and gull.aim.y > gull.position.y + radius * 0.9 and not input.dive_held, "dragging from the DIVE circle dives in the drag direction, release ends it")
	input.touch_dive = false
	# Real-flow steering through physics: the gull turns when the left thumb drags.
	game.set_physics_process(true)
	gull.state = BeachGull.State.GLIDE
	gull.position = Vector2(200, 80)
	gull.velocity = Vector2.ZERO
	input.clear_touch()
	input.touch_active = false
	_vtouch(host, 6, Vector2(100, 100), true)
	_vdrag(host, 6, Vector2(100 - sr, 100))
	for i: int in 10:
		await host.get_tree().physics_frame
	check.call(gull.velocity.x < -5.0, "a left drag turns the gull left in the running game (vx %.1f)" % gull.velocity.x)
	_vtouch(host, 6, Vector2(100 - sr, 100), false)
	# Touch explainer: once per session, touch only.
	game.set_physics_process(false)
	host.main.clear_game()
	GullInput.touch_explained = false
	host.main.start_level(2)
	await host.settle()
	game = host.main.game
	game.input.touch_visible = false
	game.dismiss_intro()
	check.call(not game.trainer_open and not GullInput.touch_explained, "desktop never shows the touch explainer")
	host.main.clear_game()
	host.main.start_level(2)
	await host.settle()
	game = host.main.game
	game.input.touch_visible = true
	game.dismiss_intro()
	var lay: String = game.overlay.trainer_card.lay_label.text
	check.call(game.trainer_open and GullInput.touch_explained and lay.contains("FLY") and lay.contains("DIVE") and game.overlay.trainer_card.how_label.text.contains("PECK"), "touch shows the explainer card after the intro")
	check.call(not game.input.enabled, "the explainer pauses play")
	game.overlay.trainer_card.dismiss()
	check.call(not game.trainer_open and game.input.enabled, "tapping the card continues")
	host.main.clear_game()
	host.main.start_level(2)
	await host.settle()
	game = host.main.game
	game.input.touch_visible = true
	game.dismiss_intro()
	check.call(not game.trainer_open, "the explainer shows only once per session")
	host.main.clear_game()
	await host.settle()
