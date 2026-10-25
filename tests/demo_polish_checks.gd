extends RefCounted
## Demo polish: contextual hint slot, compact touch cluster and the levels 1-3 demo lock.
const GOAL_PANEL := Rect2(232,44,84,29)
const MINIMAP := Rect2(108,170,106,7)
const OLD_TOUCH_AREA := 3 * 51 * 27

static func _buttons(node: Node, found: Array[Button]) -> Array[Button]:
	for child: Node in node.get_children():
		if child is Button:
			found.append(child)
		_buttons(child, found)
	return found

static func _labels(node: Node, found: Array[String]) -> Array[String]:
	for child: Node in node.get_children():
		if child is Label:
			found.append((child as Label).text)
		_labels(child, found)
	return found

static func _captions(node: Node) -> Array[String]:
	var result: Array[String] = []
	for button: Button in _buttons(node, []):
		result.append(button.text)
	return result

static func run(suite: Node, check: Callable) -> void:
	var menu_theme: Theme = BeachUI.theme()
	check.call(menu_theme.default_font.resource_path.ends_with("gull_pixel.fnt"), "menu keeps the original pixel font")
	check.call(menu_theme.get_color("font_color","Button") == BeachUI.CREAM, "menu buttons are cream normally")
	check.call(menu_theme.get_color("font_focus_color","Button") == BeachUI.GOLD, "selected menu button is gold")
	check.call(menu_theme.get_color("font_hover_color","Button") == BeachUI.CORAL and menu_theme.get_color("font_pressed_color","Button") == BeachUI.CORAL, "hovered and pressed menu buttons are coral")
	check.call(menu_theme.get_color("font_outline_color","Button") == BeachUI.INK and menu_theme.get_constant("outline_size","Button") == 1, "menu buttons have a one-pixel navy outline")
	await _demo_lock_checks(suite, check)
	await _readability_checks(suite, check)
	await _hint_checks(suite, check)
	await _touch_checks(suite, check)

static func _demo_lock_checks(suite: Node, check: Callable) -> void:
	var saved_demo: Dictionary = GameState.demo.duplicate()
	var saved_unlock: bool = GameState.unlock_all
	var saved_progress: Dictionary = GameState.progress.duplicate(true)
	GameState.load_demo()
	check.call(bool(GameState.demo.enabled) and int(GameState.demo.last_level) == 3, "data/demo.json enables the three-level demo")
	GameState.demo = {"enabled": true, "last_level": 3, "feedback_url": ""}
	GameState.unlock_all = true
	check.call(GameState.unlocked(3) and not GameState.unlocked(4) and not GameState.unlocked(5) and not GameState.unlocked(6), "demo locks levels 4-6 even with unlock_all")
	check.call(GameState.last_playable_level() == 3 and GameState.demo_locked(4) and not GameState.demo_locked(3), "demo reports level 3 as the final playable level")
	suite.main._navigate("start", 4)
	check.call(not is_instance_valid(suite.main.game) or int(suite.main.game.level.id) != 4, "navigation cannot start a demo-locked level")
	suite.main.clear_game()
	suite.main._navigate("select")
	await suite.settle()
	var full_game: int = 0
	for button: Button in _buttons(suite.main.menus, []):
		if "FULL GAME" in button.text:
			full_game += 1
			check.call(button.disabled, "full-game level card is disabled: " + button.text.replace("\n", " "))
	check.call(full_game == 3, "level select marks three full-game levels (found %d)" % full_game)
	check.call(not "FEEDBACK" in _captions(suite.main.menus), "no feedback button without a feedback URL")
	suite.layout(suite.main.menus)
	suite.menu_font_grid(suite.main.menus)
	GameState.demo.feedback_url = "https://example.com/gullin-feedback"
	suite.main._navigate("select")
	await suite.settle()
	check.call("FEEDBACK" in _captions(suite.main.menus), "level select offers feedback when a URL is set")
	suite.layout(suite.main.menus)
	var passed := {"score": 400, "base": 380, "clean": 20, "stars": 1, "items": 9, "stuns": 0, "bonuses": {"Risky": 0, "Upwind": 0, "Mugged": 0}, "elapsed": 100.0, "casual": false}
	suite.main.menus.results(Config.levels[2], passed)
	var board: ResultBoard = suite.main.menus.get_child(0) as ResultBoard
	board.finish_tally()
	await suite.settle()
	var captions: Array[String] = _captions(board)
	var labels: Array[String] = _labels(board, [])
	var demo_line: bool = false
	for text: String in labels:
		demo_line = demo_line or "DEMO COMPLETE" in text
	check.call(board.demo_finished() and demo_line, "clearing level 3 shows the demo-complete line")
	check.call(not "NEXT >" in captions and "FEEDBACK" in captions, "demo end card swaps NEXT for FEEDBACK: " + str(captions))
	suite.layout(suite.main.menus)
	suite.menu_font_grid(suite.main.menus)
	await suite.snapshot("demo-complete")
	GameState.progress["2"] = {"stars": 1, "best": 300}
	suite.main.menus.results(Config.levels[1], passed)
	board = suite.main.menus.get_child(0) as ResultBoard
	board.finish_tally()
	check.call(not board.demo_finished() and "NEXT >" in _captions(board), "level 2 still offers NEXT to level 3")
	var failed: Dictionary = passed.duplicate()
	failed.stars = 0
	suite.main.menus.results(Config.levels[2], failed)
	board = suite.main.menus.get_child(0) as ResultBoard
	check.call(not board.demo_finished(), "a failed level 3 run is not a demo completion")
	GameState.demo = {"enabled": false, "last_level": 3, "feedback_url": ""}
	check.call(GameState.unlocked(4), "disabling the demo restores normal unlock rules")
	GameState.demo = saved_demo
	GameState.unlock_all = saved_unlock
	GameState.progress = saved_progress
	suite.main.menus.hide()

