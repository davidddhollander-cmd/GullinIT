extends RefCounted
## Level 6 boss: Bev's size, shove and rear-only mugging, the sunset, and the win/lose verdict.
const DT: float = 1.0 / 60.0

static func _fresh(suite: Node) -> BeachGame:
	suite.main.start_level(6)
	var game: BeachGame = suite.main.game
	game.set_physics_process(false)
	game.running = true
	game.intro = 0
	game.player.position = Vector2(60, game.player.ground_y())
	game.player.state = BeachGull.State.GROUNDED
	return game

static func _bev(game: BeachGame) -> RivalPilot:
	for pilot: RivalPilot in game.pilots:
		if pilot.gull.rival_name == "Bev":
			return pilot
	return null

static func _pilot(game: BeachGame, rival: String) -> RivalPilot:
	for pilot: RivalPilot in game.pilots:
		if pilot.gull.rival_name == rival:
			return pilot
	return null

## Puts the gull in mid-strike with its beak on the point.
static func _strike_at(gull: BeachGull, point: Vector2) -> void:
	gull.state = BeachGull.State.STRIKE
	gull.invulnerable = 0.0
	gull.position = point + Vector2(-6.0, -6.0)
	gull.position += point - gull.beak()
	gull.previous_beak = gull.beak()
	gull.sweep_beak = gull.beak()

## The player's beak sweeps the rival from one side. Returns the attacker's state afterwards.
static func _player_mug(suite: Node, game: BeachGame, pilot: RivalPilot, side: float) -> void:
	pilot.gull.position = Vector2(400.0, 70.0)
	pilot.gull.facing = 1.0
	pilot.carried_food_id = "hotdog"
	pilot.carried = 30
	pilot.carry_window = 5.0
	game.player.digestion.snacks.clear()
	game.player.state = BeachGull.State.STRIKE
	game.player.invulnerable = 0.0
	game.player.position = pilot.gull.position + Vector2(18.0 * side, 0.0)
	game.player.previous_beak = pilot.gull.position
	game.player.sweep_beak = pilot.gull.position
	game._mugging()
	suite.eat_pending(game)

static func run(suite: Node, check: Callable) -> void:
	var level: Dictionary = Config.levels[5]
	check.call(level.name == "Sunset Showdown" and bool(level.get("boss", false)) and int(level.time_limit) == 150 and level.wind.flip == true, "level 6 is the hand-built Sunset Showdown boss with a flipping wind")
	check.call(level.rivals.size() == 3 and level.world.width == 1280 and not level.spawns.any(func(s: Dictionary) -> bool: return s.type == "market_cleaner"), "level 6 has Gary, Chip, Bev and no stage 2 market cleaner")
	check.call(str(level.objective) == "OUT-EAT THE GANG", "level 6 states the objective")
	var game: BeachGame = _fresh(suite)
	var bev: RivalPilot = _bev(game)
	var gary: RivalPilot = _pilot(game, "Gary")
	var chip: RivalPilot = _pilot(game, "Chip")
	check.call(bev != null and float(bev.personality.speed) < 0.8 and is_equal_approx(bev.mug_chance(), 0.5), "Bev is slower with mug_chance 0.5")
	check.call(is_equal_approx(bev.gull.art_scale, gary.gull.art_scale * 1.3) and bev.gull.species == gary.gull.species, "Bev is Gary's gull sprite scaled 1.3x through data")
	game.player.digestion.snacks.clear()

	game.elapsed = 0.0
	await _scenes(suite, game)

	# Shove: a diver contesting the food Bev strikes at is bumped away, losing nothing.
	var food_target: BeachTarget
	for target: BeachTarget in game.spawner.targets:
		if target.food:
			food_target = target
			break
	bev.target = food_target
	var food: Vector2 = food_target.food_position()
	_strike_at(bev.gull, food)
	var points_before: int = game.score.points
	game.player.digestion.collect("hotdog")
	_strike_at(game.player, food + Vector2(8.0, 0.0))
	BeachBoss.shove(game)
	check.call(game.player.state == BeachGull.State.STUNNED and game.player.digestion.snacks.size() == 1 and game.score.points == points_before, "Bev shoves a contesting player away without costing food or points")
	check.call(bev.gull.state == BeachGull.State.STRIKE, "the shover is untouched")
	game.player.state = BeachGull.State.GROUNDED
	_strike_at(chip.gull, food + Vector2(8.0, 0.0))
	BeachBoss.shove(game)
	check.call(chip.gull.state == BeachGull.State.STUNNED, "Bev shoves a contesting rival too")
	chip.gull.state = BeachGull.State.GROUNDED
	_strike_at(gary.gull, food + Vector2(60.0, 0.0))
	BeachBoss.shove(game)
	check.call(gary.gull.state == BeachGull.State.STRIKE, "a diver beyond shove_radius is left alone")
	game.player.digestion.snacks.clear()
	gary.gull.state = BeachGull.State.GROUNDED
	bev.gull.state = BeachGull.State.GROUNDED
	bev.target = null

	# Mugging Bev: frontal bounces, from behind succeeds.
	_player_mug(suite, game, bev, 1.0)
	check.call(bev.carry_window > 0.0 and bev.carried == 30 and game.player.state == BeachGull.State.STUNNED and game.player.digestion.snacks.is_empty(), "frontal mug of Bev bounces and stuns the attacker")
	check.call(game.quests.quests[0].progress == 0, "a bounced mug does not count towards the quest")
	game.player.state = BeachGull.State.GROUNDED
	_player_mug(suite, game, bev, -1.0)
	check.call(bev.carried == 0 and game.score.items >= 1 and game.quests.quests[0].progress == 1, "mugging Bev from behind works")
	# Gary and Chip have no guard; each different rival counts once.
	_player_mug(suite, game, gary, 1.0)
	check.call(gary.carried == 0 and game.quests.quests[0].progress == 2, "Gary can be mugged from the front")
	_player_mug(suite, game, gary, 1.0)
	_player_mug(suite, game, bev, -1.0)
	check.call(game.quests.quests[0].progress == 2 and not game.quests.quests[0].done, "mugging the same rival again does not advance l6_mug_all")
	_player_mug(suite, game, chip, -1.0)
	check.call(game.quests.quests[0].done and game.quests.quests[0].id == "l6_mug_all", "l6_mug_all completes on the third different rival")
	# Rival on Bev: same rear-only rule.
	bev.gull.position = Vector2(500.0, 70.0)
	bev.gull.facing = 1.0
	bev.carried = 30
	bev.carry_window = 5.0
	gary.leave = 0.0
	gary.carry_window = 0.0
	_strike_at(gary.gull, bev.gull.position)
	gary.gull.position.x = 520.0
	gary.gull.previous_beak = bev.gull.position
	gary.gull.sweep_beak = bev.gull.position
	game._rival_mugging()
	check.call(bev.carried == 30 and gary.mugs == 0 and gary.gull.state == BeachGull.State.STUNNED, "a rival's frontal mug of Bev bounces too")
	gary.gull.state = BeachGull.State.STRIKE
	gary.gull.position.x = 480.0
	gary.gull.previous_beak = bev.gull.position
	gary.gull.sweep_beak = bev.gull.position
	game._rival_mugging()
	check.call(bev.carried == 0 and gary.mugs == 1, "a rival mugging Bev from behind succeeds")
	suite.main.clear_game()
	await suite.settle()
	await _verdicts(suite, check)

