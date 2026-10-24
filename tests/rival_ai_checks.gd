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
	var report: Dictionary = {"pilots":game.pilots.size(),"edge_max":0.0,"out_of_bounds":0,"sand_frames":0,"shared_target":0,"cooldown_dives":0,"ground_max":0.0,"escape_short":0,"held_picks":0,"dives":[],"thefts":[],"crashes":[],"scores":[]}
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
	var ground_now: Array[float] = []
	for pilot: RivalPilot in game.pilots:
		ground_now.append(0.0)
	for frame: int in int(seconds*60.0):
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
			var air_thefts: int = pilot.thefts - pilot.ground_eats # ground meals have no escape or cooldown to check
			if air_thefts > thefts_seen[i]:
				thefts_seen[i] = air_thefts
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
				ground_now[i] += 1.0/60
				report.ground_max = maxf(report.ground_max, ground_now[i])
			else:
				ground_now[i] = 0.0
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
	report.quest_rect = game.overlay.quest_panel.get_global_rect()
	if level == 5 or level == 6:
		game.overlay.queue_redraw()
		await host.snapshot("rival-score-meter" if level == 6 else "rival-score-meter-l5")
	return report

static func run(host: Node, main: Node, check: Callable) -> void:
	await simulate(host, main, 5, 6.0)  # capture only
	for level: int in [3,4,6]:
		var r: Dictionary = await simulate(host, main, level, 90.0)
		print("RIVAL SIM level %d: %s" % [level,str(r)])
		var need_thefts: int = 2 if level == 6 else 1
		check.call(r.pilots == (3 if level == 6 else 1),"level %d rival count" % level)
		check.call(r.hud_visible and r.hud_rows == r.pilots,"level %d shows one right-side score row per rival" % level)
		check.call((r.hud_rect as Rect2).end.x <= 316.0 and (r.hud_rect as Rect2).size.x <= 40.0 and (r.hud_rect as Rect2).position.y >= 17.0 and not (r.hud_rect as Rect2).intersects(r.quest_rect) and (r.hud_rect as Rect2).end.y <= 44.0,"level %d rival score meter sits compact in the top-right corner, clear of the quest and goal panels" % level)
		for i: int in r.pilots:
			check.call(r.dives[i] >= 3 or main.game.pilots[i].gull.loose_only,"level %d rival %d dives at least 3 times (%d)" % [level,i,r.dives[i]])
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
	while gary.carried_food_id != "hotdog" and steps < 60 * 40:
		game._physics_process(1.0 / 60)
		game.player.position = Vector2(40, game.player.ground_y())
		game.player.state = BeachGull.State.GROUNDED
		game.elapsed = minf(game.elapsed, 10.0)
		steps += 1
	check.call(gary.thefts >= 1 and gary.carried_food_id == "hotdog" and gary.carry_window > 0.0 and game.stash_raids.items.is_empty(), "loose-only Gary claims loose food off the sand (%d steps)" % steps)
	check.call(gary.thefts >= 1 and gary.carried_food_id == "hotdog", "Gary has eaten the hotdog")
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

## Ground skills: land, scavenge, peck bins and bags, catch falling food; weights switch them off.
static func hold_player(game: BeachGame, x: float = 40.0) -> void:
	game.player.position = Vector2(x, game.player.ground_y())
	game.player.state = BeachGull.State.GROUNDED
	game.player.velocity = Vector2.ZERO
	game.elapsed = minf(game.elapsed, 10.0)

## Steps the game until `until` is true (or the frames run out); returns the frames used.
static func step(game: BeachGame, frames: int, until: Callable = Callable()) -> int:
	for i: int in frames:
		game._physics_process(1.0 / 60)
		hold_player(game)
		if until.is_valid() and until.call():
			return i + 1
	return frames

