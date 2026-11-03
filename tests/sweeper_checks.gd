extends RefCounted
## Sweeper: visits, warn/windup/swat fairness, litter filter, pile pushing, bin dumps and pile theft.

static func _item(x: float, age: float = 2.0) -> Dictionary:
	return {"owner":null,"source":"dropped","food_id":"half_eaten_doughnut","position":Vector2(x,float(Config.tuning.world.ground)-4.0),"velocity":Vector2.ZERO,"grounded":true,"age":age}

static func _run_for(sweeper: BeachSweeper, gull: BeachGull, seconds: float) -> void:
	for i: int in int(seconds/0.05):
		if is_instance_valid(sweeper):
			sweeper.tick(0.05,gull)

static func _until(sweeper: BeachSweeper, gull: BeachGull, state: BeachSweeper.State, limit: float = 6.0) -> bool:
	for i: int in int(limit/0.05):
		if sweeper.state == state:
			return true
		sweeper.tick(0.05,gull)
	return sweeper.state == state

static func _start(suite: Node, level: int) -> BeachGame:
	suite.main.start_level(level)
	var game: BeachGame = suite.main.game
	game.set_physics_process(false)
	game.intro = 0
	game.running = true
	game.stash_raids.items.clear()
	return game

static func _spawn(game: BeachGame, x: float) -> BeachSweeper:
	var sweeper: BeachSweeper = BeachSweeper.new()
	game.actors.add_child(sweeper)
	sweeper.setup(game,x,1)
	sweeper.state = BeachSweeper.State.PATROL
	sweeper.timer = 999.0
	return sweeper

