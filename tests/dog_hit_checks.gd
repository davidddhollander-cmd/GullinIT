extends RefCounted
## A bumped off-lead dog tumbles like a gull: thrown in an arc, spinning, dazed with stars, then cooldown.
## Drives the Level 3 dog directly on simulated ticks (no real-time timers).
const DT: float = 1.0 / 60.0

static func _fresh(suite: Node, level: int) -> BeachGame:
	suite.main.start_level(level)
	var game: BeachGame = suite.main.game
	game.set_physics_process(false)
	game.running = true
	game.intro = 0
	return game

static func _fly(game: BeachGame, x: float, height: float) -> void:
	game.player.state = BeachGull.State.GLIDE
	game.player.invulnerable = 0.0
	game.player.position = Vector2(x, float(Config.tuning.world.ground) - height)

static func run(suite: Node, check: Callable) -> void:
	var t: Dictionary = Config.tuning.off_lead_dog
	var width: float = float(Config.tuning.world.width)
	var ground: float = float(Config.tuning.world.ground)
	var fx_on: bool = bool(Config.tuning.juice.particles) and bool(Config.tuning.juice.get("pixelfx", false))
	var game: BeachGame = _fresh(suite, 3)
	var dog: OffLeadDog = game.dogs[0]
	var gull: BeachGull = game.player
	var bumps: Array[int] = [0]
	dog.bumped.connect(func(_gull: BeachGull) -> void: bumps[0] += 1)
	var landings: Array[int] = [0]
	dog.landed.connect(func(_at: Vector2) -> void: landings[0] += 1)

	# Bump: the gull is to the dog's right, so the dog is thrown left into a tumble.
	dog.state = OffLeadDog.State.CHASE
	dog.position.x = 300.0
	dog.air = 0.0
	dog.flee_to = NAN
	_fly(game, 320.0, 20.0)
	check.call(dog.bump(gull) and dog.state == OffLeadDog.State.TUMBLE and bumps[0] == 1, "a bump throws the dog into TUMBLE, not straight into cooldown")
	check.call(not dog.bump(gull) and bumps[0] == 1, "a second bump during the tumble is ignored")

	# Flight: rises on an arc, spins, moves away from the gull, stays in the world.
	var start_x: float = dog.position.x
	var peak: float = 0.0
	var max_turn: float = 0.0
	var in_bounds: bool = true
	var ticks: int = 0
	while dog.state == OffLeadDog.State.TUMBLE and not dog.tumble_landed and ticks < 600:
		dog.tick(DT, game.player)
		ticks += 1
		peak = maxf(peak, dog.air)
		max_turn = maxf(max_turn, absf(dog.sprite.rotation))
		in_bounds = in_bounds and dog.position.x >= 12.0 and dog.position.x <= width - 12.0
	check.call(peak > 10.0, "the thrown dog rises well above the sand in the air")
	check.call(max_turn > 0.5, "the thrown dog spins in the air")
	check.call(in_bounds, "the thrown dog stays inside the world bounds")
	check.call(dog.tumble_landed and is_equal_approx(dog.air, 0.0) and is_equal_approx(dog.sprite.rotation, 0.0), "the dog lands at ground level with rotation 0")
	check.call(absf(dog.position.x - start_x) > 18.0 and dog.position.x < start_x, "the throw carries the dog further than the old 18 px, away from the gull")
	check.call(is_equal_approx(dog.position.y, ground) and landings[0] == 1, "landing keeps the dog on the sand line and puffs sand once")

	# Daze: stars over the head, no bump, no catch, and no stun even with the gull at its mouth.
	check.call(not fx_on or (is_instance_valid(dog.stars) and dog.stars.get_parent() == dog), "stars circle the dog's head during the daze")
	check.call(not dog.bump(gull) and bumps[0] == 1, "the dog cannot be bumped again during the daze")
	var stunned: bool = false
	var daze_ticks: int = 0
	while dog.state == OffLeadDog.State.TUMBLE and daze_ticks < 600:
		gull.state = BeachGull.State.GROUNDED
		gull.invulnerable = 0.0
		gull.position = dog.mouth()
		dog.tick(DT, game.player)
		stunned = stunned or gull.state == BeachGull.State.STUNNED
		daze_ticks += 1
	check.call(not stunned, "the dog cannot catch a gull at its mouth during the daze")
	check.call(absf(float(daze_ticks) * DT - float(t.tumble_daze)) < 0.05, "the daze lasts tumble_daze seconds")
	check.call(dog.state == OffLeadDog.State.COOLDOWN and dog.timer > float(t.cooldown) - 0.1, "after the daze the dog takes the normal cooldown")
	check.call(not is_instance_valid(dog.stars) and is_equal_approx(dog.sprite.rotation, 0.0) and is_equal_approx(dog.air, 0.0), "stars are gone and the spin is reset after the daze")
	check.call(not dog.bump(gull), "the dog cannot be bumped during its cooldown")

	# A squall's flee_to set mid-tumble waits until the tumble and daze are over.
	dog.state = OffLeadDog.State.WANDER
	dog.position.x = 500.0
	dog.flee_to = NAN
	_fly(game, 520.0, 20.0)
	dog.bump(gull)
	dog.tick(DT, game.player)
	dog.flee_to = 20.0
	var x_in_tumble: float = dog.position.x
	dog.tick(DT, game.player)
	check.call(dog.state == OffLeadDog.State.TUMBLE and dog.position.x < x_in_tumble, "flee_to set mid-tumble does not cut the tumble short")
	var guard: int = 0
	while dog.state == OffLeadDog.State.TUMBLE and guard < 600:
		dog.tick(DT, game.player)
		guard += 1
	var x_after_daze: float = dog.position.x
	check.call(is_equal_approx(dog.sprite.rotation, 0.0) and not is_instance_valid(dog.stars), "the tumble is fully reset before the dog runs off")
	for i: int in 60:
		dog.tick(DT, game.player)
	check.call(dog.position.x < x_after_daze - 5.0, "after the tumble the dog runs for flee_to")
	dog.flee_to = NAN

	# Power immunity still bounces the dog (no tumble).
	dog.state = OffLeadDog.State.CHASE
	dog.home = Vector2(250.0, 900.0) # the gull must be inside the leash for the dog to chase it
	dog.position.x = 400.0
	dog.air = 0.0
	dog.facing = 1.0
	gull.state = BeachGull.State.GROUNDED
	gull.invulnerable = 5.0
	gull.steady_invulnerable = true
	gull.bumps_dogs = false
	gull.position = dog.mouth()
	dog._try_catch(gull)
	check.call(dog.state == OffLeadDog.State.COOLDOWN and is_equal_approx(dog.position.x, 400.0 - float(Config.tuning.shakedown.bounce_recoil)), "a power-immune gull still bounces the dog off with the old recoil")
	gull.steady_invulnerable = false
	gull.invulnerable = 0.0

	suite.main.clear_game()
	await suite.settle()
