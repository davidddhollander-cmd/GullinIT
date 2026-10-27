extends RefCounted
## Task 043: level 2 layout, the first-play screech/brashness/Gang Call lesson, and hold-to-screech on every input.

static func _fresh_level_2(host: Node, lesson_done: bool, species: String = "") -> BeachGame:
	GameState.progress = {"1": {"training_step": 7, "training_complete": true}}
	if lesson_done:
		GameState.progress["2"] = {"screech_lesson_complete": true}
	if species.is_empty():
		Config.levels[1].erase("player_species")
	else:
		Config.levels[1]["player_species"] = species
	host.main.start_level(2)
	Config.levels[1].erase("player_species")
	var game: BeachGame = host.main.game
	game.set_physics_process(false)
	game.intro = 0.0
	game.running = true
	game.input.enabled = true
	return game

static func run(host: Node, check: Callable) -> void:
	_layout_checks(check)
	await _lesson_checks(host, check)
	await _hold_checks(host, check)
	await _toddler_checks(host, check)
	GameState.progress = {"1": {"training_step": 7, "training_complete": true}, "2": {"screech_lesson_complete": true}}

static func _layout_checks(check: Callable) -> void:
	var level: Dictionary = Config.read_json("res://data/levels/level_02.json")
	var stands: Array = level.props.filter(func(p: Dictionary) -> bool: return p.type == "kiosk")
	stands.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.x) < float(b.x))
	var near: float = float(stands[0].x)
	check.call(stands.size() == 2 and near >= 220.0 and near <= 260.0 and float(stands[1].x) > 800.0, "level 2 has an ice-cream stand by the start and one on the right")
	var holders: Array = level.spawns.filter(func(s: Dictionary) -> bool: return s.type == "kiosk_customer" and absf(float(s.x) - near) <= 120.0 and float(s.x) > near and str(s.get("food_id", "")) == "ice_cream")
	check.call(holders.size() == 2, "two ice-cream holders queue just right of the near stand")
	for spawn: Dictionary in level.spawns:
		if spawn.type == "sunbather":
			check.call(float(spawn.x) > 500.0, "level 2 sunbathers are on the right side")
	var mums: Array = level.spawns.filter(func(s: Dictionary) -> bool: return s.type == "picnic_family")
	var toddlers: Array = level.spawns.filter(func(s: Dictionary) -> bool: return s.type == "toddler")
	check.call(mums.size() == 1 and toddlers.size() == 2 and toddlers.all(func(s: Dictionary) -> bool: return s.family_id == mums[0].family_id and s.station == mums[0].station), "level 2 has one mum with two toddlers sharing her family and station")
	check.call(level.has("screech_lesson") and float(level.screech_lesson.start_meter) > 0.0 and float(level.screech_lesson.grab_timeout) > 0.0, "lesson tunables live in the level data")