static func _readability_checks(suite: Node, check: Callable) -> void:
	suite.main.start_level(2)
	var game: BeachGame = suite.main.game
	game.set_physics_process(false)
	var overlay: BeachOverlay = game.overlay
	for seconds: int in [58,9,0]:
		game.elapsed = float(game.level.time_limit)-seconds
		overlay._process(0.0)
		check.call(overlay.time_label.text == "%02d" % seconds,"timer shows only padded digits: "+overlay.time_label.text)
	for score: int in [249,250,399,400,550]:
		game.score.points = score
		var index: int = 0 if score < 250 else (1 if score < 400 else 2)
		var status: Dictionary = overlay.goal_status()
		check.call(int(status.goal) == int(game.level.stars[index]),"HUD advances to the next star at %d points" % score)
		check.call(overlay.font.get_string_size(str(status.title),HORIZONTAL_ALIGNMENT_LEFT,-1,8).x <= 74,"star title fits goal box: "+str(status.title))
	game.casual = true
	game.score.items = int(Config.tuning.score.casual_items)
	await suite.settle()
	check.call(overlay.goal_status().title == "PRACTICE","casual goal keeps PRACTICE")
	_top_bar_checks(overlay,check)
	game.training = true
	await suite.settle()
	_top_bar_checks(overlay,check)
	var board := ResultBoard.new()
	board.level = game.level
	board.result = {"stars":1,"casual":false,"elapsed":120.0}
	var text: String = board._record_text()
	check.call(text == "FEATHERS %d" % GameState.feathers(),"arcade result bottom line shows Feathers only: "+text)
	board.result.feathers_earned = 1
	check.call(board._record_text() == "+1 FEATHER  /  FEATHERS %d" % GameState.feathers(),"one earned Feather is singular")
	board.result.feathers_earned = 2
	check.call(board._record_text().begins_with("+2 FEATHERS  /  "),"several earned Feathers are plural")
	board.free()
	suite.main.clear_game()
	await suite.settle()

static func _top_bar_checks(overlay: BeachOverlay, check: Callable) -> void:
	check.call(overlay.top.get_global_rect().end.y<=BeachOverlay.TOP_BAR_HEIGHT-3,"compact status row leaves room for combo meter")
	for item: Control in [overlay.score_label,overlay.time_label,overlay.wind_label,overlay.pause_button]:
		var rect: Rect2 = item.get_global_rect()
		var minimum: Vector2 = item.get_combined_minimum_size()
		check.call(rect.position.y>=0 and rect.end.y<=BeachOverlay.TOP_BAR_HEIGHT,"status text/button stays inside thinner bar: "+item.text)
		check.call(minimum.x<=item.size.x and minimum.y<=item.size.y,"compact status text fits: "+item.text)

