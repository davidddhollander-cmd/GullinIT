extends RefCounted

static func actor(host: Node, at: Vector2, role: bool = false) -> BeachGull:
	var gull := BeachGull.new()
	gull.species = "great-black-backed" if role else "herring"
	gull.rival = role
	host.add_child(gull)
	gull.position = at
	gull.aim = at+Vector2(200,-60)
	return gull

static func run(host: Node, check: Callable) -> void:
	var distances: Array[float] = []
	for hz: int in [30,60,120]:
		for side: float in [-1.0,1.0]:
			var gull := actor(host,Vector2(300,154))
			gull.land()
			gull.climb = true
			gull.stun(-1.0,Vector2(300-side*16,160))
			check.call(gull.velocity.x*side>0 and gull.velocity.y<0,"kick launches up and away at %d Hz" % hz)
			var before: Vector2 = gull.position
			gull.stun(-1.0,Vector2(300+side*16,160))
			check.call(gull.velocity.x*side>0 and gull.position==before,"repeated hit cannot redirect active tumble")
			var peak_angle: float = 0.0
			var elapsed: float = 0.0
			while gull.state == BeachGull.State.STUNNED and elapsed<2.0:
				gull.dive(0)
				check.call(not gull.attempt_peck(),"tumble blocks dive and peck input")
				gull.tick(1.0/hz,0,0)
				peak_angle = maxf(peak_angle,absf(gull.sprite.rotation))
				check.call(gull.position.y<=gull.ground_y(),"tumble stays above terrain")
				elapsed += 1.0/hz
			var distance: float = (gull.position.x-300)*side
			distances.append(distance)
			check.call(distance>=50.0 and distance<=70.0,"short tumble travel: %.2f px at %d Hz" % [distance,hz])
			check.call(peak_angle>TAU and peak_angle<TAU*2,"tumble makes one to two body turns")
			check.call(gull.tumble_bounced,"ground kick has a small bounce")
			check.call(elapsed>=0.89 and elapsed<=0.94,"control returns in roughly 0.9 seconds")
			check.call(gull.state==BeachGull.State.GROUNDED and is_zero_approx(gull.sprite.rotation),"ground recovery is upright")
			check.call(gull.invulnerable>0.9,"recovery retains protection")
			gull.stun()
			check.call(gull.state!=BeachGull.State.STUNNED,"protected recovery cannot be stun locked")
			gull.queue_free()
	check.call(distances.max()-distances.min()<2.0,"tumble travel agrees across frame rates")
	var delayed := actor(host,Vector2(300,154))
	delayed.land()
	delayed.stun(-1.0,Vector2(280,160))
	delayed.tick(2.0,0,0)
	check.call(delayed.state==BeachGull.State.GROUNDED and delayed.position.x-300<=70.0,"delayed frame stops at the recovery deadline")
	delayed.queue_free()
	var aligned := actor(host,Vector2(300,154))
	aligned.velocity.x = 50.0
	aligned.stun(-1.0,Vector2(300,160))
	check.call(aligned.velocity.x<0.0,"vertically aligned hit knocks back against incoming motion")
	aligned.queue_free()
	for at: Vector2 in [Vector2(12,154),Vector2(float(Config.tuning.world.width)-12,154),Vector2(300,22),Vector2(300,95)]:
		var gull := actor(host,at,true)
		gull.setup_perches([{"type":"kiosk","x":300,"y":160}])
		gull.support = {"x":300,"y":115,"half_width":23,"pole":false}
		gull.stun(-1.0,at+Vector2(1 if at.x<100 else -1,0))
		for frame: int in 55:
			gull.tick(1.0/60,0,0)
		check.call(gull.state!=BeachGull.State.STUNNED and gull.support.is_empty(),"rival recovers from air, perch or edge impact")
		check.call(gull.position.x>=12 and gull.position.x<=float(Config.tuning.world.width)-12,"edge tumble stays inside world")
		check.call(gull.position.y>=float(Config.tuning.flight.min_y) and gull.position.y<=gull.ground_y(),"airborne tumble remains in bounds")
		gull.queue_free()
	var effects := BeachEffects.new()
	host.add_child(effects)
	var enabled: bool = Config.tuning.juice.particles
	Config.tuning.juice.particles = true
	var gull := actor(host,Vector2(300,154))
	gull.tumble_feathers.connect(effects.feather_burst)
	gull.stun(-1.0,Vector2(280,160))
	check.call(effects.particles.size()==int(Config.tuning.juice.feathers),"impact immediately emits generated feathers")
	var initial: Vector2 = effects.particles[0].at
	for frame: int in 30:
		gull.tick(1.0/60,0,0)
		effects.tick(1.0/60)
	check.call(effects.particles.size()>int(Config.tuning.juice.feathers),"tumble sheds feathers along moving body and bounce")
	check.call(effects.particles[0].at!=initial,"feathers move in world space")
	for item: Dictionary in effects.particles:
		check.call(item.feather and item.texture in BeachEffects.FEATHER_TEXTURES,"feathers use generated texture assets")
	for frame: int in 120:
		effects.tick(1.0/60)
	check.call(effects.particles.is_empty(),"feathers expire and clean up")
	Config.tuning.juice.particles = false
	effects.feather_burst(Vector2.ZERO,Vector2.ONE,8)
	check.call(effects.particles.is_empty(),"disabled particles suppress feathers")
	Config.tuning.juice.particles = enabled
	gull.queue_free()
	effects.queue_free()
	# Exercise the real adult attack entry point, not just direct stun calls.
	var adult := BeachTarget.new()
	adult.kind = "kiosk_customer"
	adult.position = Vector2(400,160)
	gull = actor(host,Vector2(410,148))
	adult.reaction.focus = gull
	adult.reaction._hit(adult)
	check.call(gull.state==BeachGull.State.STUNNED and gull.velocity.x>0,"adult swat supplies the attacker's position")
	gull.queue_free()
	adult.free()