## One rival (Gary) with only the named skills on, no crumbs and no loose food, placed in the air at x.
static func isolate(game: BeachGame, skills: Dictionary, x: float) -> RivalPilot:
	var pilot: RivalPilot = game.pilots[0]
	pilot.personality["ground"] = {"scraps": 0.0, "bins": 0.0, "bags": 0.0, "catch": 0.0}.merged(skills, true)
	for crumb: Dictionary in game.scraps.crumbs:
		crumb.wait = 99999.0
	game.stash_raids.items.clear()
	pilot.gull.position = Vector2(x, 65.0)
	pilot.gull.velocity = Vector2.ZERO
	pilot.gull.state = BeachGull.State.GLIDE
	pilot.mode = RivalPilot.Mode.PATROL
	pilot.waypoint = -1.0
	pilot.cooldown = 0.0
	return pilot

static func ground_item(food_id: String, x: float) -> Dictionary:
	return {"owner": null, "source": "bin", "food_id": food_id, "position": Vector2(x, float(Config.tuning.world.ground) - 5.0), "velocity": Vector2.ZERO, "grounded": true, "age": 1.0}

static func ground_checks(host: Node, main: Node, check: Callable) -> void:
	var defaults: Dictionary = Config.tuning.rival.ground
	check.call(defaults.scraps == 0.5 and defaults.bins == 0.5 and defaults.bags == 0.5 and defaults.catch == 0.5, "rival ground weights default in tuning")
	var game: BeachGame = await fresh(host, main, 5)
	var by_name: Dictionary = {}
	for pilot: RivalPilot in game.pilots:
		by_name[pilot.gull.rival_name] = pilot
	check.call(by_name.Gary.weight("scraps") == 0.9 and by_name.Gary.weight("bins") == 0.9 and by_name.Gary.weight("bags") == 0.6 and by_name.Gary.weight("catch") == 0.7, "Gary the scavenger weights come from his data")
	check.call(by_name.Chip.weight("scraps") == 0.3 and by_name.Chip.weight("bins") == 0.2 and by_name.Chip.weight("bags") == 0.3 and by_name.Chip.weight("catch") == 0.8, "Chip the thief weights come from his data")
	var plain := RivalPilot.new()
	plain.personality = {}
	check.call(plain.weight("bins") == 0.5, "a profile without a ground block uses the tuning defaults")
	# Lands next to a ground item, walks to it and eats it (a theft: score and mug window), without crashing.
	game = await fresh(host, main, 3)
	var gary: RivalPilot = isolate(game, {"scraps": 1.0}, 360.0)
	game.stash_raids.items.append(ground_item("hotdog", 480.0))
	var landed: Array[bool] = [false]
	var steps: int = step(game, 60 * 25, func() -> bool:
		landed[0] = landed[0] or gary.gull.state == BeachGull.State.GROUNDED
		return gary.ground_eats > 0)
	check.call(landed[0] and gary.ground_eats == 1 and gary.thefts == 1 and gary.carried_food_id == "hotdog" and gary.score == 45, "rival lands, walks to a dropped hotdog and eats it (%d steps, %d eats)" % [steps, gary.ground_eats])
	check.call(gary.carry_window > 0.0 and is_equal_approx(gary.carry_window, GullDigestion.duration("hotdog")) and gary.crashes == 0 and game.stash_raids.items.is_empty(), "ground meal opens the swallow-time mug window and the item is gone")
	check.call(gary.gull.state == BeachGull.State.GROUNDED and gary.eat_timer > 0.0, "the rival stands still to swallow")
	step(game, 60 * 12)
	check.call(gary.gull.state != BeachGull.State.GROUNDED or gary.mode == RivalPilot.Mode.PATROL, "after the meal the rival takes off again (mode %d)" % gary.mode)
	# A player who gets there first wins; the rival does not get stuck.
	game = await fresh(host, main, 3)
	gary = isolate(game, {"scraps": 1.0}, 360.0)
	var prize: Dictionary = ground_item("hotdog", 560.0)
	game.stash_raids.items.append(prize)
	step(game, 60 * 20, func() -> bool: return gary.mode == RivalPilot.Mode.WALK)
	check.call(gary.mode == RivalPilot.Mode.WALK, "rival is walking to the item (mode %d)" % gary.mode)
	game.stash_raids.items.clear() # the player snatched it first
	step(game, 60 * 3)
	check.call(gary.ground_eats == 0 and gary.work.is_empty() and gary.mode != RivalPilot.Mode.WALK, "a rival that loses the item stops walking to it (mode %d)" % gary.mode)
	# Bin: land, peck bin_pecks times, scraps spill (the bin stays emptied), eat food but not garbage.
	game = await fresh(host, main, 3)
	gary = isolate(game, {"scraps": 1.0, "bins": 1.0}, 360.0)
	var bin: Dictionary = game.stash_raids.bins[0]
	var capacity: int = int(bin.remaining)
	steps = step(game, 60 * 40, func() -> bool: return gary.stats.bins > 0 and gary.ground_eats > 0)
	var eaten: bool = Config.foods.has(gary.carried_food_id) and gary.score > 0
	check.call(gary.stats.bins >= 1 and int(bin.remaining) == capacity - int(Config.tuning.world.bin_burst), "rival pecks a bin open and scraps leave it for good (%d steps, %d left)" % [steps, int(bin.remaining)])
	check.call(gary.ground_eats >= 1 and eaten, "rival eats a scrap from the bin (%s)" % gary.carried_food_id)
	var wrappers: int = game.stash_raids.items.filter(func(item: Dictionary) -> bool: return bool(item.get("garbage", false))).size()
	check.call(wrappers >= 1 and gary.score <= 15, "rival leaves garbage on the sand")
	# Wheelie bin: top landing.
	game = await fresh(host, main, 3)
	var wheelie_x: float = float(game.level.props.filter(func(prop: Dictionary) -> bool: return prop.type == "wheelie_bin")[0].x)
	gary = isolate(game, {"scraps": 1.0, "bins": 1.0}, wheelie_x - 40.0)
	var lid_seen: Array[bool] = [false]
	steps = step(game, 60 * 40, func() -> bool:
		lid_seen[0] = lid_seen[0] or gary.gull.is_supported_by(BeachBackdrop.WHEELIE_BIN_TYPE, wheelie_x)
		return gary.stats.bins > 0)
	check.call(lid_seen[0] and gary.stats.bins >= 1, "rival lands on the wheelie bin lid and pecks it open (%d steps)" % steps)
	# Bag: peck a sunbather's stash open.
	game = await fresh(host, main, 3)
	gary = isolate(game, {"bags": 1.0}, 140.0)
	var bag: BeachTarget
	for target: BeachTarget in game.spawner.targets:
		if target.kind == "sunbather" and (bag == null or target.stash_position().x < bag.stash_position().x):
			bag = target
	var stash_before: int = bag.stash_remaining
	steps = step(game, 60 * 40, func() -> bool: return gary.stats.bags > 0)
	check.call(gary.stats.bags >= 1 and bag.stash_remaining < stash_before and game.stash_raids.raids.has(bag), "rival pecks a sunbather's bag open (%d steps)" % steps)
	# A sunbather's swat stuns a raiding rival, as it does the player.
	var raid: Dictionary = game.stash_raids.raids[bag]
	bag.sleep_state = BeachTarget.SleepState.AWAKE
	bag.reaction.mode = ""
	gary.gull.state = BeachGull.State.GROUNDED
	gary.gull.position = bag.position - Vector2(0, 12) + Vector2(6, 0)
	raid.merge({"raider": gary.gull, "notice": 0.0, "swat": 0.0, "action": "swat_windup", "action_time": 0.0, "pickup_item": {}}, true)
	game.stash_raids.tick(1.0 / 60)
	check.call(gary.gull.state == BeachGull.State.STUNNED, "a swatting sunbather stuns the rival that raided the bag")
	# Catch: a snack flung through the air is caught by a rival that is flying through it.
	game = await fresh(host, main, 3)
	gary = isolate(game, {"catch": 1.0}, 470.0)
	gary.gull.facing = 1.0
	game.stash_raids.items.append({"owner": null, "source": "bin", "food_id": "hotdog", "position": Vector2(500.0, 80.0), "velocity": Vector2(0, -90), "grounded": false, "age": 0.35})
	steps = step(game, 60 * 4, func() -> bool: return gary.thefts > 0)
	check.call(gary.stats.catch == 1 and gary.carried_food_id == "hotdog" and gary.gull.state != BeachGull.State.GROUNDED, "rival catches falling food in the air (%d steps)" % steps)
	# A weight of 0 switches the skill off.
	game = await fresh(host, main, 3)
	gary = isolate(game, {}, 380.0)
	game.stash_raids.items.append(ground_item("hotdog", 420.0))
	game.stash_raids.items.append({"owner": null, "source": "bin", "food_id": "cookie", "position": Vector2(400.0, 60.0), "velocity": Vector2(0, -30), "grounded": false, "age": 0.35})
	check.call(gary.ground_options().is_empty() and not gary.accepts_item(game.stash_raids.items[0]) and not gary.accepts_item(game.stash_raids.items[1]), "all-zero weights: no ground options, nothing accepted")
	step(game, 60 * 12)
	check.call(gary.ground_eats == 0 and gary.stats.catch == 0 and gary.mode in [RivalPilot.Mode.PATROL, RivalPilot.Mode.RECOVER], "a rival with every ground weight at 0 never lands for food (%d eats)" % gary.ground_eats)
	game = await fresh(host, main, 3)
	gary = isolate(game, {"scraps": 1.0, "bags": 1.0, "catch": 1.0}, 360.0)
	var kinds: Array = gary.ground_options().map(func(option: Dictionary) -> String: return str(option.kind))
	check.call(not kinds.has("bin") and kinds.has("bag"), "bins weight 0 removes bin jobs only (%s)" % str(kinds))
	gary.personality.ground.bags = 0.0
	kinds = gary.ground_options().map(func(option: Dictionary) -> String: return str(option.kind))
	check.call(not kinds.has("bag"), "bags weight 0 removes bag jobs")
	game.stash_raids.items.append(ground_item("hotdog", 420.0))
	gary.personality.ground.scraps = 0.0
	kinds = gary.ground_options().map(func(option: Dictionary) -> String: return str(option.kind))
	check.call(kinds.is_empty() or not (kinds.has("item") or kinds.has("scrap")), "scraps weight 0 removes item and crumb jobs")

