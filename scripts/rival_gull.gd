class_name RivalPilot
extends RefCounted
## Rival brain: a small state machine that drives a BeachGull through the same API as the player.
## PATROL sweeps the beach, STALK picks a target and climbs, LINE_UP holds a dive position,
## DIVE strikes and pecks, ESCAPE flees after a theft, RECOVER climbs away after a miss.
## CHASE_CARRIER stalks a gull (rival or player) holding food, then dives through it (a mug).
## Rivals compete: they ignore each other's food claims and mug each other.
## LAND glides down beside a ground job (item, crumb, bin, sunbather bag), WALK strolls to it, PECK taps
## a bin or bag open like the player; RECOVER doubles as the take-off. Personality: the `ground` weights.
enum Mode { PATROL, STALK, LINE_UP, DIVE, ESCAPE, RECOVER, CHASE_CARRIER, LAND, WALK, PECK }
const GROUND_MODES: Array[Mode] = [Mode.LAND, Mode.WALK, Mode.PECK]
const COLOURS: Array[Color] = [Color("a5c7e6"), Color("d3b9e8"), Color("a4d8c4")]
var gull: BeachGull
var target: BeachTarget
var personality: Dictionary
var leave: float = 0.0
var carried: int = 0
var score: int = 0
var carry_window: float = 0.0
var carried_food_id: String = "crisps_bag"
var rng: RandomNumberGenerator
var aim_error: float = 0.0
var retreat_direction: float = 1.0
var mode: Mode = Mode.PATROL
var waypoint: float = -1.0
var waypoint_age: float = 0.0
var retarget_timer: float = 0.0
var reaction: float = 0.0
var cooldown: float = 0.0
var lineup_side: float = 1.0
var threat_x: float = -1.0
var theft_x: float = 0.0
var prey: Array[BeachGull] = [] ## gulls currently holding mug-able food (set by the game each frame)
var chase_prey: BeachGull
var game: BeachGame ## set by the game; ground jobs read the same bins, bags, items and crumbs as the player
var work: Dictionary = {} ## current ground job: kind (item|catch|scrap|bin|bag), ref, side
var air_score: float = 0.0
var eat_timer: float = 0.0
var peck_timer: float = 0.0
var failed_pecks: int = 0
var work_age: float = 0.0
var ground_time: float = 0.0
var ground_rest: float = 0.0
var avoid: Array[Dictionary] = [] ## {ref, time}: jobs to keep away from for a while (they went nowhere)
var mug_timer: float = 0.0
var mugs: int = 0
# Counters for tests and tuning.
var dives: int = 0
var thefts: int = 0
var crashes: int = 0
var ground_eats: int = 0
var stats: Dictionary = {"scraps":0,"bins":0,"bags":0,"catch":0} ## successful uses of each ground skill

func mug_chance() -> float:
	return float(personality.get("mug_chance",Config.tuning.rival.mug_chance))

func mug_range() -> float:
	return float(Config.tuning.rival.mug_range)

func setup(actor: BeachGull, profile: Dictionary, random: RandomNumberGenerator) -> void:
	gull = actor
	personality = profile
	rng = random
	gull.speed_factor = profile.speed
	gull.rival_name = str(profile.name)
	gull.loose_only = bool(profile.get("loose_only",false))
	gull.species = str(profile.get("species","great-black-backed"))
	gull.body_scale = float(profile.get("scale",1.0))
	gull.rival_tint = COLOURS[absi(str(profile.name).hash()) % COLOURS.size()]
	gull.dive_started.connect(func() -> void: dives += 1)
	gull.ground_crashed.connect(func() -> void: crashes += 1)
	gull.carry_source = func() -> String: return carried_food_id if carry_window > 0.0 and carried > 0 else ""
	gull.refresh_art()

func world_width() -> float:
	return float(Config.tuning.world.width)

func edge_margin() -> float:
	return float(Config.tuning.rival.edge_margin)

func cruise() -> float:
	return float(Config.tuning.rival.cruise_y)

