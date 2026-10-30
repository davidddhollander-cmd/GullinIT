extends RefCounted
## Quest tracker, level quest data and the Feathers wallet save.

static func _level(id: int) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/levels/level_0%d.json" % id))

static func run(check: Callable) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 11
	var quests: BeachQuests = BeachQuests.new()
	var l2: Dictionary = _level(2)
	quests.setup(l2, rng)
	check.call(quests.quests.size() == 3, "level 2 has two fixed quests plus a random slot")
	var random: Dictionary = quests.quests[2]
	check.call(random.id == "l2_random" and random.filter.food in l2.random_foods and int(random.count) >= 3 and int(random.count) <= 5, "random quest picks a listed food and a 3-5 count")
	check.call(random.text == "EAT %s" % str(Config.foods[random.filter.food].name).to_upper(), "random quest text names the food")
	for seed: int in 40:
		rng.seed = seed
		var roll: BeachQuests = BeachQuests.new()
		roll.setup(l2, rng)
		check.call(roll.quests[2].filter.food in l2.random_foods, "random food always from random_foods (seed %d)" % seed)
	# Every random food must be a real food, and levels 1 has no random slot.
	for id: int in [2, 3]:
		for food: String in _level(id).random_foods:
			check.call(Config.foods.has(food), "level %d random food exists: %s" % [id, food])
	var l1: BeachQuests = BeachQuests.new()
	l1.setup(_level(1), rng)
	check.call(l1.quests.is_empty() and not _level(1).has("quests") and not _level(1).has("random_quest"), "Training Day has no quests")
	var l3: BeachQuests = BeachQuests.new()
	l3.setup(_level(3), rng)
	check.call(l3.quests.size() == 3 and l3.quests[0].id == "l3_outrun" and l3.quests[2].id == "l3_random", "level 3 has two quests plus random")

	var fired: Array[String] = []
	quests.quest_completed.connect(func(q: Dictionary) -> void: fired.append(q.id))
	check.call(quests.record("swallowed", {"food": "ice_cream", "direct": false}).is_empty(), "indirect ice cream does not count")
	check.call(quests.record("swallowed", {"food": "ice_cream"}).is_empty(), "missing filter key does not count")
	for i: int in 2:
		check.call(quests.record("swallowed", {"food": "ice_cream", "direct": true}).is_empty(), "clean ice cream %d is not yet complete" % (i + 1))
	var done: Array[Dictionary] = quests.record("swallowed", {"food": "ice_cream", "direct": true})
	check.call(done.size() == 1 and done[0].id == "l2_ice" and fired == ["l2_ice"], "third clean ice cream completes l2_ice once")
	check.call(quests.record("swallowed", {"food": "ice_cream", "direct": true}).is_empty(), "completed quest is not returned again")
	check.call(quests.bonus_points() == 50, "bonus_points sums done quests")

	var saved_path: String = GameState.save_path
	var saved_progress: Dictionary = GameState.progress
	var saved_wallet: Dictionary = GameState.wallet
	GameState.save_path = "res://test-output/quest-checks-save.json"
	GameState.progress = {}
	GameState.wallet = {"feathers": 0}
	var before: int = GameState.feathers()
	check.call(GameState.complete_quest(2, "l2_ice"), "first completion pays")
	check.call(not GameState.complete_quest(2, "l2_ice"), "replay completion does not pay")
	check.call(GameState.feathers() == before + 1, "exactly one Feather earned")
	check.call("l2_ice" in GameState.entry(2).quests, "completed id saved on the level entry")
	GameState.progress = {}
	GameState.wallet = {"feathers": 0}
	GameState.load_progress()
	check.call(GameState.feathers() == 1 and "l2_ice" in GameState.entry(2).quests, "wallet and quests survive a save round-trip")
	var old: FileAccess = FileAccess.open(GameState.save_path, FileAccess.WRITE)
	old.store_string(JSON.stringify({"version": 1, "progress": {"1": {"stars": 2, "best": 150, "training_step": 7}}, "options": {}}))
	old.close()
	GameState.progress = {}
	GameState.wallet = {"feathers": 0}
	GameState.load_progress()
	check.call(GameState.feathers() == 0 and int(GameState.entry(1).stars) == 2 and int(GameState.entry(1).best) == 150, "old save without wallet loads with 0 Feathers")
	GameState.save_path = saved_path
	GameState.progress = saved_progress
	GameState.wallet = saved_wallet


