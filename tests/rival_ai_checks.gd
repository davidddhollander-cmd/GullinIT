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
	var report: Dictionary = {"pilots":game.pilots.size(),"edge_max":0.0,"out_of_bounds":0,"sand_frames":0,"shared_target":0,"cooldown_dives":0,"escape_short":0,"dives":[],"thefts":[],"crashes":[]}
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
	return report

static func run(host: Node, main: Node, check: Callable) -> void:
	for level: int in [3,4,6]:
		var r: Dictionary = await simulate(host, main, level, 90.0)
		print("RIVAL SIM level %d: %s" % [level,str(r)])
		var need_thefts: int = 2 if level == 6 else 1
		check.call(r.pilots == (3 if level == 6 else 1),"level %d rival count" % level)
		for i: int in r.pilots:
			check.call(r.dives[i] >= 3,"level %d rival %d dives at least 3 times (%d)" % [level,i,r.dives[i]])
			check.call(r.thefts[i] >= need_thefts,"level %d rival %d steals at least %d times (%d)" % [level,i,need_thefts,r.thefts[i]])
			check.call(r.crashes[i] == 0,"level %d rival %d never crashes its own dives" % [level,i])
		check.call(r.edge_max <= 1.5,"level %d rival never lingers at the edge (%.2f s)" % [level,r.edge_max])
		check.call(r.out_of_bounds == 0,"level %d rivals stay inside the beach" % level)
		check.call(r.shared_target == 0,"level %d rivals never chase the same target" % level)
		check.call(r.cooldown_dives == 0,"level %d rival waits out the cooldown after a theft" % level)
		check.call(r.escape_short == 0,"level %d rival leaves the scene of a theft" % level)