func tick(delta: float, targets: Array[BeachTarget], claims: Dictionary, wind: BeachWind, threat: Vector2 = Vector2(-1, -1)) -> void:
	gull.mug_cue = carry_window > 0.0 and carried > 0 and threat.x >= 0.0 and gull.position.distance_to(threat) <= mug_range()
	carry_window = maxf(0.0, carry_window - delta)
	cooldown = maxf(0.0, cooldown - delta)
	mug_timer = maxf(0.0, mug_timer - delta)
	eat_timer = maxf(0.0, eat_timer - delta)
	if carry_window <= 0.0 and leave <= 0.0:
		carried = 0 # swallowed on the ground: nothing left to mug
	ground_rest = maxf(0.0, ground_rest - delta)
	for i: int in range(avoid.size() - 1, -1, -1):
		avoid[i].time -= delta
		if avoid[i].time <= 0.0:
			avoid.remove_at(i)
	if threat.x >= 0.0:
		threat_x = threat.x
	if leave > 0:
		mode = Mode.ESCAPE
		leave -= delta
		escape()
		gull.tick(delta, wind.direction, wind.strength)
		if leave <= 0:
			carried = 0
			cooldown = relax_time()
			mode = Mode.PATROL
			waypoint = -1.0
		return
	if mode in GROUND_MODES:
		ground_step(delta)
	elif mode == Mode.DIVE:
		dive_step(wind)
	elif mode == Mode.RECOVER:
		recover()
	else:
		if not chase_step(delta, wind):
			hunt(delta, targets, claims, wind)
	gull.tick(delta, wind.direction, wind.strength)
	if mode == Mode.DIVE and gull.state in [BeachGull.State.GLIDE, BeachGull.State.GROUNDED, BeachGull.State.STUNNED]:
		finish_dive()

func hunt(delta: float, targets: Array[BeachTarget], claims: Dictionary, wind: BeachWind) -> void:
	retarget_timer -= delta
	var valid: bool = is_instance_valid(target) and target.food and not target.leaving
	if not valid:
		target = null
	if cooldown <= 0.0 and (target == null or retarget_timer <= 0.0):
		retarget_timer = float(Config.tuning.rival.retarget_interval)
		pick_target(targets, claims)
		if pick_ground():
			return
	if not is_instance_valid(target):
		mode = Mode.PATROL
		patrol(delta, targets)
		return
	claims[target] = self # bookkeeping only: rivals race for food, they never yield it
	var food: Vector2 = target.food_position()
	var dy: float = maxf(food.y - cruise(), 30.0)
	var offset: float = dy * float(Config.tuning.rival.lineup_ratio)
	var side: float = lineup_side
	# Approach from the side the gull is already on, unless the far side has no room.
	if mode == Mode.PATROL or mode == Mode.RECOVER:
		side = signf(gull.position.x - food.x) if absf(gull.position.x - food.x) > 4.0 else gull.facing
	if food.x + side * offset > world_width() - edge_margin() or food.x + side * offset < edge_margin():
		side = -side
	lineup_side = side
	var lineup_x: float = clampf(food.x + side * offset, edge_margin(), world_width() - edge_margin())
	gull.aim = Vector2(lineup_x, cruise())
	gull.climb = gull.state in [BeachGull.State.GLIDE, BeachGull.State.GROUNDED] and needs_height()
	var close: bool = absf(gull.position.x - lineup_x) <= float(Config.tuning.rival.lineup_tolerance) and absf(gull.position.y - cruise()) < 18.0
	if close and gull.state == BeachGull.State.GLIDE:
		if mode != Mode.LINE_UP:
			mode = Mode.LINE_UP
			reaction = float(Config.tuning.rival.reaction_delay) * rng.randf_range(0.7, 1.3) / maxf(0.3, float(personality.speed) * float(personality.speed))
		reaction -= delta
		if reaction <= 0.0 and gull.cooldown <= 0.0:
			var spread: float = float(personality.accuracy_px) * float(Config.tuning.rival.aim_spread)
			aim_error = rng.randf_range(-spread, spread)
			gull.aim = food + Vector2(aim_error, 0)
			gull.climb = false
			gull.dive(wind.direction)
			if gull.state == BeachGull.State.WINDUP:
				mode = Mode.DIVE
	elif mode == Mode.LINE_UP and absf(gull.position.x - lineup_x) > float(Config.tuning.rival.lineup_tolerance) * 3.0:
		mode = Mode.STALK
	elif mode != Mode.LINE_UP:
		mode = Mode.STALK

func relax_time() -> float:
	# Slower rivals take longer to get their nerve back.
	return float(Config.tuning.rival.cooldown) / maxf(0.3, float(personality.speed) * float(personality.speed))

