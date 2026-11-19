class_name BeachFeeding
extends Node
## Level 4 "Feeding Time": owns the crumb lady, the pigeon flock, the thrown crumbs (BeachScraps entries
## flagged "thrown") and the gull-mugs-pigeon scatter. Everything is tuned by the level's `feeding` block.
var game: BeachGame
var cfg: Dictionary
var lady: CrumbLady
var pigeons: Array[BeachPigeon] = []
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var eaten: int = 0 # thrown crumbs the player has eaten since the last aggro wave
var eat_goal: int = 3

func setup(owner_game: BeachGame, actors: Node2D) -> void:
	game = owner_game
	cfg = game.level.feeding
	rng.seed = int(game.level.seed)+13
	eat_goal = rng.randi_range(int(cfg.aggro_eat[0]),int(cfg.aggro_eat[1]))
	lady = CrumbLady.new()
	actors.add_child(lady)
	lady.setup(cfg,int(game.level.seed)+11)
	lady.threw.connect(_throw)
	lady.swatted.connect(_swat)
	for flock: Dictionary in cfg.flocks:
		for i: int in int(flock.size):
			var pigeon: BeachPigeon = BeachPigeon.new()
			actors.add_child(pigeon)
			pigeon.setup(self,"pigeon_a" if pigeons.size()%2 == 0 else "pigeon_b",float(flock.x),int(game.level.seed)+17+pigeons.size())
			pigeons.append(pigeon)
	for x: float in cfg.seed_crumbs: # crumbs already on the sand at the start; thrown-type, so they never respawn
		game.scraps.crumbs.append({"x":x,"wait":0.0,"food_id":"crumbs","thrown":true})

## A spot within `wander` of the pigeon's home that keeps `min_gap` from every other pigeon's spot (best of a few tries).
func free_spot(pigeon: BeachPigeon) -> float:
	var best: float = pigeon.home
	var best_gap: float = -1.0
	var w: float = float(cfg.wander)
	for i: int in 48: # a few random tries for variety, then an even sweep (~2.5 px steps) so a crowded flock still finds any free slot
		var x: float = pigeon.home+(pigeon.rng.randf_range(-w,w) if i < 8 else float(i-8)*2.0*w/39.0-w)
		var gap: float = 1e9
		for other: BeachPigeon in pigeons:
			if other != pigeon:
				for at: float in other.spots():
					gap = minf(gap,absf(at-x))
		if gap >= float(cfg.min_gap):
			return x
		if gap > best_gap:
			best = x
			best_gap = gap
	return best

var coo_wait: float = 1.5

## Now and then a grounded pigeon on screen coos.
func _coo(step: float) -> void:
	coo_wait -= step
	if coo_wait > 0.0:
		return
	var s: Dictionary = cfg.sfx
	coo_wait = randf_range(float(s.coo_gap[0]),float(s.coo_gap[1]))
	var seen: Array[BeachPigeon] = pigeons.filter(func(p: BeachPigeon) -> bool: return p.grounded() and absf(p.position.x-game.camera_x) < 160.0)
	if not seen.is_empty():
		Audio.play(Audio.pick(["pigeon_coo_1","pigeon_coo_2","pigeon_coo_3"]),randf_range(0.92,1.08),float(s.coo_db))

func tick(step: float) -> void:
	lady.tick(step,game.player)
	lady.z_index = game.spawner.depth_z(lady.position,2)
	_check_scatter()
	if eaten >= eat_goal:
		_try_aggro()
	for pigeon: BeachPigeon in pigeons:
		pigeon.tick(step)
		pigeon.z_index = game.spawner.depth_z(pigeon.position,2)
	_coo(step)

## Called when the player eats a thrown crumb.
func player_ate_crumb() -> void:
	eaten += 1

func aggro_active() -> bool:
	return pigeons.any(func(p: BeachPigeon) -> bool: return p.state == BeachPigeon.State.AGGRO)

