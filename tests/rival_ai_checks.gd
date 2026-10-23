extends RefCounted
## Deterministic rival simulations: the player idles while rivals hunt for 90 s at 60 Hz.

static func simulate(host: Node, main: Node, level: int, seconds: float) -> Dictionary:
	main.start_level(level)
	var game: BeachGame = main.game
	game.set_physics_process(false)
	await host.settle()
	game.rng.seed = 4242 + level
	if not game.pending_rivals.is_empty():
		game._release_rivals()
	game.intro = 0
	game.running = true
	game.player.position = Vector2(40,game.player.ground_y())
	game.player.state = BeachGull.State.GROUNDED
	var width: float = float(Config.tuning.world.width)
	var report: Dictionary = {"pilots":game.pilots.size(),"edge_max":0.0,"out_of_bounds":0,"sand_frames":0,"shared_target":0,"cooldown_dives":0,"escape_short":0,"held_picks":0,"dives":[],"thefts":[],"crashes":[],"scores":[]}
	var edge_time: Array[float] = []
	var last_theft: Array[float] = []
	var dives_seen: Array[int] = []
	var thefts_seen: Array[int] = []
	var escape_origin: Array[float] = []
	for pilot: RivalPilot in game.pilots:
		edge_time.append(0.0)
		last_theft.append(-100.0)
		dives_seen.append(0)
		thefts_seen.append(0)
		escape_origin.append(0.0)
	var clock: float = 0.0
	var window: float = float(Config.tuning.rival.leave_time) + float(Config.tuning.rival.cooldown)
	var feed: bool = false
	for pilot: RivalPilot in game.pilots:
		feed = feed or pilot.gull.loose_only
	for frame: int in int(seconds*60.0):
		# Loose-only rivals live off dropped food: scatter a hotdog on the sand every 4 s.
		if feed and frame % 240 == 120:
			game.stash_raids.items.append({"owner":null,"source":"bin","food_id":"hotdog","position":Vector2(220.0+float((frame/240)*173 % 700),float(Config.tuning.world.ground)-5.0),"velocity":Vector2.ZERO,"grounded":true,"age":1.0})
		game._physics_process(1.0/60)
		clock += 1.0/60
		# Keep the idle player from wandering into the fight or finishing the level.
		game.player.position = Vector2(40,game.player.ground_y())
		game.player.state = BeachGull.State.GROUNDED
		game.player.velocity = Vector2.ZERO
		game.elapsed = minf(game.elapsed,10.0)
		for i: int in game.pilots.size():
			var pilot: RivalPilot = game.pilots[i]
			var gull: BeachGull = pilot.gull
			if gull.loose_only and is_instance_valid(pilot.target) and not pilot.target.is_loose():
				report.held_picks += 1
			if pilot.thefts > thefts_seen[i]:
				thefts_seen[i] = pilot.thefts
				last_theft[i] = clock
				escape_origin[i] = gull.position.x
			if pilot.carried == 0 and pilot.leave <= 0.0 and clock - last_theft[i] < float(Config.tuning.rival.leave_time) - 0.05:
				last_theft[i] = -100.0 # mugged mid-escape: the theft is over, so its escape and cooldown windows no longer apply
			if pilot.dives > dives_seen[i]:
				dives_seen[i] = pilot.dives
				if clock - last_theft[i] < window - 0.2 and clock - last_theft[i] > 0.1:
					report.cooldown_dives += 1
			if clock - last_theft[i] > float(Config.tuning.rival.leave_time) - 0.05 and clock - last_theft[i] < float(Config.tuning.rival.leave_time) + 0.02 and absf(gull.position.x - escape_origin[i]) < 120.0:
				report.escape_short += 1
			if gull.position.x < 0.0 or gull.position.x > width or gull.position.y > float(Config.tuning.world.ground):
				report.out_of_bounds += 1
			if gull.state == BeachGull.State.GROUNDED:
				report.sand_frames += 1
			if gull.position.x < 30.0 or gull.position.x > width - 30.0:
				edge_time[i] += 1.0/60
				report.edge_max = maxf(report.edge_max, edge_time[i])
			else:
				edge_time[i] = 0.0
			for j: int in range(i+1, game.pilots.size()):
				var other: RivalPilot = game.pilots[j]
				if pilot.mode in [RivalPilot.Mode.LINE_UP, RivalPilot.Mode.DIVE] and other.mode in [RivalPilot.Mode.LINE_UP, RivalPilot.Mode.DIVE] and is_instance_valid(pilot.target) and pilot.target == other.target:
					report.shared_target += 1
	for pilot: RivalPilot in game.pilots:
		report.dives.append(pilot.dives)
		report.thefts.append(pilot.thefts)
		report.crashes.append(pilot.crashes)
		report.scores.append(pilot.score)
	game.overlay._process(0.0)
	report.hud_visible = game.overlay.rival_score_panel.visible
	report.hud_rows = game.overlay.rival_score_labels.size()
	report.hud_rect = game.overlay.rival_score_panel.get_global_rect()
	if level == 6:
		game.overlay.queue_redraw()
		await host.snapshot("rival-score-meter")
	return report