func pick_target(targets: Array[BeachTarget], claims: Dictionary) -> void:
	var best: float = 0.0
	var best_target: BeachTarget
	var current: float = 0.0
	for candidate: BeachTarget in targets:
		if not candidate.food or candidate.leaving or candidate.defense > 0.0 or (gull.loose_only and not candidate.is_loose()):
			continue
		var distance: float = absf(gull.position.x - candidate.food_position().x)
		if distance > float(Config.tuning.rival.search_radius):
			continue
		var score: float = float(candidate.food_value()) / (distance + 80.0)
		if candidate.alert >= 1.0:
			score *= 0.7
		if candidate == target:
			score *= 1.3
			current = score
		if score > best:
			best = score
			best_target = candidate
	air_score = maxf(best, current)
	if best_target != null and best_target != target and best > current:
		target = best_target
		mode = Mode.STALK
		lineup_side = signf(gull.position.x - target.food_position().x)
		if lineup_side == 0.0:
			lineup_side = 1.0
		claims[target] = self

func patrol(delta: float, targets: Array[BeachTarget]) -> void:
	waypoint_age += delta
	if waypoint < 0.0 or absf(gull.position.x - waypoint) < 25.0 or waypoint_age > 8.0:
		waypoint = pick_waypoint(targets)
		waypoint_age = 0.0
	gull.aim = Vector2(waypoint, cruise())
	gull.climb = gull.state in [BeachGull.State.GLIDE, BeachGull.State.GROUNDED] and needs_height()

func pick_waypoint(targets: Array[BeachTarget]) -> float:
	# Prefer places where someone is holding food; otherwise sweep the width of the beach.
	var spots: Array[float] = []
	for candidate: BeachTarget in targets:
		if candidate.food and not candidate.leaving and (not gull.loose_only or candidate.is_loose()) and absf(candidate.position.x - gull.position.x) > 120.0:
			spots.append(candidate.position.x)
	var x: float
	if not spots.is_empty() and rng.randf() < 0.7:
		x = spots[rng.randi_range(0, spots.size() - 1)] + rng.randf_range(-40.0, 40.0)
	else:
		x = rng.randf_range(edge_margin(), world_width() - edge_margin())
		if absf(x - gull.position.x) < 150.0:
			x = world_width() - x
	return clampf(x, edge_margin(), world_width() - edge_margin())

func dive_step(wind: BeachWind) -> void:
	if chase_prey != null:
		mug_dive_step()
		return
	if not is_instance_valid(target) or not target.food or target.leaving:
		abort_dive()
		return
	var food: Vector2 = target.food_position()
	gull.aim = food + Vector2(aim_error, 0)
	gull.climb = false
	if gull.state == BeachGull.State.STRIKE:
		var past: bool = gull.position.y > food.y + 4.0 or gull.beak().y > float(Config.tuning.world.ground) - 10.0
		if not gull.peck_used:
			var reach: float = gull.dive_speed * float(Config.tuning.dive.peck_window) * 0.5 + 6.0
			if gull.beak().distance_to(food) <= reach:
				gull.attempt_peck()
		if (gull.peck_used and gull.peck_time <= 0.0) or past:
			abort_dive()

## Picks a nearby carrier (by mug_chance), climbs over it, then dives through it.
func chase_step(delta: float, wind: BeachWind) -> bool:
	if mode != Mode.CHASE_CARRIER:
		if cooldown > 0.0 or mug_timer > 0.0 or leave > 0.0 or mug_chance() <= 0.0 or gull.state == BeachGull.State.STUNNED:
			return false
		var near: BeachGull = nearest_prey()
		if near == null:
			return false
		mug_timer = 0.5
		if rng.randf() >= mug_chance():
			return false
		chase_prey = near
		mode = Mode.CHASE_CARRIER
	if not prey.has(chase_prey) or not prey_reachable(chase_prey) or gull.position.distance_to(chase_prey.position) > mug_range() * 1.6:
		chase_prey = null
		mode = Mode.PATROL
		waypoint = -1.0
		return false
	var spot: Vector2 = chase_prey.position
	gull.aim = Vector2(spot.x, minf(cruise(), spot.y - 25.0))
	gull.climb = gull.state in [BeachGull.State.GLIDE, BeachGull.State.GROUNDED] and needs_height()
	if gull.state == BeachGull.State.GLIDE and absf(gull.position.x - spot.x) < 40.0 and gull.position.y < spot.y - 12.0 and gull.cooldown <= 0.0:
		gull.aim = spot + chase_prey.velocity * 0.25
		gull.climb = false
		gull.dive(wind.direction)
		if gull.state == BeachGull.State.WINDUP:
			mode = Mode.DIVE
	return true

