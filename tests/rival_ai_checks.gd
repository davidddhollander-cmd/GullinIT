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
		check.call(r.shared_target == 0,"level %d rivals never chase the same target" % level)
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
