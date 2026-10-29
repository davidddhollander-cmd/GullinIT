extends RefCounted
## Drives the water-gun teenager directly: place gulls, tick, read state. No full run needed.
const DT: float = 1.0 / 60.0

static func _fresh(suite: Node, level: int) -> BeachGame:
	suite.main.start_level(level)
	var game: BeachGame = suite.main.game
	game.set_physics_process(false)
	game.running = true
	game.intro = 0.0
	return game

static func _put(gull: BeachGull, at: Vector2) -> void:
	gull.position = at
	gull.velocity = Vector2.ZERO
	gull.state = BeachGull.State.GLIDE
	gull.invulnerable = 0.0
	gull.visible = true

static func _park_all(game: BeachGame) -> void:
	for index: int in game.gulls.size():
		_put(game.gulls[index],Vector2(1250.0-index*20.0,30.0))

static func _reset(teen: WatergunTeen, game: BeachGame) -> void:
	teen.position.x = 640.0
	teen.home = Vector2(600.0,740.0)
	teen._patrol()
	teen.timer = 99.0
	teen.rearm = 0.0
	teen.shot_gap = 0.0
	teen.shots_fired = 0
	for shot: BeachWaterShot in teen.shots:
		shot.queue_free()
	teen.shots.clear()
	_park_all(game)

static func _run(teen: WatergunTeen, game: BeachGame, seconds: float) -> void:
	for i: int in int(seconds / DT):
		teen.tick(DT,game.gulls)