func prey_reachable(candidate: BeachGull) -> bool:
	# Climbing above the cruise height puts a carrier out of a diver's reach.
	return candidate != gull and candidate.position.y >= cruise() - 4.0 and gull.position.distance_to(candidate.position) <= mug_range() * 1.6

func nearest_prey() -> BeachGull:
	var best: BeachGull
	var best_distance: float = mug_range()
	for candidate: BeachGull in prey:
		var distance: float = gull.position.distance_to(candidate.position)
		if prey_reachable(candidate) and distance <= best_distance:
			best = candidate
			best_distance = distance
	return best

func mug_dive_step() -> void:
	if not prey.has(chase_prey):
		abort_dive()
		return
	gull.aim = chase_prey.position + chase_prey.velocity * 0.25
	gull.climb = false
	if gull.state == BeachGull.State.STRIKE and (gull.position.y > chase_prey.position.y + 8.0 or gull.beak().y > float(Config.tuning.world.ground) - 10.0):
		abort_dive()

func abort_dive() -> void:
	chase_prey = null
	if not is_instance_valid(target) or not target.food or target.leaving:
		target = null # lost the race: nothing left to dive at
	# Pull out of the swoop; a held climb ends STRIKE without touching the sand.
	gull.climb = true
	gull.aim = Vector2(gull.position.x + gull.facing * 60.0, cruise())
	mode = Mode.RECOVER
	cooldown = maxf(cooldown, float(Config.tuning.rival.miss_cooldown))

func finish_dive() -> void:
	chase_prey = null
	mode = Mode.RECOVER

func recover() -> void:
	gull.aim = Vector2(clampf(gull.position.x + gull.facing * 80.0, edge_margin(), world_width() - edge_margin()), cruise())
	gull.climb = gull.state != BeachGull.State.WINDUP
	if gull.state in [BeachGull.State.GLIDE, BeachGull.State.GROUNDED] and not needs_height() and gull.position.y < cruise() + 20.0:
		mode = Mode.PATROL
		waypoint = -1.0

func escape() -> void:
	# Fly the committed way out; turning around is done by moving the aim, never by poking facing.
	var goal: float = clampf(gull.position.x + retreat_direction * 320.0, edge_margin() + 20.0, world_width() - edge_margin() - 20.0)
	gull.aim = Vector2(goal, cruise() - 10.0)
	gull.climb = gull.state != BeachGull.State.WINDUP and gull.position.y + gull.velocity.y * 0.25 > cruise() - 10.0

func needs_height() -> bool:
	# Look a quarter second ahead so flapping stops before the climb overshoots cruise height.
	return gull.position.y + gull.velocity.y * 0.25 > float(Config.tuning.rival.cruise_y)

func took_food(value: int) -> void:
	carried = value
	score += value
	# Mug-able for as long as the player would take to swallow the same food in the air.
	carry_window = GullDigestion.duration(carried_food_id)
	thefts += 1
	target = null
	chase_prey = null
	if gull.state == BeachGull.State.GLIDE:
		stats["catch"] += 1 # snatched out of the air, not by a swoop
	if gull.state == BeachGull.State.GROUNDED:
		stats["scraps"] += 1
		# Eaten where it was found: stand still for the swallow, then carry on (or take off).
		eat_timer = carry_window
		ground_eats += 1
		cooldown = maxf(cooldown, float(Config.tuning.rival.ground_cooldown))
		return
	leave = Config.tuning.rival.leave_time
	# Away from the player, unless that is a dead end against the wall.
	retreat_direction = signf(gull.position.x - threat_x) if threat_x >= 0.0 and absf(gull.position.x - threat_x) > 10.0 else (-1.0 if gull.position.x > world_width() * 0.5 else 1.0)
	var room: float = world_width() - gull.position.x if retreat_direction > 0.0 else gull.position.x
	if room < 250.0:
		retreat_direction = -retreat_direction
	# Keep the dive's momentum when there is room: turning round on the sand wastes ~2 s and 100+ px
	# (that was the flaky 'leaves the scene of a theft' failure), and still flees the shortest way off.
	var heading: float = signf(gull.velocity.x)
	if absf(gull.velocity.x) > 40.0 and (world_width() - gull.position.x if heading > 0.0 else gull.position.x) >= 250.0:
		retreat_direction = heading
	theft_x = gull.position.x
	mode = Mode.ESCAPE

