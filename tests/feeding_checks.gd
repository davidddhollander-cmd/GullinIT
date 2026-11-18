extends RefCounted
## Level 4 "Feeding Time": level order, the crumb lady's throw and swat, pigeons eating crumbs, and the mug scatter.
const DT: float = 1.0 / 20.0
static var _ok: Callable

static func _fresh(host: Node) -> BeachGame:
	host.main.start_level(4)
	var game: BeachGame = host.main.game
	game.set_physics_process(false)
	game.running = true
	game.intro = 0.0
	game.player.position = Vector2(800.0,100.0) # well clear of the lady and the flock
	game.player.state = BeachGull.State.GLIDE
	game.feeding.eat_goal = 99 # aggro and bin pecking have their own checks below
	game.feeding.cfg.bin_chance = 0.0
	return game

static func _step(game: BeachGame, seconds: float) -> void:
	for i: int in int(seconds/DT):
		game.feeding.tick(DT)
		game.scraps.tick(DT,game.player)

static func _reset(game: BeachGame) -> void:
	game.scraps.crumbs.clear()
	for pigeon: BeachPigeon in game.feeding.pigeons:
		if pigeon.grounded():
			pigeon.crumb = {}
			pigeon._idle()

static func _land(game: BeachGame, x: float) -> Dictionary:
	var crumb: Dictionary = {"x":x,"wait":0.0,"food_id":"crumbs","thrown":true}
	game.scraps.crumbs.append(crumb)
	return crumb

static func _park_pigeons(game: BeachGame) -> void:
	for pigeon: BeachPigeon in game.feeding.pigeons:
		pigeon.position.x = 40.0 # a long walk from anything the test drops
		pigeon.dest = 40.0
		pigeon.home = 40.0 # idle wandering stays over there too

