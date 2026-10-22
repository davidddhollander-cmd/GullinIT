extends RefCounted
## SCORE RULES card: pause menu entry, result-sign link and end-of-training popup.

static func _card(node: Node) -> ScoreRulesCard:
	for child: Node in node.find_children("*", "ScoreRulesCard", true, false):
		if not child.is_queued_for_deletion():
			return child as ScoreRulesCard
	return null

static func run(suite: Node, check: Callable) -> void:
	var main: Node = suite.main
	GameState.progress["1"] = {"training_complete": true, "training_step": BeachGame.TRAINING_LESSONS}
	main.start_level(2)
	main.game.dismiss_intro()
	main._navigate("pause")
	await suite.settle()
	var rules_button: Button = null
	for button: Button in main.menus.find_children("*", "Button", true, false):
		if button.text == "SCORE RULES":
			rules_button = button
	check.call(rules_button != null, "pause menu offers SCORE RULES")
	suite.layout(main.menus)
	suite.menu_font_grid(main.menus)
	if rules_button != null:
		rules_button.pressed.emit()
		await suite.settle()
		var card: ScoreRulesCard = _card(main.menus)
		check.call(card != null and card.close_button.text == "BACK", "pause SCORE RULES opens the card with BACK")
		suite.layout(main.menus)
		suite.menu_font_grid(main.menus)
		var texts: Array[String] = []
		for label: Label in main.menus.find_children("*", "Label", true, false):
			texts.append(label.text)
		for word: String in ["COMBO", "RISKY", "UPWIND", "MUGGED", "COUNTER", "CLEAN RUN", "SWATTED", "CRASH"]:
			check.call(texts.any(func(text: String) -> bool: return text.begins_with(word)), "score rules lists " + word)
		check.call(texts.has("+%d%%" % roundi(float(Config.tuning.score.risky) * 100.0)), "score rules reads bonus values from tuning")
		if card != null:
			card.close_button.pressed.emit()
			await suite.settle()
			check.call(_card(main.menus) == null and rules_button.has_focus(), "closing the card returns to the pause menu")
	main._finished({"score": 400, "base": 380, "clean": 20, "stars": 1, "items": 9, "stuns": 0, "bonuses": {"Risky": 1, "Upwind": 0, "Mugged": 0, "Handover": 0}, "elapsed": 100.0, "casual": false})
	var board: ResultBoard = main.menus.get_child(0) as ResultBoard
	board.finish_tally()
	await suite.settle()
	var link: Button = board.get_node_or_null("RulesLink") as Button
	check.call(link != null and link.size == Vector2(11, 11), "result bonus line has a rules link")
	if link != null:
		link.pressed.emit()
		await suite.settle()
		check.call(_card(board) != null, "result rules link opens the card")
		_card(board).close()
		await suite.settle()
	main.start_level(1, true)
	main.game.dismiss_intro()
	main.game.lesson = BeachGame.TRAINING_LESSONS
	main.game.finish()
	await suite.settle()
	var training_card: ScoreRulesCard = _card(main.menus)
	check.call(training_card != null and training_card.close_button.text == "GOT IT", "finishing training pops up the score rules with GOT IT")
	suite.layout(main.menus)
	suite.menu_font_grid(main.menus)
	if training_card != null:
		training_card.close_button.pressed.emit()
		await suite.settle()
		var training_board: ResultBoard = main.menus.get_child(0) as ResultBoard
		check.call(_card(main.menus) == null and not training_board.buttons.is_empty() and training_board.buttons[0].has_focus(), "GOT IT reveals the training-complete sign")
	main.clear_game()
	await suite.settle()
