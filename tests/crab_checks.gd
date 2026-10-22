extends RefCounted

static func make_game(host: Node) -> BeachGame:
	var game := BeachGame.new()
	host.add_child(game)
	var level: Dictionary = Config.levels[1].duplicate(true)
	level.spawns = []
	level.rivals = []
	level.props = []
	level.crabs = {"enabled":false}
	game.setup(level,false)
	game.set_physics_process(false)
	game.set_process_unhandled_input(false)
	game.running = true
	game.intro = 0
	game.player.position = Vector2(50,50)
	return game

static func run(host: Node, check: Callable) -> void:
	check.call(FileAccess.file_exists("res://assets/sprites/crabs-transparent.png"),"original supplied crab sheet remains intact")
	for color: String in ["red","blue"]:
		var frames: SpriteFrames = Config.frames("crab_"+color)
		check.call(frames.get_frame_count(&"idle")==6,color+" crab uses all six supplied poses")
		for frame: int in 6:
			var image: Image = frames.get_frame_texture(&"idle",frame).get_image()
			var bounds: Rect2i = image.get_used_rect()
			check.call(bounds.has_area() and bounds.end.y==40 and bounds.size.x<=40 and bounds.size.y<=32,color+" crab retains sharper complete artwork and aligned feet "+str(frame))
	for id: String in Config.foods:
		if id!="crab":
			check.call(int(Config.foods.crab.points)>int(Config.foods[id].points),"crab base points exceed "+id)
	for level: Dictionary in Config.levels:
		check.call(bool(level.get("crabs",{}).get("enabled",false)),"level "+str(level.id)+" retains crab configuration")
	for origin: String in ["sea","left","right"]:
		var game: BeachGame = make_game(host)
		var rng_before: int = game.rng.state
		var crab: BeachCrab = game.crabs.spawn(origin,480,origin=="right")
		check.call(crab!=null and not crab.food,"crab visibly arrives before it becomes catchable: "+origin)
		if origin=="left":
			check.call(crab.position.x<320,"left arrival begins outside current screen, within the world")
		elif origin=="right":
			check.call(crab.position.x>640,"right arrival begins outside current screen, within the world")
		else:
			check.call(crab.position.y==132,"sea arrival begins at the shoreline")
		if origin=="sea":
			var initial: float = crab.sprite.scale.x
			check.call(is_equal_approx(initial,crab.full_scale*0.35),"sea crab starts at 35 percent size")
			game.crabs.tick(0.4,480)
			check.call(crab.sprite.scale.x>initial and crab.sprite.scale.x<crab.full_scale and not crab.food,"sea crab grows toward the viewer before becoming catchable")
			check.call(is_zero_approx(crab.sprite.position.y+20.0*crab.sprite.scale.x),"perspective growth keeps feet on the surface")
			game.crabs.tick(0.61,480)
		else:
			check.call(is_equal_approx(crab.sprite.scale.x,crab.full_scale*0.9),"screen-edge crabs enter at rear-lane size")
			game.crabs.tick(1.01,480)
		check.call(is_equal_approx(crab.sprite.scale.x,crab.full_scale*0.9),"crab reaches rear-lane size on the sand")
		check.call(crab.phase==BeachCrab.Phase.SCUTTLE and crab.food and crab.position.y==146,"crab emerges into the second lane and becomes catchable: "+origin)
		game.crabs.tick(0.31,480)
		var before: Vector2 = crab.position
		var pose: int = crab.sprite.frame
		game.crabs.tick(0.2,480)
		check.call(crab.position.x!=before.x and crab.sprite.frame!=pose,"live crab scuttles and animates: "+origin)
		check.call(game.rng.state==rng_before,"crab spawning leaves gameplay RNG untouched")
		game.queue_free()
		await host.get_tree().process_frame
	for scenario: String in ["peck","dive","no_peck","walk","full","pause","expiry"]:
		var game: BeachGame = make_game(host)
		var crab: BeachCrab = game.crabs.spawn("sea",160)
		game.crabs.tick(1.01,160)
		var player: BeachGull = game.player
		player.upwind = false
		if scenario=="peck":
			for frame: int in 160:
				game.crabs.tick(0.05,160)
				if crab.position.y==crab.front_y:
					break
			player.state = BeachGull.State.GROUNDED
			player.facing = 1
			player.position = Vector2(crab.position.x-float(Config.tuning.dive.beak_offset),player.ground_y())
			game._peck()
			check.call(not crab.food and not crab in game.crabs.targets and player.art_event==&"peck","normal ground PECK catches and removes the crab exactly once")
		elif scenario in ["dive","no_peck","walk"]:
			player.state = BeachGull.State.STRIKE
			player.sweep_state = BeachGull.State.STRIKE
			player.peck_sweep_active = scenario!="no_peck"
			player.grounded_sweep = scenario=="walk"
			if scenario=="walk":
				player.sweep_state = BeachGull.State.GROUNDED
			player.direction = Vector2(0.8,0.6)
			player.previous_beak = crab.food_position()-Vector2(40,30)
			player.sweep_beak = crab.food_position()+Vector2(40,30)
			BeachCollisions.resolve(player,game.crabs.targets,[])
			check.call(crab.food==(scenario!="dive"),"crab requires a timed dive peck, not flight or walking contact: "+scenario)
		elif scenario=="full":
			player.digestion.collect("hotdog")
			check.call(not crab.take(player) and crab.food and game.crabs.targets.has(crab),"full stomach refuses a crab without consuming or removing it")
		elif scenario=="pause":
			var clock: float = crab.clock
			game.set_paused(true)
			await host.get_tree().process_frame
			check.call(crab.clock==clock,"pause freezes crab movement and sprite animation")
			game.effects.freeze = 1.0
			game._physics_process(0.1)
			check.call(crab.clock==clock,"hit freeze stops crab simulation")
			game.effects.freeze = 0
			game.running = false
			game._physics_process(0.1)
			check.call(crab.clock==clock,"results do not advance crabs")
		elif scenario=="expiry":
			game.crabs.tick(float(Config.tuning.crabs.lifetime),160)
			check.call(crab.phase==BeachCrab.Phase.EXIT and not crab.food,"expired crab retreats without remaining collectible")
			game.crabs.tick(0.5,160)
			check.call(crab.sprite.scale.x<crab.full_scale,"retreating crab shrinks toward the water")
			game.crabs.tick(0.6,160)
			check.call(game.crabs.targets.is_empty(),"retreat removes crab from active targets")
		if scenario in ["peck","dive"]:
			check.call(player.digestion.snacks.size()==1 and game.score.points==0,"crab catch queues normal digestion before score: "+scenario)
			check.call(not crab.take(player),"same crab cannot be caught twice")
			player.digestion.tick(3.1,false)
			check.call(game.score.points==100 and game.score.items==1 and game.score.bonuses.Handover==0,"crab awards 100 once without a stall bonus: "+scenario)
		game.queue_free()
		await host.get_tree().process_frame
		check.call(not is_instance_valid(crab),"level teardown frees crab actor: "+scenario)
	var game: BeachGame = make_game(host)
	game.crabs.enabled = true
	game.crabs.wait = 0
	game.crabs.tick(0.1,480,false)
	check.call(game.crabs.targets.is_empty(),"active tutorial suppresses ambient crab arrivals")
	game.crabs.tick(0.1,480,true)
	check.call(game.crabs.targets.size()==1,"configured crab wave starts after the tutorial")
	game.crabs.spawn("right",480)
	check.call(game.crabs.spawn("left",480)==null and game.crabs.targets.size()==2,"crab population respects its cap")
	game.queue_free()
	await host.get_tree().process_frame
	await preload("res://tests/crab_habitat_checks.gd").run(host,check)