static func run(host: Node, main: Node, check: Callable) -> void:
	for level: int in [3,4,6]:
		var r: Dictionary = await simulate(host, main, level, 90.0)
		print("RIVAL SIM level %d: %s" % [level,str(r)])
		var need_thefts: int = 2 if level == 6 else 1
		check.call(r.pilots == (3 if level == 6 else 1),"level %d rival count" % level)
		check.call(r.hud_visible and r.hud_rows == r.pilots,"level %d shows one right-side score row per rival" % level)
		check.call((r.hud_rect as Rect2).end.x <= 320.0 and (r.hud_rect as Rect2).position.y >= 74.0 and (r.hud_rect as Rect2).end.y < 124.0,"level %d rival score meter stays in its right-side safe area" % level)
		for i: int in r.pilots:
			check.call(r.dives[i] >= 3,"level %d rival %d dives at least 3 times (%d)" % [level,i,r.dives[i]])
			check.call(r.thefts[i] >= need_thefts,"level %d rival %d steals at least %d times (%d)" % [level,i,need_thefts,r.thefts[i]])
			check.call(r.scores[i] > 0,"level %d rival %d accumulates a visible food score (%d)" % [level,i,r.scores[i]])
			check.call(r.crashes[i] == 0,"level %d rival %d never crashes its own dives" % [level,i])
		check.call(r.held_picks == 0,"level %d loose-only rivals never target held food" % level)
		check.call(r.edge_max <= 1.5,"level %d rival never lingers at the edge (%.2f s)" % [level,r.edge_max])
		check.call(r.out_of_bounds == 0,"level %d rivals stay inside the beach" % level)
		if level == 6:
			check.call(r.shared_target > 0,"level 6 rivals race for the same food (%d shared frames)" % r.shared_target)
		check.call(r.cooldown_dives == 0,"level %d rival waits out the cooldown after a theft" % level)
		check.call(r.escape_short == 0,"level %d rival leaves the scene of a theft" % level)

## A loose-only rival (Gary) never steals or knocks food a person holds, and can be mugged
## while carrying food he claimed from the sand.
static func loose_only_checks(host: Node, main: Node, check: Callable) -> void:
	var r: Dictionary = await simulate(host, main, 3, 60.0)
	var game: BeachGame = main.game
	var held_thefts: int = 0
	for target: BeachTarget in game.spawner.targets:
		held_thefts += target.thefts + (1 if target.dropped_pending else 0)
	check.call(bool(game.pilots[0].personality.get("loose_only", false)), "level 3 Gary profile is loose-only")
	check.call(held_thefts == 0 and r.held_picks == 0, "loose-only Gary never steals or knocks held food over 60 s (%d)" % held_thefts)
	game.pilots[0].target = null
	var held: Array[BeachTarget] = []
	for target: BeachTarget in game.spawner.targets:
		target.food = true
		held.append(target)
	game.pilots[0].pick_target(held, {})
	check.call(game.pilots[0].target == null, "loose-only Gary ignores every held-food target")
	# Gary claims a hotdog from the sand, then the player mugs him.
	main.start_level(3)
	game = main.game
	game.set_physics_process(false)
	await host.settle()
	game.dismiss_intro()
	game._release_rivals()
	var gary: RivalPilot = game.pilots[0]
	game.player.position = Vector2(40, game.player.ground_y())
	game.player.state = BeachGull.State.GROUNDED
	game.stash_raids.items.append({"owner":null,"source":"bin","food_id":"hotdog","position":Vector2(gary.gull.position.x + 60.0, float(Config.tuning.world.ground) - 5.0),"velocity":Vector2.ZERO,"grounded":true,"age":1.0})
	var steps: int = 0
	while gary.thefts == 0 and steps < 60 * 40:
		game._physics_process(1.0 / 60)
		game.player.position = Vector2(40, game.player.ground_y())
		game.player.state = BeachGull.State.GROUNDED
		game.elapsed = minf(game.elapsed, 10.0)
		steps += 1
	check.call(gary.thefts == 1 and gary.carried_food_id == "hotdog" and gary.carry_window > 0.0 and game.stash_raids.items.is_empty(), "loose-only Gary claims loose food off the sand (%d steps)" % steps)
	game.player.position = gary.gull.position
	game.player.state = BeachGull.State.STRIKE
	game.player.previous_beak = gary.gull.position
	game.player.sweep_beak = gary.gull.position
	game._mugging()
	host.eat_pending(game)
	check.call(game.quests.quests[0].id == "l3_mug_gary" and game.quests.quests[0].done, "mugging loose-only Gary completes l3_mug_gary")