## Gary the scavenger in a plain level 3 (no scattered food): eats a lot, with at least two different skills.
static func scavenger_checks(host: Node, main: Node, check: Callable) -> void:
	var r: Dictionary = await simulate(host, main, 3, 90.0)
	var pilot: RivalPilot = main.game.pilots[0]
	var used: int = 0
	for skill: String in ["scraps", "bins", "bags", "catch"]:
		used += 1 if int(pilot.stats[skill]) > 0 else 0
	print("RIVAL SIM level 3 ground: eats %d stats %s ground_max %.1f" % [pilot.ground_eats, str(pilot.stats), r.ground_max])
	check.call(pilot.ground_eats >= 4, "level 3 Gary eats at least 4 items with no scattered food (%d)" % pilot.ground_eats)
	check.call(used >= 2, "level 3 Gary uses at least two ground skills (%s)" % str(pilot.stats))
	check.call(r.ground_max <= 6.0, "level 3 Gary is never stuck on the ground for over 6 s (%.1f)" % r.ground_max)
	check.call(r.dives[0] == 0 and r.held_picks == 0, "level 3 Gary stays loose-only: no snatching from hands")

## Screenshots: a rival pecking a bin, then eating a scrap it released.
static func ground_captures(host: Node, main: Node) -> void:
	var game: BeachGame = await fresh(host, main, 3)
	var gary: RivalPilot = isolate(game, {"scraps": 1.0, "bins": 1.0}, 360.0)
	step(game, 60 * 60, func() -> bool: return gary.mode == RivalPilot.Mode.PECK and not gary.work.is_empty() and int(gary.work.ref.pecks) >= 2 and gary.gull.art_event_left > 0.1)
	game.camera_x = clampf(gary.gull.position.x, 160.0, 1120.0)
	game.camera.position = Vector2(roundf(game.camera_x), 90)
	await host.snapshot("rival-pecks-bin")
	step(game, 60 * 40, func() -> bool: return gary.ground_eats > 0)
	game.camera_x = clampf(gary.gull.position.x, 160.0, 1120.0)
	game.camera.position = Vector2(roundf(game.camera_x), 90)
	await host.snapshot("rival-eats-scrap")
