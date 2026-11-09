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

## Task 071: he always starts just off a screen edge, never on it, and runs in along the ground to his range.
static func _entry_checks(suite: Node, check: Callable) -> void:
	var t: Dictionary = Config.tuning.sweeper
	var game: BeachGame = _start(suite,2)
	var visits: SweeperVisits = game.sweeper_visits
	var gull: BeachGull = game.player
	var half: float = visits._half_width()
	var reach: float = BeachSweeper.screen_reach()
	check.call(absf(half-160.0) < 0.01,"the view is 320 wide, so the spawn offset comes from the real half-width (%s)" % half)
	var width: float = float(Config.tuning.world.width)
	var cams: Array[float] = []
	var cam: float = 160.0
	while cam <= width-160.0:
		cams.append(cam)
		cam += 16.0
	cams.append(width-160.0)
	var hidden: bool = true
	var smooth: bool = true
	var reached: bool = true
	var near_side: bool = true
	var step: float = 0.05
	for camera: float in cams:
		game.camera_x = camera
		gull.position = Vector2(camera,40.0) # high and out of notice, so he only runs in
		if is_instance_valid(visits.sweeper):
			visits.sweeper.queue_free()
		visits._spawn()
		var sweeper: BeachSweeper = visits.sweeper
		if absf(sweeper.position.x-camera) < half+reach:
			hidden = false
		if camera-half > float(t.range[1]) and sweeper.position.x > camera:
			near_side = false # past his range the side nearer the sand is the left one
		var prev: float = sweeper.position.x
		for i: int in 200:
			sweeper.tick(step,gull)
			var now: float = sweeper.position.x
			var seen: bool = absf(now-camera) < half or absf(prev-camera) < half
			if seen and absf(now-prev) > float(t.run_speed)*step+0.01:
				smooth = false # a jump onto the screen, not a run
			prev = now
			if sweeper.state != BeachSweeper.State.ENTER:
				break
		if sweeper.state != BeachSweeper.State.PATROL or sweeper.position.x < float(t.range[0])-20.0 or sweeper.position.x > float(t.range[1])+20.0:
			reached = false
	check.call(hidden,"every new sweeper starts outside the visible screen, at every camera position, including past his sand range")
	check.call(near_side,"past his sand range he comes in from the side nearer the sand")
	check.call(smooth,"he runs in at his run speed; nothing jumps him onto the screen")
	check.call(reached,"he reaches his sand range by running, then patrols, from every camera position")
	if is_instance_valid(visits.sweeper):
		visits.sweeper.queue_free()
	game.stash_raids.items.clear()

static func run(suite: Node, check: Callable) -> void:
	var t: Dictionary = Config.tuning.sweeper
	check.call(Config.sprites.has("sweeper") and BeachSweeper.art().animations.has("swat"),"sweeper sprite and art data are registered")
	_entry_checks(suite,check)
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
	# Rivals are marks too: a low rival is warned and swatted while the player stays high.
	game = _start(suite,2)
	game._release_rivals()
	var rival: BeachGull = game.pilots[0].gull
	game.player.position = Vector2(700.0,40.0)
	rival.position = Vector2(300.0,rival.ground_y())
	rival.land()
	sweeper = _spawn(game,350.0)
	check.call(game._sweeper_mark(sweeper) == rival,"a low rival is his mark when the player is out of notice height")
	sweeper.tick(0.05,rival)
	check.call(sweeper.state == BeachSweeper.State.WARN and sweeper.prey == rival,"he warns a low rival")
	_until(sweeper,rival,BeachSweeper.State.WINDUP)
	rival.position.x = sweeper.position.x+sweeper.facing*18.0
	_until(sweeper,game.player,BeachSweeper.State.SWAT)
	_run_for(sweeper,game.player,0.7)
	check.call(rival.state == BeachGull.State.STUNNED and game.player.state != BeachGull.State.STUNNED,"his swing lands on the rival he chased, not on the far-off player")
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