static func _lesson_checks(host: Node, check: Callable) -> void:
	var game: BeachGame = _fresh_level_2(host, false)
	check.call(game.screech_lesson and game.screech_step == 0 and game.lesson_active() and not game.training, "first herring play of level 2 starts the screech lesson")
	var perch: Dictionary = game.lesson_perch()
	check.call(not perch.is_empty() and absf(float(perch.x) - 240.0) < 40.0, "the lesson perch is the near ice-cream stand roof sign")
	var ring: Vector2 = game.screech_lesson_target()
	check.call(absf(ring.x - float(perch.x)) < 2.0 and ring.y > 40.0 and ring.y < 130.0, "step 1 rings the stand's roof sign")
	# Keys switch with the input device.
	game.input.gamepad = false
	game.input.touch_visible = false
	check.call(game.screech_lesson_text().contains("SIGN"), "step 1 asks for the roof sign: " + game.screech_lesson_text())
	game.overlay._process(0.0)
	game.overlay.queue_redraw()
	await host.snapshot("level2-start-lesson-1")
	var holding: int = 0
	for target: BeachTarget in game.spawner.targets:
		if target.kind == "kiosk_customer" and target.food and target.position.x < 400.0:
			holding += 1
	check.call(holding >= 2, "two shoppers hold food by the stand when the lesson starts")
	# The level clock is paused while the lesson runs.
	for frame: int in 30:
		game._physics_process(1.0 / 60)
	check.call(is_zero_approx(game.elapsed) and game.screech_step == 0, "level timer is paused during the lesson")
	# Step 1: perch.
	var gull: BeachGull = game.player
	gull.support = perch
	gull.state = BeachGull.State.GROUNDED
	gull.velocity = Vector2.ZERO
	gull.position = Vector2(float(perch.x), BeachGull.perch_y(perch, float(perch.x)) - float(Config.tuning.flight.feet_offset))
	game._screech_lesson_tick(0.016)
	check.call(game.screech_step == 1, "landing on the stand's sign finishes step 1")
	check.call(is_equal_approx(game.brash.meter, float(game.screech_settings().start_meter)), "step 2 starts the meter at the data-driven fill")
	game.camera_x = 240.0
	game.camera.position.x = 240.0
	game.beach.camera_x = 240.0
	game.overlay._process(0.0)
	game.overlay.queue_redraw()
	await host.snapshot("level2-lesson-2-screech")
	game.input.gamepad = false
	check.call(game.screech_lesson_text().contains("HOLD E TO SCREECH") and game.screech_lesson_text().contains("BRASH"), "step 2 names the keyboard peck key")
	game.input.gamepad = true
	check.call(game.screech_lesson_text().contains("HOLD X "), "step 2 names the gamepad peck button")
	game.input.gamepad = false
	game.input.touch_visible = true
	check.call(game.screech_lesson_text().contains("HOLD PECK "), "step 2 names the touch PECK button")
	game.input.touch_visible = false
	# Screeching from the perch really fills it (a high perch, so quickly).
	game.peck_hold_pending = true
	game._stop_screech(false)
	var before: float = game.brash.meter
	gull.screech_held = true
	game.peck_hold_pending = true
	game._advance_screech_hold(1.0)
	check.call(game.brash.meter > before, "screeching on the perch fills the meter")
	game._stop_screech(false)
	game.peck_hold_pending = false
	game.brash.meter = 1.0
	game._screech_lesson_tick(0.016)
	check.call(game.screech_step == 2, "a full meter finishes step 2")
	game.input.gamepad = false
	check.call(game.screech_lesson_text().contains("Q") and game.screech_lesson_text().contains("GANG"), "step 3 mentions Q and the gang")
	game.input.touch_visible = true
	check.call(game.screech_lesson_text().contains("CALL"), "step 3 mentions the touch CALL button")
	game.input.touch_visible = false
	# Someone is holding food in range when the gang is called.
	game.camera_x = gull.position.x
	var in_range: int = 0
	for target: BeachTarget in game.spawner.targets:
		if game.snatchable(target) and absf(target.position.x - game.camera_x) < 170.0:
			in_range += 1
	check.call(in_range >= 2, "at least two people hold food in Gang Call range")
	game.start_slowmo()
	check.call(not game.brash.allies.is_empty(), "Q fires Gang Call on a full meter")
	game._screech_lesson_tick(0.016)
	check.call(game.screech_step == 3, "firing Gang Call finishes step 3")
	game.overlay._process(0.0)
	check.call(game.overlay.training_panel.visible and game.overlay.lesson_prompt.text.contains("GRAB"), "the lesson panel shows the grab step")
	# Let the gang land.
	for frame: int in 120:
		game.brash.tick(1.0 / 60)
	var dropped: int = 0
	for item: Dictionary in game.stash_raids.items:
		if item.get("owner") != null:
			dropped += 1
	check.call(dropped >= 1, "the gang knocks food loose for step 4")
	game.player.digestion.collect("ice_cream")
	game._screech_lesson_tick(0.016)
	check.call(not game.screech_lesson and bool(GameState.entry(2).get("screech_lesson_complete", false)), "collecting food finishes and saves the lesson")
	check.call(is_zero_approx(game.brash.meter), "the meter is empty for the real run")
	game.effects.freeze = 0.0
	game._physics_process(1.0 / 60)
	check.call(game.elapsed > 0.0, "the level timer runs after the lesson")
	host.main.clear_game()
	await host.settle()
	# Replay: the saved flag skips the lesson.
	game = _fresh_level_2(host, true)
	check.call(not game.screech_lesson and not game.lesson_active(), "a saved lesson is skipped on replay")
	host.main.clear_game()
	await host.settle()
	# Another species never gets the herring lesson.
	game = _fresh_level_2(host, false, "kittiwake")
	check.call(game.player.species == "kittiwake" and not game.screech_lesson, "non-herring species skip the lesson")
	host.main.clear_game()
	await host.settle()
	# The grab step also ends on its timeout, and skipping is saved.
	game = _fresh_level_2(host, false)
	game.screech_step = 3
	game.screech_clock = 0.0
	game._screech_lesson_tick(float(game.screech_settings().grab_timeout) + 0.1)
	check.call(not game.screech_lesson, "the grab step times out")
	host.main.clear_game()
	await host.settle()
	game = _fresh_level_2(host, false)
	game.end_screech_lesson(false)
	check.call(not game.screech_lesson and bool(GameState.entry(2).get("screech_lesson_complete", false)), "skipping the lesson saves it as done")
	host.main.clear_game()
	await host.settle()