static func _hint_checks(suite: Node, check: Callable) -> void:
	suite.main.start_level(2)
	var game: BeachGame = suite.main.game
	game.set_physics_process(false)
	game.intro = 0
	game.running = true
	game.input.touch_visible = false
	game.input.gamepad = false
	var overlay: BeachOverlay = game.overlay
	game.player.position = Vector2(60, game.player.ground_y())
	game.player.land()
	await suite.settle()
	_top_bar_checks(overlay,check)
	var hint: Dictionary = overlay.context_hint()
	check.call(not hint.is_empty() and "SPACE" in str(hint.text), "grounded hint uses keyboard wording: " + str(hint))
	game.input.touch_visible = true
	check.call("FLAP" in str(overlay.context_hint().text), "grounded hint uses touch wording")
	game.input.touch_visible = false
	var row: Control = overlay.score_announcement.get_parent() as Control
	var callout := Rect2(0, row.offset_top, 320, row.offset_bottom - row.offset_top)
	var signs: Array[Rect2] = []
	for sign: Dictionary in game.beach.sign_layouts():
		signs.append(sign.rect)
	for text: String in ["WALK FOR SCRAPS / HOLD SPACE TO FLY", "LANDING / HOLD SPACE TO CLIMB", "PECK SPENT - DIVE AGAIN", "TAP E AT THE SNACK", "TAP PECK AT TODDLER", "PULL UP! CRASH AHEAD"]:
		var box: Rect2 = overlay.hint_rect(text)
		check.call(box.position.x >= 0 and box.end.x <= 320 and box.position.y >= BeachOverlay.TOP_BAR_HEIGHT, "hint stays on screen below the HUD: " + text)
		check.call(not box.intersects(GOAL_PANEL), "hint clears the goal panel: " + text + " " + str(box))
		check.call(not box.intersects(callout), "hint clears the score callout row: " + text)
		var clear_of_signs: bool = true
		for board: Rect2 in signs:
			clear_of_signs = clear_of_signs and box.end.y <= board.position.y
		check.call(clear_of_signs, "hint sits above every zone sign board: " + text)
	await suite.snapshot("hint-grounded")
	suite.main.clear_game()
	suite.main.start_level(1, true)
	game = suite.main.game
	game.set_physics_process(false)
	game.intro = 0
	game.running = true
	overlay = game.overlay
	game.player.position = Vector2(60, game.player.ground_y())
	game.player.land()
	await suite.settle()
	var panel: Rect2 = overlay.training_panel.get_global_rect()
	_top_bar_checks(overlay,check)
	var box: Rect2 = overlay.hint_rect("WALK FOR SCRAPS / HOLD SPACE TO FLY")
	check.call(panel.size.y > 0 and box.position.y >= panel.end.y and not box.intersects(panel), "training hint sits below the lesson panel: " + str(box) + " panel " + str(panel))
	var training_signs: bool = true
	for sign: Dictionary in game.beach.sign_layouts():
		training_signs = training_signs and box.end.y <= (sign.rect as Rect2).position.y
	check.call(training_signs, "training hint stays above the zone signs")
	overlay.show_score_announcement("ice_cream", 15)
	var first_score_font: Font = overlay.score_announcement.get_theme_font("font")
	check.call(first_score_font.resource_path.ends_with("arcade_score_blue.fnt"), "first food score uses colorful font 1")
	overlay.show_score_announcement("ice_cream", 15)
	var second_score_font: Font = overlay.score_announcement.get_theme_font("font")
	check.call(second_score_font.resource_path.ends_with("arcade_score_hot.fnt"), "next food score alternates to colorful font 2")
	check.call(is_equal_approx(BeachOverlay.SCORE_ANNOUNCEMENT_HOLD, 3.0), "food score holds for 3 seconds before fading")
	check.call(is_equal_approx(BeachOverlay.SCORE_ANNOUNCEMENT_FADE, 1.5), "food score fades over 1.5 seconds")
	var score_tween: Tween = overlay.score_announcement_tween
	score_tween.pause()
	score_tween.custom_step(3.0)
	check.call(overlay.score_announcement.visible and is_equal_approx(overlay.score_announcement.modulate.a, 1.0), "food score is still fully visible 3s in")
	score_tween.custom_step(0.75)
	check.call(overlay.score_announcement.visible and overlay.score_announcement.modulate.a < 1.0 and overlay.score_announcement.modulate.a > 0.0, "food score is mid-fade at 3.75s")
	score_tween.custom_step(1.0)
	check.call(not overlay.score_announcement.visible, "food score is hidden after ~4.6s")
	overlay.show_score_announcement("ice_cream", 15)
	row = overlay.score_announcement.get_parent() as Control
	check.call(row.offset_top >= box.end.y, "training score callout sits below the hint")
	var callout_rect := Rect2(0, row.offset_top, 320, row.offset_bottom - row.offset_top)
	var callout_clear: bool = callout_rect.end.y <= 160.0
	for sign: Dictionary in game.beach.sign_layouts():
		callout_clear = callout_clear and not callout_rect.intersects(sign.rect)
	check.call(callout_clear, "training score callout clears the zone signs: " + str(callout_rect))
	check.call(not overlay.you_marker_rect(game.player.position - Vector2(game.camera_x - 160, 0)).intersects(box), "YOU marker avoids the hint")
	await suite.snapshot("hint-training")
	suite.main.clear_game()
	await suite.settle()

