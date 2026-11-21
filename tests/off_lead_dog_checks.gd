extends RefCounted
## Drives the Level 7 terrier directly: set positions, tick, read state. No full run needed.
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
	# Level data: Boardwalk Bustle (3) has no dogs now; Dog Day Afternoon (5) has four; levels 7-9 keep their one terrier.
	var level: Dictionary = Config.levels[6] # Three's a Crowd: one plain terrier, the fixture for the behaviour checks below
	var three: Dictionary = Config.levels[2]
	check.call(three.name == "Boardwalk Bustle" and int(three.map_version) >= 3 and three.has("world") and three.has("zones"), "level 3 is the hand-built Boardwalk Bustle")
	check.call(not three.spawns.any(func(spawn: Dictionary) -> bool: return spawn.type == "off_lead_dog") and three.twist.id == "gary_intro", "level 3 has no off-lead dogs; Gary is its twist")
	check.call(Config.levels[5].quests[0].id == "l5_counter" and not Config.levels[5].spawns.any(func(spawn: Dictionary) -> bool: return spawn.type == "off_lead_dog"), "Water Fight (6) has no dog and keeps its counter quest")
	for number: int in [1, 2, 3, 4, 6]:
		var other: BeachGame = _fresh(suite, number)
		check.call(other.dogs.is_empty(), "level %d has no off-lead dog" % number)
		suite.main.clear_game()
	var dog_day: BeachGame = _fresh(suite, 5)
	check.call(dog_day.dogs.size() == 4, "level 5 (Dog Day Afternoon) spawns 4 dogs")
	var breeds: Array[String] = []
	var homes: Array = []
	for each: OffLeadDog in dog_day.dogs:
		breeds.append(each.breed_id)
		homes.append(each.home)
	var homes_unique: bool = true
	for i: int in homes.size():
		for j: int in range(i + 1, homes.size()):
			homes_unique = homes_unique and homes[i] != homes[j]
	check.call(breeds.count("golden_retriever") == 1 and breeds.count("german_shepherd") == 1 and breeds.count("small_dog") == 2 and homes_unique, "level 5 has a golden, a shepherd and two small dogs, each with its own home")
	await _breed_checks(suite, check, dog_day)
	suite.main.clear_game()
	await suite.settle()
	var five: BeachGame = _fresh(suite, 7)
	check.call(five.dogs.size() == 1 and five.dogs[0].breed_id.is_empty(), "level 7 has the plain terrier by the family")
	suite.main.clear_game()
	var six: BeachGame = _fresh(suite, 8)
	check.call(six.dogs.size() == 1 and six.dogs[0].breed_id.is_empty(), "level 8 has the plain terrier")
	suite.main.clear_game()
	var seven: BeachGame = _fresh(suite, 9)
	check.call(seven.dogs.size() == 1 and seven.dogs[0].breed_id.is_empty(), "level 9 has the plain terrier")
	suite.main.clear_game()
	var game: BeachGame = _fresh(suite, 7)
	var dog: OffLeadDog = game.dogs[0]
	check.call(game.spawner.targets.size() == level.spawns.size() - 1, "dogs are their own actors, not targets")
	var barks: Array[int] = [0]
	var outruns: Array[int] = [0]
	var catches: Array[int] = [0]
	dog.barked.connect(func() -> void: barks[0] += 1)
	dog.outrun.connect(func() -> void: outruns[0] += 1)
	dog.caught.connect(func() -> void: catches[0] += 1)
	var outrun_probe: Dictionary = {"id": "t_outrun", "text": "T", "event": "dog_outrun", "filter": {}, "count": 1, "bonus": 0, "progress": 0, "done": false}
	game.quests.quests.append(outrun_probe)
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

	check.call(outrun_probe.done and int(outrun_probe.progress) >= 1 and outruns[0] >= 1, "each escaped chase fires dog_outrun once; one completes an outrun quest")

	# Rivals: the dog chases the nearest low gull, catches it, and the rival drops its food.
	suite.main.clear_game()
	await suite.settle()
	game = _fresh(suite, 7)
	dog = game.dogs[0]
	var pilot: RivalPilot = game.pilots[0] # Gary is on the beach from the start
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
	game = _fresh(suite, 7)
	dog = game.dogs[0]
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