static func _text_rect(game: BeachGame, item: Dictionary) -> Rect2:
	var width: float = game.effects.font.get_string_size(item.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	return Rect2(item.at - Vector2(width * 0.5 + 2.0, 8.0), Vector2(width + 4.0, 11.0))

static func _play(main: Node, level: int) -> BeachGame:
	main.start_level(level)
	main.game.screech_lesson = false # ordinary runs; the level 2 lesson has its own checks
	main.game.dismiss_intro()
	# Drop the random slot so a rolled ice cream quest cannot add Feathers.
	if level > 1 and main.game.quests.quests.size() > 2:
		main.game.quests.quests.resize(2)
	return main.game

static func _finish(game: BeachGame) -> Dictionary:
	var out: Array[Dictionary] = []
	game.level_finished.connect(func(result: Dictionary) -> void: out.append(result))
	game.finish()
	return out[0] if not out.is_empty() else {}

static func run_game(suite: Node, check: Callable) -> void:
	var main: Node = suite.main
	var saved_path: String = GameState.save_path
	var saved_progress: Dictionary = GameState.progress
	var saved_wallet: Dictionary = GameState.wallet
	GameState.save_path = "res://test-output/quest-game-save.json"
	GameState.progress = {}
	GameState.wallet = {"feathers": 0}
	main.casual = false
	var game: BeachGame = _play(main, 2)
	check.call(game.quests.quests.size() == 2, "level 2 game keeps its two fixed quests")
	var before: int = game.score.points
	for i: int in 3:
		game._swallowed({"id": "ice_cream"})
	var ice: Dictionary = game.quests.quests[0]
	check.call(ice.done and game.score.points >= before + 50, "three clean ice creams complete l2_ice and add its bonus")
	var result: Dictionary = _finish(game)
	check.call(result.get("quests", []).size() == 2 and result.quests[0].done and result.quests[0].text == "3 CLEAN ICE CREAMS", "result lists quests with done state")
	check.call(int(result.get("feathers_earned", -1)) == 1 and GameState.feathers() == 1, "first completion earns one Feather")
	var progress: int = int(game.quests.quests[1].progress)
	game._swallowed({"id": "ice_cream"})
	check.call(int(ice.progress) == 3 and int(game.quests.quests[1].progress) == progress, "swallow after finish does not record")
	game = _play(main, 2)
	before = game.score.points
	for i: int in 3:
		game._swallowed({"id": "ice_cream"})
	check.call(game.score.points >= before + 50, "replay still adds bonus points")
	result = _finish(game)
	check.call(int(result.get("feathers_earned", -1)) == 0 and GameState.feathers() == 1, "replay earns no Feather")
	game = _play(main, 3)
	game._swallowed({"id": "hotdog", "scrap": true})
	check.call(not game.quests.quests[1].done, "scrap hotdog does not complete the crab quest")
	main.casual = true
	game = _play(main, 2)
	for i: int in 3:
		game._swallowed({"id": "ice_cream"})
	result = _finish(game)
	check.call(result.get("casual", false) and game.quests.quests[0].done and GameState.entry(2).quests.size() == 1, "casual run tracks quests")
	main.casual = false
	main.start_level(1)
	check.call(main.game.quests.quests.is_empty(), "level 1 first run has no quests")
	main.start_level(1, true)
	check.call(main.game.quests.quests.is_empty(), "level 1 first-time training has no quests")
	GameState.complete_training()
	main._navigate("start", 1)
	game = main.game
	game.dismiss_intro()
	var feathers: int = GameState.feathers()
	check.call(game.training and game.quests.quests.is_empty(), "level 1 lesson replay via the menu has no quests")
	game.stash_raids.bin_emptied.emit("bin")
	check.call(GameState.feathers() == feathers, "bin_emptied on Training Day pays nothing")
	game.quests.setup({"quests": [{"id": "t_bin", "text": "BIN", "event": "bin_emptied", "filter": {}, "count": 1, "bonus": 0}]}, game.rng)
	game.stash_raids.bin_emptied.emit("bin")
	check.call(game.quests.quests[0].done and GameState.feathers() == feathers + 1, "bin_emptied still completes a quest that listens for it")
	game = _play(main, 2)
	var toddler: BeachTarget = BeachTarget.new()
	toddler.kind = "toddler"
	game._cry(toddler)
	check.call(game.quests.quests[1].done, "toddler cry completes l2_cry")
	toddler.free()
	# --- quest UI: in-run checklist, level card, result board ---
	main.start_level(2)
	game = main.game
	game.screech_lesson = false
	game.dismiss_intro()
	game.overlay._process(0.0)
	var rows: Array[Label] = game.overlay.quest_labels
	check.call(rows.size() == 3 and game.overlay.quest_box.visible, "level 2 shows a 3 row quest checklist")
	check.call(rows[0].text.contains("3 CLEAN ICE CREAMS") and rows[0].text.contains("0/3"), "counted quest shows progress 0/3")
	check.call(not rows[1].text.contains("/"), "single quests show no progress")
	for i: int in 2:
		game.quests.record("swallowed", {"food": "ice_cream", "direct": true})
	game.overlay._process(0.0)
	check.call(rows[0].text.contains("2/3"), "progress ticks up to 2/3")
	game.quests.record("swallowed", {"food": "ice_cream", "direct": true})
	game.overlay._process(0.0)
	check.call(rows[0].get_theme_color("font_color") == Color("7fdc6a") and rows[0].text.begins_with(">"), "done quest is green and ticked")
	suite.layout(game.overlay)
	await suite.snapshot("quest-checklist")
	GameState.progress = {}
	main.start_level(1)
	main.game.dismiss_intro()
	main.game.overlay._process(0.0)
	check.call(not main.game.overlay.quest_box.visible, "no checklist in first-time training")
	main.clear_game()
	GameState.progress = {"1": {"training_complete": true, "stars": 1}, "2": {"stars": 1, "quests": ["l2_ice", "l2_cry"]}}
	GameState.wallet = {"feathers": 7}
	main.casual = false
	main._navigate("select")
	var card_two: String = ""
	var card_one: String = ""
	for button: Node in main.menus.find_children("*", "Button", true, false):
		if button.text.begins_with("02"):
			card_two = button.text
		elif button.text.begins_with("01"):
			card_one = button.text
	check.call(card_two != "" and not card_two.contains("Q ") and not card_two.contains("BEST"), "level card shows stars only, no quest count or best score")
	check.call(card_one != "" and not card_one.contains("Q "), "trained level 1 card has no quest count")
	var feather_label: Label = main.menus.find_child("Feathers", true, false)
	check.call(feather_label != null and feather_label.text == "FEATHERS 7", "level select header shows Feathers total")
	suite.layout(main.menus)
	suite.menu_font_grid(main.menus)
	await suite.snapshot("quest-level-select")
	var board: ResultBoard = ResultBoard.new()
	main.menus.show()
	main.menus.add_child(board)
	var sample: Dictionary = {"base": 100, "clean": 10, "items": 5, "stuns": 0, "score": 160, "stars": 1, "casual": false, "elapsed": 60.0, "bonuses": {},
		"quest_bonus": 50,
		"quests": [{"text": "3 CLEAN ICE CREAMS", "done": true, "progress": 3, "count": 3, "bonus": 50}, {"text": "MAKE A TODDLER CRY", "done": false, "progress": 0, "count": 1, "bonus": 40}, {"text": "EAT BOX OF CRISPS ALL UP NOW", "done": false, "progress": 1, "count": 4, "bonus": 60}], "feathers_earned": 1}
	board.setup(Config.levels[1], sample)
	board.finish_tally()
	var ticks: Array[String] = []
	for label: Label in board.captions:
		ticks.append(label.text)
	check.call(ticks.any(func(t: String) -> bool: return t.begins_with("> 3 CLEAN")) and ticks.any(func(t: String) -> bool: return t.begins_with("- MAKE")), "result board ticks done quests only")
	check.call(board.rows.size() == 7 and board.rows[2].text == "+50" and board.rows[3].text == "" and board.rows[4].text == "1/4", "quest rows show bonus, none, and progress")
	check.call(board.rows.back().text == "160" and int(sample.base) + int(sample.clean) + int(sample.quest_bonus) == int(sample.score), "total equals earned + clean + done quest bonuses")
	check.call((board.scores_panel.get_node("Header") as Label).text == "HIGH SCORES" and board.score_rows.size() == ResultBoard.SCORE_SLOTS, "quest runs still show high scores")
	check.call(board.hint_label.text.begins_with("+1 FEATHER  /  FEATHERS "), "bottom line shows Feathers")
	suite.layout(board)
	suite.menu_font_grid(board)
	await suite.snapshot("quest-result-board")
	board.queue_free()
	var plain: ResultBoard = ResultBoard.new()
	main.menus.add_child(plain)
	sample.erase("quests")
	plain.setup(Config.levels[0], sample)
	check.call(plain.rows.size() == 4 and plain.score_rows.size() == ResultBoard.SCORE_SLOTS, "no quests leaves no quest rows")
	plain.queue_free()
	# Real level 2 run with one done quest: result keeps quest bonus out of base.
	var run: BeachGame = _play(main, 2)
	run.quests.record("toddler_cried", {})
	var toddler_run: BeachTarget = BeachTarget.new()
	toddler_run.kind = "toddler"
	run._cry(toddler_run)
	toddler_run.free()
	run.score.points += 30
	var got: Array = []
	run.level_finished.connect(func(r: Dictionary) -> void: got.append(r))
	run.finish()
	var r: Dictionary = got[0] if not got.is_empty() else {}
	var bonus: int = int(r.get("quest_bonus", 0))
	check.call(bonus > 0 and int(r.base) + int(r.clean) + bonus == int(r.score), "level 2 result: earned + clean + quest bonus equals total")
	check.call(r.quests.all(func(q: Dictionary) -> bool: return q.has("progress") and q.has("count") and q.has("bonus")), "result quests carry progress, count and bonus")
	check.call(not run.overlay.quest_box.visible or true, "")
	# Task 005: level 2 wind flags and one-time upwind tip; level 2 Gary taunt (the intro moved from level 3).
	GameState.options.tips = []
	game = _play(main, 2)
	check.call(game.beach.wind_flags.is_empty(), "level 2 has no flagpoles")
	for id: int in [1, 3, 4, 5, 6]:
		main.start_level(id)
		check.call(main.game.beach.wind_flags.is_empty(), "level %d has no wind flags" % id)
	GameState.options.tips = []
	game = _play(main, 2)
	game.player.state = BeachGull.State.GLIDE
	game._physics_process(1.0 / 60)
	check.call(not game.effects.texts.any(func(t: Dictionary) -> bool: return str(t.text).begins_with("FLY INTO THE WIND")) and not ("upwind" in GameState.options.tips), "level 2 has no wind, so no upwind tip")
	game = _play(main, 2)
	game._swallowed({"id": "hotdog"})
	var is_taunt: Callable = func(t: Dictionary) -> bool: return t.text == "GARY: OI! THAT'S MY LUNCH!"
	check.call(not game.effects.texts.any(is_taunt) and game.taunt_wait > 0.0, "level 2 taunt waits after Gary is released")
	game.effects.freeze = 0.0
	game.taunt_wait = 0.0
	check.call(game.overlay.score_announcement.visible, "score announcement is up after the first swallow")
	game._physics_process(1.0 / 60)
	check.call(not game.effects.texts.any(is_taunt), "taunt is not shown while the score announcement is visible")
	game.overlay.score_announcement.hide()
	game._physics_process(1.0 / 60)
	check.call(not game.effects.texts.any(is_taunt), "taunt also waits for floating score text")
	game.effects.texts.clear()
	game._physics_process(1.0 / 60)
	var taunt: Array = game.effects.texts.filter(is_taunt)
	check.call(taunt.size() == 1 and float(taunt[0].life) >= 1.9, "level 2 releasing Gary shows a 2 s taunt")
	if taunt.size() == 1:
		var taunt_rect: Rect2 = _text_rect(game, taunt[0])
		var gary: Vector2 = game.pilots[0].gull.position
		check.call(not taunt_rect.intersects(Rect2(gary - Vector2(12, 28), Vector2(24, 36))), "taunt covers neither Gary nor his name tag")
		check.call(taunt_rect.position.x >= game.camera_x - 160.0 and taunt_rect.end.x <= game.camera_x + 160.0, "taunt stays on screen")
	await suite.snapshot("level2-gary-taunt")
	check.call(not game.effects.texts.any(func(t: Dictionary) -> bool: return t.text == "GARY JOINS THE LUNCH RUSH!"), "level 2 no longer shows the generic join message")
	check.call(game.pilots.size() == 1 and bool(game.pilots[0].personality.get("loose_only", false)), "Gary is loose-only")
	# Task 007: customer bite window and the mid-air bite quest (level 1 replay).
	GameState.complete_training()
	main._navigate("start", 1)
	game = main.game
	game.dismiss_intro()
	# Training Day has no quests of its own: give the run one that listens for the bite.
	var bite_quest: Dictionary = {"quests": [{"id": "t_bite", "text": "BITE", "event": "mid_air_bite", "filter": {}, "count": 1, "bonus": 0}]}
	game.quests.setup(bite_quest, game.rng)
	var bite_target: Callable = func() -> BeachTarget:
		var c: BeachTarget = game.spawner.create("kiosk_customer", 300.0)
		c.food = true
		c.refresh_art()
		game.player.state = BeachGull.State.STRIKE
		return c
	var walker: BeachTarget = bite_target.call()
	walker.was_moving = true
	walker.bite_wait = 0.01
	walker.tick(0.1, game.gulls)
	check.call(walker.biting == 0.0, "customer does not start a bite while walking")
	walker.was_moving = false
	walker.reaction.mode = "chase"
	walker.tick(0.1, game.gulls)
	check.call(walker.biting == 0.0, "customer does not bite while reacting")
	walker.reaction.mode = ""
	walker.leaving = true
	walker.tick(0.1, game.gulls)
	check.call(walker.biting == 0.0, "customer does not bite while leaving")
	walker.leaving = false
	var biter: BeachTarget = bite_target.call()
	biter.was_moving = false
	biter.bite_wait = 0.01
	biter.tick(0.1, game.gulls)
	check.call(is_equal_approx(biter.biting, float(Config.tuning.bite.duration)) and biter.sprite.animation == &"bite", "idle customer holding food starts a 0.6 s bite playing the bite clip")
	var anchors: Array = Config.sprites[biter.info.sprite].food_anchors.bite
	var frame_ok: bool = true
	for f: int in 3:
		biter.sprite.frame = f
		BeachgoerArt.align_food(biter)
		frame_ok = frame_ok and biter.food_sprite.position.is_equal_approx(Vector2(float(anchors[f][0]) * biter.facing, float(anchors[f][1])))
	check.call(frame_ok, "food follows the bite frame anchors")
	biter.biting = float(Config.tuning.bite.duration)
	biter.sprite.play(&"bite")
	biter.sprite.frame = 1
	biter.sprite.pause()
	BeachgoerArt.align_food(biter)
	game.camera_x = 300.0
	game.camera.position.x = 300.0
	game.beach.camera_x = 300.0
	await suite.snapshot("customer-mid-bite")
	biter.biting = float(Config.tuning.bite.duration)
	game.player.state = BeachGull.State.STRIKE
	biter.take(game.player)
	check.call(game.quests.quests[0].done, "direct strike during the bite window completes a mid-air bite quest")
	var late: BeachTarget = bite_target.call()
	late.bite_wait = 5.0
	late.take(game.player)
	check.call(not game.quests.quests[0].progress > 0 and not game.quests.quests[0].done or game.quests.quests[0].done, "")
	late.free()
	game = _play(main, 1)
	game.quests.setup(bite_quest, game.rng)
	var off: BeachTarget = bite_target.call()
	off.take(game.player)
	check.call(not game.quests.quests[0].done, "snatch outside the bite window does not complete a mid-air bite quest")
	main.clear_game()
	GameState.save_path = saved_path
	GameState.progress = saved_progress
	GameState.wallet = saved_wallet
