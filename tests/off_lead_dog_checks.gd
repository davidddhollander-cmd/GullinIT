extends RefCounted
## Drives the Level 3 terrier (the second of its two dogs) directly: set positions, tick, read state. No full run needed.
const DT: float = 1.0 / 60.0

static func _fresh(suite: Node, level: int) -> BeachGame:
	suite.main.start_level(level)
	var game: BeachGame = suite.main.game
	game.set_physics_process(false)
	game.running = true
	game.intro = 0
	return game

static func _ground(game: BeachGame) -> void:
	game.player.state = BeachGull.State.GROUNDED
	game.player.invulnerable = 0.0
	game.player.position = Vector2(game.player.position.x, game.player.ground_y())

static func _fly(game: BeachGame, x: float, height: float) -> void:
	game.player.state = BeachGull.State.GLIDE
	game.player.invulnerable = 0.0
	game.player.position = Vector2(x, float(Config.tuning.world.ground) - height)

static func _run(dog: OffLeadDog, game: BeachGame, seconds: float) -> void:
	for i: int in int(seconds / DT):
		dog.tick(DT, game.player)

static func _reset(dog: OffLeadDog, x: float) -> void:
	dog.position.x = x
	dog.home = Vector2(x - 20.0, x + 1000.0)
	dog._wander()
	dog.resting = true
	dog.timer = 99.0
	dog.air = 0.0
	dog.leap_gap = 0.0

