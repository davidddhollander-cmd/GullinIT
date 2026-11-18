extends RefCounted
## Level 4 "Feeding Time": level order, the crumb lady's throw and swat, pigeons eating crumbs, and the mug scatter.
const DT: float = 1.0 / 20.0

static func _fresh(host: Node) -> BeachGame:
	host.main.start_level(4)
	var game: BeachGame = host.main.game
	game.set_physics_process(false)
	game.running = true
	game.intro = 0.0
	game.player.position = Vector2(800.0,100.0) # well clear of the lady and the flock
	game.player.state = BeachGull.State.GLIDE
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

static func run(host: Node, check: Callable) -> void:
	var ids: Array = Config.levels.map(func(level: Dictionary) -> int: return int(level.id))
	check.call(Config.levels.size() == 8 and ids == [1,2,3,4,5,6,7,8] and Config.levels[3].name == "Feeding Time" and Config.levels[4].name == "Water Fight" and Config.levels[7].name == "Sunset Showdown","eight levels in order with Feeding Time at 4 and the boss at 8")
	var level: Dictionary = Config.levels[3]
	check.call(level.rivals.is_empty() and level.crabs.enabled and not bool(level.scraps) and level.twist.tip.text == "MUG THE PIGEONS, NICK THEIR CRUMBS!" and int(level.stars[0]) == 200 and int(level.time_limit) == 120,"Feeding Time has no rivals, crabs on, no fixed scrap row, its twist tip and 200/400/550 stars")
	var bins: int = level.props.filter(func(p: Dictionary) -> bool: return p.type == "bin").size()
	check.call(bins >= 3 and bins <= 4 and level.props.any(func(p: Dictionary) -> bool: return p.type == "wheelie_bin"),"Feeding Time has 3-4 bins and a wheelie bin")
	var game: BeachGame = _fresh(host)
	var feeding: BeachFeeding = game.feeding
	var cfg: Dictionary = feeding.cfg
	check.call(feeding != null and game.scraps.crumbs.is_empty() and feeding.pigeons.size() == int(cfg.flock) and game.pilots.is_empty(),"level 4 starts with the lady, a flock and no fixed ground crumbs")
	check.call(feeding.pigeons[0].art_id != feeding.pigeons[1].art_id and feeding.pigeons[0].art_id == feeding.pigeons[2].art_id,"the flock alternates the two pigeon sheets")
	check.call(feeding.lady.sprite is AnimatedSprite2D and feeding.lady.get_children().size() == 1 and Config.sprites.crumb_lady.file.ends_with("crumb-lady-v2-sheet.png") and Config.sprites.pigeon_a.file.ends_with("pigeon-v1-sheet.png") and Config.sprites.pigeon_b.file.ends_with("pigeon-v2-sheet.png"),"the lady and pigeons are the supplied sheets only")
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
	check.call(game.quests.quests[0].progress == 1,"eating a thrown crumb counts for EAT 15 THROWN CRUMBS")

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
	for i: int in int(10.0/DT):
		_step(game,DT)
		pecked = pecked or (pigeon.state == BeachPigeon.State.PECK and pigeon.sprite.animation == &"peck")
		if bool(peck.get("gone",false)):
			break
	game.scraps.tick(0.0,game.player)
	check.call(pecked and bool(peck.get("gone",false)) and not game.scraps.crumbs.has(peck),"a pigeon walks to a thrown crumb, pecks it and eats it")
	check.call(float(cfg.pigeon_speed) < float(Config.tuning.flight.max_speed)*0.5,"pigeons walk slower than the gull flies")
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
	check.call(hit.state == BeachPigeon.State.FLEE and near.state == BeachPigeon.State.FLEE and far.state != BeachPigeon.State.FLEE,"a mug scatters the pigeon and its neighbours within 40 px")
	check.call(game.quests.quests[1].progress == progress+1,"a scatter reports pigeons_scattered to the quest")
	feeding._check_scatter()
	check.call(game.quests.quests[1].progress == progress+1 and not hit.grounded(),"a pigeon in the air cannot be mugged again")
	# Airborne pigeons ignore crumbs and are gone for the return delay.
	var lure: Dictionary = _land(game,hit.position.x)
	_step(game,0.5)
	check.call(not [hit.get_instance_id(),near.get_instance_id()].has(lure.get("claim",-1)) and not bool(lure.get("gone",false)),"a pigeon in the air cannot eat crumbs")
	_reset(game)
	gull.state = BeachGull.State.GLIDE
	gull.position = Vector2(800.0,100.0)
	var wingbeat: bool = hit.sprite.animation == &"wingbeat"
	var away: bool = false
	var returned_at: float = -1.0
	var landed_at: float = -1.0
	var t: float = 0.5 # the lure step above
	while t < float(cfg.return_delay)+12.0 and landed_at < 0.0:
		t += DT
		_step(game,DT)
		away = away or (hit.state == BeachPigeon.State.AWAY and not hit.visible)
		if returned_at < 0.0 and hit.state == BeachPigeon.State.RETURN:
			returned_at = t
		if hit.state in [BeachPigeon.State.LAND,BeachPigeon.State.IDLE] and returned_at >= 0.0:
			landed_at = t
	check.call(wingbeat and away,"scattered pigeons take off on the wingbeat row and leave the screen")
	check.call(returned_at >= float(cfg.return_delay)-0.1 and returned_at <= float(cfg.return_delay)+1.0,"the flock glides back after about %d s (%.1f s)" % [int(cfg.return_delay),returned_at])
	check.call(landed_at > returned_at and hit.visible and is_equal_approx(hit.position.y,float(Config.tuning.world.ground)) and absf(hit.position.x-feeding.lady.position.x) <= float(cfg.wander)+float(cfg.walk_speed)*20.0,"it lands near the lady and is a ground pigeon again")

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
	host.main.clear_game()
	await host.settle()

