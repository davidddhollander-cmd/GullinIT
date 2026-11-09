extends RefCounted
## Task 074: gull-on-gull bumps scale with the attacker's speed and weight; a force of 0 is no bump.

const Tumble = preload("res://tests/gull_tumble_checks.gd")
const BLACKBACK: String = "great-black-backed"

static func _striker(host: Node, at: Vector2, species: String, speed: float) -> BeachGull:
	var gull: BeachGull = Tumble.actor(host, at)
	gull.species = species
	gull.state = BeachGull.State.STRIKE
	gull.dive_speed = speed
	gull.invulnerable = 0.0
	return gull

static func _victim(host: Node, at: Vector2, species: String) -> BeachGull:
	var gull: BeachGull = Tumble.actor(host, at)
	gull.species = species
	gull.state = BeachGull.State.GLIDE
	gull.invulnerable = 0.0
	return gull

static func _fresh(host: Node) -> BeachGame:
	host.main.start_level(7)
	var game: BeachGame = host.main.game
	game.set_physics_process(false)
	game.running = true
	game.intro = 0
	game.player.position = Vector2(60, game.player.ground_y())
	game.player.state = BeachGull.State.GROUNDED
	return game

static func _pilot(game: BeachGame, rival: String) -> RivalPilot:
	for pilot: RivalPilot in game.pilots:
		if pilot.gull.rival_name == rival:
			return pilot
	return null

## The player's beak sweeps through the rival from the side, with the dive at the given speed.
static func _sweep(game: BeachGame, pilot: RivalPilot, speed: float) -> void:
	game.player.state = BeachGull.State.STRIKE
	game.player.invulnerable = 0.0
	game.player.dive_speed = speed
	game.player.position = pilot.gull.position + Vector2(18.0, 0.0)
	game.player.previous_beak = pilot.gull.position
	game.player.sweep_beak = pilot.gull.position

static func run(host: Node, check: Callable) -> void:
	_model_checks(check)
	_launch_checks(host, check)
	_site_checks(host, check)
	host.main.clear_game()

static func _model_checks(check: Callable) -> void:
	var full: float = float(Config.tuning.tumble.impact.full_speed)
	var floor_speed: float = float(Config.tuning.tumble.impact.min_speed)
	var max_force: float = float(Config.tuning.tumble.impact.max_force)
	check.call(is_equal_approx(BeachGull.bump_force(full, 1.0, 1.0), 1.0), "a herring at full speed hitting a herring has force 1.0")
	var heavy: float = BeachGull.bump_force(full, 1.6, 0.7)
	check.call(heavy > 1.0 and heavy <= max_force and is_equal_approx(heavy, 1.6 / 0.7), "a black-back at full speed on a kittiwake bumps further than a herring, under max_force")
	check.call(BeachGull.bump_force(full * 0.5, 1.6, 0.7) < heavy, "half speed bumps less than full speed")
	check.call(BeachGull.bump_force(floor_speed - 0.5, 1.6, 0.7) == 0.0, "below min_speed there is no bump")
	check.call(BeachGull.bump_force(full, 0.7, 1.6) < BeachGull.bump_force(full, 1.6, 0.7), "a kittiwake hitting a black-back bumps less than the reverse")
	check.call(is_equal_approx(BeachGull.bump_force(full, 5.0, 0.5), max_force), "force is capped at max_force")
	var weights: Dictionary = {"herring": 1.0, BLACKBACK: 1.6, "kittiwake": 0.7}
	var ok: bool = true
	for species: String in weights:
		var gull: BeachGull = BeachGull.new()
		gull.species = species
		ok = ok and is_equal_approx(gull.species_weight(), float(weights[species]))
		gull.free()
	check.call(ok, "species weights come from data/species.json")