## Greedy gull: up to `aggro_count` grounded pigeons within notice range fly at it. Waits for a calm moment (one wave at a time, gull not stunned).
func _try_aggro() -> void:
	var gull: BeachGull = game.player
	if gull.state == BeachGull.State.STUNNED or aggro_active() or game.brash.active():
		return
	var near: Array = pigeons.filter(func(p: BeachPigeon) -> bool: return p.grounded() and absf(p.position.x-gull.position.x) <= float(cfg.aggro_notice))
	if near.is_empty():
		return
	near.sort_custom(func(a: BeachPigeon, b: BeachPigeon) -> bool: return absf(a.position.x-gull.position.x) < absf(b.position.x-gull.position.x))
	for pigeon: BeachPigeon in near.slice(0,int(cfg.aggro_count)):
		pigeon.annoy()
		game.effects.shout(pigeon.position-Vector2(0,16),"!",Color("ef725c"))
	eaten = 0
	eat_goal = rng.randi_range(int(cfg.aggro_eat[0]),int(cfg.aggro_eat[1]))

func pigeon_bumps_gull(pigeon: BeachPigeon) -> void:
	var gull: BeachGull = game.player
	game.effects.snatch_contact(pigeon.position-Vector2(0,8),gull.velocity,false)
	game.effects.shout(pigeon.position-Vector2(0,20),"PECK!",Color("ef725c"))
	gull.swatted(float(cfg.aggro_stun),pigeon.position,float(cfg.aggro_force)) # the species' stun multiplier scales it

## A ground bin within reach of the pigeon's home that still has food and no pigeon already on it (wheelie bins need a top landing).
func claim_bin(pigeon: BeachPigeon) -> Dictionary:
	for bin: Dictionary in game.stash_raids.bins:
		if int(bin.remaining) > 0 and not bin.requires_top_landing and not bin.has("pigeon") and absf(float(bin.x)-pigeon.home) <= float(cfg.bin_range):
			bin.pigeon = pigeon.get_instance_id()
			return bin
	return {}

func thrown_on_ground() -> int:
	return game.scraps.crumbs.filter(func(c: Dictionary) -> bool: return c.get("thrown",false) and not c.get("gone",false)).size()

## Nearest thrown crumb that has landed and is not already someone's lunch; claims it for the pigeon.
func claim_crumb(pigeon: BeachPigeon) -> Dictionary:
	var best: Dictionary = {}
	var best_gap: float = float(cfg.notice)
	for crumb: Dictionary in game.scraps.crumbs:
		var gap: float = absf(float(crumb.x)-pigeon.position.x)
		if crumb.get("thrown",false) and not crumb.get("gone",false) and float(crumb.get("fly",0.0)) <= 0.0 and not crumb.has("claim") and gap <= best_gap:
			best = crumb
			best_gap = gap
	if not best.is_empty():
		best.claim = pigeon.get_instance_id()
	return best

func _throw(from: Vector2, facing: float) -> void:
	var room: int = int(cfg.crumb_cap)-thrown_on_ground()
	var count: int = mini(rng.randi_range(int(cfg.fan[0]),int(cfg.fan[1])),room)
	var width: float = float(Config.tuning.world.width)
	for i: int in count:
		var landing: float = clampf(lady.position.x+facing*rng.randf_range(float(cfg.reach[0]),float(cfg.reach[1])),12.0,width-12.0)
		game.scraps.crumbs.append({"x":landing,"x0":from.x,"hand":from.y,"wait":0.0,"food_id":"crumbs","thrown":true,"fly":float(cfg.fly_time),"fly_total":float(cfg.fly_time),"arc":float(cfg.arc)})

func _swat(gull: BeachGull) -> void:
	game.effects.shout(gull.position-Vector2(0,20),"OI! SHOO!",Color("ef725c"))
	gull.swatted(float(cfg.swat_stun),lady.position)