## Breeds are data (tuning.off_lead_dog_breeds): speeds, leaps and sizes differ without per-breed code.
static func _breed_checks(suite: Node, check: Callable, game: BeachGame) -> void:
	var base: Dictionary = Config.tuning.off_lead_dog
	var golden: OffLeadDog = game.dogs[0]
	var small: OffLeadDog = game.dogs[1]
	var shepherd: OffLeadDog = game.dogs[2]
	var small_b: OffLeadDog = game.dogs[3]
	check.call(float(golden._t().run_speed) < float(base.run_speed) and float(base.run_speed) < float(shepherd._t().run_speed) and float(small._t().run_speed) > float(base.run_speed) * 0.99, "golden is slower than the terrier, shepherd faster, small dog quick")
	check.call(float(shepherd._t().leap_height) > float(golden._t().leap_height) and float(golden._t().leap_height) > float(small._t().leap_height) and float(shepherd._t().leap_lift) > float(golden._t().leap_lift) and float(small._t().leap_lift) < float(base.leap_lift), "shepherd leaps highest, small dogs only reach a very low gull")
	check.call(float(shepherd._t().chase_timeout) > float(base.chase_timeout) and float(golden._t().chase_timeout) < float(base.chase_timeout) and float(small._t().chase_timeout) < float(golden._t().chase_timeout), "the shepherd chases longest, the golden gives up sooner, small dogs dash briefly")
	check.call(float(golden._t().sniff_max) > float(base.sniff_max) and float(golden._t().rest_max) > float(base.rest_max), "the golden sniffs and idles more")
	check.call(golden.sprite.sprite_frames == Config.frames("golden_retriever") and shepherd.sprite.sprite_frames == Config.frames("german_shepherd") and small.sprite.sprite_frames == Config.frames("off_lead_dog"), "each breed uses its own full source sheet; small dogs use the terrier sheet")
	check.call(small.sprite.scale.x < golden.sprite.scale.x and is_equal_approx(small.sprite.scale.x, small_b.sprite.scale.x), "small dogs are drawn smaller")
	for each: OffLeadDog in game.dogs:
		each.tick(1.0 / 60.0, game.player)
		check.call(is_equal_approx(each.sprite.position.y, each.sprite_offset_y() - each.air) and absf(each.sprite_offset_y() + 36.0 * each.sprite.scale.x) < 0.01, "%s paws sit on the sand (offset follows scale)" % (each.breed_id if not each.breed_id.is_empty() else "terrier"))
	# A small dog's bark puts the people next to it on alert; a shepherd's does not.
	var neighbour: BeachTarget = game.spawner.targets[0]
	var far_neighbour: BeachTarget = game.spawner.targets[1]
	neighbour.alert = 0.0
	far_neighbour.alert = 0.0
	neighbour.position = Vector2(small.position.x + 30.0, neighbour.position.y)
	far_neighbour.position = Vector2(small.position.x + small.bark_alert_radius() + 80.0, far_neighbour.position.y)
	small.barked.emit()
	check.call(is_equal_approx(neighbour.alert, 1.0) and far_neighbour.alert < 1.0, "a small dog's bark alerts the humans near it, not far ones")
	neighbour.alert = 0.0
	neighbour.position = Vector2(shepherd.position.x + 20.0, neighbour.position.y)
	shepherd.barked.emit()
	check.call(neighbour.alert == 0.0, "a shepherd's bark alerts nobody (bark_alert_radius is data)")
	# Leap reach: a gull 44 px up is leapt at by the shepherd but not by a golden or a small dog.
	for each: OffLeadDog in [shepherd, golden, small]:
		each.home = Vector2(each.position.x - 20.0, each.position.x + 1000.0)
		each.state = OffLeadDog.State.CHASE
		each.leap_gap = 0.0
		game.player.state = BeachGull.State.GLIDE
		game.player.invulnerable = 0.0
		game.player.position = Vector2(each.position.x + 10.0, float(Config.tuning.world.ground) - 44.0)
		each.tick(1.0 / 60.0, game.player)
	check.call(shepherd.state == OffLeadDog.State.LEAP and golden.state != OffLeadDog.State.LEAP and small.state != OffLeadDog.State.LEAP, "only the shepherd leaps at a gull 44 px up")
	# Depth rule (AGENTS.md rule 6): a new breed and a small dog, beside a bench, a bin and a stall.
	game.running = true
	game.set_physics_process(false)
	var level: Dictionary = game.level
	for dog: OffLeadDog in [shepherd, small]:
		dog.state = OffLeadDog.State.WANDER
		dog.resting = true
		dog.timer = 99.0
		game.player.state = BeachGull.State.GROUNDED
		game.player.position = Vector2(2000.0, game.player.ground_y())
		for type: String in ["beach_bench", "bin", "hotdog_stand"]:
			var prop: Dictionary = level.props.filter(func(candidate: Dictionary) -> bool: return candidate.type == type)[0]
			var base_y: float = float(prop.get("y", 160))
			var prop_z: int = FoodStall.DRAW_DEPTH if type == "hotdog_stand" else game.beach.prop_sprites[level.props.find(prop)].z_index
			dog.position = Vector2(float(prop.x), base_y + 8.0)
			game._physics_process(1.0 / 60.0)
			var front_z: int = dog.z_index
			dog.position = Vector2(float(prop.x), base_y - 8.0)
			game._physics_process(1.0 / 60.0)
			var back_z: int = dog.z_index
			check.call(front_z > prop_z and front_z >= 3, "%s feet below a %s base draw in front of it" % [dog.breed_id, type])
			check.call(back_z < prop_z, "%s feet above a %s base draw behind it" % [dog.breed_id, type])
			# Against characters: a walker with feet in front draws over a dog behind the prop, and the reverse.
			check.call(game.spawner.depth_z(Vector2(float(prop.x), base_y + 8.0), 2) > back_z and game.spawner.depth_z(Vector2(float(prop.x), base_y - 8.0), 2) < front_z, "%s and a walker at the same %s order by their feet" % [dog.breed_id, type])