func mug(attacker: Vector2 = Vector2.INF) -> int:
	if carry_window <= 0 or carried <= 0:
		return 0
	var value: int = carried
	carried = 0
	score = maxi(0, score - value)
	carry_window = 0
	leave = 0
	chase_prey = null
	work = {}
	eat_timer = 0.0
	cooldown = relax_time()
	mode = Mode.RECOVER
	gull.stun(Config.tuning.rival.mug_stun,attacker)
	return value

# --- Ground skills -------------------------------------------------------------------------------

func weight(skill: String) -> float:
	return float(personality.get("ground",{}).get(skill,Config.tuning.rival.ground[skill]))

func ground_score(value: float, x: float, skill: String) -> float:
	return value / (absf(gull.position.x - x) + 80.0) * weight(skill)

## Everything a rival could walk to right now, scored like air targets (value over distance) times its taste.
func ground_options() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if game == null:
		return out
	var lo: float = edge_margin()
	var hi: float = world_width() - edge_margin()
	var reach: float = float(Config.tuning.rival.search_radius)
	for item: Dictionary in game.stash_raids.items:
		var x: float = float(item.position.x)
		if bool(item.get("garbage",false)) or bool(item.get("recovered",false)) or str(item.get("food_id","")).is_empty() or avoided(item) or x < lo or x > hi or absf(x - gull.position.x) > reach:
			continue
		# Food still in the air is caught if the rival likes catching, otherwise waited for on the sand.
		var catching: bool = not bool(item.grounded) and weight("catch") > 0.0
		var skill: String = "catch" if catching else "scraps"
		if weight(skill) > 0.0:
			out.append({"kind":"catch" if catching else "item","ref":item,"score":ground_score(float(Config.foods[item.food_id].points),x,skill)})
	if weight("scraps") > 0.0:
		for crumb: Dictionary in game.scraps.crumbs:
			var x: float = float(crumb.x)
			if float(crumb.wait) <= 0.0 and not avoided(crumb) and x >= lo and x <= hi and absf(x - gull.position.x) <= reach:
				out.append({"kind":"scrap","ref":crumb,"score":ground_score(float(Config.foods[crumb.food_id].points),x,"scraps")})
	if weight("bins") > 0.0:
		for bin: Dictionary in game.stash_raids.bins:
			var x: float = float(bin.x)
			if int(bin.remaining) > 0 and not avoided(bin) and not spill_near(x) and x >= lo and x <= hi and absf(x - gull.position.x) <= reach:
				out.append({"kind":"bin","ref":bin,"score":ground_score(float(Config.tuning.rival.bin_value),x,"bins")})
	if weight("bags") > 0.0:
		for owner: BeachTarget in game.spawner.targets:
			if is_instance_valid(owner) and owner.kind == "sunbather" and owner.stash_remaining > 0 and not owner.leaving and not avoided(owner):
				var x: float = owner.stash_position().x
				if x >= lo and x <= hi and absf(x - gull.position.x) <= reach:
					out.append({"kind":"bag","ref":owner,"score":ground_score(float(Config.tuning.rival.bag_value),x,"bags")})
	return out

## Where the job is (the thing's x), not where the gull stands.
func job_x(job: Dictionary) -> float:
	match str(job.kind):
		"item", "catch":
			return float(job.ref.position.x)
		"scrap", "bin":
			return float(job.ref.x)
	return job.ref.stash_position().x

## The hunt() entry: ground work wins when its score beats the best air snatch.
func pick_ground() -> bool:
	if ground_rest > 0.0 or gull.state == BeachGull.State.STUNNED:
		return false
	var best: Dictionary = {}
	var best_score: float = air_score if is_instance_valid(target) else 0.0
	for option: Dictionary in ground_options():
		if float(option.score) > best_score:
			best = option
			best_score = float(option.score)
	if best.is_empty():
		return false
	begin_work(best)
	return true

