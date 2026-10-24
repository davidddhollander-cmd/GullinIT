extends RefCounted
## Task 026: benches get used, start occupied, and theft victims sulk then wander.

static func new_game(host: Node, id: int) -> BeachGame:
	var game := BeachGame.new()
	host.add_child(game)
	game.setup(Config.levels[id-1].duplicate(true),false)
	game.set_physics_process(false)
	game.running = true
	game.intro = 0
	game.player.position = Vector2(80,50)
	return game

static func step(game: BeachGame, time: float, gulls: Array[BeachGull] = []) -> void:
	for i: int in ceili(time/0.02):
		game.spawner.reset_spacing()
		for t: BeachTarget in game.spawner.targets.duplicate():
			t.tick(0.02,gulls)
		game.stalls.tick(0.02)
		game.spawner.tick(0.02,0.0)
		game.spawner.apply_spacing(0.02)

static func run(host: Node, check: Callable) -> void:
	var previous_audio: bool = bool(Config.tuning.juice.audio)
	Config.tuning.juice.audio = false
	for id: int in [3,4,5,6]:
		var game := new_game(host,id)
		var seated: Array = game.spawner.targets.filter(func(t: BeachTarget) -> bool: return t.bench_visit.phase == BenchVisit.Phase.REST and t.food)
		check.call(seated.size() >= 1 or id == 4,"level %d starts with a bench occupied by a holding shopper" % id)
		if true:
			if not seated.is_empty():
				var starter: BeachTarget = seated[0]
				check.call(is_equal_approx(starter.position.x,float(starter.bench_visit.seat.ground.x)) and game.spawner.benches.owns(starter.bench_visit.seat,starter),"starter sits on the reserved bench")
			if not seated.is_empty():
				var at: float = float(seated[0].bench_visit.seat.ground.x)
				game.camera_x = at
				game.camera.position = Vector2(at,90)
				game.player.position = Vector2(at-200,50)
				await host.snapshot("bench_start_level6")
			var phases: Dictionary = {}
			var visits: int = 0
			for i: int in 6000:
				step(game,0.02)
				for t: BeachTarget in game.spawner.targets:
					var phase: int = t.bench_visit.phase
					if phase == BenchVisit.Phase.SIT and int(phases.get(t,0)) == BenchVisit.Phase.APPROACH:
						visits += 1
					phases[t] = phase
			print("BENCH SIM level %d: %d visits in 120 s" % [id,visits])
			check.call(visits >= 2,"level %d sees at least 2 bench visits in 120 s (%d)" % [id,visits])
		game.queue_free()
	# Theft victim wanders away, does not queue within 10 s, shops again later.
	var game := new_game(host,6)
	var victim: BeachTarget = game.spawner.create("kiosk_customer",700.0,{"appearance":"shopper_mullet","food_id":"hotdog"})
	game.stalls.bind(victim)
	check.call(victim != null,"level 6 has a free holding shopper")
	if victim != null:
		var gull := BeachGull.new()
		host.add_child(gull)
		gull.position = victim.position
		check.call(victim.take(gull),"shopper snack is stolen")
		var stand: FoodStall = game.stalls.find_stall(victim,victim.purchase_stall_type())
		var locked_early: bool = false
		for i: int in 500:
			step(game,0.02)
			locked_early = locked_early or victim.service_locked or (stand != null and absf(victim.position.x-stand.contact_x()) < 3.0)
		check.call(not locked_early,"theft victim does not reach a stall within 10 s")
		var shopped: bool = false
		for i: int in 6000:
			step(game,0.02)
			shopped = shopped or victim.service_locked
		check.call(shopped or victim.food,"theft victim shops again later")
		gull.queue_free()
	game.queue_free()
	Config.tuning.juice.audio = previous_audio
