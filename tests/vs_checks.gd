extends RefCounted
## VS mode round (task 080): Scrap Sands, the VS level copy, intro, verdict, result sign, board names, analytics.
const PropOverlap := preload("res://tests/prop_overlap_checks.gd")
const ArenaId: String = "scrap_sands"

static func _count(items: Array, type: String) -> int:
	return items.filter(func(item: Dictionary) -> bool: return item.type == type).size()

static func _buttons(node: Node) -> Array[Button]:
	var found: Array[Button] = []
	for child: Node in node.get_children():
		if child is Button:
			found.append(child)
		found.append_array(_buttons(child))
	return found

## Finishes the round with the given scores and returns the result dictionary.
static func _finish(game: BeachGame, mine: int, rival: int) -> Dictionary:
	var box: Array = []
	var catcher: Callable = func(result: Dictionary) -> void: box.append(result)
	game.level_finished.connect(catcher)
	game.score.points = mine
	game.pilots[0].score = rival
	game.finish()
	game.level_finished.disconnect(catcher)
	return box[0] if not box.is_empty() else {}

static func run(suite: Node, check: Callable) -> void:
	var main: Node = suite.main
	main.clear_game()

	# Data and arena.
	var arena: Dictionary = Config.arenas.get(ArenaId, {})
	check.call(int(Config.vs.round_time) == 75 and Config.vs.board_prefix == "vs-" and Config.vs.opponents.gary.entry == "fly_in" and Config.vs.seed_scores.size() == 3, "data/vs.json loads into Config.vs")
	check.call(not arena.is_empty() and arena.name == "Scrap Sands" and int(arena.world.width) == 640 and int(arena.world.promenade_start) == 240, "Scrap Sands loads into Config.arenas")
	check.call(not Config.levels.any(func(level: Dictionary) -> bool: return str(level.id) == ArenaId) and Config.levels.size() == 7, "the arena is not an Arcade level")
	var spawns: Array = arena.spawns
	var props: Array = arena.props
	check.call(_count(spawns, "sunbather") == 1 and _count(spawns, "off_lead_dog") == 1 and _count(spawns, "kiosk_customer") == 3, "Scrap Sands has one sunbather, one dog, three shoppers")
	check.call(_count(props, "kiosk") == 1 and _count(props, "hotdog_stand") == 1 and _count(props, "bin") + _count(props, "wheelie_bin") == 3 and _count(props, "wheelie_bin") == 1, "Scrap Sands has two shops and three bins, one a wheelie bin")
	check.call(_count(props, "beach_palm") == 1 and _count(props, "beach_bench") == 1 and _count(props, "beach_lamp") == 2 and _count(props, "beach_parasol") == 1, "Scrap Sands has a palm, a bench, two lamps and the parasol")
	check.call(spawns.filter(func(s: Dictionary) -> bool: return s.type == "kiosk_customer" and s.station == "hotdogs").size() == 2, "two shoppers queue at the hot-dog stand")
	check.call(not arena.has("quests") and not arena.has("stars") and not arena.has("twist") and arena.rivals.is_empty(), "the arena file carries no quests, stars, twist or rivals")
	var raw: Dictionary = Config.read_json("res://data/arenas/scrap_sands.json")
	check.call(JSON.stringify(arena.props) == JSON.stringify(raw.props) and arena.spawns.size() == raw.spawns.size(), "the level generator leaves the authored arena layout alone")
	var bad: Array[String] = PropOverlap.overlaps(props)
	check.call(bad.is_empty(), "Scrap Sands props do not overlap %s" % str(bad))
	var stands: Array = props.filter(func(prop: Dictionary) -> bool: return prop.type in ["kiosk", "hotdog_stand"])
	check.call(absf(float(stands[0].x) - float(stands[1].x)) >= 140.0, "Scrap Sands stands keep 140 px apart")
	for spawn: Dictionary in spawns:
		check.call(float(spawn.x) >= 12.0 and float(spawn.x) <= float(arena.world.width) - 12.0, "%s at %d is inside the arena" % [spawn.type, int(spawn.x)])
		if spawn.type in ["sunbather", "off_lead_dog"]:
			for stand: Dictionary in stands:
				check.call(absf(float(spawn.x) - float(stand.customer_x)) >= 50.0, "%s at %d clears the %s customer slot" % [spawn.type, int(spawn.x), stand.type])
		if spawn.type == "sunbather":
			for prop: Dictionary in props:
				if prop.type != "beach_parasol":
					check.call(not PropOverlap.actor_overlaps_prop(spawn, prop), "sunbather clears %s at %d" % [prop.type, int(prop.x)])

	# Not in the Arcade level select.
	main._navigate("select")
	check.call(not _buttons(main.menus).any(func(button: Button) -> bool: return button.text.to_upper().contains("SCRAP")), "the Arcade level select does not list Scrap Sands")

	# The VS level copy.
	var before: String = JSON.stringify(Config.arenas[ArenaId])
	var progress_before: String = JSON.stringify(GameState.progress)
	var wallet_before: String = JSON.stringify(GameState.wallet)
	main._navigate("vs_start", {"arena": ArenaId, "opponent": "gary"})
	var game: BeachGame = main.game
	game.set_physics_process(false)
	check.call(game.is_vs() and game.level.rivals.size() == 1 and game.level.rivals[0].name == "Gary" and int(game.level.time_limit) == 75 and game.level.vs.opponent == "gary", "start_vs builds a one-rival, 75 second VS level")
	check.call(JSON.stringify(Config.arenas[ArenaId]) == before and Config.arenas[ArenaId].rivals.is_empty(), "start_vs leaves the source arena untouched")
	check.call(main.screen == "game" and game.pilots.size() == 1 and game.player.position.x < 100.0 and game.mode_name() == "vs", "the round starts with Gary on the beach and the player on the left")
	check.call(game.intro > 1.9 and game.intro <= 2.0 and not game.running and not game.overlay.intro_panel.get_children().is_empty(), "the VS intro card shows for about two seconds")
	check.call(game.quests.quests.is_empty() and not game.training and not game.screech_lesson and not game.trainer_open, "a VS round runs no quests, lessons or trainer cards")
	game.dismiss_intro()
	check.call(game.running and game.entry_pilot != null and game.entry_pilot.gull.rival_name == "Gary" and absf(game.entry_pilot.gull.position.x - game.camera_x) > 150.0, "Gary flies in from off-screen as the round starts")
	await suite.settle()
	game.overlay._process(0.0)
	check.call(game.overlay.rival_score_panel.visible and game.overlay.rival_score_labels.size() == 1, "the rival meter shows during a VS round")

	# Verdict: win, loss, tie.
	var result: Dictionary = _finish(game, 100, 40)
	check.call(result.vs and result.won and result.margin == 60 and result.rival_best == 40 and not result.has("boss"), "a win records margin +60")
	check.call(JSON.stringify(GameState.progress) == progress_before and JSON.stringify(GameState.wallet) == wallet_before and not GameState.progress.has("stage1_complete"), "a finished VS round changes no stars, Feathers, quests, flags or level records")
	check.call(int(result.feathers_earned) == 0 and result.quests.is_empty(), "a VS round awards no Feathers and lists no quests")
	game.running = true
	result = _finish(game, 40, 100)
	check.call(not result.won and result.margin == -60, "a loss records margin -60")
	game.running = true
	result = _finish(game, 50, 50)
	check.call(not result.won and result.margin == 0, "a tie is a loss")

	# Result sign.
	var asked: Array = []
	for outcome: Array in [[40, 100, false], [100, 40, true]]: # the win goes last: its buttons end the round
		game.running = true
		var sign_result: Dictionary = _finish(game, outcome[0], outcome[1])
		main.menus.results(game.level, sign_result)
		var board: ResultBoard = main.menus.get_child(main.menus.get_child_count() - 1)
		board.finish_tally()
		check.call(board.title_label.text == ("YOU WIN!" if outcome[2] else "OUT-EATEN!"), "VS sign title for won=%s" % str(outcome[2]))
		var captions: String = " ".join(board.captions.map(func(label: Label) -> String: return label.text))
		check.call(captions.contains("YOU") and captions.contains("GARY") and captions.contains("WON BY" if outcome[2] else "LOST BY"), "VS sign shows both scores and the margin")
		check.call(board._best() == (60 if outcome[2] else 0), "only a win carries a board score (the margin)")
		check.call(board._board() == "vs-scrap_sands-gary", "the sign posts to vs-scrap_sands-gary")
		var listed: Array = board.score_rows.map(func(row: Dictionary) -> String: return row.name.text)
		check.call(listed.has("TIDES") and listed.has("YOU") == outcome[2], "offline the sign shows the seed scores, with YOU only after a win")
		var names: Array = _buttons(board).map(func(button: Button) -> String: return button.text)
		check.call(names == ["REMATCH", "VS MENU"], "VS sign buttons are REMATCH and VS MENU")
		if outcome[2]:
			board.requested.connect(func(action: String, payload: Variant) -> void: asked.append([action, payload]))
			for button: Button in _buttons(board):
				button.pressed.emit() # the menus route REMATCH to a fresh round, then VS MENU to the title
	check.call(asked.size() == 2 and asked[0][0] == "vs_start" and asked[0][1] == {"arena": ArenaId, "opponent": "gary"} and asked[1][0] == "vs", "REMATCH sends vs_start with the same payload and VS MENU sends vs")
	check.call(main.game == null and main.screen == "title", "VS MENU leaves the round (to the title until task 081)")
	main._navigate("vs_start", asked[0][1])
	check.call(main.game != game and main.game.is_vs() and main.game.score.points == 0, "REMATCH starts a fresh VS round")
	main._navigate("restart")
	check.call(main.game.is_vs() and main.game.level.vs.opponent == "gary", "R restarts the VS round, not an Arcade level")

	# Boards: Arcade names are unchanged.
	check.call(OnlineScores.vs_board(ArenaId, "gary") == "vs-scrap_sands-gary" and OnlineScores.level_board(3) == "level-3", "VS and Arcade board names")
	check.call(not OnlineScores.active(), "online scores stay offline in VS tests")

	# Analytics carry the VS mode.
	var saved_config: Dictionary = Analytics.config.duplicate()
	var saved_sender: Callable = Analytics.sender
	var sent: Array = []
	Analytics.sender = func(_url: String, body: String, done: Callable) -> void:
		sent.append(JSON.parse_string(body))
		done.call(true)
	Analytics.config = {"enabled": true, "host": "https://eu.i.posthog.com", "project_key": "phc_test"}
	main._navigate("vs_start", {"arena": ArenaId, "opponent": "gary"})
	game = main.game
	game.set_physics_process(false)
	game.dismiss_intro()
	var final: Dictionary = _finish(game, 90, 30)
	game.track_end("completed", final)
	var started: Dictionary = sent.filter(func(e: Dictionary) -> bool: return e.event == "level_start")[0].properties
	var ended: Dictionary = sent.filter(func(e: Dictionary) -> bool: return e.event == "level_end")[0].properties
	check.call(started.mode == "vs" and started.arena == ArenaId and started.opponent == "gary", "level_start carries mode vs, arena and opponent")
	check.call(ended.mode == "vs" and ended.arena == ArenaId and ended.opponent == "gary" and ended.won == true and ended.margin == 60, "level_end carries won and margin")
	Analytics.config = saved_config
	Analytics.sender = saved_sender
	main.clear_game()