static func _launch_checks(host: Node, check: Callable) -> void:
	var full: float = float(Config.tuning.tumble.impact.full_speed)
	var launch: float = float(Config.tuning.tumble.launch_speed)
	var up: float = float(Config.tuning.tumble.launch_up)
	# Herring on herring at full speed launches exactly as the old fixed launch did.
	var striker: BeachGull = _striker(host, Vector2(280, 100), "herring", full)
	var victim: BeachGull = _victim(host, Vector2(300, 100), "herring")
	victim.stun(-1.0, striker.position, striker.bump_force_on(victim))
	check.call(is_equal_approx(victim.velocity.x, launch) and is_equal_approx(victim.velocity.y, -up), "herring on herring at full speed launches at today's values")
	# Black-back on kittiwake: further than herring on herring, shorter at half speed, nothing below min speed.
	var heavy: BeachGull = _striker(host, Vector2(280, 100), BLACKBACK, full)
	var light: BeachGull = _victim(host, Vector2(300, 100), "kittiwake")
	light.stun(-1.0, heavy.position, heavy.bump_force_on(light))
	var heavy_launch: float = light.velocity.x
	check.call(heavy_launch > launch and heavy_launch <= launch * float(Config.tuning.tumble.impact.max_force) + 0.01, "black-back on kittiwake at full speed launches further than herring on herring, at most max_force")
	heavy.dive_speed = full * 0.5
	var half: BeachGull = _victim(host, Vector2(300, 100), "kittiwake")
	half.stun(-1.0, heavy.position, heavy.bump_force_on(half))
	check.call(half.velocity.x > 0.0 and half.velocity.x < heavy_launch, "black-back at half speed launches shorter")
	heavy.dive_speed = float(Config.tuning.tumble.impact.min_speed) - 1.0
	check.call(heavy.bump_force_on(light) == 0.0, "black-back below min_speed makes no bump")
	# Kittiwake on black-back: less than the reverse.
	var small: BeachGull = _striker(host, Vector2(280, 100), "kittiwake", full)
	var big: BeachGull = _victim(host, Vector2(300, 100), BLACKBACK)
	big.stun(-1.0, small.position, small.bump_force_on(big))
	check.call(big.velocity.x > 0.0 and big.velocity.x < heavy_launch, "a kittiwake hitting a black-back launches it less than the reverse")
	# Knockback is still a kick and sweep multiplier, and does not also apply to a gull hit.
	var kicked: BeachGull = _victim(host, Vector2(300, 100), BLACKBACK)
	kicked.apply_species_stats()
	kicked.stun(-1.0, Vector2(280, 100))
	check.call(is_equal_approx(kicked.velocity.x, launch * float(Config.species.species[BLACKBACK].knockback)), "a kick still uses the black-back's knockback")
	var bumped: BeachGull = _victim(host, Vector2(300, 100), BLACKBACK)
	bumped.apply_species_stats()
	var herring: BeachGull = _striker(host, Vector2(280, 100), "herring", full)
	bumped.stun(-1.0, herring.position, herring.bump_force_on(bumped))
	check.call(is_equal_approx(bumped.velocity.x, launch / 1.6), "a gull hit on a black-back uses the force, not knockback too")
	for gull: BeachGull in [striker, victim, heavy, light, half, small, big, kicked, bumped, herring]:
		gull.queue_free()

