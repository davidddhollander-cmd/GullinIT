extends RefCounted
## Level 6 "Squall": level order and saves, phase timing, abandoned food, everyone leaving the map and the two quests.
const DT: float = 0.1

static func _fresh(suite: Node) -> BeachGame:
	suite.main.start_level(6)
	var game: BeachGame = suite.main.game
	game.set_physics_process(false)
	game.running = true
	game.intro = 0.0
	game.player.position = Vector2(60.0, game.player.ground_y())
	game.player.state = BeachGull.State.GROUNDED
	return game

## Advances the level clock and the squall by whole 0.1 s steps.
static func _run_to(game: BeachGame, seconds: float) -> void:
	while game.elapsed < seconds - 0.001:
		game.elapsed += DT
		game.wind.tick(DT)
		game.squall.tick(DT)
		game.stash_raids.tick(DT)

static func _abandoned(game: BeachGame) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for item: Dictionary in game.stash_raids.items:
		if item.get("source", "") == "abandoned":
			out.append(item)
	return out

static func _find(game: BeachGame, kind: String, appearance: String = "") -> BeachTarget:
	for target: BeachTarget in game.spawner.targets:
		if target.kind == kind and (appearance.is_empty() or target.shopper_appearance == appearance):
			return target
	return null

static func run(suite: Node, check: Callable) -> void:
	_order_and_saves(check)
	var game: BeachGame = _fresh(suite)
	var level: Dictionary = game.level
	check.call(game.squall != null and level.name == "Squall" and str(level.twist.id) == "squall" and int(level.time_limit) == 150 and int(level.stars[0]) == 600 and int(level.stars[1]) == 950 and int(level.stars[2]) == 1250, "level 6 is Squall with the squall twist, a 150 s limit and initial 600/950/1250 stars")
	check.call(level.quests.size() == 2 and level.quests[0].event == "abandoned_looted" and level.quests[0].text == "LOOT 3 PICNICS" and level.quests[1].event == "umbrella_snatch" and level.quests[1].text == "SNATCH UNDER AN UMBRELLA" and level.has("random_quest"), "squall quests: loot 3 picnics, snatch under an umbrella, plus random")
	check.call(game.quests.quests.size() == 3 and game.quests.quests[2].id == "l6_random", "squall rolls its random quest in slot three")
	var squall: BeachSquall = game.squall
	var old_man: BeachTarget = _find(game, "kiosk_customer", "old_man")
	var sunbather: BeachTarget = _find(game, "sunbather")
	var mum: BeachTarget = _find(game, "picnic_family")
	var diner: BeachTarget = _find(game, "pier_diner")
	check.call(old_man != null and old_man.food and mum != null and sunbather != null and diner != null and diner.food, "squall opens with a held hotdog, a mum, a sunbather and a diner holding fish")
	# Calm: light wind, no rain, nothing abandoned.
	_run_to(game, 40.0)
	check.call(squall.phase == BeachSquall.Phase.CALM and not squall.warned and is_zero_approx(squall.intensity) and not game.wind.gusts and is_equal_approx(game.wind.strength, 0.3) and _abandoned(game).is_empty(), "calm lasts 45 s: light wind, no gusts, no rain, no loose food")
	check.call(not squall.rain.visible and game.beach.modulate == Color.WHITE, "calm has no rain overlay and no tint")
	# Umbrella: pier diners hold their food under one, so a steep dive is blocked and a low one lands the snatch.
	var steep: bool = _dive(game, diner, 70.0)
	check.call(not steep and diner.food, "a steep dive cannot take food from a pier diner")
	game.player.invulnerable = 0.0
	var low: bool = _dive(game, diner, 20.0)
	check.call(low and not diner.food, "a low dive snatches from under a diner's umbrella")
	check.call(game.quests.quests[1].done and int(game.quests.quests[1].progress) == 1, "snatching an umbrella-twist target completes the umbrella quest")
	# The warning arrives three seconds ahead.
	_run_to(game, 42.1)
	check.call(squall.warned and squall.phase == BeachSquall.Phase.CALM and game.effects.texts.any(func(t: Dictionary) -> bool: return t.text == "SQUALL INCOMING!"), "SQUALL INCOMING! shows 3 s before the squall")
	# The squall.
	_run_to(game, 45.2)
	check.call(squall.phase == BeachSquall.Phase.SQUALL and game.wind.gusts, "squall begins at 45 s with gusts on")
	_run_to(game, 49.0)
	check.call(is_equal_approx(squall.intensity, 1.0) and game.wind.base > 0.8 and squall.rain.visible and game.beach.modulate.r < 0.7, "wind, rain and tint ramp to full within the squall")
	var loose: Array[Dictionary] = _abandoned(game)
	check.call(loose.size() == squall.abandoned and loose.size() >= 4, "food on the sand is abandoned at the squall (%d items)" % loose.size())
	check.call(not _abandoned(game).any(func(item: Dictionary) -> bool: return not Config.foods.has(item.food_id) or bool(item.get("recovered", false))), "abandoned items are real, unrecovered foods")
	check.call(_abandoned(game).all(func(item: Dictionary) -> bool: return item.grounded), "abandoned food has landed on the sand")
	var width: float = float(Config.tuning.world.width)
	check.call(game.spawner.targets.all(func(t: BeachTarget) -> bool: return t.panic.state == CrowdPanic.State.SHELTER), "everyone runs from the squall")
	check.call(game.spawner.targets.all(func(t: BeachTarget) -> bool: return t.panic.destination < 0.0 or t.panic.destination > width), "everyone runs for an edge of the map, sand and promenade alike")
	check.call(not old_man.food and not diner.food and not mum.food and not sunbather.food and not _find(game, "kiosk_customer", "kiosk_customer").food, "everyone drops their food")
	check.call(game.spawner.arrivals_blocked, "nobody new arrives while the squall rages")
	check.call(game.dogs.all(func(d: OffLeadDog) -> bool: return d.flee_to < 0.0 or d.flee_to > width), "the off-lead dog runs off too")
	check.call(game.pilots.size() == 2 and game.pending_rivals.is_empty(), "Gary and Chip are both out for the squall")
	for pilot: RivalPilot in game.pilots:
		check.call(float(pilot.personality.ground.scraps) >= 0.95, "%s mobs abandoned food in the squall" % pilot.gull.rival_name)
	# Arrivals mid-squall are sent off the map as well.
	var late: BeachTarget = game.spawner.create("kiosk_customer", 400.0, {"appearance": "shopper_mullet", "food_id": "hotdog"})
	_run_to(game, 49.3)
	check.call(late.panic.state == CrowdPanic.State.SHELTER, "someone arriving mid-squall runs off the map")
	# Looting abandoned food counts toward LOOT 3 PICNICS.
	game.player.digestion.snacks.clear()
	var looted: int = 0
	for item: Dictionary in _abandoned(game):
		if looted >= 3:
			break
		game.player.digestion.snacks.clear()
		game.player.digestion.rest = 0.0
		game.player.state = BeachGull.State.GROUNDED
		game.player.position = Vector2(float(item.position.x) - (game.player.beak().x - game.player.position.x), game.player.ground_y())
		item.age = 1.0
		var before: int = game.stash_raids.items.size()
		game.stash_raids.tick(DT)
		if game.stash_raids.items.size() < before:
			looted += 1
		check.call(int(game.quests.quests[0].progress) == looted, "loot quest counts abandoned pickup %d" % looted)
	check.call(looted == 3 and game.quests.quests[0].done, "three looted abandoned foods complete LOOT 3 PICNICS")
	# Rivals do not feed the loot quest.
	var progress: int = int(game.quests.quests[0].progress)
	check.call(not _abandoned(game).is_empty() or progress == 3, "other abandoned food remains for the rivals")
	# Clearing: the wind eases, rain stops, people drift back.
	game.player.state = BeachGull.State.GROUNDED
	_run_to(game, 85.2)
	check.call(squall.phase == BeachSquall.Phase.CLEARING and not game.wind.gusts, "clearing begins at 85 s and the gusts stop")
	check.call(old_man.panic.state == CrowdPanic.State.RETURN or old_man.panic.state == CrowdPanic.State.NONE, "people come back when it clears")
	check.call(old_man.info.twist == "walk" and sunbather.info.twist == "sleep" and mum.info.twist == "shield", "nobody's twist was changed by the squall")
	_run_to(game, 100.0)
	check.call(is_zero_approx(squall.intensity) and not squall.rain.visible and game.beach.modulate == Color.WHITE and is_equal_approx(game.wind.strength, 0.3), "rain stops, tint fades and the wind eases back to light")
	check.call(game.pilots.all(func(pilot: RivalPilot) -> bool: return float(pilot.personality.ground.scraps) < 0.95), "rivals' own tastes are restored when it clears")
	suite.main.clear_game()
	# One mid-squall direction flip, in the second half only.
	game = _fresh(suite)
	var start_dir: int = game.wind.direction
	_run_to(game, 64.0)
	check.call(game.wind.direction == start_dir and game.wind.gusts, "gusts blow in the first half of the squall without turning the wind")
	_run_to(game, 84.0)
	check.call(game.wind.direction == -start_dir, "the wind flips once in the second half of the squall")
	_run_to(game, 100.0)
	check.call(game.wind.direction == -start_dir and not game.wind.gusts and is_equal_approx(game.wind.strength, 0.3), "after the flip it stays put and the clearing leaves a light wind")
	suite.main.clear_game()
	_full_run(suite, check)

