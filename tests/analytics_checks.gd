extends RefCounted
## Analytics: nothing is sent without a key or with STATS off; events fire once with their properties.
## No real network calls: Analytics.sender is replaced with a recorder.

class Recorder extends RefCounted:
	var sent: Array[Dictionary] = []
	var urls: Array[String] = []
	var results: Array[bool] = []  # per-request outcome; empty => success
	func send(url: String, body: String, done: Callable) -> void:
		urls.append(url)
		sent.append(JSON.parse_string(body))
		done.call(results.pop_front() if not results.is_empty() else true)
	func names() -> Array:
		return sent.map(func(e: Dictionary) -> String: return e.event)
	func last(event: String) -> Dictionary:
		for i: int in range(sent.size() - 1, -1, -1):
			if sent[i].event == event:
				return sent[i].properties
		return {}

static func run(suite: Node, check: Callable) -> void:
	var main: Node = suite.main
	var saved_config: Dictionary = Analytics.config.duplicate()
	var saved_sender: Callable = Analytics.sender
	var saved_stats: Variant = GameState.options.get("stats", true)
	var saved_progress: Dictionary = GameState.progress.duplicate(true)
	var saved_demo: Dictionary = GameState.demo.duplicate()
	var rec := Recorder.new()
	Analytics.sender = Callable(rec, "send")
	GameState.demo.feedback_url = ""
	GameState.progress["1"] = {"training_complete": true, "training_step": BeachGame.TRAINING_LESSONS}

	# No key / disabled / opted out => nothing queued or sent, even through a full level.
	Analytics.config = {"enabled": true, "host": "https://eu.i.posthog.com", "project_key": ""}
	main.start_level(2)
	main.game.dismiss_intro()
	main.game._swallowed({"id": "ice_cream"})
	main.game.finish()
	main._navigate("feedback")
	main.clear_game()
	check.call(rec.sent.is_empty() and Analytics.queue.is_empty(), "empty project key sends nothing")
	Analytics.config = {"enabled": false, "host": "https://eu.i.posthog.com", "project_key": "phc_test"}
	Analytics.track("level_start")
	check.call(rec.sent.is_empty(), "enabled=false sends nothing")
	Analytics.config.enabled = true
	GameState.options.stats = false
	Analytics.track("level_start")
	check.call(rec.sent.is_empty() and Analytics.queue.is_empty(), "STATS OFF sends nothing")
	GameState.options.stats = true

	# Events with a dummy key.
	main.start_level(2)
	var game: BeachGame = main.game
	game.dismiss_intro()
	check.call(rec.names() == ["level_start"] and rec.last("level_start").level == 2 and rec.last("level_start").mode == "arcade", "level_start fires when the level begins")
	var common: Dictionary = rec.last("level_start")
	check.call(common.platform != "" and common.build == "0.1.0-demo" and common.input == "keyboard_mouse" and common["$process_person_profile"] == false, "common properties are attached")
	check.call(rec.sent[0].api_key == "phc_test" and rec.sent[0].distinct_id.length() == 32 and rec.sent[0].has("timestamp") and rec.urls[0] == "https://eu.i.posthog.com/i/v0/e/", "capture payload and endpoint")
	game.elapsed = 12.34
	game._swallowed({"id": "ice_cream", "scrap": true})
	check.call(not rec.names().has("first_steal"), "scrap snacks are not a first steal")
	game._swallowed({"id": "ice_cream"})
	game._swallowed({"id": "ice_cream"})
	check.call(rec.names().count("first_steal") == 1 and rec.last("first_steal").level == 2 and is_equal_approx(rec.last("first_steal").seconds, 12.3), "first_steal fires once per run")
	# Dive outcomes ride on level_end (player feedback suggestion 4): a dive that ends past its lined-up snack is an overshoot.
	var snack: BeachTarget = null
	for target: BeachTarget in game.spawner.targets:
		if game.snatchable(target):
			snack = target
			break
	check.call(snack != null, "level 2 has a snack to dive at")
	var gull: BeachGull = game.player
	gull.position = snack.food_position() + Vector2(-60, -40)
	gull.direction = (snack.food_position() - gull.position).normalized()
	game._dive_began()
	gull.state = BeachGull.State.STRIKE
	game._dive_tick()
	gull.peck_started.emit()
	gull.position = snack.food_position() + Vector2(40, -5)
	gull.state = BeachGull.State.GLIDE
	game._dive_tick()
	game._dive_tick()
	check.call(game.dive_stats == {"dives": 1, "dive_pecks": 1, "dive_snatches": 0, "dive_overshoots": 1}, "a dive that flies past its snack counts once as an overshoot")
	gull.position = snack.food_position() + Vector2(-60, -40)
	game._dive_began()
	gull.state = BeachGull.State.GLIDE
	game._dive_tick()
	check.call(game.dive_stats.dives == 2 and game.dive_stats.dive_overshoots == 1, "a dive pulled up short of the snack is not an overshoot")
	game._crashed()
	game.finish()
	var ended: Dictionary = rec.last("level_end")
	check.call(ended.dives == 2 and ended.dive_pecks == 1 and ended.dive_snatches == 0 and ended.dive_overshoots == 1, "level_end reports dive outcomes")
	check.call(rec.names().count("level_end") == 1 and ended.level == 2 and ended.mode == "arcade" and ended.has("score") and ended.has("stars") and ended.crashes == 1 and is_equal_approx(ended.seconds, 12.3) and ended.outcome in ["completed", "failed"], "level_end fires on finish with its properties")
	main.clear_game()
	check.call(rec.names().count("level_end") == 1, "leaving the results screen does not report a second end")
	main.start_level(3)
	main.game.dismiss_intro()
	main.clear_game()
	check.call(rec.names().count("level_end") == 2 and rec.last("level_end").level == 3 and rec.last("level_end").outcome == "quit", "leaving a running level reports quit")
	main.start_level(3)
	main.clear_game()
	check.call(rec.names().count("level_end") == 2, "abandoning a level before it starts reports nothing")
	main.start_level(1, true)
	game = main.game
	game.dismiss_intro()
	check.call(rec.last("level_start").mode == "training", "training level_start mode")
	game.elapsed = 5.0
	game._dive_began()
	game._crashed()
	game._training_advance()
	check.call(rec.last("lesson_complete").lesson == 1 and is_equal_approx(rec.last("lesson_complete").seconds, 5.0), "lesson_complete fires with lesson and seconds")
	check.call(rec.last("lesson_complete").lesson_dives == 1 and rec.last("lesson_complete").lesson_crashes == 1, "lesson_complete reports that lesson's dives and crashes")
	game._dive_began()
	game.play_clock = 7.0
	game.track_hidden()
	var hidden: Dictionary = rec.last("game_hidden")
	check.call(hidden.lesson == 2 and hidden.lesson_dives == 1 and hidden.lesson_crashes == 0 and hidden.dives == 2 and is_equal_approx(hidden.play_seconds, 7.0), "game_hidden reports the current lesson only, and true play time")
	main.clear_game()
	check.call(rec.last("level_end").outcome == "quit" and rec.last("level_end").lesson_dives == 1 and is_equal_approx(rec.last("level_end").play_seconds, 7.0), "level_end reports the lesson the player stopped on")
	var hidden_count: int = rec.names().count("game_hidden")
	main.start_level(1, true)
	main.game.track_hidden()
	main.clear_game()
	check.call(rec.names().count("game_hidden") == hidden_count, "hiding the tab before the level starts reports nothing")
	check.call(rec.sent[0].properties.schema == 4 and rec.sent[0].properties.has("dev"), "events carry schema and dev marker")
	Analytics.page_id = "page123"
	Analytics.track("level_start")
	check.call(rec.last("level_start").page_id == "page123", "game events link to the page_open that loaded them")
	Analytics.page_id = ""
	var presets: String = FileAccess.get_file_as_string("res://export_presets.cfg")
	check.call(presets.contains("send('page_open')") and presets.contains(str(saved_config.get("project_key", "missing"))) and presets.contains(str(saved_config.get("host", "missing")).rstrip("/") + "/i/v0/e/"), "the web page reports page_open to the same PostHog project as the game")
	var saved_save: String = GameState.save_path
	GameState.save_path = "res://test-output/analytics-save.json"
	var tagline := Label.new()
	for _tap: int in BeachMenus.DEV_TAPS - 1:
		main.menus._logo_tapped(tagline)
	check.call(not bool(GameState.options.dev_player) and not rec.names().has("dev_device"), "a few logo taps do not mark a dev device")
	main.menus._logo_tapped(tagline)
	check.call(bool(GameState.options.dev_player) and rec.last("dev_device").dev == true and tagline.text != "", "seven logo taps mark this install as a dev device")
	tagline.free()
	GameState.options.dev_player = false
	GameState.save_path = saved_save
	main.screen = "select"
	main._navigate("feedback")
	check.call(rec.last("feedback_click").screen == "level_select", "feedback_click from level select")
	main.screen = "results"
	main._navigate("feedback")
	check.call(rec.last("feedback_click").screen == "results", "feedback_click from results")
	var count: int = rec.sent.size()
	var session_main: Node = preload("res://scenes/main.tscn").instantiate()
	suite.add_child(session_main)
	check.call(rec.sent.size() == count + 1 and rec.sent[count].event == "session_start", "session_start fires once at the title screen")
	session_main.queue_free()

	# Distinct id persists across a save/load.
	var saved_path: String = GameState.save_path
	GameState.save_path = "res://test-output/analytics-save.json"
	var id: String = GameState.anon_id()
	GameState.save_progress()
	GameState._anon_id = ""
	GameState.load_progress()
	check.call(id.length() == 32 and GameState.anon_id() == id, "anonymous id persists across save/load")
	GameState.save_path = saved_path

	# Failed sends are retried once, then dropped; the queue keeps moving.
	rec.sent.clear()
	rec.results = [false, false, true]
	Analytics.track("level_start")
	Analytics.track("level_end")
	check.call(Analytics.queue.is_empty() and not Analytics.in_flight and rec.sent.size() == 3 and rec.sent[2].event == "level_end", "event is dropped after 2 failures without blocking the queue")

	Analytics.config = saved_config
	Analytics.sender = saved_sender
	GameState.options.stats = saved_stats
	GameState.progress = saved_progress
	GameState.demo = saved_demo
	await suite.settle()
