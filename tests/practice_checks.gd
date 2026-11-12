extends RefCounted
## Practice mode: title button, three-button menu, and an open-ended Scrap Sands session with one dummy pilot.

static func _button(root: Node, text: String) -> Button:
	for node: Node in root.find_children("*", "Button", true, false):
		if (node as Button).text == text:
			return node as Button
	return null

static func run(suite: Node, check: Callable) -> void:
	var main: Node = suite.main
	main.clear_game()
	main._navigate("title")
	check.call(_button(main.menus, "PRACTICE  >") != null and _button(main.menus, "CASUAL  /  PRACTICE") == null, "title offers PRACTICE instead of CASUAL / PRACTICE")
	main._navigate("practice")
	await suite.settle()
	check.call(main.screen == "practice" and _button(main.menus, "HOW TO SCORE") != null and _button(main.menus, "STEAL TYPES") != null and _button(main.menus, "LET'S PRACTICE!") != null and _button(main.menus, "< BACK") != null, "practice menu has HOW TO SCORE, STEAL TYPES, LET'S PRACTICE! and BACK")
	suite.layout(main.menus)
	_button(main.menus, "HOW TO SCORE").pressed.emit()
	check.call(main.menus.find_children("*", "ScoreRulesCard", true, false).size() == 1, "HOW TO SCORE opens the score rules card")
	(main.menus.find_children("*", "ScoreRulesCard", true, false)[0] as ScoreRulesCard).closed.emit()
	main.menus.find_children("*", "ScoreRulesCard", true, false)[0].queue_free()
	await suite.settle()
	_button(main.menus, "STEAL TYPES").pressed.emit()
	check.call(main.menus.find_children("*", "ScoreWaysCard", true, false).size() == 1, "STEAL TYPES opens the score ways card")
	(main.menus.find_children("*", "ScoreWaysCard", true, false)[0] as ScoreWaysCard).close()
	await suite.settle()
	check.call(main.menus.find_children("*", "ScoreWaysCard", true, false).is_empty(), "the ways card closes again")
	_button(main.menus, "LET'S PRACTICE!").pressed.emit()
	await suite.settle()
	var game: BeachGame = main.game
	game.set_physics_process(false)
	check.call(game != null and game.practice and game.level.id == "scrap_sands" and not game.is_vs() and not game.casual and not game.training, "LET'S PRACTICE! loads Scrap Sands in practice mode")
	check.call(game.pilots.size() == 1 and game.pilots[0].dummy and game.pilots[0].dummy_food == BeachGame.DUMMY_FOOD and game.pending_rivals.is_empty(), "one dummy pilot carrying food, and no other rivals")
	check.call(game.quests.quests.is_empty() and game.mode_name() == "practice", "no quests, analytics mode stays practice")
	game.intro = 0
	game.running = true
	game.elapsed = float(game.level.time_limit) + 500.0
	game.score.items = 99
	game._physics_process(1.0 / 60.0)
	check.call(game.running, "practice never ends on its own")
	game.overlay._process(0.016)
	check.call(game.overlay.time_label.text.is_empty(), "the clock is hidden")
	main._navigate("pause")
	check.call(_button(main.menus, "PRACTICE MENU") != null and _button(main.menus, "LEVEL SELECT") == null and _button(main.menus, "RESTART") != null, "pause menu offers PRACTICE MENU in practice")
	main._navigate("restart")
	check.call(main.game != game and main.game.practice, "RESTART restarts practice")
	# A mugged dummy is re-armed after the pause, so practice can go on.
	var dummy: RivalPilot = main.game.training_dummy()
	main.game.set_physics_process(false)
	dummy.carry_window = 1.0
	dummy.carried = 10
	check.call(dummy.mug() > 0 and dummy.dummy_food.is_empty(), "mugging the dummy empties its beak")
	dummy.gull.state = BeachGull.State.GLIDE
	for i: int in 3:
		main.game._practice_tick(0.5)
	check.call(dummy.dummy_food.is_empty(), "the dummy waits before it is re-armed")
	for i: int in 3:
		main.game._practice_tick(0.5)
	check.call(dummy.dummy_food == BeachGame.DUMMY_FOOD, "the mugged dummy is re-armed with food")
	main._navigate("practice")
	check.call(main.screen == "practice" and not is_instance_valid(main.game), "PRACTICE MENU returns to the practice menu")
	# The gull cycler lists owned gulls only.
	var unlock: Variant = Config.species.get("unlock_all", false)
	var owned: Variant = GameState.wallet.get("owned", [])
	Config.species.unlock_all = false
	GameState.wallet.owned = []
	GameState.options.gull = "herring"
	main._navigate("practice")
	var cycler: Button = main.menus.find_child("GullCycler", true, false)
	check.call(cycler != null and cycler.text == "HERRING GULL", "the cycler shows the chosen gull")
	main._navigate("gull_practice", "kittiwake")
	check.call(GameState.options.gull == "herring", "a locked gull cannot be picked in the practice menu")
	cycler.pressed.emit()
	check.call(GameState.options.gull == "great-black-backed" and cycler.text == "BLACK BACK", "the cycler moves to the next owned gull")
	cycler.pressed.emit()
	check.call(GameState.options.gull == "herring", "the cycler skips the locked kittiwake")
	GameState.wallet.owned = ["kittiwake"]
	main._navigate("gull_practice", "kittiwake")
	check.call(GameState.options.gull == "kittiwake", "an owned gull can be picked")
	Config.species.unlock_all = unlock
	GameState.wallet.owned = owned
	GameState.options.gull = "herring"
	suite.layout(main.menus)
	main._navigate("title")