static func run(suite: Node, check: Callable) -> void:
	var t: Dictionary = Config.tuning.watergun_teen
	for number: int in [1, 2, 3, 6]:
		check.call(not Config.levels[number-1].has("watergun_teens"),"level %d has no water-gun teenager" % number)
	for number: int in [4, 5, 7]:
		var placed: Array = Config.levels[number-1].get("watergun_teens",[])
		check.call(placed.size() == 1,"level %d places one water-gun teenager" % number)
		var other: BeachGame = _fresh(suite,number)
		check.call(other.teens.size() == 1 and other.teens[0].get_parent() == other.actors,"level %d spawns the teenager as an actor" % number)
		check.call(other.spawner.targets.size() == Config.levels[number-1].spawns.filter(func(spawn: Dictionary) -> bool: return spawn.type != "off_lead_dog").size(),"level %d teenager is not a food target" % number)
		suite.main.clear_game()

	var game: BeachGame = _fresh(suite,4)
	var teen: WatergunTeen = game.teens[0]
	var player: BeachGull = game.player
	var rival: BeachGull = game.pilots[0].gull
	var frames: SpriteFrames = teen.sprite.sprite_frames
	check.call(frames.has_animation(&"shoot_high") and frames.has_animation(&"shoot_level") and frames.has_animation(&"shoot_low") and frames.has_animation(&"run") and frames.has_animation(&"alert"),"teenager frames carry the pursue and shoot clips")
	check.call(is_equal_approx(teen.sprite.scale.x,float(Config.sprites.watergun_teen.visual_scale)) and is_equal_approx(teen.position.y,float(Config.tuning.world.ground)),"teenager is drawn at its configured scale on the sand line")
	# Depth rule (AGENTS.md): feet level with or below a prop's base draw in front of it, feet above draw behind.
	var bench: Dictionary = Config.levels[3].props.filter(func(prop: Dictionary) -> bool: return prop.type == "beach_bench")[0]
	var base_y: float = float(bench.get("y",160))
	var bench_z: int = game.beach.prop_sprites[Config.levels[3].props.find(bench)].z_index
	check.call(game.spawner.depth_z(Vector2(float(bench.x),base_y+8.0),2) > bench_z,"a teenager in front of a bench draws over it")
	check.call(game.spawner.depth_z(Vector2(float(bench.x),base_y-8.0),2) < bench_z,"a teenager behind a bench draws under it")
	var spots: Array[int] = [0]
	var shots_seen: Array[int] = [0]
	var hits: Array[int] = [0]
	var splashes: Array[int] = [0]
	var quits: Array[int] = [0]
	var fired_at: Array[Vector2] = [Vector2.INF]
	teen.spotted.connect(func(_gull: BeachGull) -> void: spots[0] += 1)
	teen.fired.connect(func(shot: BeachWaterShot, _direction: Vector2) -> void:
		shots_seen[0] += 1
		fired_at[0] = shot.position
	)
	teen.hit.connect(func(_gull: BeachGull) -> void: hits[0] += 1)
	teen.splashed.connect(func(_at: Vector2) -> void: splashes[0] += 1)
	teen.gave_up.connect(func() -> void: quits[0] += 1)
	var level_y: float = teen.muzzle_level_y()

	# Patrol stays inside the home zone.
	_reset(teen,game)
	teen.resting = false
	var min_x: float = 9999.0
	var max_x: float = 0.0
	for i: int in 1800:
		teen.tick(DT,game.gulls)
		min_x = minf(min_x,teen.position.x)
		max_x = maxf(max_x,teen.position.x)
	check.call(min_x >= teen.home.x-0.5 and max_x <= teen.home.y+0.5 and spots[0] == 0 and teen.state != WatergunTeen.State.SPOT,"patrol wanders inside the home zone and fires at nothing")

	# Eligibility: stunned, invulnerable, too high and out-of-leash gulls are ignored.
	_reset(teen,game)
	_put(player,Vector2(teen.position.x+60.0,level_y))
	player.state = BeachGull.State.STUNNED
	teen.tick(DT,game.gulls)
	check.call(teen.state == WatergunTeen.State.PATROL,"a stunned gull is not a mark")
	_put(player,Vector2(teen.position.x+60.0,level_y))
	player.invulnerable = 1.0
	teen.tick(DT,game.gulls)
	check.call(teen.state == WatergunTeen.State.PATROL,"a gull in post-stun invulnerability is not a mark")
	_put(player,Vector2(teen.position.x+40.0,level_y-float(t.aim_max_dy)-10.0))
	teen.tick(DT,game.gulls)
	check.call(teen.state == WatergunTeen.State.PATROL,"a gull flying above aiming height is safe")
	teen.home = Vector2(450.0,460.0)
	_put(player,Vector2(teen.position.x+30.0,level_y))
	teen.tick(DT,game.gulls)
	check.call(teen.state == WatergunTeen.State.PATROL,"a gull inside notice_radius but outside the leash is ignored")
	teen.home = Vector2(600.0,740.0)
	_put(player,Vector2(teen.position.x+float(t.notice_radius)+10.0,level_y))
	teen.tick(DT,game.gulls)
	check.call(teen.state == WatergunTeen.State.PATROL,"a gull outside notice_radius is ignored")

	# Spot -> warning pause -> pursue.
	_reset(teen,game)
	_put(player,Vector2(teen.position.x+float(t.notice_radius)-5.0,level_y))
	teen.tick(DT,game.gulls)
	check.call(teen.state == WatergunTeen.State.SPOT and spots[0] == 1 and teen.target == player,"teenager spots a gull inside notice_radius")
	var start_x: float = teen.position.x
	_run(teen,game,float(t.alert_time)-0.1)
	check.call(teen.state == WatergunTeen.State.SPOT and is_equal_approx(teen.position.x,start_x),"the alert pause holds him still")
	_run(teen,game,0.15)
	check.call(teen.state == WatergunTeen.State.PURSUE,"he starts pursuing after the alert")
	var before: float = teen.position.x
	_run(teen,game,0.5)
	var speed: float = (teen.position.x-before)/0.5
	check.call(absf(speed-float(t.run_speed)) < 3.0 and speed > float(Config.tuning.flight.ground_speed) and speed < float(Config.tuning.flight.max_speed),"pursuit speed sits between gull walking and flying")

	# Aim pose follows the mark's height.
	check.call(teen.aim_clip_for(_at(player,level_y-30.0)) == &"shoot_high" and teen.aim_clip_for(_at(player,level_y)) == &"shoot_level" and teen.aim_clip_for(_at(player,level_y+30.0)) == &"shoot_low","aim clip is chosen from the gull's height")

	# Reach range, plant feet, hold the aim pose on its first frame.
	_reset(teen,game)
	_put(player,Vector2(teen.position.x+float(t.fire_range)-10.0,level_y))
	teen.state = WatergunTeen.State.PURSUE
	teen.target = player
	teen.tick(DT,game.gulls)
	check.call(teen.state == WatergunTeen.State.AIM and teen.sprite.animation == &"shoot_level" and teen.sprite.frame == 0 and shots_seen[0] == 0,"in range he plants his feet and holds the first aim frame")
	var aim_x: float = teen.position.x
	_run(teen,game,float(t.aim_time)-0.1)
	check.call(teen.state == WatergunTeen.State.AIM and is_equal_approx(teen.position.x,aim_x) and shots_seen[0] == 0,"the aim window is a visible telegraph before any shot")

	# Fire on the fire frame, from that frame's muzzle anchor.
	_run(teen,game,0.15)
	check.call(teen.state == WatergunTeen.State.FIRE and teen.sprite.frame == int(Config.sprites.watergun_teen.shooting.fire_frame_offset) and shots_seen[0] == 1 and teen.shots.size() == 1,"one shot spawns on the fire frame")
	var anchor: Array = Config.sprites.watergun_teen.shooting.muzzle_anchors_source_px.shoot_level[1]
	var expected: Vector2 = teen.position+Vector2(teen.facing*(float(anchor[0])-64.0)*float(Config.sprites.watergun_teen.visual_scale),float(Config.sprites.watergun_teen.sprite_offset_y)+(float(anchor[1])-64.0)*float(Config.sprites.watergun_teen.visual_scale))
	check.call(fired_at[0].distance_to(expected) < 0.01,"the shot starts at the fire frame's muzzle anchor")
	_run(teen,game,float(t.muzzle_time)+0.01)
	check.call(teen.state == WatergunTeen.State.RECOVER and teen.sprite.frame == 2,"he recovers on the last shoot frame")

	# The shot travels, hits the player and stuns them.
	_run(teen,game,1.0)
	check.call(hits[0] == 1 and player.state == BeachGull.State.STUNNED and teen.shots.is_empty() and splashes[0] >= 1,"a water shot stuns the player it reaches and splashes")

	# Rival gulls are marks too, and the nearer gull is chosen.
	hits[0] = 0
	_reset(teen,game)
	_put(rival,Vector2(teen.position.x+60.0,level_y))
	_put(player,Vector2(teen.position.x+120.0,level_y))
	teen.tick(DT,game.gulls)
	check.call(teen.target == rival,"he picks the nearest gull, which can be a rival")
	_run(teen,game,float(t.alert_time)+0.3)
	_run(teen,game,float(t.aim_time)+0.3)
	_run(teen,game,0.6)
	check.call(hits[0] == 1 and rival.state == BeachGull.State.STUNNED and player.state != BeachGull.State.STUNNED,"a water shot stuns a rival and spares the player")

	# A swerving gull can dodge: it leaves the shot line after the shot is fired.
	hits[0] = 0
	_reset(teen,game)
	_put(player,Vector2(teen.position.x+90.0,level_y))
	teen.state = WatergunTeen.State.PURSUE
	teen.target = player
	_run(teen,game,float(t.aim_time)+0.05)
	_put(player,Vector2(teen.position.x+90.0,level_y-60.0))
	_run(teen,game,1.0)
	check.call(hits[0] == 0 and player.state != BeachGull.State.STUNNED,"stepping off the shot line dodges it")

	# Out of water: give up, shout, then a rearm pause before he notices again.
	_reset(teen,game)
	_put(player,Vector2(teen.position.x+60.0,level_y))
	teen.state = WatergunTeen.State.PURSUE
	teen.target = player
	teen.shots_fired = int(t.shots_per_engagement)
	var quits_before: int = quits[0]
	teen.tick(DT,game.gulls)
	check.call(teen.state == WatergunTeen.State.GIVE_UP and quits[0] == quits_before+1 and teen.target == null,"he gives up once his shots are spent")
	_run(teen,game,float(t.give_up_time)+0.1)
	check.call(teen.state == WatergunTeen.State.PATROL,"after giving up he returns to patrol")
	teen.timer = 99.0
	teen.tick(DT,game.gulls)
	check.call(teen.state == WatergunTeen.State.PATROL,"he ignores gulls while rearming")
	_run(teen,game,teen.rearm-0.05)
	check.call(teen.state == WatergunTeen.State.PATROL,"he is still deaf to gulls just before the rearm ends")
	_run(teen,game,0.1)
	check.call(teen.state == WatergunTeen.State.SPOT,"he notices gulls again after rearming")

	# Pausing freezes the sprite.
	game.set_paused(true)
	teen.tick(DT,game.gulls)
	check.call(is_equal_approx(teen.sprite.speed_scale,0.0),"pausing freezes the teenager's animation")
	game.set_paused(false)
	game.set_physics_process(false)

	# Shot lifecycle on its own: it lands on the sand and ends.
	var shot: BeachWaterShot = BeachWaterShot.new()
	game.actors.add_child(shot)
	shot.setup(Vector2(100.0,float(Config.tuning.world.ground)-10.0),Vector2(0.0,100.0),150.0,Vector2(10.0,7.0))
	var empty: Array[BeachGull] = []
	check.call(shot.tick(0.5,empty) == null and shot.landed and is_equal_approx(shot.position.y,float(Config.tuning.world.ground)),"a water shot ends on the sand line")
	shot.queue_free()
	suite.main.clear_game()
	await suite.settle()

static func _at(gull: BeachGull, y: float) -> BeachGull:
	gull.position.y = y
	return gull