static func run(suite: Node, check: Callable) -> void:
	var t: Dictionary = Config.tuning.sweeper
	check.call(Config.sprites.has("sweeper") and BeachSweeper.art().animations.has("swat"),"sweeper sprite and art data are registered")
	# Level gating and visit schedule.
	var game: BeachGame = _start(suite,1)
	check.call(not game.sweeper_visits.enabled,"levels without a sweeper block never schedule him")
	game = _start(suite,2)
	var visits: SweeperVisits = game.sweeper_visits
	check.call(visits.enabled and not is_instance_valid(visits.sweeper),"level 2 schedules a sweeper but he starts absent")
	game.player.position.x = 300.0
	visits.tick(float(t.first_arrival)-1.0,true)
	check.call(not is_instance_valid(visits.sweeper),"no sweeper before the first arrival time")
	visits.tick(2.0,true)
	check.call(is_instance_valid(visits.sweeper),"sweeper arrives after the first arrival time")
	var sweeper: BeachSweeper = visits.sweeper
	check.call(sweeper.position.x >= float(t.range[0])-20.0 and sweeper.position.x <= float(t.range[1])+20.0,"sweeper enters at the sand edge of his range")
	sweeper.queue_free()
	# Early call by litter: more than call_litter items, not exactly call_litter.
	game = _start(suite,2)
	visits = game.sweeper_visits
	visits.wait = 9999.0
	visits.absent = float(t.call_min_absence)
	for i: int in int(t.call_litter):
		game.stash_raids.items.append(_item(100.0+i*10.0))
	visits.tick(0.1,true)
	check.call(not is_instance_valid(visits.sweeper),"exactly %d loose items do not call the sweeper" % int(t.call_litter))
	game.stash_raids.items.append(_item(200.0))
	visits.tick(0.1,true)
	check.call(is_instance_valid(visits.sweeper),"one more loose item calls him early")
	visits.sweeper.queue_free()
	# Sweepable filter.
	var owned: Dictionary = _item(100.0)
	owned.owner = game.spawner.targets[0]
	var airborne: Dictionary = _item(100.0)
	airborne.grounded = false
	var young: Dictionary = _item(100.0,0.2)
	var far: Dictionary = _item(float(t.range[1])+60.0)
	var swept: Dictionary = _item(100.0)
	swept.swept = true
	check.call(BeachSweeper.is_sweepable(_item(100.0)),"settled unowned grounded food is sweepable")
	check.call(not BeachSweeper.is_sweepable(owned) and not BeachSweeper.is_sweepable(airborne) and not BeachSweeper.is_sweepable(young) and not BeachSweeper.is_sweepable(far) and not BeachSweeper.is_sweepable(swept),"owned, falling, fresh, out-of-range and already-swept items are skipped")
	# Warn, windup, swat; a hit is the ordinary stun.
	game = _start(suite,2)
	var gull: BeachGull = game.player
	gull.position = Vector2(300.0,gull.ground_y())
	gull.land()
	sweeper = _spawn(game,350.0)
	var warned: Array = [0]
	sweeper.warned.connect(func() -> void: warned[0] += 1)
	sweeper.tick(0.05,gull)
	check.call(sweeper.state == BeachSweeper.State.WARN and warned[0] == 1,"a low gull in range is warned first, not hit")
	check.call(_until(sweeper,gull,BeachSweeper.State.CHASE),"warning leads to a chase")
	check.call(_until(sweeper,gull,BeachSweeper.State.WINDUP),"he runs in and winds up inside swing range")
	gull.position.x = sweeper.position.x+sweeper.facing*18.0
	check.call(_until(sweeper,gull,BeachSweeper.State.SWAT),"windup ends in a swing")
	var hit: Array = [false]
	sweeper.swatted.connect(func(_g: BeachGull) -> void: hit[0] = true)
	_run_for(sweeper,gull,0.7)
	check.call(hit[0] and gull.state == BeachGull.State.STUNNED,"a swing that connects stuns the gull through the normal stun")
	check.call(absf(gull.velocity.x) >= float(t.knock_speed)*0.9 and gull.velocity.y < 0.0,"a hit knocks the gull back much harder than a normal tumble")
	check.call(sweeper.cooldown > 0.0,"after a hit his cooldown starts")
	# Rising out of reach during the windup avoids the swing.
	game = _start(suite,2)
	gull = game.player
	gull.position = Vector2(300.0,gull.ground_y())
	gull.land()
	sweeper = _spawn(game,320.0)
	sweeper.tick(0.05,gull)
	_until(sweeper,gull,BeachSweeper.State.WINDUP)
	gull.position.y = float(Config.tuning.world.ground)-float(t.reach_height)-30.0
	hit[0] = false
	sweeper.swatted.connect(func(_g: BeachGull) -> void: hit[0] = true)
	_run_for(sweeper,gull,1.6)
	check.call(not hit[0] and gull.state != BeachGull.State.STUNNED,"a gull that rises above his reach during windup is not hit")
	gull.position = Vector2(sweeper.position.x+10.0,gull.ground_y())
	gull.land()
	sweeper.state = BeachSweeper.State.PATROL
	sweeper.timer = 999.0
	sweeper.cooldown = float(t.cooldown)
	sweeper.tick(0.05,gull)
	check.call(sweeper.state == BeachSweeper.State.PATROL,"the cooldown stops him warning again straight away")
	sweeper.queue_free()
	# Sweeping into the closest bin.
	game = _start(suite,2)
	gull = game.player
	gull.position = Vector2(600.0,float(Config.tuning.world.ground)-120.0)
	var bin: Dictionary = {}
	for candidate: Dictionary in game.stash_raids.bins:
		if float(candidate.x) > float(t.range[0])+80.0 and float(candidate.x) < float(t.range[1]):
			bin = candidate
			break
	check.call(not bin.is_empty(),"level 2 has a bin on the sand for the sweeper")
	if bin.is_empty():
		return
	var remaining: int = int(bin.remaining)
	var a: Dictionary = _item(float(bin.x)-70.0)
	var b: Dictionary = _item(float(bin.x)-62.0)
	game.stash_raids.items.append_array([a,b])
	sweeper = _spawn(game,float(bin.x)-130.0)
	gull.position.x = float(bin.x)+300.0
	sweeper.tick(0.05,gull)
	check.call(sweeper.state == BeachSweeper.State.SWEEP and is_same(sweeper.bin,bin) and a.get("swept",false),"he heads for the nearest litter and picks the closest bin")
	var sealed: Array = [0]
	sweeper.dumped.connect(func(count: int) -> void: sealed[0] = count)
	_until(sweeper,gull,BeachSweeper.State.DUMP,25.0)
	check.call(b.get("swept",false) and sweeper.pile.size() == 2,"the second item joins the pile as the brush passes it")
	check.call(absf(float(a.position.x)-sweeper._head_x()) < 6.0,"the pile rides at the broom head")
	_run_for(sweeper,gull,1.2)
	check.call(sealed[0] == 2 and game.stash_raids.items.is_empty(),"the pile goes into the bin and leaves the sand")
	check.call(int(bin.remaining) == remaining,"swept food does not refill the bin by default")
	# Stealing from the pile.
	var c: Dictionary = _item(float(bin.x)-70.0)
	var d: Dictionary = _item(float(bin.x)-62.0)
	game.stash_raids.items.append_array([c,d])
	sweeper.queue_free()
	sweeper = _spawn(game,float(bin.x)-130.0)
	var stolen: Array = [0]
	sweeper.pile_stolen.connect(func() -> void: stolen[0] += 1)
	sweeper.tick(0.05,gull)
	_run_for(sweeper,gull,1.5)
	game.stash_raids.items.erase(c)
	sweeper.tick(0.05,gull)
	check.call(stolen[0] == 1 and sweeper.state == BeachSweeper.State.SURPRISE,"taking food from his pile makes him react")
	game.stash_raids.items.clear()
	sweeper.queue_free()