static func _site_checks(host: Node, check: Callable) -> void:
	var launch: float = float(Config.tuning.tumble.launch_speed)
	var full: float = float(Config.tuning.tumble.impact.full_speed)
	var slow: float = float(Config.tuning.tumble.impact.min_speed) - 10.0
	var game: BeachGame = _fresh(host)
	var gary: RivalPilot = _pilot(game, "Gary")
	var bev: RivalPilot = _pilot(game, "Bev")
	for pilot: RivalPilot in game.pilots:
		pilot.carry_window = 0.0
		pilot.carried = 0
		pilot.gull.state = BeachGull.State.GROUNDED
	gary.gull.state = BeachGull.State.GLIDE
	gary.gull.position = Vector2(400.0, 70.0)
	game.player.digestion.snacks.clear()

	# Bump (not carrying): a slow peck is no bump at all and the dive carries on.
	_sweep(game, gary, slow)
	var score_before: int = game.score.points
	var brash_before: float = game.brash.meter
	game._mugging()
	check.call(gary.gull.state != BeachGull.State.STUNNED and game.player.state == BeachGull.State.STRIKE and game.score.points == score_before and is_equal_approx(game.brash.meter, brash_before), "a slow peck at a rival is no bump: no stun, no brash, the dive carries on")
	# Bump (not carrying): a full-speed peck uses the real player's weight and the rival's.
	gary.gull.state = BeachGull.State.GLIDE
	gary.gull.invulnerable = 0.0
	_sweep(game, gary, full)
	var expected: float = BeachGull.bump_force(full, game.player.species_weight(), gary.gull.species_weight())
	game._mugging()
	check.call(gary.gull.state == BeachGull.State.STUNNED and is_equal_approx(absf(gary.gull.velocity.x), launch * expected), "a full-speed peck bumps a rival by the real attacker's weight")

	# Mug (carrying): a slow grab still takes the food, but the rival does not tumble.
	gary.gull.state = BeachGull.State.GLIDE
	gary.carry_window = 5.0
	gary.carried = 30
	gary.carried_food_id = "hotdog"
	_sweep(game, gary, slow)
	game._mugging()
	check.call(game.player.digestion.snacks.size() == 1 and gary.carried == 0 and gary.gull.state != BeachGull.State.STUNNED, "a slow mug still takes the food without tumbling the rival")
	game.player.digestion.snacks.clear()

	# Rival mugs player: real rival speed and weight; at force 0 the snack still goes.
	gary.carry_window = 0.0
	gary.carried = 0
	gary.leave = 0.0
	game.player.digestion.collect("hotdog")
	game.player.state = BeachGull.State.GLIDE
	game.player.invulnerable = 0.0
	gary.gull.state = BeachGull.State.STRIKE
	gary.gull.dive_speed = full
	gary.gull.previous_beak = game.player.position
	gary.gull.sweep_beak = game.player.position
	var rival_force: float = gary.gull.bump_force_on(game.player)
	game._rival_mugging()
	check.call(game.player.state == BeachGull.State.STUNNED and is_equal_approx(absf(game.player.velocity.x), launch * rival_force), "a full-speed rival mug stuns the player by the rival's weight")
	game.player.state = BeachGull.State.GLIDE
	game.player.invulnerable = 0.0
	game.player.velocity = Vector2.ZERO
	game.player.digestion.collect("hotdog")
	gary.gull.dive_speed = slow
	gary.leave = 0.0 # the first grab left Gary running
	gary.gull.state = BeachGull.State.STRIKE
	game._rival_mugging()
	check.call(game.player.state != BeachGull.State.STUNNED and game.player.digestion.snacks.is_empty(), "a slow rival mug still takes the snack without stunning the player")
	gary.gull.state = BeachGull.State.GROUNDED
	game.player.digestion.snacks.clear()

	# Boss shove of the player (the player is a black-back).
	game.player.shoves = true
	var food_target: BeachTarget
	for target: BeachTarget in game.spawner.targets:
		if target.food:
			food_target = target
			break
	var food: Vector2 = food_target.food_position()
	gary.target = food_target
	gary.gull.state = BeachGull.State.STRIKE
	gary.gull.position = food
	gary.gull.direction = Vector2.ZERO
	gary.gull.dive_speed = full
	game.player.state = BeachGull.State.STRIKE
	game.player.direction = Vector2.ZERO
	game.player.position = food
	game.player.dive_speed = slow
	BeachBoss.shove_player(game)
	check.call(gary.gull.state != BeachGull.State.STUNNED, "a slow black-back dive does not shove a rival")
	game.player.dive_speed = full
	BeachBoss.shove_player(game)
	check.call(gary.gull.state == BeachGull.State.STUNNED, "a full-speed black-back dive shoves a rival off the food")
	gary.gull.state = BeachGull.State.GROUNDED
	game.player.state = BeachGull.State.GROUNDED
	gary.target = null

	# Bev's shove of a contesting diver: a slow Bev does not bump.
	bev.target = food_target
	bev.gull.state = BeachGull.State.STRIKE
	bev.gull.dive_speed = slow
	bev.gull.position = food
	bev.gull.direction = Vector2.ZERO
	game.player.state = BeachGull.State.STRIKE
	game.player.direction = Vector2.ZERO
	game.player.position = food + Vector2(8.0, 0.0)
	game.player.dive_speed = full
	BeachBoss.shove(game)
	check.call(game.player.state != BeachGull.State.STUNNED, "a slow Bev does not shove a contesting diver")
	bev.gull.dive_speed = full
	BeachBoss.shove(game)
	check.call(game.player.state == BeachGull.State.STUNNED, "a full-speed Bev shoves a contesting diver")
	game.player.state = BeachGull.State.GROUNDED
	bev.gull.state = BeachGull.State.GROUNDED
	bev.target = null

	# Bev's frontal guard: a slow mug is not blocked (and goes through); a full-speed one bounces.
	bev.gull.facing = 1.0
	bev.gull.position = Vector2(400.0, 70.0)
	game.player.position = bev.gull.position + Vector2(18.0, 0.0)
	game.player.state = BeachGull.State.STRIKE
	game.player.invulnerable = 0.0
	game.player.previous_beak = bev.gull.position
	game.player.sweep_beak = bev.gull.position
	game.player.dive_speed = slow
	check.call(not BeachBoss.blocks_mug(game, bev, game.player), "a slow frontal mug is not blocked by Bev's guard")
	game.player.dive_speed = full
	check.call(BeachBoss.blocks_mug(game, bev, game.player) and game.player.state == BeachGull.State.STUNNED, "a full-speed frontal mug bounces off Bev's guard")
	game.player.state = BeachGull.State.GROUNDED
