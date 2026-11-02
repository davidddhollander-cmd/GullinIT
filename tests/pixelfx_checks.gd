extends RefCounted
## pixelfx spike: the hit-spark sheet is registered, spawns on snatch contact, mirrors for leftward
## snatches, frees itself, and the tuning flag turns it off.

static func run(suite: Node, check: Callable) -> void:
	for spec: Dictionary in [
		{"id":"pixelfx_hit_spark","frames":13},
		{"id":"pixelfx_crit_hit","frames":25},
		{"id":"pixelfx_poof","frames":43},
		{"id":"pixelfx_collect_burst","frames":33},
		{"id":"pixelfx_heavy_landing","frames":36},
		{"id":"pixelfx_stunned","frames":60,"loop":true},
	]:
		var id: String = spec.id
		check.call(Config.sprites.has(id) and FileAccess.file_exists(str(Config.sprites[id].file)),"%s sprite entry and sheet exist" % id)
		var frames: SpriteFrames = Config.frames(id)
		check.call(frames.has_animation(&"burst") and frames.get_frame_count(&"burst") == int(spec.frames) and frames.get_animation_loop(&"burst") == bool(spec.get("loop",false)),
			"%s exposes a %d-frame burst (one-shot unless flagged loop)" % [id,int(spec.frames)])
		var entry: Dictionary = Config.sprites[id]
		var texture: Texture2D = load(entry.file) as Texture2D
		var columns: int = texture.get_width()/int(entry.frame_w)
		check.call(entry.has("pivot") and ceili(float(spec.frames)/float(columns))*int(entry.frame_h) == texture.get_height(),
			"%s has a pivot and its sheet is a whole grid of frames" % id)

	suite.main.start_level(1)
	var game: BeachGame = suite.main.game
	game.set_physics_process(false)
	var effects: BeachEffects = game.effects
	var right: AnimatedSprite2D = effects.pixelfx_hit_spark(Vector2(100,80),Vector2.RIGHT)
	var left: AnimatedSprite2D = effects.pixelfx_hit_spark(Vector2(100,80),Vector2.LEFT)
	check.call(right != null and left != null and right.z_index == 5 and not right.flip_h and left.flip_h,
		"hit spark sits in effect band 5 and mirrors for a leftward snatch")
	check.call(is_equal_approx(right.offset.x,-left.offset.x),
		"mirroring keeps the pivot on the contact point")

	var before: int = effects.get_child_count()
	effects.snatch_contact(Vector2(90,70),Vector2.RIGHT,false)
	check.call(effects.get_child_count() == before+1, "snatch contact spawns one pixelfx hit spark")

	var before_bonus: int = effects.get_child_count()
	effects.snatch_contact(Vector2(90,70),Vector2.RIGHT,true)
	check.call(effects.get_child_count() == before_bonus+2, "a bonus snatch adds the crit burst to the hit spark")
	var before_bin: int = effects.get_child_count()
	effects.release_burst(Vector2(120,100))
	check.call(effects.get_child_count() == before_bin, "a non-bin release burst spawns no poof")
	effects.release_burst(Vector2(120,100),true)
	check.call(effects.get_child_count() == before_bin, "poof is parked: a bin burst spawns no pixelfx sprite")
	check.call(is_equal_approx(right.scale.x,1.25) and is_equal_approx(effects.pixelfx("pixelfx_collect_burst",Vector2(100,80)).scale.x,0.5),
		"data scale applies: hit spark 1.25x, collect burst 0.5x")
	var crumb: AnimatedSprite2D = effects.collect_burst(Vector2(100,80),"crumbs")
	var dog: AnimatedSprite2D = effects.collect_burst(Vector2(100,80),"hotdog")
	var pie: AnimatedSprite2D = effects.collect_burst(Vector2(100,80),"pizza_slice_cheese")
	check.call(crumb.scale.x < effects.collect_burst(Vector2(100,80),"crisps_bag").scale.x and effects.collect_burst(Vector2(100,80),"crisps_bag").scale.x < dog.scale.x and is_equal_approx(dog.scale.x,0.5) and pie.scale.x >= dog.scale.x - 0.001,
		"the collect burst grows with the food: crumbs smallest, hot dog and pizza full size")
	var gold: AnimatedSprite2D = effects.pixelfx("pixelfx_collect_burst",Vector2(100,80))
	check.call(gold != null and gold.animation == &"burst" and gold.z_index == 5, "collect burst plays in effect band 5")
	var mirrored_offset: float = effects.pixelfx("pixelfx_crit_hit",Vector2(100,80),Vector2.LEFT).offset.x
	check.call(is_equal_approx(mirrored_offset,-effects.pixelfx("pixelfx_crit_hit",Vector2(100,80)).offset.x),
		"every sheet mirrors its pivot offset for leftward heading")

	# Hard landing, splash and stun stars hang off the existing game events.
	var landed: Array = []
	game.player.hard_landed.connect(func(at: Vector2) -> void: landed.append(at))
	game.player.state = BeachGull.State.STRIKE
	game.player.velocity = Vector2(0,float(Config.tuning.dive.hard_landing_speed)+10.0)
	game.player.land()
	check.call(landed.size() == 1, "a dive-speed landing emits hard_landed")
	game.player.state = BeachGull.State.GLIDE
	game.player.velocity = Vector2(0,20)
	game.player.land()
	check.call(landed.size() == 1, "a gentle landing does not")
	game.player.invulnerable = 0.0
	game.player.stun(0.9)
	var stars: AnimatedSprite2D = game.player.get_node_or_null("PixelfxStunned")
	check.call(stars != null and stars.z_index == 5 and not stars.z_as_relative and stars.sprite_frames.get_animation_loop(&"burst"),
		"a stunned gull wears looping stars in effect band 5")
	# Dive juice: release ring + camera shove, speed-scaled beak trail.
	effects.particles.clear()
	effects.kick = Vector2.ZERO
	effects.dive_release(Vector2(100,80),Vector2.RIGHT)
	check.call(effects.particles.size() == 2 and effects.particles[0].has("grow") and effects.kick.x > 0.0, "dive release adds rings and a camera shove along the dive")
	effects.kick = effects.kick.move_toward(Vector2.ZERO,10.0)
	check.call(effects.kick == Vector2.ZERO, "the shove decays to zero")
	effects.particles.clear()
	effects.dive_trail(Vector2(100,80),Vector2.RIGHT,float(Config.tuning.juice.dive_trail_min_speed)-1.0,0.1)
	check.call(effects.particles.is_empty(), "no beak trail below the trail speed")
	effects.dive_trail(Vector2(100,80),Vector2.RIGHT,float(Config.tuning.dive.max_speed),0.1)
	var fast_scale: float = float(effects.particles[0].length)
	effects.particles.clear()
	effects.dive_trail(Vector2(100,80),Vector2.RIGHT,float(Config.tuning.juice.dive_trail_min_speed)+20.0,0.1)
	check.call(not effects.particles.is_empty() and fast_scale > float(effects.particles[0].length), "the beak trail grows with dive speed")
	effects.particles.clear()

	# Wind lines: none in calm air, streaks and sand once the gull feels a real wind, none when the flag is off.
	effects.particles.clear()
	game.player.wind_force = 0.0
	effects.wind_tick(1.0,400.0,game.player)
	check.call(effects.particles.is_empty(), "calm air spawns no wind lines")
	game.player.wind_force = 1.0
	effects.wind_tick(1.0,400.0,game.player)
	var wind_streaks: int = 0
	var wind_sand: int = 0
	for item: Dictionary in effects.particles:
		wind_streaks += 1 if item.get("streak",false) else 0
		wind_sand += 1 if item.get("sand",false) else 0
		check.call(not item.get("streak",false) or float(item.dir.x) > 0.0, "gust lines blow with the wind")
	check.call(wind_streaks > 0 and wind_sand > 0, "a strong wind spawns gust lines and skating sand")
	Config.tuning.juice.wind_streaks = false
	effects.particles.clear()
	effects.wind_tick(1.0,400.0,game.player)
	check.call(effects.particles.is_empty(), "juice.wind_streaks turns the wind lines off")
	Config.tuning.juice.wind_streaks = true
	game.player.wind_force = 0.0
	effects.particles.clear()

	Config.tuning.juice.pixelfx = false
	check.call(effects.pixelfx_hit_spark(Vector2(100,80),Vector2.RIGHT) == null, "the juice.pixelfx flag turns the spark off")
	Config.tuning.juice.pixelfx = true

	await suite.get_tree().create_timer(0.6).timeout
	check.call(not is_instance_valid(right) and not is_instance_valid(left),
		"hit sparks free themselves after the animation ends")
	suite.main.clear_game()
	await suite.settle()