static func run(host: Node, check: Callable) -> void:
	_ok = check
	var ids: Array = Config.levels.map(func(level: Dictionary) -> int: return int(level.id))
	check.call(Config.levels.size() == 8 and ids == [1,2,3,4,5,6,7,8] and Config.levels[3].name == "Feeding Time" and Config.levels[4].name == "Water Fight" and Config.levels[7].name == "Sunset Showdown","eight levels in order with Feeding Time at 4 and the boss at 8")
	var level: Dictionary = Config.levels[3]
	check.call(level.rivals.is_empty() and level.crabs.enabled and not bool(level.scraps) and level.twist.tip.text == "MUG THE PIGEONS, NICK THEIR CRUMBS!" and int(level.stars[0]) == 200 and int(level.time_limit) == 120,"Feeding Time has no rivals, crabs on, no fixed scrap row, its twist tip and a 200 pass mark")
	var bins: int = level.props.filter(func(p: Dictionary) -> bool: return p.type == "bin").size()
	check.call(bins >= 3 and bins <= 4 and level.props.any(func(p: Dictionary) -> bool: return p.type == "wheelie_bin"),"Feeding Time has 3-4 bins and a wheelie bin")
	var game: BeachGame = _fresh(host)
	var feeding: BeachFeeding = game.feeding
	var cfg: Dictionary = feeding.cfg
	var flock_total: int = cfg.flocks.reduce(func(sum: int, f: Dictionary) -> int: return sum+int(f.size),0)
	check.call(feeding != null and feeding.pigeons.size() == flock_total and cfg.flocks.size() == 2 and game.pilots.is_empty(),"level 4 starts with the lady, two flocks and no rivals")
	# More boardwalk, and crumbs on the floor from the start.
	var world: Dictionary = level.world
	check.call(float(world.promenade_start) <= 300.0 and float(world.width)-float(world.promenade_start) > float(world.width)*0.7 and level.zones[level.zones.size()-1].to == world.width,"most of Feeding Time is boardwalk (starts at %d of %d)" % [int(world.promenade_start),int(world.width)])
	check.call(cfg.seed_crumbs.size() >= 12 and cfg.seed_crumbs.size() <= 16 and game.scraps.crumbs.size() == cfg.seed_crumbs.size() and game.scraps.crumbs.all(func(c: Dictionary) -> bool: return c.thrown and c.food_id == "crumbs" and not c.has("fly")) and feeding.thrown_on_ground() == cfg.seed_crumbs.size() and int(cfg.crumb_cap) >= cfg.seed_crumbs.size()+int(cfg.fan[1]),"12-16 thrown-type crumbs are on the ground at the start and count toward the cap")
	# Each flock clusters at its own home, with the minimum gap, and the lady's patrol reaches both.
	var spread_ok: bool = true
	var gap_ok: bool = true
	for pigeon: BeachPigeon in feeding.pigeons:
		spread_ok = spread_ok and absf(pigeon.position.x-pigeon.home) <= float(cfg.wander)
		for other: BeachPigeon in feeding.pigeons:
			if other != pigeon and other.home == pigeon.home:
				gap_ok = gap_ok and absf(other.position.x-pigeon.position.x) >= float(cfg.min_gap)-0.01
	check.call(spread_ok and gap_ok and feeding.pigeons[0].home != feeding.pigeons[7].home and feeding.pigeons.filter(func(p: BeachPigeon) -> bool: return p.home == feeding.pigeons[0].home).size() == int(cfg.flocks[0].size),"two flocks of 4 cluster at their own homes at least %d px apart" % int(cfg.min_gap))
	check.call(float(cfg.lady.home[0]) <= float(cfg.flocks[0].x) and float(cfg.lady.home[1]) >= float(cfg.flocks[1].x),"the lady patrols past both flocks")
	game.scraps.crumbs.clear()
	feeding.lady.throw_timer = 99.0
	_step(game,20.0)
	var wander_ok: bool = true
	var wander_gap: bool = true
	for pigeon: BeachPigeon in feeding.pigeons:
		wander_ok = wander_ok and absf(pigeon.position.x-pigeon.home) <= float(cfg.wander)+1.0
	check.call(wander_ok,"idle pigeons wander around their own flock home, not the lady")
	for i: int in 40:
		for pigeon: BeachPigeon in feeding.pigeons:
			for other: BeachPigeon in feeding.pigeons:
				if other != pigeon and other.home == pigeon.home and pigeon.state == BeachPigeon.State.IDLE and other.state == BeachPigeon.State.IDLE and pigeon.resting and other.resting:
					wander_gap = wander_gap and absf(other.position.x-pigeon.position.x) >= float(cfg.min_gap)-0.01
		_step(game,0.5)
	check.call(wander_gap,"resting pigeons keep the minimum gap while wandering")
	feeding.lady.throw_timer = float(cfg.interval[0])
	check.call(feeding.pigeons[0].art_id != feeding.pigeons[1].art_id and feeding.pigeons[0].art_id == feeding.pigeons[2].art_id,"the flock alternates the two pigeon sheets")
	check.call(feeding.lady.sprite is AnimatedSprite2D and feeding.lady.get_children().size() == 1 and Config.sprites.crumb_lady.file.ends_with("crumb-lady-v2-steady-medium.png") and Config.sprites.pigeon_a.file.ends_with("pigeon-v1-light.png") and Config.sprites.pigeon_b.file.ends_with("pigeon-v2-steady-light.png"),"the lady and pigeons are the supplied sheets only")
	# The sheets' grids line up with the sprite definitions.
	for id: String in ["crumb_lady","pigeon_a","pigeon_b"]:
		var art: Dictionary = Config.sprites[id]
		var texture: Texture2D = load(art.file)
		check.call(texture.get_width() % int(art.frame_w) == 0 and texture.get_height() % int(art.frame_h) == 0,"%s sheet size is a whole grid of its frames" % id)

	# The lady stops and throws within the data's interval, and the fan lands ahead of her.
	var thrown_at: Array[float] = []
	var release_x: Array[float] = []
	var release_facing: Array[float] = []
	var clock: Array[float] = [0.0]
	feeding.lady.threw.connect(func(_from: Vector2, facing: float) -> void:
		thrown_at.append(clock[0])
		release_x.append(feeding.lady.position.x)
		release_facing.append(facing)
	)
	_park_pigeons(game)
	var walked_from: float = feeding.lady.position.x
	var seen_walk: bool = false
	while thrown_at.is_empty() and clock[0] < 12.0:
		clock[0] += DT
		_step(game,DT)
		seen_walk = seen_walk or (feeding.lady.state == CrumbLady.State.WALK and feeding.lady.sprite.animation == &"walk")
	var fan: Array = game.scraps.crumbs.filter(func(c: Dictionary) -> bool: return c.get("thrown",false))
	check.call(seen_walk and not is_equal_approx(release_x[0],walked_from),"the lady walks her patrol before she throws")
	check.call(not thrown_at.is_empty() and thrown_at[0] <= float(cfg.interval[1])+1.0 and thrown_at[0] >= float(cfg.interval[0]),"the lady throws once the 8-10 s interval is up (%.1f s)" % clock[0])
	var in_arc: bool = true
	for crumb: Dictionary in fan:
		var ahead: float = (float(crumb.x)-release_x[0])*release_facing[0]
		in_arc = in_arc and ahead >= float(cfg.reach[0])-0.01 and ahead <= float(cfg.reach[1])+0.01
	check.call(fan.size() >= int(cfg.fan[0]) and fan.size() <= int(cfg.fan[1]) and in_arc,"the throw adds a 5-8 crumb fan landing 15-50 px ahead (%d crumbs)" % fan.size())
	check.call(feeding.lady.sprite.animation == &"throw" and absf(feeding.lady.position.x-release_x[0]) < 0.01,"she stands still on the throw row while she throws")
	# Crumbs spend a moment in the air, then wait on the sand; the gull eats them for crumbs points and they never return.
	check.call(fan.all(func(c: Dictionary) -> bool: return float(c.get("fly",0.0)) > 0.0),"thrown crumbs start in the air")
	_step(game,float(cfg.fly_time)+0.1)
	check.call(fan.all(func(c: Dictionary) -> bool: return float(c.fly) <= 0.0),"thrown crumbs land after their flight")
	for i: int in fan.size():
		fan[i].x = 600.0+float(i)*30.0 # spread out so the gull eats exactly one
	var target: Dictionary = fan[0]
	var before: int = game.score.points
	var gull: BeachGull = game.player
	gull.state = BeachGull.State.GROUNDED
	gull.position = Vector2(float(target.x)-gull.facing*float(Config.tuning.dive.beak_offset),float(Config.tuning.world.ground))
	feeding.lady.swat_cooldown = 99.0 # keep the lady out of this check
	game.scraps.tick(0.0,gull)
	host.eat_pending(game)
	var count: int = game.scraps.crumbs.size()
	check.call(game.score.points-before == int(Config.foods.crumbs.points) and not game.scraps.crumbs.has(target) and count == fan.size()-1,"the gull eats a thrown crumb for crumbs points and it is removed")
	game.scraps.tick(float(Config.tuning.world.scrap_respawn)*3.0,gull)
	check.call(game.scraps.crumbs.size() == count,"eaten thrown crumbs never respawn")
	gull.state = BeachGull.State.GLIDE
	gull.position = Vector2(800.0,100.0)
	check.call(game.quests.quests[0].progress == 1,"eating a thrown crumb counts for EAT 8 THROWN CRUMBS")

	# The ground crumb cap is respected.
	_reset(game)
	for i: int in int(cfg.crumb_cap)-2:
		_land(game,100.0+float(i))
	feeding._throw(Vector2(300.0,140.0),1.0)
	check.call(feeding.thrown_on_ground() == int(cfg.crumb_cap),"thrown crumbs are capped at %d on the ground" % int(cfg.crumb_cap))
	_reset(game)

	# A pigeon walks to a fresh crumb, pecks it and removes it.
	var pigeon: BeachPigeon = feeding.pigeons[0]
	_park_pigeons(game)
	pigeon.position.x = 300.0
	var peck: Dictionary = _land(game,330.0)
	var pecked: bool = false
	var downs: int = 0
	var was_down: bool = false
	for i: int in int(10.0/DT):
		_step(game,DT)
		var down: bool = pigeon.state == BeachPigeon.State.PECK and pigeon.sprite.animation == &"peck"
		pecked = pecked or down
		downs += 1 if down and not was_down else 0
		was_down = down
		if bool(peck.get("gone",false)):
			break
	check.call(downs == int(cfg.pecks) and int(cfg.pecks) == 3,"a pigeon needs 3 pecks to eat a crumb (%d seen)" % downs)
	game.scraps.tick(0.0,game.player)
	check.call(pecked and bool(peck.get("gone",false)) and not game.scraps.crumbs.has(peck),"a pigeon walks to a thrown crumb, pecks it and eats it")
	check.call(float(cfg.pigeon_speed) < float(Config.tuning.flight.max_speed)*0.5,"pigeons walk slower than the gull flies")
	# The gull can steal the crumb between pecks, and the pigeon gives up.
	_reset(game)
	_park_pigeons(game)
	var thief: BeachPigeon = feeding.pigeons[0]
	thief.position.x = 500.0
	var stolen: Dictionary = _land(game,500.0)
	thief.crumb = feeding.claim_crumb(thief)
	thief.state = BeachPigeon.State.SEEK
	_step(game,0.15)
	check.call(thief.state == BeachPigeon.State.PECK and not bool(stolen.get("gone",false)),"the crumb stays on the sand while the pigeon is mid-peck")
	gull.state = BeachGull.State.GROUNDED
	gull.position = Vector2(500.0-gull.facing*float(Config.tuning.dive.beak_offset),float(Config.tuning.world.ground))
	game.scraps.tick(0.0,gull)
	gull.state = BeachGull.State.GLIDE
	gull.position = Vector2(800.0,100.0)
	_step(game,0.1)
	check.call(bool(stolen.get("gone",false)) and thief.state != BeachPigeon.State.PECK,"the gull taking the crumb mid-peck stops the pigeon")
	host.eat_pending(game)
	# Two pigeons never share a crumb: the nearer one claims it.
	_park_pigeons(game)
	feeding.pigeons[0].position.x = 300.0
	feeding.pigeons[1].position.x = 320.0
	var shared: Dictionary = _land(game,340.0)
	var first: Dictionary = feeding.claim_crumb(feeding.pigeons[0])
	var second: Dictionary = feeding.claim_crumb(feeding.pigeons[1])
	check.call(not first.is_empty() and second.is_empty(),"a claimed crumb is not offered to a second pigeon")
	_reset(game)

	# Mugging: a dive through a grounded pigeon scatters it and the pigeons within 40 px, not the far one.
	var hit: BeachPigeon = feeding.pigeons[0]
	var near: BeachPigeon = feeding.pigeons[1]
	var far: BeachPigeon = feeding.pigeons[2]
	hit.position.x = 400.0
	near.position.x = 400.0+float(cfg.scatter_radius)-6.0
	far.position.x = 400.0+float(cfg.scatter_radius)+30.0
	for p: BeachPigeon in feeding.pigeons.slice(3):
		p.position.x = 40.0
	gull.state = BeachGull.State.STRIKE
	gull.position = Vector2(380.0,float(Config.tuning.world.ground)-12.0)
	gull.previous_beak = hit.position+Vector2(-12.0,-14.0)
	gull.sweep_beak = hit.position+Vector2(0.0,-4.0)
	var progress: int = game.quests.quests[1].progress
	feeding._check_scatter()
	check.call(hit.state == BeachPigeon.State.TUMBLE and near.state == BeachPigeon.State.FLEE and far.state != BeachPigeon.State.FLEE,"a dive bumps the pigeon into a crouch and scatters its neighbours within 40 px")
	# The bumped pigeon arcs away, spins, bounces once, slides and crouches.
	var ground: float = float(Config.tuning.world.ground)
	var peak: float = ground
	var spun: bool = false
	var bounced: bool = false
	var crouched: bool = false
	var hittable: bool = false
	for i: int in int(float(cfg.bump_stun)/DT)+4:
		hit.tick(DT)
		peak = minf(peak,hit.position.y)
		spun = spun or absf(hit.sprite.rotation) > 0.3
		bounced = bounced or hit.tumble_bounced
		crouched = crouched or (hit.state == BeachPigeon.State.STUNNED and hit.sprite.animation == &"stunned")
		hittable = hittable or (hit.grounded() and hit.state != BeachPigeon.State.IDLE)
	check.call(hit.position.x > 400.0+10.0 and peak < ground-8.0 and spun and crouched and is_zero_approx(hit.sprite.rotation) and is_equal_approx(hit.position.y,ground),"a bumped pigeon arcs away, spins, lands and crouches stunned")
	check.call(bounced and not hittable,"it bounces on the sand and cannot be mugged or eat while it tumbles")
	hit.state = BeachPigeon.State.STUNNED # back into the crouch for the rest of the checks
	hit.timer = float(cfg.bump_stun)
	hit.position.x = 400.0
	check.call(gull.state == BeachGull.State.STUNNED and gull.timer > 0.0 and gull.timer <= float(cfg.pigeon_stun)*gull.stun_mult+0.01,"the bump stuns the gull briefly (%.2f s)" % gull.timer)
	check.call(game.quests.quests[1].progress == progress+1,"a scatter reports pigeons_scattered to the quest")
	gull.state = BeachGull.State.STRIKE
	feeding._check_scatter()
	check.call(game.quests.quests[1].progress == progress+1 and not hit.grounded() and hit.state == BeachPigeon.State.STUNNED,"a stunned pigeon cannot be bumped again")
	gull.state = BeachGull.State.GLIDE
	_step(game,float(cfg.bump_stun)+0.2)
	check.call(hit.state != BeachPigeon.State.STUNNED and hit.grounded(),"the bumped pigeon goes back to normal after about %.1f s" % float(cfg.bump_stun))
	# Bump-back stun scales with the species stun multiplier: black-back shortest, kittiwake longest.
	var stuns: Dictionary = {}
	for species: String in ["great-black-backed","herring","kittiwake"]:
		gull.state = BeachGull.State.STRIKE
		gull.stun_mult = float(Config.species.species[species].stun)
		gull.invulnerable = 0.0
		hit.state = BeachPigeon.State.IDLE
		hit.position.x = 400.0
		gull.previous_beak = hit.position+Vector2(-12.0,-14.0)
		gull.sweep_beak = hit.position+Vector2(0.0,-4.0)
		feeding._check_scatter()
		stuns[species] = gull.timer
	gull.stun_mult = 1.0
	check.call(stuns["great-black-backed"] < stuns["herring"] and stuns["herring"] < stuns["kittiwake"],"bump-back stun is shortest for the black-back and longest for the kittiwake")
	hit.state = BeachPigeon.State.IDLE
	game.quests.quests[1].progress = progress+1
	gull.state = BeachGull.State.GLIDE
	gull.position = Vector2(800.0,100.0)
	near.state = BeachPigeon.State.FLEE
	near.timer = float(cfg.return_delay)
	# Airborne pigeons ignore crumbs and are gone for the return delay.
	var lure: Dictionary = _land(game,near.position.x)
	_step(game,0.5)
	check.call(near.get_instance_id() != lure.get("claim",-1) and not bool(lure.get("gone",false)),"a pigeon in the air cannot eat crumbs")
	_reset(game)
	gull.state = BeachGull.State.GLIDE
	gull.position = Vector2(800.0,100.0)
	var wingbeat: bool = near.sprite.animation == &"wingbeat"
	var away: bool = false
	var returned_at: float = -1.0
	var landed_at: float = -1.0
	var t: float = 0.5 # the lure step above
	while t < float(cfg.return_delay)+12.0 and landed_at < 0.0:
		t += DT
		_step(game,DT)
		away = away or (near.state == BeachPigeon.State.AWAY and not near.visible)
		if returned_at < 0.0 and near.state == BeachPigeon.State.RETURN:
			returned_at = t
		if near.state in [BeachPigeon.State.LAND,BeachPigeon.State.IDLE] and returned_at >= 0.0:
			landed_at = t
	check.call(wingbeat and away,"scattered pigeons take off on the wingbeat row and leave the screen")
	check.call(returned_at >= float(cfg.return_delay)-0.1 and returned_at <= float(cfg.return_delay)+1.0,"the flock glides back after about %d s (%.1f s)" % [int(cfg.return_delay),returned_at])
	check.call(landed_at > returned_at and near.visible and is_equal_approx(near.position.y,float(Config.tuning.world.ground)) and absf(near.position.x-near.home) <= float(cfg.wander),"it lands back at its flock home and is a ground pigeon again")


	# Shakedown: grounded pigeons within the scare radius fly off and return; far ones stay.
	_reset(game)
	game.player.position = Vector2(600.0,100.0)
	var close: BeachPigeon = feeding.pigeons[4]
	var distant: BeachPigeon = feeding.pigeons[5]
	var radius: float = float(CrowdPanic.settings().panic_radius)
	close.position.x = 600.0+radius-10.0
	distant.position.x = 600.0+radius+30.0
	feeding.scare_pigeons(600.0,radius)
	check.call(close.state == BeachPigeon.State.FLEE and distant.state != BeachPigeon.State.FLEE,"Shakedown scares pigeons within the scare radius only")
	var back: bool = false
	for i: int in int((float(cfg.return_delay)+12.0)/DT):
		_step(game,DT)
		back = back or close.state == BeachPigeon.State.RETURN
	check.call(back and close.grounded(),"scared pigeons come back after the return delay")
	# The lady swats a gull that lands beside her, and not while she throws; there is a cooldown.
	_reset(game)
	game.player.position = Vector2(800.0,100.0)
	game.player.state = BeachGull.State.GLIDE
	var lady: CrumbLady = feeding.lady
	lady.swat_cooldown = 0.0
	lady.throw_timer = 99.0
	lady.state = CrumbLady.State.WALK
	gull.state = BeachGull.State.GROUNDED
	gull.position = Vector2(lady.position.x+float(cfg.swat_range)-4.0,float(Config.tuning.world.ground))
	var swatted: Array[int] = [0]
	lady.swatted.connect(func(_g: BeachGull) -> void: swatted[0] += 1)
	var angry: bool = false
	for i: int in int(1.5/DT):
		feeding.tick(DT)
		angry = angry or (lady.state == CrumbLady.State.SWAT and lady.sprite.animation == &"swat")
		if gull.state == BeachGull.State.STUNNED:
			break
	check.call(angry and swatted[0] == 1 and gull.state == BeachGull.State.STUNNED,"a gull landing beside the lady gets the angry swat row and is stunned")
	check.call(lady.swat_cooldown > 0.0,"the swat starts a cooldown")
	# Cooldown: standing there again does not trigger a second swat.
	gull.state = BeachGull.State.GROUNDED
	gull.position = Vector2(lady.position.x+4.0,float(Config.tuning.world.ground))
	for i: int in int(1.5/DT):
		feeding.tick(DT)
	check.call(swatted[0] == 1 and gull.state == BeachGull.State.GROUNDED,"the lady does not swat again during the cooldown")
	# Never mid-throw.
	gull.position.x = lady.position.x+4.0
	lady.swat_cooldown = 0.0
	lady.state = CrumbLady.State.THROW
	lady.clip_time = 0.0
	lady.acted = true
	feeding.tick(DT)
	check.call(lady.state == CrumbLady.State.THROW and swatted[0] == 1,"she does not swat while she is throwing")
	# A gull in the air above her is left alone.
	lady.state = CrumbLady.State.WALK
	gull.state = BeachGull.State.GLIDE
	gull.position = Vector2(lady.position.x,100.0)
	for i: int in 20:
		feeding.tick(DT)
	check.call(swatted[0] == 1 and lady.state != CrumbLady.State.SWAT,"a gull flying over the lady is not swatted")
	# Real game loop: the lady keeps throwing and the flock keeps eating while the gull idles overhead.
	_reset(game)
	lady.swat_cooldown = 0.0
	lady.state = CrumbLady.State.WALK
	lady.throw_timer = 1.0
	var throws: Array[int] = [0]
	lady.threw.connect(func(_from: Vector2, _facing: float) -> void: throws[0] += 1)
	for i: int in 60*25:
		gull.position = Vector2(800.0,60.0)
		gull.velocity = Vector2.ZERO
		game._physics_process(1.0/60.0)
	check.call(throws[0] >= 2 and game.feeding.thrown_on_ground() <= int(cfg.crumb_cap),"the real game loop keeps the lady throwing and the flock eating (%d throws)" % throws[0])
	_pass3(game)
	host.main.clear_game()
	await host.settle()