static func _touch_checks(suite: Node, check: Callable) -> void:
	var area: float = 0.0
	var kinds: Array = GullInput.TOUCH_BUTTONS.keys()
	for kind: String in kinds:
		var box: Rect2 = GullInput.TOUCH_BUTTONS[kind]
		area += box.get_area()
		check.call(box.position.x >= 0 and box.end.x <= 320 and box.position.y >= 28 and box.end.y <= 180, "touch button on screen: " + kind)
		check.call(not box.intersects(MINIMAP) and not box.intersects(GOAL_PANEL), "touch button clears minimap and goal panel: " + kind)
		check.call(GullInput.touch_button_at(box.get_center()) == kind, "touch hit test matches drawn button: " + kind)
		for other: String in kinds:
			if other != kind:
				check.call(not box.intersects(GullInput.TOUCH_BUTTONS[other]), "touch buttons do not overlap: %s/%s" % [kind, other])
	check.call(area <= OLD_TOUCH_AREA * 0.75, "touch cluster covers at least 25%% less screen (%d vs %d)" % [area, OLD_TOUCH_AREA])
	check.call(GullInput.touch_button_at(Vector2(160, 160)) == "" and GullInput.touch_button_at(Vector2(120, 100)) == "", "beach outside the cluster stays available for aiming")
	suite.main.start_level(2)
	var game: BeachGame = suite.main.game
	game.set_physics_process(false)
	game.intro = 0
	game.running = true
	game.input.enabled = true
	for pair: Array in [["peck", "touch_peck"], ["dive", "touch_dive"], ["flap", "touch_climb"]]:
		game.input.clear_touch()
		game.input.touch_dive = false
		var tap := InputEventScreenTouch.new()
		tap.index = 2
		tap.position = (GullInput.TOUCH_BUTTONS[pair[0]] as Rect2).get_center()
		tap.pressed = true
		game.input._input(tap)
		var others: bool = false
		for flag: String in ["touch_peck", "touch_dive", "touch_climb"]:
			if flag != pair[1]:
				others = others or bool(game.input.get(flag))
		check.call(bool(game.input.get(pair[1])) and not others, "touch %s triggers only its own action" % pair[0])
		tap = InputEventScreenTouch.new()
		tap.index = 2
		tap.position = (GullInput.TOUCH_BUTTONS[pair[0]] as Rect2).get_center()
		tap.pressed = false
		game.input._input(tap)
	check.call(not game.input.touch_climb, "releasing FLAP stops climbing")
	var aim_tap := InputEventScreenTouch.new()
	aim_tap.index = 3
	aim_tap.position = Vector2(160, 160)
	aim_tap.pressed = true
	game.input._input(aim_tap)
	check.call(game.input.touch_active and game.input.aim_finger == 3 and game.input.stick_anchor == Vector2(160, 160), "former PECK position now starts the stick")
	game.input.clear_touch()
	game.input.touch_dive = false
	game.input.touch_visible = true
	game.player.state = BeachGull.State.GLIDE
	check.call(not game.overlay.peck_available() and game.overlay.touch_buttons_visible(), "PECK dims while gliding")
	game.player.position = Vector2(60, game.player.ground_y())
	game.player.land()
	check.call(game.overlay.peck_available(), "PECK is fully available on foot")
	game.overlay.queue_redraw()
	await suite.snapshot("touch-cluster")
	suite.main.clear_game()
	await suite.settle()