func begin_work(job: Dictionary) -> void:
	work = job
	work.side = signf(gull.position.x - job_x(job))
	if work.side == 0.0:
		work.side = gull.facing
	work_age = 0.0
	failed_pecks = 0
	target = null
	var near: bool = absf(job_x(job) - gull.position.x) < float(Config.tuning.rival.walk_range)
	mode = Mode.WALK if gull.state == BeachGull.State.GROUNDED and gull.support.is_empty() and near else Mode.LAND

## Where the gull stands to work: beside the thing, beak over it. Wheelie bins are worked from the lid.
func stand_x() -> float:
	var x: float = job_x(work)
	if on_lid():
		return x
	# Too close to line up (the gull would face away): step back first, then walk in so the beak leads.
	var gap: float = absf(gull.position.x - x)
	if not work.has("backed"):
		work.backed = gull.state != BeachGull.State.GROUNDED or gap >= 14.0
	if not work.backed and gap >= 22.0:
		work.backed = true
	return clampf(x + float(work.side) * (9.0 if work.backed else 26.0), 20.0, world_width() - 20.0)

func on_lid() -> bool:
	return str(work.kind) == "bin" and bool(work.ref.get("requires_top_landing",false)) and not lid().is_empty()

func lid() -> Dictionary:
	for surface: Dictionary in gull.perch_surfaces:
		if str(surface.prop_type) == str(work.ref.type) and absf(float(surface.x) - float(work.ref.x)) < 1.0:
			return surface
	return {}

func work_valid() -> bool:
	match str(work.kind):
		"item", "catch":
			var found: bool = false
			for entry: Dictionary in game.stash_raids.items:
				found = found or is_same(entry,work.ref)
			if not found or bool(work.ref.get("recovered",false)):
				return false
			if work.kind == "catch" and bool(work.ref.grounded):
				work.kind = "item" # it landed before we reached it: walk to it
				return weight("scraps") > 0.0
			return true
		"scrap":
			return float(work.ref.wait) <= 0.0
		"bin":
			return int(work.ref.remaining) > 0
	return is_instance_valid(work.ref) and work.ref.stash_remaining > 0 and not work.ref.leaving

## Food already lying around a bin is eaten before the bin is pecked again.
func spill_near(x: float) -> bool:
	if weight("scraps") <= 0.0:
		return false
	for item: Dictionary in game.stash_raids.items:
		if not bool(item.get("garbage",false)) and not str(item.get("food_id","")).is_empty() and absf(float(item.position.x) - x) < 80.0:
			return true
	return false

func avoided(ref: Variant) -> bool:
	for entry: Dictionary in avoid:
		if is_same(entry.ref, ref):
			return true
	return false

func shun(ref: Variant, seconds: float) -> void:
	avoid.append({"ref":ref,"time":seconds})

## Drops the job; `rest` keeps the gull from landing straight back down.
func end_work(rest: float = 0.0, shun: bool = false) -> void:
	if shun and not work.is_empty():
		shun(work.ref, float(Config.tuning.rival.avoid_time))
	work = {}
	ground_rest = rest

func take_off() -> void:
	end_work(1.0)
	mode = Mode.RECOVER

func ground_step(delta: float) -> void:
	if gull.state == BeachGull.State.STUNNED:
		end_work(1.0)
		mode = Mode.RECOVER
		return
	work_age += delta
	ground_time = ground_time + delta if gull.state == BeachGull.State.GROUNDED else 0.0
	if ground_time > float(Config.tuning.rival.ground_session) or work_age > float(Config.tuning.rival.work_timeout):
		if work_age > float(Config.tuning.rival.work_timeout):
			end_work(0.0,true)
		take_off()
		return
	if gull.state == BeachGull.State.GROUNDED:
		eat_crumb_underfoot()
	if eat_timer > 0.0 and gull.state == BeachGull.State.GROUNDED:
		gull.aim = gull.position
		gull.climb = false
		return
	if work.is_empty() or not work_valid():
		next_work()
		return
	if mode == Mode.LAND:
		land_step()
	elif mode == Mode.WALK:
		walk_step()
	else:
		peck_step(delta)

## Finished (or lost the race for) a job: the best one close by, otherwise off we go.
func next_work() -> void:
	work = {}
	var best: Dictionary = {}
	var range_limit: float = float(Config.tuning.rival.walk_range)
	for option: Dictionary in ground_options():
		if (gull.state != BeachGull.State.GROUNDED or absf(job_x(option) - gull.position.x) < range_limit) and (best.is_empty() or float(option.score) > float(best.score)):
			best = option
	if best.is_empty():
		take_off()
	else:
		begin_work(best)