static func _hold_checks(host: Node, check: Callable) -> void:
	var game: BeachGame = _fresh_level_2(host, true)
	var gull: BeachGull = game.player
	var settle_gull: Callable = func() -> void:
		gull.land()
		gull.position = Vector2(300, gull.ground_y())
		gull.velocity = Vector2.ZERO
		gull.aim = gull.position
		gull.climb = false
	settle_gull.call()
	# Gamepad X.
	var pad := InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_X
	pad.pressed = true
	game._unhandled_input(pad)
	check.call(game.peck_hold_pending and not gull.screech_held, "gamepad X press waits to tell a tap from a hold")
	game._advance_screech_hold(BeachGame.SCREECH_HOLD_TIME)
	check.call(gull.screech_held, "holding gamepad X starts the screech")
	var pad_up := InputEventJoypadButton.new()
	pad_up.button_index = JOY_BUTTON_X
	pad_up.pressed = false
	game._unhandled_input(pad_up)
	check.call(not gull.screech_held and not game.peck_hold_pending, "releasing gamepad X stops the screech")
	settle_gull.call()
	game._unhandled_input(pad)
	game._advance_screech_hold(0.05)
	gull.state = BeachGull.State.STRIKE
	game._unhandled_input(pad_up)
	check.call(gull.peck_used and not gull.screech_held, "a gamepad X tap still pecks")
	settle_gull.call()
	# Touch PECK button.
	var area: Rect2 = GullInput.TOUCH_BUTTONS.peck
	var touch := InputEventScreenTouch.new()
	touch.index = 3
	touch.position = area.get_center()
	touch.pressed = true
	game.input._input(touch)
	check.call(game.input.touch_peck and game.input.peck_held, "the touch PECK button reports a held press")
	for frame: int in 20:
		game._physics_process(1.0 / 60)
	check.call(gull.screech_held, "holding the touch PECK button starts the screech")
	var touch_up := InputEventScreenTouch.new()
	touch_up.index = 3
	touch_up.position = area.get_center()
	touch_up.pressed = false
	game.input._input(touch_up)
	game.effects.freeze = 0.0
	game._physics_process(1.0 / 60)
	check.call(not gull.screech_held and not game.peck_hold_touch, "releasing the touch PECK button stops the screech")
	settle_gull.call()
	game.input._input(touch)
	game._physics_process(1.0 / 60)
	check.call(game.peck_hold_touch and game.peck_hold_pending, "a touch PECK press waits to tell a tap from a hold")
	game.input._input(touch_up)
	game.effects.freeze = 0.0
	game._physics_process(1.0 / 60)
	check.call(not gull.screech_held and not game.peck_hold_pending and not game.peck_hold_touch, "a quick touch PECK tap ends as a tap, not a screech")
	host.main.clear_game()
	await host.settle()

static func _toddler_checks(host: Node, check: Callable) -> void:
	var game: BeachGame = _fresh_level_2(host, true)
	var mum: BeachTarget
	var kids: Array[BeachTarget] = []
	for target: BeachTarget in game.spawner.targets:
		if target.kind == "picnic_family":
			mum = target
		elif target.kind == "toddler":
			kids.append(target)
	check.call(mum != null and kids.size() == 2 and mum.family_children.size() == 2 and kids[0].family_parent == mum and kids[1].family_parent == mum, "the mum links both toddlers")
	var quest_before: int = 0
	for quest: Dictionary in game.quests.quests:
		if quest.id == "l2_cry":
			quest_before = int(quest.progress)
	game.player.position = Vector2(kids[1].position.x, 70)
	kids[1].defense = 0
	check.call(kids[1].take(game.player), "a toddler's snack can be taken")
	game.player.digestion.tick(30, false)
	check.call(kids[1].seeking_parent or kids[1].toddler_cry_run_active, "the robbed toddler cries and runs for mum")
	var crying: bool = false
	for quest: Dictionary in game.quests.quests:
		if quest.id == "l2_cry":
			crying = int(quest.progress) > quest_before or bool(quest.done)
	check.call(crying, "making a toddler cry progresses the quest with two toddlers")
	check.call(mum.alert == 1, "the designated mum notices the cry")
	for frame: int in 600:
		kids[1].tick(1.0 / 60, [])
		mum.tick(1.0 / 60, [])
		kids[0].tick(1.0 / 60, [])
	check.call(is_instance_valid(kids[0]) and is_instance_valid(kids[1]) and is_instance_valid(mum), "both toddlers and mum stay in play")
	host.main.clear_game()
	await host.settle()