## Pass 3: brash from bumps, aggro wave, bin pecking. `check` is the harness's; results go through the module-level `_ok`.
static func _pass3(game: BeachGame) -> void:
	var feeding: BeachFeeding = game.feeding
	var cfg: Dictionary = feeding.cfg
	var gull: BeachGull = game.player
	var ground: float = float(Config.tuning.world.ground)
	_reset(game)
	_park_pigeons(game)
	gull.state = BeachGull.State.GLIDE
	gull.invulnerable = 0.0
	gull.stun_mult = 1.0
	_ok.call(float(Config.tuning.brash.pigeon_bump) > 0.0 and float(Config.tuning.brash.pigeon_bump) < float(Config.tuning.brash.dog_bump),"pigeon_bump brash is below a dog bump")
	var pigeon: BeachPigeon = feeding.pigeons[0]
	pigeon.position = Vector2(400.0,ground)
	pigeon._idle()
	gull.state = BeachGull.State.STRIKE
	gull.position = Vector2(380.0,ground-12.0)
	gull.previous_beak = pigeon.position+Vector2(-12.0,-14.0)
	gull.sweep_beak = pigeon.position+Vector2(0.0,-4.0)
	game.brash.meter = 0.5
	var meter: float = game.brash.meter
	feeding._check_scatter()
	var filled: float = game.brash.meter-meter
	var fill: Dictionary = game.brash.power().get("fill",{})
	var expect: float = float(Config.tuning.brash.pigeon_bump)*float(fill.get("pigeon_bump",1.0))+float(Config.tuning.brash.stun)*float(fill.get("stun",1.0)) # the bump also stuns the gull, which costs brash
	_ok.call(game.brash.power().is_empty() or is_equal_approx(filled,expect),"bumping a pigeon fills the brash meter by pigeon_bump (%.2f)" % filled)
	_reset(game)
	pigeon.sprite.rotation = 0.0
	gull.invulnerable = 0.0
	gull.state = BeachGull.State.GLIDE
	gull.position = Vector2(800.0,100.0)
	# Aggro: eating 2-3 thrown crumbs sends the nearest grounded pigeons (at most aggro_count) at the gull.
	_park_pigeons(game)
	for i: int in 3:
		var p: BeachPigeon = feeding.pigeons[i]
		p.position = Vector2(740.0+float(i)*8.0,ground)
		p._idle()
	feeding.eaten = 0
	feeding.eat_goal = 2
	feeding.player_ate_crumb()
	feeding.tick(DT)
	_ok.call(not feeding.aggro_active(),"one eaten crumb is not enough to annoy the pigeons")
	feeding.player_ate_crumb()
	gull.state = BeachGull.State.STUNNED
	feeding.tick(DT)
	_ok.call(not feeding.aggro_active(),"no aggro while the gull is stunned")
	gull.state = BeachGull.State.GLIDE
	feeding.tick(DT)
	var angry: Array = feeding.pigeons.filter(func(p: BeachPigeon) -> bool: return p.state == BeachPigeon.State.AGGRO)
	_ok.call(angry.size() == int(cfg.aggro_count) and feeding.eaten == 0 and feeding.eat_goal >= int(cfg.aggro_eat[0]) and feeding.eat_goal <= int(cfg.aggro_eat[1]),"the threshold sends %d pigeons into aggro and resets the count" % angry.size())
	_ok.call(angry[0].sprite.animation == &"wingbeat" and not angry[0].grounded(),"an aggro pigeon is airborne on the wingbeat row")
	feeding.eaten = 99
	var before_wave: int = feeding.pigeons.filter(func(p: BeachPigeon) -> bool: return p.state == BeachPigeon.State.AGGRO).size()
	feeding.tick(DT)
	_ok.call(feeding.pigeons.filter(func(p: BeachPigeon) -> bool: return p.state == BeachPigeon.State.AGGRO).size() == before_wave,"only one aggro wave at a time")
	feeding.eaten = 0
	# It flies at the gull and bumps it, then goes home.
	gull.position = Vector2(700.0,ground-20.0)
	gull.velocity = Vector2.ZERO
	var bumper: BeachPigeon = angry[0]
	var bumped: bool = false
	for i: int in int(float(cfg.aggro_time)/DT):
		feeding.tick(DT)
		if gull.state == BeachGull.State.STUNNED:
			bumped = true
			break
	_ok.call(bumped and gull.timer <= float(cfg.aggro_stun)*gull.stun_mult+0.01 and gull.timer > 0.0 and bumper.state == BeachPigeon.State.RETURN,"an aggro pigeon bumps the gull (stun %.2f s) and heads home" % gull.timer)
	var timers: Dictionary = {}
	for species: String in ["great-black-backed","herring","kittiwake"]:
		gull.state = BeachGull.State.GLIDE
		gull.stun_mult = float(Config.species.species[species].stun)
		gull.invulnerable = 0.0
		bumper.position = gull.position
		bumper.annoy()
		bumper.tick(DT)
		timers[species] = gull.timer
	gull.stun_mult = 1.0
	_ok.call(timers["great-black-backed"] < timers["herring"] and timers["herring"] < timers["kittiwake"],"the pigeon bump is shortest for the black-back and longest for the kittiwake")
	for i: int in int(20.0/DT):
		feeding.tick(DT)
	_ok.call(bumper.grounded() and is_equal_approx(bumper.position.y,ground),"the pigeon lands back at its home after the bump")
	# Missing: the gull gets away, or the time runs out; the pigeon goes home.
	gull.state = BeachGull.State.GLIDE
	gull.invulnerable = 0.0
	bumper.position = Vector2(740.0,ground)
	bumper.annoy()
	gull.position = Vector2(740.0+float(cfg.aggro_range)+60.0,40.0)
	bumper.tick(DT)
	_ok.call(bumper.state == BeachPigeon.State.RETURN and gull.state != BeachGull.State.STUNNED,"a pigeon gives up when the gull gets away")
	bumper.position = Vector2(740.0,ground)
	bumper.annoy()
	bumper.timer = 0.0
	gull.position = Vector2(740.0,ground-100.0)
	bumper.tick(DT)
	_ok.call(bumper.state == BeachPigeon.State.RETURN,"aggro times out and the pigeon goes home")
	# Shakedown cancels aggro: those pigeons scatter instead.
	gull.position = Vector2(740.0,ground-20.0)
	bumper.position = Vector2(744.0,ground-30.0)
	bumper.annoy()
	feeding.scare_pigeons(gull.position.x,60.0)
	_ok.call(bumper.state == BeachPigeon.State.FLEE,"Shakedown scatters aggro pigeons instead")
	for p: BeachPigeon in feeding.pigeons:
		p.sprite.rotation = 0.0
		p.position = Vector2(40.0,ground)
		p._idle()
	gull.state = BeachGull.State.GLIDE
	gull.position = Vector2(800.0,100.0)
	# Bins: a pigeon with no crumbs walks to a nearby ground bin, pecks it open, and the spill is left for the gull.
	var bin: Dictionary = game.stash_raids.bins.filter(func(b: Dictionary) -> bool: return not b.requires_top_landing and absf(float(b.x)-380.0) <= float(cfg.bin_range))[0]
	var picker: BeachPigeon = feeding.pigeons[0]
	var other: BeachPigeon = feeding.pigeons[1]
	picker.home = 380.0
	other.home = 380.0
	picker.position = Vector2(370.0,ground)
	picker.resting = true
	picker.timer = 0.0
	picker.state = BeachPigeon.State.IDLE
	cfg.bin_chance = 1.0
	game.scraps.crumbs.clear()
	var items_before: int = game.stash_raids.items.size()
	var remaining: int = int(bin.remaining)
	picker.tick(DT)
	_ok.call(picker.state == BeachPigeon.State.BIN_WALK and bin.has("pigeon"),"a pigeon with no crumbs claims a nearby ground bin")
	_ok.call(game.stash_raids.bins.all(func(b: Dictionary) -> bool: return b.has("pigeon") == is_same(b,bin)) and feeding.claim_bin(other).get("x",-1.0) != float(bin.x),"at most one pigeon per bin")
	_ok.call(feeding.pigeons.all(func(p: BeachPigeon) -> bool: return p.bin.is_empty() or not p.bin.requires_top_landing),"wheelie bins that need a top landing are skipped")
	var pecks: int = 0
	var was_peck: bool = false
	for i: int in int(30.0/DT):
		picker.tick(DT)
		var down: bool = picker.state == BeachPigeon.State.BIN_PECK and picker.sprite.animation == &"peck"
		pecks += 1 if down and not was_peck else 0
		was_peck = down
		if int(bin.remaining) < remaining:
			break
	_ok.call(int(bin.remaining) < remaining and game.stash_raids.items.size() > items_before and pecks == int(Config.tuning.world.bin_pecks),"the pigeon pecks the bin %d times and the last peck spills it (%d pecks)" % [int(Config.tuning.world.bin_pecks),pecks])
	_ok.call(not bin.has("pigeon") and picker.state == BeachPigeon.State.IDLE and game.stash_raids.items.size() > items_before,"the pigeon is free again and leaves the spill for the gull")
	cfg.bin_chance = 0.0