## Plays the real level loop through a squall: everyone is off the map by the end of it, nobody jumps
## across the beach on the way, nobody new arrives, and the beach refills afterwards.
static func _full_run(suite: Node, check: Callable) -> void:
	var game: BeachGame = _fresh(suite)
	var width: float = float(Config.tuning.world.width)
	var count: int = -1 ## people on the beach when the squall hit
	var jumps: int = 0
	var last: Dictionary = {}
	var arrivals: bool = false
	for stop: float in [84.0, 125.0]:
		while game.elapsed < stop:
			game._physics_process(DT)
			if game.squall.phase == BeachSquall.Phase.SQUALL:
				if count < 0:
					count = game.spawner.targets.size()
				arrivals = arrivals or game.spawner.targets.size() > count
			for t: BeachTarget in game.spawner.targets:
				if last.has(t) and absf(t.position.x - float(last[t])) > 25.0:
					jumps += 1
				last[t] = t.position.x
		if stop == 84.0:
			var stragglers: Array = game.spawner.targets.filter(func(t: BeachTarget) -> bool: return t.position.x > -20.0 and t.position.x < width + 20.0).map(func(t: BeachTarget) -> String: return "%s@%d" % [t.kind, int(t.position.x)])
			check.call(stragglers.is_empty(), "by the end of the squall the whole crowd is off the map (stragglers: %s)" % str(stragglers))
			check.call(game.dogs.all(func(d: OffLeadDog) -> bool: return d.position.x <= -20.0 or d.position.x >= width + 20.0), "the dog is off the map too")
		else:
			check.call(game.spawner.targets.all(func(t: BeachTarget) -> bool: return t.position.x >= 0.0 and t.position.x <= width) and game.dogs.all(func(d: OffLeadDog) -> bool: return d.position.x >= 0.0 and d.position.x <= width and is_nan(d.flee_to)), "once it clears everyone, dog included, is back on the map")
	check.call(jumps == 0, "nobody teleports across the beach while running off (%d jumps)" % jumps)
	check.call(not arrivals, "no new beachgoer walks on during the squall")
	suite.main.clear_game()

