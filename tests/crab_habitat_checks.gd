extends RefCounted

static func population(host: Node, definition: Dictionary = {}) -> CrabPopulation:
	var level: Dictionary = definition.duplicate(true) if not definition.is_empty() else {"seed":7103,"world":{"width":1280,"promenade_start":800,"pier_start":960},"crabs":{"enabled":false}}
	level.crabs = {"enabled":false}
	var result := CrabPopulation.new()
	host.add_child(result)
	result.setup(level,[],BeachSpawner.new())
	return result

static func person(host: Node, source: BeachSpawner, x: float) -> BeachTarget:
	var target := BeachTarget.new()
	target.kind = "kiosk_customer"
	target.position = Vector2(x,160)
	target.hide()
	host.add_child(target)
	source.targets.append(target)
	return target

static func run(host: Node, check: Callable) -> void:
	# Real per-level boundaries, including beach-only opening maps and level 3's
	# early boardwalk. A camera on a boardwalk must not drag crabs along with it.
	for level: Dictionary in Config.levels:
		var pop: CrabPopulation = population(host,level)
		var expected_end: float = minf(float(level.get("world",{}).get("promenade_start",Config.default_world.promenade_start)),float(level.get("world",{}).get("width",Config.default_world.width)))-12.0
		check.call(is_equal_approx(pop.beach_bounds.y,expected_end),"crab habitat follows level boundary: "+str(level.id))
		var valid: bool = true
		var arrivals: int = 0
		for camera: float in [160.0,400.0,700.0,1100.0]:
			for origin: String in ["sea","left","right"]:
				var crab: BeachCrab = pop.spawn(origin,camera)
				if crab!=null:
					arrivals += 1
					valid = valid and crab.position.x>=pop.beach_bounds.x and crab.position.x<=expected_end and crab.home_bounds.x>=pop.beach_bounds.x and crab.home_bounds.y<=expected_end
					for frame: int in 80:
						pop.tick(0.05,camera)
						valid = valid and crab.position.x>=crab.home_bounds.x and crab.position.x<=crab.home_bounds.y
					pop.remove(crab)
		check.call(valid and arrivals>0,"all crab entries and walks remain on sand: "+str(level.id))
		pop.queue_free()
		await host.get_tree().process_frame

	var pop: CrabPopulation = population(host)
	check.call(pop.spawn("sea",1100)==null and pop.spawn("right",1100)==null,"boardwalk-only view defers arrivals instead of spawning on wood")
	pop.scenery = [{"type":"kiosk","x":220},{"type":"wheelie_bin","x":450}]
	check.call(not pop.clear_lane(220) and not pop.clear_lane(450) and pop.clear_lane(100),"quiet habitat excludes stalls and active bin interactions")
	var owner: BeachTarget = person(host,pop.people_source,110)
	owner.kind = "sunbather"
	owner.stash_home_x = 300
	check.call(not pop.clear_lane(110) and not pop.clear_lane(300),"quiet spots exclude both people and their unattended towel/bag anchors")
	owner.kind = "picnic_family"
	owner.family_home = 550
	check.call(not pop.clear_lane(550),"family picnic anchor remains excluded during shopping")
	owner.queue_free()
	pop.queue_free()
	await host.get_tree().process_frame

	pop = population(host)
	var crowd: Array[BeachTarget] = []
	for x: int in range(20,800,60):
		crowd.append(person(host,pop.people_source,float(x)))
	pop.enabled = true
	pop.wait = 0.0
	pop.tick(0.1,160)
	check.call(pop.targets.is_empty() and pop.wait>0.0 and pop.serial==0,"crowded beach delays arrival without advancing the entry sequence")
	for target: BeachTarget in crowd:
		target.queue_free()
	pop.people_source.targets.clear()
	pop.tick(2.1,160)
	check.call(pop.targets.size()==1,"arrival resumes after a quiet patch becomes available")
	pop.queue_free()
	await host.get_tree().process_frame

	pop = population(host)
	pop.settings.lifetime = 60.0
	var crab: BeachCrab = pop.spawn("sea",160)
	pop.tick(1.01,160)
	var anchor: float = crab.start.x
	var rear_frames: int = 0
	var front_frames: int = 0
	var bounded: bool = true
	var pauses: int = 0
	for frame: int in 600:
		var before: float = crab.position.x
		pop.tick(0.05,160)
		bounded = bounded and crab.position.x>=crab.home_bounds.x and crab.position.x<=crab.home_bounds.y and absf(crab.position.x-anchor)<=60.01
		if crab.position.y<(crab.rear_y+crab.front_y)*0.5:
			rear_frames += 1
		if crab.position.y==crab.front_y:
			front_frames += 1
		if crab.activity==BeachCrab.Activity.PAUSE and is_equal_approx(before,crab.position.x):
			pauses += 1
	check.call(bounded,"crabs retain a fixed local walking radius over repeated trips")
	check.call(rear_frames>390 and rear_frames<550 and front_frames>0,"crabs linger in the rear lane but make short visits to the front")
	check.call(pauses>0,"foraging includes stationary pauses")
	check.call(is_zero_approx(crab.sprite.position.y+20.0*crab.sprite.scale.x),"lane changes keep supplied artwork anchored at the feet")
	pop.queue_free()
	await host.get_tree().process_frame

	# The rear lane uses actual position for catches, not a cosmetic offset.
	var game := BeachGame.new()
	host.add_child(game)
	var level: Dictionary = Config.levels[1].duplicate(true)
	level.spawns = []
	level.props = []
	level.rivals = []
	level.crabs = {"enabled":false}
	game.setup(level,false)
	game.set_physics_process(false)
	game.set_process_unhandled_input(false)
	crab = game.crabs.spawn("sea",160)
	game.crabs.tick(1.01,160)
	game.player.state = BeachGull.State.GROUNDED
	game.player.position = Vector2(crab.position.x-float(Config.tuning.dive.beak_offset),game.player.ground_y())
	game.player.facing = 1
	game._peck()
	check.call(crab.food and game.player.digestion.snacks.is_empty(),"ground peck cannot secretly reach a crab in the farther lane")
	check.call(game.player.art_event==&"peck","missed ground peck still displays the normal peck animation")
	game.player.state = BeachGull.State.STRIKE
	game.player.sweep_state = BeachGull.State.STRIKE
	game.player.peck_sweep_active = true
	game.player.grounded_sweep = false
	game.player.direction = Vector2(0.8,0.6)
	game.player.previous_beak = crab.food_position()-Vector2(20,15)
	game.player.sweep_beak = crab.food_position()+Vector2(20,15)
	BeachCollisions.resolve(game.player,game.crabs.targets,[])
	check.call(not crab.food and game.player.digestion.snacks.size()==1,"timed dive catches the rear-lane crab at its visible position")
	game.queue_free()
	await host.get_tree().process_frame

	pop = population(host)
	crab = pop.spawn("sea",160)
	pop.tick(1.01,160)
	var gull := BeachGull.new()
	host.add_child(gull)
	gull.position = Vector2(crab.position.x-20,70)
	var gulls: Array[BeachGull] = [gull]
	pop.tick(0.1,160,true,gulls)
	check.call(crab.activity!=BeachCrab.Activity.NOTICE,"high flight does not scare crabs")
	gull.position.y = 145
	var before: Vector2 = crab.position
	pop.tick(0.05,160,true,gulls)
	check.call(crab.activity==BeachCrab.Activity.NOTICE and crab.position==before and crab.food,"low approach gets a visible catchable notice pause")
	for frame: int in 6:
		pop.tick(0.05,160,true,gulls)
	check.call(crab.activity==BeachCrab.Activity.ESCAPE and crab.food,"sustained threat starts a catchable escape burst")
	var escape_x: float = crab.escape_destination
	var burst_time: float = crab.activity_time
	crab.knock_food(gull)
	check.call(crab.escape_destination==escape_x and crab.activity_time==burst_time and not crab.dropped_pending,"a second missed peck cannot reset an escape or create food")
	gull.position = Vector2(1000,70)
	for frame: int in 40:
		pop.tick(0.05,160,true,gulls)
	check.call(crab.phase==BeachCrab.Phase.SCUTTLE and crab.activity in [BeachCrab.Activity.WALK,BeachCrab.Activity.PAUSE],"crab settles and resumes its local routine when the gull leaves")
	gull.position = Vector2(crab.position.x-10,145)
	for frame: int in 60:
		pop.tick(0.05,160,true,gulls)
		gull.position.x = crab.position.x-10
		if crab.phase==BeachCrab.Phase.EXIT:
			break
	check.call(crab.phase==BeachCrab.Phase.EXIT and not crab.food,"persistent pressure produces sea retreat instead of endless bursts")
	check.call(gull.state!=BeachGull.State.STUNNED,"crab encounters never pinch or stun gulls")
	gull.queue_free()
	pop.queue_free()
	await host.get_tree().process_frame

	pop = population(host)
	crab = pop.spawn("sea",160)
	pop.tick(1.01,160)
	owner = person(host,pop.people_source,crab.position.x+20)
	pop.tick(0.1,160)
	check.call(crab.activity==BeachCrab.Activity.NOTICE,"approaching human triggers a notice cue")
	pop.tick(0.21,160)
	check.call(crab.phase==BeachCrab.Phase.EXIT and not crab.food,"human entering quiet pocket triggers prompt sea retreat")
	var retreat_start: Vector2 = crab.position
	pop.tick(0.2,160)
	check.call(crab.position.x==retreat_start.x and crab.position.y<retreat_start.y and crab.position.y>132 and crab.sprite.modulate.a>0,"retreat follows a short continuous sandy route without teleporting")
	pop.tick(0.51,160)
	check.call(pop.targets.is_empty(),"short sea retreat removes the actor")
	owner.queue_free()
	pop.queue_free()
	await host.get_tree().process_frame

	var first: CrabPopulation = population(host)
	var second: CrabPopulation = population(host)
	var a: BeachCrab = first.spawn("sea",160)
	var b: BeachCrab = second.spawn("sea",160)
	for frame: int in 160:
		first.tick(0.05,160)
		second.tick(0.05,160)
	check.call(a.position==b.position and a.home_bounds==b.home_bounds and a.activity==b.activity,"same level seed reproduces crab habitat, lanes and routine")
	first.queue_free()
	second.queue_free()
	await host.get_tree().process_frame