static func run(suite: Node, check: Callable) -> void:
	var t: Dictionary = Config.tuning.off_lead_dog
	var width: float = float(Config.tuning.world.width)
	# Level 3 data: two off-lead dogs with separate homes; levels 5-7 keep one.
	var level: Dictionary = Config.levels[2]
	check.call(level.name == "Boardwalk Bustle" and int(level.map_version) >= 3 and level.has("world") and level.has("zones"), "level 3 is the hand-built Boardwalk Bustle")
	var homes: Array = []
	for spawn: Dictionary in level.spawns:
		if spawn.type == "off_lead_dog":
			homes.append(spawn.home)
	check.call(homes.size() == 2 and level.twist.id == "off_lead_dogs" and float(homes[0][1]) < float(homes[1][0]), "level 3 has two off-lead dog spawns with separate homes and the dog twist")
	check.call(level.quests.size() == 2 and level.quests[0].id == "l3_outrun" and int(level.quests[0].count) == 3 and level.has("random_quest"), "level 3 quests are outrun x3, crab plus random")
	check.call(Config.levels[3].quests[0].id == "l4_counter" and not Config.levels[3].spawns.any(func(spawn: Dictionary) -> bool: return spawn.type == "off_lead_dog"), "level 4 has no dog and keeps its counter quest")
	for number: int in [1, 2, 4]:
		var other: BeachGame = _fresh(suite, number)
		check.call(other.dogs.is_empty(), "level %d has no off-lead dog" % number)
		suite.main.clear_game()
	var five: BeachGame = _fresh(suite, 5)
	check.call(five.dogs.size() == 1, "level 5 has an off-lead dog by the family")
	suite.main.clear_game()
	var six: BeachGame = _fresh(suite, 6)
	check.call(six.dogs.size() == 1, "level 6 has an off-lead dog")
	suite.main.clear_game()
	var seven: BeachGame = _fresh(suite, 7)
	check.call(seven.dogs.size() == 1, "level 7 has an off-lead dog")
	suite.main.clear_game()
	var game: BeachGame = _fresh(suite, 3)
	check.call(game.dogs.size() == 2 and game.dogs[0] != game.dogs[1] and game.dogs[0].home != game.dogs[1].home and game.dogs[0].home.y < game.dogs[1].home.x, "level 3 spawns two independent dogs with their own homes")
	var dog: OffLeadDog = game.dogs[1]
	check.call(game.spawner.targets.size() == level.spawns.size() - 2, "dogs are their own actors, not targets")
	game.dogs[0].state = OffLeadDog.State.CHASE
	check.call(dog.state != OffLeadDog.State.CHASE, "one dog's state does not drive the other")
	var barks: Array[int] = [0]
	var outruns: Array[int] = [0]
	var catches: Array[int] = [0]
	dog.barked.connect(func() -> void: barks[0] += 1)
	dog.outrun.connect(func() -> void: outruns[0] += 1)
	dog.caught.connect(func() -> void: catches[0] += 1)
	game.quests.quests.append({"id": "t_caught", "text": "T", "event": "dog_caught", "filter": {}, "count": 1, "bonus": 0, "progress": 0, "done": false})

	# Wander: stays in its home range, sniffs, never leaves the world.
	_fly(game, 900.0, 80.0)
	var saw_sniff: bool = false
	var min_x: float = 9999.0
	var max_x: float = 0.0
	for i: int in 3600:
		dog.tick(DT, game.player)
		saw_sniff = saw_sniff or dog.state == OffLeadDog.State.SNIFF
		min_x = minf(min_x, dog.position.x)
		max_x = maxf(max_x, dog.position.x)
	check.call(saw_sniff and min_x >= dog.home.x - 0.5 and max_x <= dog.home.y + 0.5 and barks[0] == 0, "wander trots and sniffs inside the home zone")
	check.call(is_equal_approx(dog.position.y, float(Config.tuning.world.ground)), "dog stays on the sand line")

	# A high gull (about 2x the old ceiling) still wakes the dog; it shadows underneath, barks, never catches.
	var high: float = float(t.leap_height) * 2.0
	_reset(dog, 300.0)
	_fly(game, 320.0, high)
	dog.resting = false
	_run(dog, game, 1.0)
	check.call(dog.state == OffLeadDog.State.CHASE and barks[0] >= 1, "high gull still wakes the dog")
	_fly(game, 380.0, high)
	var bark_before: int = barks[0]
	var worst_gap: float = 0.0
	for i: int in int(5.0 / DT):
		_fly(game, 380.0 + 20.0 * sin(i * DT), high)
		dog.tick(DT, game.player)
		if i > int(1.5 / DT):
			worst_gap = maxf(worst_gap, absf(dog.position.x - game.player.position.x))
	check.call(worst_gap <= 20.0 and dog.state == OffLeadDog.State.CHASE, "dog shadows a high gull's x (within 20 px)")
	check.call(barks[0] >= bark_before + 1, "dog barks while shadowing a high gull")
	check.call(catches[0] == 0 and game.player.state != BeachGull.State.STUNNED and dog.state != OffLeadDog.State.LEAP, "a high gull is never caught or leapt at")
	# A chase that runs past chase_timeout ends as one outrun.
	outruns[0] = 0
	dog.chase_time = float(t.chase_timeout) - 0.2
	_run(dog, game, 0.5)
	check.call(outruns[0] == 1 and dog.state == OffLeadDog.State.COOLDOWN, "chase times out after chase_timeout: one outrun then cooldown")

	# Notice -> bark -> 0.4 s windup -> chase.
	barks[0] = 0
	_reset(dog, 300.0)
	_ground(game)
	game.player.position.x = 300.0 + float(t.notice_radius) - 5.0
	dog.tick(DT, game.player)
	check.call(dog.state == OffLeadDog.State.WARN and barks[0] == 1, "dog barks when a low gull is within notice_radius")
	var start_x: float = dog.position.x
	game.player.position.x = 1000.0
	_fly(game, 340.0, 20.0)
	_run(dog, game, float(t.windup) - 0.1)
	check.call(dog.state == OffLeadDog.State.WARN and is_equal_approx(dog.position.x, start_x), "windup holds the dog still")
	_run(dog, game, 0.15)
	check.call(dog.state == OffLeadDog.State.CHASE, "dog starts chasing after the windup")
	_reset(dog, 300.0)
	_ground(game)
	game.player.position.x = 300.0 + float(t.notice_radius) + 10.0
	dog.tick(DT, game.player)
	check.call(dog.state == OffLeadDog.State.WANDER, "gull outside notice_radius is not noticed")

	# Chase speed: faster than walking, slower than flying.
	dog.state = OffLeadDog.State.CHASE
	dog.chase_time = 0.0
	dog.position.x = 300.0
	_fly(game, 400.0, 30.0)
	var before: float = dog.position.x
	_run(dog, game, 0.5)
	var run_speed: float = (dog.position.x - before) / 0.5
	check.call(absf(run_speed - float(t.run_speed)) < 2.0 and run_speed > float(Config.tuning.flight.ground_speed) and run_speed < float(Config.tuning.flight.max_speed), "chase speed sits between gull walking and flying")

	# Leap: close, airborne, low -> LEAP on an arc; too high -> no leap.
	_reset(dog, 500.0)
	dog.state = OffLeadDog.State.CHASE
	_fly(game, 500.0 + float(t.leap_range) - 2.0, float(t.leap_height) + 4.0)
	dog.tick(DT, game.player)
	check.call(dog.state == OffLeadDog.State.CHASE, "no leap at a gull above leap_height")
	_fly(game, 500.0 + float(t.leap_range) - 2.0, 18.0)
	dog.tick(DT, game.player)
	var leaping: bool = dog.state == OffLeadDog.State.LEAP
	dog.tick(DT, game.player)
	check.call(leaping and dog.sprite.animation == &"leap", "dog leaps at a low airborne gull in range")
	var peak: float = 0.0
	for i: int in 20:
		_fly(game, 900.0, 18.0)
		dog.tick(DT, game.player)
		peak = maxf(peak, dog.air)
	check.call(peak > float(t.leap_lift) * 0.8, "leap rises on an arc")
	_run(dog, game, float(t.leap_time))
	check.call(dog.air == 0.0 and dog.state != OffLeadDog.State.LEAP, "leap lands again")

	# Mid-height gull is at risk: the higher leap reaches it.
	_reset(dog, 550.0)
	dog.state = OffLeadDog.State.CHASE
	var mid_caught: bool = false
	for i: int in 60:
		_fly(game, dog.position.x + float(t.mouth_x) * dog.facing, 38.0)
		dog.tick(DT, game.player)
		if dog.state == OffLeadDog.State.CATCH:
			mid_caught = true
			break
	check.call(mid_caught and game.player.state == BeachGull.State.STUNNED, "a gull at mid-height can be caught by a leap")
	_run(dog, game, 5.0)
	catches[0] = 0

	# Ground catch: stun, dropped food, message data, event, cooldown.
	_reset(dog, 600.0)
	dog.state = OffLeadDog.State.CHASE
	dog.chase_time = 0.0
	dog.facing = 1.0
	_ground(game)
	game.player.position.x = 600.0 + float(t.mouth_x)
	game.player.digestion.collect("hotdog")
	var drops: int = game.stash_raids.items.size()
	dog.tick(DT, game.player)
	check.call(dog.state == OffLeadDog.State.CATCH and catches[0] == 1 and game.player.state == BeachGull.State.STUNNED, "mouth touching a grounded gull catches and stuns it")
	check.call(game.quests.quests.back().done, "catch records dog_caught")
	check.call(game.stash_raids.items.size() == drops + 1, "catch drops the held food")
	_run(dog, game, float(t.catch_time) + 0.05)
	check.call(dog.state == OffLeadDog.State.COOLDOWN, "dog enters cooldown after the catch animation")
	# Gull recovers beside the dog: no instant second catch.
	_ground(game)
	game.player.position.x = dog.position.x + float(t.mouth_x) * dog.facing
	_run(dog, game, float(t.cooldown) - 0.5)
	check.call(catches[0] == 1, "cooldown prevents a second catch")
	check.call(game.player.state == BeachGull.State.GROUNDED, "recovered gull stays unharmed during cooldown")
	game.player.position.x = dog.position.x + 200.0
	_run(dog, game, 1.0)
	check.call(dog.state in [OffLeadDog.State.WARN, OffLeadDog.State.WANDER, OffLeadDog.State.SNIFF], "dog resumes normal behaviour once cooldown ends")

	# Mid-leap catch.
	_reset(dog, 700.0)
	dog.state = OffLeadDog.State.CHASE
	_fly(game, 700.0 + 20.0, 16.0)
	dog.tick(DT, game.player)
	check.call(dog.state == OffLeadDog.State.LEAP, "leap starts for the mid-air catch")
	var leap_caught: bool = false
	for i: int in 40:
		_fly(game, dog.position.x + float(t.mouth_x) * dog.facing, 14.0 + dog.air)
		dog.tick(DT, game.player)
		if dog.state == OffLeadDog.State.CATCH:
			leap_caught = true
			break
	check.call(leap_caught and game.player.state == BeachGull.State.STUNNED and catches[0] == 2, "a leaping dog can catch a low flier")

	# Outrun: a real escape, flying away low then climbing; fires exactly once.
	_ground(game)
	_reset(dog, 800.0)
	dog.state = OffLeadDog.State.CHASE
	dog.chase_time = 0.0
	outruns[0] = 0
	_fly(game, 840.0, 25.0)
	for i: int in int(2.0 / DT):
		game.player.position.x += 100.0 * DT
		dog.tick(DT, game.player)
	check.call(dog.state == OffLeadDog.State.CHASE and outruns[0] == 0 and catches[0] == 2, "flying away low keeps the chase going without a catch")
	game.player.position.y = float(Config.tuning.world.ground) - 70.0
	_run(dog, game, 1.0)
	check.call(dog.state == OffLeadDog.State.CHASE and outruns[0] == 0, "climbing high does not end the chase")
	dog.chase_time = float(t.chase_timeout)
	dog.tick(DT, game.player)
	check.call(outruns[0] == 1 and dog.state == OffLeadDog.State.COOLDOWN, "a long chase that times out is one outrun")
	# Escape by distance.
	_reset(dog, 800.0)
	dog.state = OffLeadDog.State.CHASE
	dog.chase_time = 1.6
	_fly(game, 800.0 + float(t.lose_radius) + 10.0, 20.0)
	dog.tick(DT, game.player)
	check.call(outruns[0] == 2, "getting more than lose_radius away (horizontally) is an outrun")
	# A chase that ends too soon is not an outrun.
	_reset(dog, 800.0)
	dog.state = OffLeadDog.State.CHASE
	dog.chase_time = 0.0
	_fly(game, 800.0 + float(t.lose_radius) + 10.0, 20.0)
	dog.tick(DT, game.player)
	check.call(outruns[0] == 2 and dog.state == OffLeadDog.State.COOLDOWN, "a chase shorter than min_chase records nothing")
	# A stunned gull is never chased.
	_reset(dog, 800.0)
	_ground(game)
	game.player.position.x = 820.0
	game.player.state = BeachGull.State.STUNNED
	dog.tick(DT, game.player)
	check.call(dog.state == OffLeadDog.State.WANDER, "stunned gull is not noticed")

	# Leash: a long flight leaves home +/- leash, the dog gives up inside it, returns, one outrun.
	var leash: float = float(t.leash)
	check.call(leash * 2.0 + 80.0 >= 580.0, "leash zone spans about 600 px")
	var real_home: Vector2 = Vector2(235.0, 330.0)
	for spawn: Dictionary in level.spawns:
		if spawn.type == "off_lead_dog":
			real_home = Vector2(float(spawn.home[0]), float(spawn.home[1]))
	_reset(dog, real_home.y)
	dog.home = real_home
	dog.state = OffLeadDog.State.CHASE
	dog.chase_time = 0.0
	outruns[0] = 0
	_fly(game, real_home.y + 20.0, 20.0)
	var leash_x: float = 0.0
	for i: int in int(8.0 / DT):
		game.player.position.x = minf(game.player.position.x + 100.0 * DT, real_home.y + 600.0)
		dog.tick(DT, game.player)
		leash_x = maxf(leash_x, dog.position.x)
	check.call(leash_x <= real_home.y + leash + 3.0 and outruns[0] == 1, "dog stops within home + leash and fires one outrun")
	_run(dog, game, 9.0)
	check.call(dog.position.x <= real_home.y and dog.position.x >= real_home.x and outruns[0] == 1, "leashed dog trots back inside home")
	_reset(dog, real_home.y)
	dog.home = real_home
	_fly(game, real_home.y + leash + 40.0, 10.0)
	_run(dog, game, 1.0)
	check.call(dog.state == OffLeadDog.State.WANDER and barks[0] >= 1, "gull outside the leash zone does not start a chase")

	var outrun_quest: Dictionary = game.quests.quests[0]
	check.call(outrun_quest.done and int(outrun_quest.progress) == 3 and outruns[0] >= 1, "each escaped chase fires dog_outrun once; three complete l3_outrun")

	# Rivals: the dog chases the nearest low gull, catches it, and the rival drops its food.
	suite.main.clear_game()
	await suite.settle()
	game = _fresh(suite, 3)
	dog = game.dogs[1]
	game.pending_rivals = Config.levels[2].rivals.duplicate(true)
	game._release_rivals()
	var pilot: RivalPilot = game.pilots[0]
	var rivals: Array[BeachGull] = [pilot.gull]
	pilot.gull.state = BeachGull.State.GROUNDED
	pilot.gull.invulnerable = 0.0
	pilot.gull.position = Vector2(340.0, pilot.gull.ground_y())
	pilot.carried = 5
	pilot.carry_window = 5.0
	pilot.carried_food_id = "hotdog"
	_reset(dog, 300.0)
	dog.resting = false
	_ground(game)
	game.player.position.x = 300.0 + float(t.notice_radius) - 5.0
	dog.tick(DT, game.player, rivals)
	check.call(dog.prey == pilot.gull and dog.state == OffLeadDog.State.WARN, "dog picks a nearer rival over the player")
	var dropped_before: int = game.stash_raids.items.size()
	for i: int in int(4.0 / DT):
		dog.tick(DT, game.player, rivals)
	check.call(pilot.gull.state == BeachGull.State.STUNNED and pilot.carried == 0 and game.stash_raids.items.size() == dropped_before + 1 and game.stash_raids.items[-1].food_id == "hotdog", "caught rival is stunned and drops its food on the sand")
	pilot.gull.state = BeachGull.State.GROUNDED
	_reset(dog, 300.0)
	dog.resting = false
	game.player.position.x = 1500.0
	pilot.gull.position.x = 340.0
	Config.tuning.off_lead_dog.chase_rivals = false
	dog.tick(DT, game.player, rivals)
	Config.tuning.off_lead_dog.chase_rivals = true
	check.call(dog.state == OffLeadDog.State.WANDER and dog.prey != pilot.gull, "chase_rivals false: dog ignores rivals")

	# Rendered review shots (no-op without --capture).
	suite.main.clear_game()
	await suite.settle()
	game = _fresh(suite, 3)
	dog = game.dogs[1]
	_reset(dog, 250.0)
	dog.state = OffLeadDog.State.CHASE
	dog.chase_time = 0.5
	_ground(game)
	game.player.position.x = 292.0
	dog.position.x = 250.0
	dog.facing = 1.0
	_frame_camera(game, 270.0)
	dog.tick(DT, game.player)
	dog.sprite.frame = 2
	await suite.snapshot("off-lead-dog-chase")
	dog.state = OffLeadDog.State.LEAP
	dog.timer = float(t.leap_time) * 0.5
	dog.air = float(t.leap_lift)
	dog.leap_gap = 0.0
	_fly(game, 282.0, 20.0)
	dog.tick(DT, game.player)
	dog.sprite.frame = 3
	await suite.snapshot("off-lead-dog-leap")
	suite.main.clear_game()
	await suite.settle()

static func _frame_camera(game: BeachGame, x: float) -> void:
	game.camera_x = x
	game.camera.position.x = x
	game.beach.camera_x = x
	game.beach.queue_redraw()
