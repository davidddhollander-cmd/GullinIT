class_name BeachFeeding
extends Node
## Level 4 "Feeding Time": owns the crumb lady, the pigeon flock, the thrown crumbs (BeachScraps entries
## flagged "thrown") and the gull-mugs-pigeon scatter. Everything is tuned by the level's `feeding` block.
var game: BeachGame
var cfg: Dictionary
var lady: CrumbLady
var pigeons: Array[BeachPigeon] = []
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func setup(owner_game: BeachGame, actors: Node2D) -> void:
	game = owner_game
	cfg = game.level.feeding
	rng.seed = int(game.level.seed)+13
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
	for i: int in 8:
		var x: float = pigeon.home+pigeon.rng.randf_range(-float(cfg.wander),float(cfg.wander))
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

func tick(step: float) -> void:
	lady.tick(step,game.player)
	lady.z_index = game.spawner.depth_z(lady.position,2)
	_check_scatter()
	for pigeon: BeachPigeon in pigeons:
		pigeon.tick(step)
		pigeon.z_index = game.spawner.depth_z(pigeon.position,2)

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
	if gull.state != BeachGull.State.STRIKE:
		return
	var hit: Array = cfg.hit
	for pigeon: BeachPigeon in pigeons:
		if pigeon.grounded() and BeachCollisions.segment_hits(gull.previous_beak,gull.sweep_beak,pigeon.position+Vector2(0,-6),Vector2(float(hit[0]),float(hit[1]))):
			scatter_around(pigeon,gull.position.x)
			gull.swatted(float(cfg.pigeon_stun),pigeon.position,float(cfg.pigeon_force)) # bump back, scaled by the species' stun multiplier
			return

## The hit pigeon is bumped and stays; every other grounded pigeon within the scatter radius flies off.
func scatter_around(hit_pigeon: BeachPigeon, from_x: float) -> void:
	hit_pigeon.bump(signf(hit_pigeon.position.x-from_x))
	game.effects.sand_puff(hit_pigeon.position,true)
	for pigeon: BeachPigeon in pigeons:
		if pigeon != hit_pigeon and pigeon.grounded() and pigeon.position.distance_to(hit_pigeon.position) <= float(cfg.scatter_radius):
			game.effects.sand_puff(pigeon.position,true)
			pigeon.scatter(signf(pigeon.position.x-from_x))
	game.effects.shout(hit_pigeon.position-Vector2(0,16),"SHOO!",BeachUI.GOLD)
	Audio.play("click")
	game._quest_event("pigeons_scattered")

## Shakedown: every grounded pigeon within `radius` of the gull flies off and returns after the normal delay.
func scare_pigeons(at: float, radius: float) -> void:
	for pigeon: BeachPigeon in pigeons:
		if pigeon.grounded() and absf(pigeon.position.x-at) <= radius:
			game.effects.sand_puff(pigeon.position,true)
			pigeon.scatter(1.0 if pigeon.position.x >= at else -1.0)