## Review captures: the objective card, then the beach early and near dark with the whole gang in view.
static func _scenes(suite: Node, game: BeachGame) -> void:
	game.running = false
	game.intro = 5.0
	game.overlay._process(0.0)
	await suite.snapshot("boss-intro")
	game.intro = 0.0
	game.running = true
	game.overlay._process(0.0)
	var spots := {"Gary": 150.0, "Chip": 205.0, "Bev": 255.0}
	for pilot: RivalPilot in game.pilots:
		pilot.gull.position = Vector2(float(spots[pilot.gull.rival_name]), pilot.gull.ground_y())
		pilot.gull.state = BeachGull.State.GROUNDED
		pilot.gull.aim = pilot.gull.position
		pilot.gull.facing = -1.0
		pilot.gull.tick(0, 0, 0)
	game.player.position = Vector2(95.0, game.player.ground_y())
	game.player.state = BeachGull.State.GROUNDED
	game.player.tick(0, 0, 0)
	game.camera_x = 175.0
	game.camera.position.x = 175.0
	for label: String in ["boss-start"]:
		game.elapsed = 0.0
		game.beach.camera_x = 175.0
		game.beach.queue_redraw()
		game.overlay._process(0.0)
		await suite.snapshot(label)
	game.elapsed = 0.0

static func _finish(suite: Node, rivals: Array, points: int) -> Dictionary:
	suite.main.start_level(6)
	var game: BeachGame = suite.main.game
	game.set_physics_process(false)
	game.running = true
	game.intro = 0
	for i: int in rivals.size():
		game.pilots[i].score = int(rivals[i])
	game.score.points = points
	game.finish()
	var board: ResultBoard = suite.main.menus.get_child(0) as ResultBoard
	return {"quests": game.quests.quests, "title": board.title_label.text if board != null else "", "result": board.result if board != null else {}}

static func _verdicts(suite: Node, check: Callable) -> void:
	var saved_path: String = GameState.save_path
	var saved_progress: Dictionary = GameState.progress
	GameState.save_path = "res://test-output/boss-checks-save.json"
	GameState.progress = {}
	var lose: Dictionary = _finish(suite, [100, 300, 200], 300)
	check.call(not lose.result.won and lose.title == "OUT-EATEN!" and not GameState.progress.has("stage1_complete"), "tying the best rival loses; no stage flag")
	var lost_double: bool = lose.quests[1].done
	check.call(not lost_double, "WIN BY DOUBLE does not fire on a loss")
	suite.main.clear_game()
	await suite.settle()
	var win: Dictionary = _finish(suite, [100, 300, 200], 301)
	check.call(win.result.won and win.title == "BEACH BOSS!" and GameState.progress.get("stage1_complete", false) == true, "beating every rival wins and sets stage1_complete")
	check.call(not win.quests[1].done, "301 vs 300 is not a double win")
	check.call(win.result.stars == 0 and int(win.result.score) < 700, "stars stay score-based")
	var reloaded: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GameState.save_path))
	check.call(reloaded.progress.get("stage1_complete", false) == true, "stage1_complete is saved to disk")
	suite.main.clear_game()
	await suite.settle()
	var edge: Dictionary = _finish(suite, [100, 300, 200], 599)
	check.call(edge.result.won and not edge.quests[1].done, "599 vs 300 wins but is not a double")
	suite.main.clear_game()
	await suite.settle()
	var double: Dictionary = _finish(suite, [100, 300, 200], 600)
	check.call(double.quests[1].done and int(double.result.quest_bonus) >= 100 and double.result.quests[1].done, "600 vs 300 completes WIN BY DOUBLE, counted on the result board")
	check.call(double.result.won and double.result.score >= 700, "the double bonus is part of the final score")
	await suite.snapshot("boss-result")
	suite.main.clear_game()
	await suite.settle()
	GameState.progress = saved_progress
	GameState.save_path = saved_path