func land_step() -> void:
	var stand: float = stand_x()
	if gull.state == BeachGull.State.GROUNDED:
		if on_lid() or (gull.support.is_empty() and absf(stand - gull.position.x) < float(Config.tuning.rival.walk_range)):
			mode = Mode.WALK
			return
		gull.aim = Vector2(stand, cruise())
		gull.climb = true # far away, or on a lid: take off first
		return
	if work.kind == "catch":
		var item: Dictionary = work.ref
		gull.aim = Vector2(item.position) + Vector2(item.velocity) * 0.15
		gull.climb = gull.aim.y < gull.position.y - 6.0
		return
	# Come in from the side (so the gull faces the job when it arrives) unless it lands on a lid.
	var land_x: float = stand if on_lid() else stand + float(work.side) * 21.0
	var land_y: float = float(lid().y) if on_lid() else float(Config.tuning.world.ground)
	var drop: float = land_y - gull.position.y
	if absf(land_x - gull.position.x) <= minf(30.0, maxf(drop, 14.0) * 0.45):
		gull.aim = Vector2(land_x, land_y + 10.0) # aim a little below the surface so the descent never stalls just above it
		gull.climb = false
	else:
		gull.aim = Vector2(land_x, cruise())
		gull.climb = needs_height()

func walk_step() -> void:
	if gull.state != BeachGull.State.GROUNDED:
		mode = Mode.LAND
		return
	var stand: float = stand_x()
	if not gull.support.is_empty() and not on_lid() and absf(stand - gull.position.x) > 40.0:
		mode = Mode.LAND # on a roof or lid and the job is elsewhere
		return
	gull.aim = Vector2(stand, gull.ground_y())
	gull.climb = false
	if absf(stand - gull.position.x) <= 5.0 and str(work.kind) in ["bin","bag"]:
		mode = Mode.PECK
		peck_timer = 0.1

func peck_step(delta: float) -> void:
	gull.aim = gull.position
	gull.climb = false
	peck_timer -= delta
	if peck_timer > 0.0:
		return
	peck_timer = float(Config.tuning.rival.peck_interval) * rng.randf_range(0.8,1.2)
	var bin: bool = str(work.kind) == "bin"
	var before: int = int(work.ref.remaining) if bin else int(work.ref.stash_remaining)
	if game.stash_raids.peck_as(gull):
		gull.show_ground_peck()
		var after: int = int(work.ref.remaining) if bin else int(work.ref.stash_remaining)
		if after < before:
			stats["bins" if bin else "bags"] += 1
			if not bin:
				shun(work.ref, float(Config.tuning.rival.avoid_time) * 0.5) # the owner is up and tidying: let it settle
			next_work() # the loot is on the sand: pick it up before the bin or bag
		return
	failed_pecks += 1
	if failed_pecks >= 3:
		end_work(0.0,true)
		next_work()

## Crumbs and chips along the beach are food for anyone standing on them.
func eat_crumb_underfoot() -> void:
	if weight("scraps") <= 0.0 or eat_timer > 0.0 or leave > 0.0:
		return
	for crumb: Dictionary in game.scraps.crumbs:
		var radius: float = float(Config.foods[crumb.food_id].pickup_radius[0]) + float(Config.tuning.dive.beak_w) * 0.5
		if float(crumb.wait) <= 0.0 and absf(gull.beak().x - float(crumb.x)) < radius:
			crumb.wait = Config.tuning.world.scrap_respawn
			ate_ground(str(crumb.food_id))
			return

func accepts_item(item: Dictionary) -> bool:
	if game == null or leave > 0.0 or eat_timer > 0.0 or gull.state == BeachGull.State.STUNNED or bool(item.get("garbage",false)) or str(item.get("food_id","")).is_empty():
		return false
	return weight("scraps" if bool(item.grounded) else "catch") > 0.0 and gull.can_collect_food(str(item.food_id))

## Food reached on the ground (or caught in the air): scores like a theft, with the same mug window.
func ate_ground(food_id: String) -> void:
	carried_food_id = food_id
	took_food(int(Config.foods[food_id].points))
	game.effects.message(gull.position,"MINE!",Color("ffc65c"))
	if gull.state == BeachGull.State.GROUNDED:
		gull.show_ground_peck(float(Config.tuning.world.pickup_pose_time))
