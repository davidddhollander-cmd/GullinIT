extends RefCounted
## Deterministic wingbeat, weight, wind-soaring and dive-drag trajectories at three physics rates.

static func gull_at(host: Node, y: float, vy: float = 0.0) -> BeachGull:
	var gull: BeachGull = BeachGull.new()
	host.add_child(gull)
	gull.position = Vector2(300,y)
	gull.velocity = Vector2(0,vy)
	gull.aim = gull.position
	return gull

# Passive fall from y=40 in neutral aim; returns seconds to reach the sand.
static func fall_time(host: Node, hz: int, wind_dir: int, strength: float) -> float:
	var gull: BeachGull = gull_at(host,40)
	gull.wind_force = wind_dir*strength
	var elapsed: float = 0.0
	while gull.state != BeachGull.State.GROUNDED and elapsed < 20.0:
		gull.aim = gull.position
		gull.tick(1.0/hz,wind_dir,strength)
		elapsed += 1.0/hz
	gull.queue_free()
	return elapsed

# Swoop from y=25 (straight down, or 45 degrees toward +x/-x); returns the fastest speed before impact.
static func dive_impact(host: Node, hz: int, wind_dir: int, strength: float, heading: float = 0.0) -> float:
	var gull: BeachGull = gull_at(host,25)
	gull.wind_force = wind_dir*strength
	gull.dive_speed = 65.0
	gull.direction = Vector2(heading,1).normalized()
	gull.state = BeachGull.State.STRIKE
	var fastest: float = 0.0
	var elapsed: float = 0.0
	while gull.state == BeachGull.State.STRIKE and elapsed < 5.0:
		gull.aim = gull.position + gull.direction*50.0
		gull.tick(1.0/hz,wind_dir,strength)
		elapsed += 1.0/hz
		fastest = maxf(fastest,gull.velocity.length())
	gull.queue_free()
	return fastest

# Seconds of held flap to gain 80px while moving in +heading; wind_force is signed (positive blows toward +x).
static func climb_time(host: Node, hz: int, heading: int, wind: float) -> float:
	var gull: BeachGull = gull_at(host,145)
	gull.velocity.x = 100.0*heading
	gull.wind_force = wind
	gull.climb = true
	var elapsed: float = 0.0
	while gull.position.y > 65.0 and elapsed < 15.0:
		gull.aim = gull.position + Vector2(100.0*heading,0)
		gull.tick(1.0/hz,int(signf(wind)),absf(wind))
		elapsed += 1.0/hz
	gull.queue_free()
	return elapsed

