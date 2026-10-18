class_name RivalPilot
extends RefCounted
var gull: BeachGull
var target: BeachTarget
var personality: Dictionary
var leave: float = 0.0
var carried: int = 0
var carry_window: float = 0.0
var carried_food_id: String = "crisps_bag"
var rng: RandomNumberGenerator
var aim_error: float = 0.0
var retreat_direction: float = 1.0

func setup(actor: BeachGull, profile: Dictionary, random: RandomNumberGenerator) -> void:
	gull = actor
	personality = profile
	rng = random
	gull.speed_factor = profile.speed
	gull.rival_name = str(profile.name)
	var colors: Array[Color] = [Color("a5c7e6"), Color("d3b9e8"), Color("a4d8c4")]
	gull.rival_tint = colors[absi(str(profile.name).hash()) % colors.size()]
	gull.refresh_art()

func tick(delta: float, targets: Array[BeachTarget], claims: Dictionary, wind: BeachWind) -> void:
	carry_window = maxf(0.0, carry_window - delta)
	if leave > 0:
		leave -= delta
		if gull.position.x < 30:
			retreat_direction = 1.0
		elif gull.position.x > float(Config.tuning.world.width) - 30:
			retreat_direction = -1.0
		gull.aim = Vector2(clampf(gull.position.x + retreat_direction * 100, 25, float(Config.tuning.world.width) - 25), float(Config.tuning.rival.cruise_y))
		gull.climb = true
		gull.tick(delta, wind.direction, wind.strength)
		if leave <= 0:
			carried = 0
		return
	if not is_instance_valid(target) or not target.food or target.leaving:
		target = null
		var best: float = -1.0
		for candidate: BeachTarget in targets:
			if not candidate.food or candidate.leaving or claims.has(candidate):
				continue
			var distance: float = gull.position.distance_to(candidate.food_position())
			if distance > float(Config.tuning.rival.search_radius):
				continue
			var priority: float = float(candidate.food_value()) / maxf(distance, 1.0)
			if priority > best:
				best = priority
				target = candidate
		if is_instance_valid(target):
			aim_error = rng.randf_range(-float(personality.accuracy_px), float(personality.accuracy_px))
	if is_instance_valid(target):
		claims[target] = self
		gull.aim = target.food_position() + Vector2(aim_error, 0)
		gull.climb = gull.state in [BeachGull.State.GLIDE, BeachGull.State.GROUNDED] and gull.position.y > float(Config.tuning.rival.cruise_y)
		var distance_x: float = absf(gull.position.x - target.position.x)
		if distance_x < float(Config.tuning.rival.dive_range) and distance_x > 15:
			gull.dive(wind.direction)
			if gull.state == BeachGull.State.WINDUP:
				gull.climb = false
		if gull.state == BeachGull.State.STRIKE and not gull.peck_used:
			var peck_reach: float = gull.dive_speed*float(Config.tuning.dive.peck_window)+18.0
			if gull.beak().distance_to(target.food_position()) <= peck_reach:
				gull.attempt_peck()
	else:
		gull.aim = Vector2(gull.position.x + gull.facing * 100, Config.tuning.rival.cruise_y)
		gull.climb = gull.position.y > float(Config.tuning.rival.cruise_y)
		if gull.position.x < 25 or gull.position.x > float(Config.tuning.world.width) - 25:
			gull.facing *= -1
	gull.tick(delta, wind.direction, wind.strength)

func took_food(value: int) -> void:
	carried = value
	carry_window = Config.tuning.rival.mug_window
	leave = Config.tuning.rival.leave_time
	retreat_direction = -1.0 if gull.position.x > float(Config.tuning.world.width) * 0.5 else 1.0
	target = null

func mug() -> int:
	if carry_window <= 0 or carried <= 0:
		return 0
	var value: int = carried
	carried = 0
	carry_window = 0
	leave = 0
	gull.stun(Config.tuning.rival.mug_stun)
	return value
