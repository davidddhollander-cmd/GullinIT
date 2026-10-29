extends RefCounted
## Generated water effects: registered atlas animations, projectile presentation and
## one-shot cleanup. Gameplay targeting and stun behaviour remain in the teen tests.

static func run(suite: Node, check: Callable) -> void:
	for spec: Dictionary in [
		{"id":"water_stream","clip":&"travel","frames":4,"loop":true},
		{"id":"water_muzzle","clip":&"burst","frames":3,"loop":false},
		{"id":"water_splash","clip":&"impact","frames":5,"loop":false},
	]:
		var id: String = spec.id
		var clip: StringName = spec.clip
		check.call(Config.sprites.has(id) and FileAccess.file_exists(str(Config.sprites[id].file)),
			"%s generated sprite entry and sheet exist" % id)
		var frames: SpriteFrames = Config.frames(id)
		check.call(frames.has_animation(clip) and frames.get_frame_count(clip) == int(spec.frames),
			"%s exposes the expected %d-frame animation" % [id,int(spec.frames)])
		check.call(frames.get_animation_loop(clip) == bool(spec.loop),
			"%s loop mode matches its runtime role" % id)

	suite.main.start_level(4)
	var game: BeachGame = suite.main.game
	game.set_physics_process(false)
	game.running = true
	game.intro = 0.0
	var teen: WatergunTeen = game.teens[0]
	var target: BeachGull = game.player
	target.position = Vector2(teen.position.x+60.0,teen.muzzle_level_y())
	target.velocity = Vector2.ZERO
	target.state = BeachGull.State.GLIDE
	target.invulnerable = 0.0
	teen.target = target
	teen.facing = 1.0
	teen._fire()
	var shot: BeachWaterShot = teen.shots[0]
	check.call(shot.stream != null and shot.stream.get_parent() == shot and shot.stream.animation == &"travel" and shot.stream.is_playing(),
		"firing creates a shot with the looping animated water stream")
	check.call(is_equal_approx(shot.stream.rotation,shot.velocity.angle()),
		"the stream points along the projectile velocity")

	var muzzle: AnimatedSprite2D = game.effects.water_muzzle(Vector2(100,70),Vector2.LEFT)
	check.call(muzzle != null and muzzle.animation == &"burst" and muzzle.flip_h and is_zero_approx(muzzle.rotation),
		"the muzzle one-shot uses generated art and mirrors along a leftward shot")
	var splash: AnimatedSprite2D = game.effects.water_splash(Vector2(120,80))
	check.call(splash != null and splash.animation == &"impact" and splash.is_playing(),
		"water splash spawns as a generated one-shot animation")
	await suite.get_tree().create_timer(0.5).timeout
	check.call(not is_instance_valid(muzzle) and not is_instance_valid(splash),
		"muzzle and splash free themselves after their animations finish")

	suite.main.clear_game()
	await suite.settle()