## A dive peck through a grounded pigeon scatters it and every grounded pigeon within the scatter radius.
func _check_scatter() -> void:
	var gull: BeachGull = game.player
	if gull.state not in [BeachGull.State.STRIKE,BeachGull.State.GLIDE]:
		return
	var hit: Array = cfg.hit
	for pigeon: BeachPigeon in pigeons:
		if _air_hit(gull,pigeon) or (gull.state == BeachGull.State.STRIKE and pigeon.grounded() and BeachCollisions.segment_hits(gull.previous_beak,gull.sweep_beak,pigeon.position+Vector2(0,-6),Vector2(float(hit[0]),float(hit[1])))):
			scatter_around(pigeon,gull.position.x)
			game.brash.earn("pigeon_bump")
			gull.swatted(float(cfg.pigeon_stun),pigeon.position,float(cfg.pigeon_force)) # bump back, scaled by the species' stun multiplier
			return

## A flying gull body-checks a pigeon in the air. An attacking (AGGRO) pigeon only goes down to a dive, so it can still land its peck.
func _air_hit(gull: BeachGull, pigeon: BeachPigeon) -> bool:
	var airborne: bool = pigeon.state in [BeachPigeon.State.FLEE,BeachPigeon.State.AWAY,BeachPigeon.State.RETURN] or (pigeon.state == BeachPigeon.State.AGGRO and gull.state == BeachGull.State.STRIKE)
	return airborne and gull.position.distance_to(pigeon.position+Vector2(0,-6)) <= float(cfg.air_hit)

## The hit pigeon is bumped and stays; every other grounded pigeon within the scatter radius flies off.
func scatter_around(hit_pigeon: BeachPigeon, from_x: float) -> void:
	hit_pigeon.bump(signf(hit_pigeon.position.x-from_x),game.player.velocity.length())
	if hit_pigeon.position.y >= float(Config.tuning.world.ground)-1.0:
		game.effects.sand_puff(hit_pigeon.position,true)
	feathers(hit_pigeon,game.player.velocity,int(cfg.feathers.hit),float(cfg.feathers.hit_spread))
	Audio.play(Audio.pick(["pigeon_scared_1","pigeon_scared_2"]),randf_range(0.95,1.1),float(cfg.sfx.scared_db))
	var flew: bool = false
	for pigeon: BeachPigeon in pigeons:
		if pigeon != hit_pigeon and pigeon.grounded() and pigeon.position.distance_to(hit_pigeon.position) <= float(cfg.scatter_radius):
			game.effects.sand_puff(pigeon.position,true)
			feathers(pigeon,Vector2.ZERO,int(cfg.feathers.scare))
			pigeon.scatter(signf(pigeon.position.x-from_x))
			flew = true
	if flew:
		Audio.play("pigeon_takeoff",1.0,float(cfg.sfx.takeoff_db))
	game.effects.shout(hit_pigeon.position-Vector2(0,16),"SHOO!",BeachUI.GOLD)
	game._quest_event("pigeons_scattered")

## Small grey pigeon feathers (level `feeding.feathers`).
func feathers(pigeon: BeachPigeon, impulse: Vector2, amount: int, spread: float = 1.0) -> void:
	var f: Dictionary = cfg.feathers
	game.effects.feather_burst(pigeon.position-Vector2(0,6),impulse,amount,Color(f.tint[0],f.tint[1],f.tint[2]),float(f.size),spread)

## Shakedown: every grounded pigeon within `radius` of the gull flies off and returns after the normal delay.
func scare_pigeons(at: float, radius: float) -> void:
	var flew: bool = false
	for pigeon: BeachPigeon in pigeons:
		if (pigeon.grounded() or pigeon.state == BeachPigeon.State.AGGRO) and absf(pigeon.position.x-at) <= radius:
			game.effects.sand_puff(pigeon.position,true)
			feathers(pigeon,Vector2.ZERO,int(cfg.feathers.scare))
			pigeon.scatter(1.0 if pigeon.position.x >= at else -1.0)
			flew = true
	if flew:
		Audio.play("pigeon_takeoff",1.0,float(cfg.sfx.takeoff_db))