static func run(host: Node, check: Callable) -> void:
	var f: Dictionary = Config.tuning.flight
	for hz: int in [30,60,120]:
		var dt: float = 1.0/hz
		# One stroke gives a small, visible lift and then gravity takes over.
		var gull: BeachGull = gull_at(host,100)
		gull.climb = true
		gull.tick(dt,0,0)
		gull.climb = false
		var apex: float = gull.position.y
		for frame: int in hz*2:
			gull.tick(dt,0,0)
			apex = minf(apex,gull.position.y)
		check.call(100.0-apex > 4.0 and 100.0-apex < 12.0,"single wingbeat lifts a few pixels at %dHz: %.1f" % [hz,100.0-apex])
		check.call(gull.position.y > apex+5.0,"gull sinks again after a single wingbeat at %dHz" % hz)
		gull.queue_free()
		# Released upward momentum fades promptly.
		gull = gull_at(host,120,-float(f.takeoff_speed))
		var top: float = gull.position.y
		var top_time: float = 0.0
		for frame: int in hz*2:
			gull.tick(dt,0,0)
			if gull.position.y < top:
				top = gull.position.y
				top_time = (frame+1)*dt
		check.call(top_time < 0.7 and 120.0-top < 16.0,"released climb peaks quickly at %dHz: %.2fs" % [hz,top_time])
		gull.queue_free()
		# Held flap climbs steadily, not instantly.
		gull = gull_at(host,145)
		gull.climb = true
		var elapsed: float = 0.0
		while gull.position.y > 65.0 and elapsed < 10.0:
			gull.aim = gull.position
			gull.tick(dt,0,0)
			elapsed += dt
		check.call(elapsed > 1.3 and elapsed < 3.0,"held flap needs several wingbeats to gain 80px at %dHz: %.2fs" % [hz,elapsed])
		var held_y: float = gull.position.y
		gull.queue_free()
		# Re-pressing every frame cannot beat the wingbeat cadence.
		gull = gull_at(host,145)
		for frame: int in int(elapsed*hz):
			gull.climb = frame%2 == 0
			gull.aim = gull.position
			gull.tick(dt,0,0)
		check.call(gull.position.y > held_y-6.0,"rapid re-pressing is no faster than holding at %dHz" % hz)
		gull.queue_free()
		# Sparse wingbeats cannot sustain height.
		gull = gull_at(host,100)
		for frame: int in hz*4:
			gull.climb = frame%(hz*2) == 0
			gull.aim = gull.position
			gull.tick(dt,0,0)
		check.call(gull.position.y > 100.0 or gull.state == BeachGull.State.GROUNDED,"sparse wingbeats lose height at %dHz" % hz)
		gull.queue_free()
		# Takeoff launch counts as the first wingbeat: no second boost right after it.
		gull = gull_at(host,float(Config.tuning.world.ground)-float(f.feet_offset))
		gull.state = BeachGull.State.GROUNDED
		gull.climb = true
		gull.tick(dt,0,0)
		check.call(is_equal_approx(gull.velocity.y,-float(f.takeoff_speed)+float(f.gravity)*dt),"takeoff is a single launch at %dHz" % hz)
		for frame: int in int(0.25*hz):
			gull.tick(dt,0,0)
		check.call(gull.velocity.y > -float(f.takeoff_speed),"no extra stroke within a quarter second of takeoff at %dHz" % hz)
		gull.queue_free()
		# Stroke state cannot leak into stun or dive.
		gull = gull_at(host,100)
		gull.climb = true
		gull.tick(dt,0,0)
		check.call(gull.stroke_left > 0.0,"stroke is under way after pressing flap")
		gull.stun()
		gull.tick(dt,0,0)
		check.call(gull.stroke_left == 0.0,"stun cancels the stroke")
		gull.queue_free()
		# Leaving a fast dive brakes with passive drag, with or without flapping.
		gull = gull_at(host,50,200)
		gull.velocity.x = 60
		gull.pullup()
		var worst_step: float = 0.0
		for frame: int in int(0.3*hz):
			var before: float = gull.velocity.y
			gull.tick(dt,0,0)
			worst_step = maxf(worst_step,absf(gull.velocity.y-before))
		check.call(worst_step*hz < 400.0 and gull.velocity.y < 200.0,"dive exit eases down without snapping at %dHz" % hz)
		gull.queue_free()
		# Wind extends a passive glide in either direction, but never holds the gull up.
		var calm: float = fall_time(host,hz,0,0.0)
		var breeze: float = fall_time(host,hz,1,0.65)
		var gust: float = fall_time(host,hz,-1,1.04)
		check.call(calm > 2.2 and calm < 3.5,"calm passive descent is weighted but not slow at %dHz: %.2fs" % [hz,calm])
		check.call(breeze > calm+0.3 and gust > breeze,"wind lengthens the glide in both directions at %dHz: %.2f/%.2f/%.2f" % [hz,calm,breeze,gust])
		check.call(gust < 20.0,"strongest gust still brings the gull down at %dHz" % hz)
		# A swoop with the wind is much faster, against it much slower; straight down is only nudged.
		var calm_dive: float = dive_impact(host,hz,0,0.0,1.0)
		var with_wind: float = dive_impact(host,hz,1,0.65,1.0)
		var against_wind: float = dive_impact(host,hz,1,0.65,-1.0)
		var mirrored: float = dive_impact(host,hz,-1,0.65,-1.0)
		check.call(with_wind > calm_dive*1.15 and against_wind < calm_dive*0.8,"swoops follow the wind at %dHz: %.0f/%.0f/%.0f" % [hz,against_wind,calm_dive,with_wind])
		var steep_against: float = dive_impact(host,hz,1,0.65,-0.27)
		check.call(steep_against > dive_impact(host,hz,0,0.0,-0.27)*0.85,"steep swoops stay strong into the wind at %dHz: %.0f" % [hz,steep_against])
		check.call(absf(mirrored-with_wind) < 3.0,"wind direction is symmetric at %dHz" % hz)
		var straight: float = dive_impact(host,hz,0,0.0)
		var straight_wind: float = dive_impact(host,hz,1,0.65)
		check.call(straight > float(Config.tuning.dive.crash_vertical_speed) and straight_wind > straight*0.8 and straight_wind < straight,"straight swoops stay dangerous in wind at %dHz" % hz)
		# Climbing out against the wind is hard; with it, easy.
		var climb_calm: float = climb_time(host,hz,1,0.0)
		var climb_head: float = climb_time(host,hz,1,-0.65)
		var climb_tail: float = climb_time(host,hz,1,0.65)
		check.call(climb_head > climb_calm*1.5 and climb_tail < climb_calm and climb_head < 8.0,"flap lift is harder into the wind at %dHz: %.2f/%.2f/%.2f" % [hz,climb_head,climb_calm,climb_tail])
	# Rivals hold cruise height without overshooting into the ceiling.
	var pilot: RivalPilot = RivalPilot.new()
	pilot.gull = gull_at(host,140)
	var lowest: float = 999.0
	for frame: int in 60*10:
		pilot.gull.climb = pilot.needs_height()
		pilot.gull.aim = pilot.gull.position
		pilot.gull.tick(1.0/60,0,0)
		if frame > 60*4:
			lowest = minf(lowest,pilot.gull.position.y)
	var cruise: float = float(Config.tuning.rival.cruise_y)
	check.call(lowest > float(f.min_y)+15.0 and pilot.gull.position.y < cruise+25.0,"rival settles near cruise height: low %.0f now %.0f" % [lowest,pilot.gull.position.y])
	pilot.gull.queue_free()