static func fresh(host: Node, main: Node, level: int) -> BeachGame:
	main.start_level(level)
	var game: BeachGame = main.game
	game.set_physics_process(false)
	await host.settle()
	game.dismiss_intro()
	game._release_rivals()
	game.pending_rivals.clear()
	return game

static func has_text(game: BeachGame, text: String) -> bool:
	for entry: Dictionary in game.effects.texts:
		if str(entry.text) == text:
			return true
	return false

## Rivals race, mug each other and mug the player; personality comes from data.
static func competition_checks(host: Node, main: Node, check: Callable) -> void:
	var game: BeachGame = await fresh(host, main, 5)
	var gary: RivalPilot = game.pilots[0]
	var chip: RivalPilot = game.pilots[1]
	check.call(gary.mug_chance() == 0.3 and chip.mug_chance() == 0.8, "level 5 profiles set mug_chance in data (Gary 0.3, Chip 0.8)")
	var plain := RivalPilot.new()
	plain.personality = {}
	check.call(is_equal_approx(plain.mug_chance(), float(Config.tuning.rival.mug_chance)) and float(Config.tuning.rival.mug_range) == 90.0, "mug_chance and mug_range default from tuning")
	# A rival stays mug-able for the player's in-air swallow time of what it carries.
	for pair: Array in [["hotdog", 3.0], ["single_chip", 0.5]]:
		gary.carried_food_id = pair[0]
		gary.took_food(10)
		check.call(is_equal_approx(gary.carry_window, pair[1]), "rival carrying %s is mug-able for %.1f s" % pair)
	gary.leave = 0.0
	gary.carry_window = 0.0
	gary.carried = 0
	# Race: a food another rival is already diving at is still a fair target.
	var food_targets: Array[BeachTarget] = []
	for target: BeachTarget in game.spawner.targets:
		if target.food:
			food_targets.append(target)
			break
	var prize: BeachTarget = food_targets[0]
	for pilot: RivalPilot in [gary, chip]:
		pilot.gull.position = prize.food_position() + Vector2(0, -50)
		pilot.target = null
	var claims: Dictionary = {prize: gary}
	chip.pick_target(food_targets, claims)
	check.call(chip.target == prize, "a rival may pick food another rival has already claimed")
	# The loser of the race abandons the dive cleanly and retargets.
	gary.target = prize
	gary.mode = RivalPilot.Mode.STALK
	gary.gull.position = Vector2(prize.food_position().x, 65.0)
	gary.gull.state = BeachGull.State.GLIDE
	gary.gull.velocity = Vector2.ZERO
	gary.gull.cooldown = 0.0
	gary.gull.aim = prize.food_position()
	gary.gull.dive(1)
	gary.mode = RivalPilot.Mode.DIVE
	var steps: int = 0
	while gary.gull.state != BeachGull.State.STRIKE and steps < 120:
		gary.tick(1.0 / 60, food_targets, {}, game.wind)
		steps += 1
	check.call(gary.gull.state == BeachGull.State.STRIKE, "test rival reaches STRIKE (%d steps)" % steps)
	prize.food = false
	gary.tick(1.0 / 60, food_targets, {}, game.wind)
	check.call(gary.mode == RivalPilot.Mode.RECOVER, "the rival that loses the race pulls up (mode %d)" % gary.mode)
	for i: int in 240:
		gary.tick(1.0 / 60, food_targets, {}, game.wind)
	check.call(gary.target == null and gary.gull.state != BeachGull.State.STRIKE and gary.mode != RivalPilot.Mode.DIVE, "the loser drops the empty target and is not stuck diving (mode %d state %d target %s)" % [gary.mode,gary.gull.state,str(gary.target)])
	prize.food = true
	# Rival mugs rival.
	game = await fresh(host, main, 5)
	gary = game.pilots[0]
	chip = game.pilots[1]
	gary.gull.position = Vector2(600, 70)
	chip.gull.position = Vector2(600, 70)
	gary.carried_food_id = "hotdog"
	gary.took_food(25)
	gary.score = 25
	chip.gull.state = BeachGull.State.STRIKE
	chip.gull.previous_beak = gary.gull.position
	chip.gull.sweep_beak = gary.gull.position
	game._rival_mugging()
	check.call(gary.carried == 0 and gary.score == 0 and gary.gull.state == BeachGull.State.STUNNED, "mugged rival loses the food and is stunned")
	check.call(chip.carried == 25 and chip.score == 25 and chip.carried_food_id == "hotdog" and chip.leave > 0.0, "mugging rival gets the food, the score and runs")
	check.call(has_text(game, "MUGGED!"), "rival-on-rival mug shows MUGGED!")
	chip.leave = 0.0
	game._rival_mugging()
	check.call(chip.mugs == 1 and gary.score == 0, "a stunned victim cannot be mugged again")
	# Rival mugs player.
	game = await fresh(host, main, 5)
	gary = game.pilots[0]
	gary.gull.position = Vector2(600, 70)
	game.player.position = Vector2(600, 100)
	game.player.state = BeachGull.State.GLIDE
	game.player.digestion.collect("hotdog")
	gary.gull.state = BeachGull.State.STRIKE
	gary.gull.previous_beak = game.player.position
	gary.gull.sweep_beak = game.player.position
	var points: int = game.score.points
	game._rival_mugging()
	check.call(game.player.digestion.snacks.is_empty() and game.stash_raids.items.is_empty(), "mugged player's food goes to the rival, not the sand")
	check.call(gary.carried_food_id == "hotdog" and gary.carried > 0 and gary.leave > 0.0, "rival leaves with the player's food")
	check.call(game.player.state == BeachGull.State.STUNNED and game.player.timer <= float(Config.tuning.rival.mug_stun) + 0.01, "player is stunned briefly (%.2f s)" % game.player.timer)
	check.call(game.score.points <= points, "the usual stun penalty applies to the player")
	check.call(has_text(game, "MUGGED BY GARY!"), "player sees MUGGED BY <NAME>!")
	# Nothing to steal once swallowed.
	game = await fresh(host, main, 5)
	gary = game.pilots[0]
	gary.gull.position = Vector2(600, 70)
	game.player.position = Vector2(600, 100)
	game.player.state = BeachGull.State.GLIDE
	gary.gull.state = BeachGull.State.STRIKE
	gary.gull.previous_beak = game.player.position
	gary.gull.sweep_beak = game.player.position
	game._rival_mugging()
	check.call(gary.mugs == 0 and game.player.state == BeachGull.State.GLIDE, "a player with nothing in the beak is not mugged")
	# Chase behaviour: eager rivals go for a carrier in range; climbing out of reach or mug_chance 0 avoids it.
	game = await fresh(host, main, 5)
	gary = game.pilots[0]
	gary.personality = {"name": "Gary", "speed": 0.8, "accuracy_px": 16, "mug_chance": 1.0}
	gary.gull.position = Vector2(600, 65)
	game.player.position = Vector2(640, 100)
	gary.prey = [game.player]
	check.call(gary.chase_step(1.0 / 60, game.wind) and gary.mode == RivalPilot.Mode.CHASE_CARRIER and gary.chase_prey == game.player, "mug_chance 1 chases a carrier in range")
	game.player.position = Vector2(640, 30)
	gary.chase_step(1.0 / 60, game.wind)
	check.call(gary.mode != RivalPilot.Mode.CHASE_CARRIER, "climbing above cruise height escapes the chase")
	gary.mode = RivalPilot.Mode.PATROL
	gary.mug_timer = 0.0
	game.player.position = Vector2(640, 100)
	gary.prey = []
	gary.chase_step(1.0 / 60, game.wind)
	check.call(gary.mode != RivalPilot.Mode.CHASE_CARRIER, "swallowing (no carrier) ends the chase")
	gary.personality = {"name": "Gary", "speed": 0.8, "accuracy_px": 16, "mug_chance": 0.0}
	gary.prey = [game.player]
	var chased: bool = false
	for i: int in 600:
		gary.mug_timer = 0.0
		chased = chased or gary.chase_step(1.0 / 60, game.wind)
	check.call(not chased and gary.mode != RivalPilot.Mode.CHASE_CARRIER, "a rival with mug_chance 0 never goes for a carrier")
	# Whole loop: an eager rival chases, dives through and mugs a player hovering with a snack.
	game = await fresh(host, main, 5)
	gary = game.pilots[0]
	game.pilots[1].personality["mug_chance"] = 0.0
	gary.personality["mug_chance"] = 1.0
	game.player.digestion.collect("hotdog")
	var mugged: bool = false
	for frame: int in 60 * 20:
		game.player.position = Vector2(gary.gull.position.x + 20.0, 105.0)
		game.player.velocity = Vector2.ZERO
		game.player.state = BeachGull.State.GLIDE
		game._physics_process(1.0 / 60)
		if gary.mugs > 0:
			mugged = true
			break
	check.call(mugged and gary.carried > 0, "an eager rival chases and mugs the player in the air (%d mugs)" % gary.mugs)
