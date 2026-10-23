class_name RivalPilot
extends RefCounted
## Rival brain: a small state machine that drives a BeachGull through the same API as the player.
## PATROL sweeps the beach, STALK picks a target and climbs, LINE_UP holds a dive position,
## DIVE strikes and pecks, ESCAPE flees after a theft, RECOVER climbs away after a miss.
## CHASE_CARRIER stalks a gull (rival or player) holding food, then dives through it (a mug).
## Rivals compete: they ignore each other's food claims and mug each other.
enum Mode { PATROL, STALK, LINE_UP, DIVE, ESCAPE, RECOVER, CHASE_CARRIER }
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
var mug_timer: float = 0.0
var mugs: int = 0
# Counters for tests and tuning.
var dives: int = 0
var thefts: int = 0
var crashes: int = 0

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
	gull.rival_tint = COLOURS[absi(str(profile.name).hash()) % COLOURS.size()]
	gull.dive_started.connect(func() -> void: dives += 1)
	gull.ground_crashed.connect(func() -> void: crashes += 1)
	gull.refresh_art()

func world_width() -> float:
	return float(Config.tuning.world.width)

func edge_margin() -> float:
	return float(Config.tuning.rival.edge_margin)

func cruise() -> float:
	return float(Config.tuning.rival.cruise_y)

func tick(delta: float, targets: Array[BeachTarget], claims: Dictionary, wind: BeachWind, threat: Vector2 = Vector2(-1, -1)) -> void:
	carry_window = maxf(0.0, carry_window - delta)
	cooldown = maxf(0.0, cooldown - delta)
	mug_timer = maxf(0.0, mug_timer - delta)
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
	if mode == Mode.DIVE:
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
	carry_window = Config.tuning.rival.mug_window
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
	thefts += 1
	target = null
	chase_prey = null
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
	cooldown = relax_time()
	mode = Mode.RECOVER
	gull.stun(Config.tuning.rival.mug_stun,attacker)
	return value