## A dive at the held food from the given angle below horizontal; true when the food was taken.
static func _dive(game: BeachGame, target: BeachTarget, degrees: float) -> bool:
	var gull: BeachGull = game.player
	var food: Vector2 = target.food_position()
	var heading: Vector2 = Vector2(cos(deg_to_rad(degrees)), sin(deg_to_rad(degrees)))
	gull.state = BeachGull.State.STRIKE
	gull.sweep_state = BeachGull.State.STRIKE
	gull.peck_sweep_active = true
	gull.direction = heading
	gull.previous_beak = food - heading * 8.0
	gull.sweep_beak = food
	gull.position = gull.sweep_beak - (gull.beak() - gull.position)
	gull.previous_beak = food - heading * 8.0
	gull.sweep_beak = food
	BeachCollisions.resolve(gull, game.spawner.targets, game.beach.props)
	gull.sweep_state = BeachGull.State.GLIDE
	gull.peck_sweep_active = false
	return not target.food

static func _order_and_saves(check: Callable) -> void:
	var names: Array[String] = []
	for level: Dictionary in Config.levels:
		names.append(str(level.name))
	check.call(Config.levels.size() == 7 and names == ["Training Day", "Family Picnic", "Boardwalk Bustle", "Water Fight", "Three's a Crowd", "Squall", "Sunset Showdown"], "seven levels in order, Squall at 6 and the boss at 7: %s" % str(names))
	var ids_ok: bool = true
	for index: int in Config.levels.size():
		ids_ok = ids_ok and int(Config.levels[index].id) == index + 1
	check.call(ids_ok and bool(Config.levels[6].get("boss", false)) and not bool(Config.levels[5].get("boss", false)), "level ids match their order and only level 7 is the boss")
	check.call(GameState.last_playable_level() >= 4 and GameState.demo.last_level >= 4, "demo and last-level defaults cover the new level")
	var saved_progress: Dictionary = GameState.progress.duplicate(true)
	var saved_unlock: bool = GameState.unlock_all
	var saved_demo: Dictionary = GameState.demo.duplicate()
	var saved_path: String = GameState.save_path
	GameState.demo = {"enabled": false, "last_level": 7, "feedback_url": ""}
	GameState.unlock_all = false
	GameState.progress = {"5": {"stars": 1}}
	check.call(GameState.unlocked(6) and not GameState.unlocked(7), "Squall opens after level 5; the boss waits for Squall")
	GameState.progress = {"5": {"stars": 1}, "6": {"stars": 1}}
	check.call(GameState.unlocked(7), "the boss opens once Squall is cleared")
	# A version 1 save: its level 6 record was the boss.
	GameState.save_path = "user://squall_migration_test.json"
	var old_save: Dictionary = {"version": 1, "progress": {"5": {"stars": 2, "best": 900}, "6": {"stars": 3, "best": 1500, "quests": ["l6_mug_all", "l6_random"]}, "stage1_complete": true}, "wallet": {"feathers": 4}}
	var file: FileAccess = FileAccess.open(GameState.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(old_save))
	file.close()
	GameState.progress = {}
	GameState.load_progress()
	var boss: Dictionary = GameState.entry(7)
	check.call(not GameState.progress.has("6") and int(boss.get("stars", 0)) == 3 and int(boss.get("best", 0)) == 1500 and boss.quests == ["l6_mug_all", "l7_random"], "an old save's boss record moves from level 6 to level 7")
	check.call(GameState.unlocked(7) and GameState.unlocked(6) and bool(GameState.progress.get("stage1_complete", false)) and GameState.feathers() == 4, "a beaten boss stays unlocked, with the shop flag and feathers kept")
	GameState.save_progress()
	var saved: Variant = JSON.parse_string(FileAccess.get_file_as_string(GameState.save_path))
	check.call(saved is Dictionary and int(saved.version) == GameState.SAVE_VERSION and saved.progress.has("7") and not saved.progress.has("6"), "the migrated save is written back as the new version")
	GameState.progress = {}
	GameState.load_progress()
	check.call(int(GameState.entry(7).get("stars", 0)) == 3 and GameState.entry(6).is_empty(), "a migrated save is not migrated twice")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameState.save_path))
	GameState.save_path = saved_path
	GameState.progress = saved_progress
	GameState.unlock_all = saved_unlock
	GameState.demo = saved_demo
	check.call(ResultBoard.seed_scores(6).size() >= 5 and ResultBoard.seed_scores(7).size() >= 5 and int(ResultBoard.seed_scores(6)[0].score) != int(ResultBoard.seed_scores(7)[0].score), "level 6 and 7 each have starter leaderboards")
