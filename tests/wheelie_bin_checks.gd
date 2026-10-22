extends RefCounted
## Wheelie bins share finite bin contents but require the gull to stand on their lid.

const SHED_TYPES: Array[String] = ["beach_hut", "kiosk", "hotdog_stand"]

static func run(suite: Node, check: Callable) -> void:
	check.call(Config.sprites.has("wheelie_bin"),"wheelie bin sprite is registered")
	for level: Dictionary in Config.levels:
		var wheelies: Array[Dictionary] = []
		var sheds: Array[Dictionary] = []
		for prop: Dictionary in level.props:
			if prop.type == "wheelie_bin":
				wheelies.append(prop)
			elif str(prop.type) in SHED_TYPES:
				sheds.append(prop)
		var expected_count: int = 4 if int(level.id)==3 else 1
		check.call(wheelies.size()==expected_count,"level %d has %d wheelie bin%s" % [int(level.id),expected_count,"" if expected_count==1 else "s"])
		if wheelies.size()!=expected_count or sheds.is_empty():
			continue
		var closest: float = INF
		for shed: Dictionary in sheds:
			for wheelie: Dictionary in wheelies:
				closest = minf(closest,absf(float(wheelie.x)-float(shed.x)))
		check.call(closest<=50.0,"level %d keeps a wheelie bin beside a shed" % int(level.id))
		for wheelie: Dictionary in wheelies:
			for prop: Dictionary in level.props:
				if prop == wheelie or str(prop.type) in SHED_TYPES:
					continue
				check.call(absf(float(wheelie.x)-float(prop.x))>=24.0,"level %d wheelie bin clears other scenery" % int(level.id))
		if int(level.id)==3:
			var right_end_bins: Array[Dictionary] = wheelies.filter(func(wheelie: Dictionary) -> bool: return float(wheelie.x)>=float(level.world.width)-60.0)
			check.call(right_end_bins.size()==3,"level 3 lines up three wheelie bins at the complete right end")

	suite.main.start_level(1)
	var game: BeachGame = suite.main.game
	game.set_physics_process(false)
	game.intro = 0.0
	game.running = true
	var raids: BeachStashRaids = game.stash_raids
	var gull: BeachGull = game.player
	var wheelie: Dictionary = {}
	var ordinary: Dictionary = {}
	for bin: Dictionary in raids.bins:
		if bin.type == "wheelie_bin":
			wheelie = bin
		elif bin.type == "bin":
			ordinary = bin
	check.call(not wheelie.is_empty() and not ordinary.is_empty(),"level exposes ordinary and wheelie bins to the shared raid system")
	if wheelie.is_empty() or ordinary.is_empty():
		suite.main.clear_game()
		await suite.settle()
		return
	var ordinary_capacity: int = int(Config.tuning.world.bin_stash_size)
	var wheelie_capacity: int = ordinary_capacity*int(Config.tuning.world.wheelie_bin_stash_multiplier)
	check.call(int(ordinary.capacity)==ordinary_capacity and int(ordinary.remaining)==ordinary_capacity,"ordinary bin keeps the standard finite capacity")
	check.call(int(wheelie.capacity)==wheelie_capacity and int(wheelie.remaining)==wheelie_capacity,"wheelie bin stores twice as much as the ordinary bin")

	# Being beside a wheelie bin is deliberately insufficient, even inside peck reach.
	gull.support = {}
	gull.state = BeachGull.State.GROUNDED
	gull.position = Vector2(float(wheelie.x)-10.0,gull.ground_y())
	gull.facing = 1.0
	var starting_stock: int = int(wheelie.remaining)
	check.call(raids.nearby_bin(true).is_empty(),"gull beside wheelie bin cannot target its contents")
	check.call(not raids.peck() and int(wheelie.remaining)==starting_stock,"beside-the-bin peck leaves wheelie contents untouched")

	var lid: Dictionary = {}
	for surface: Dictionary in gull.perch_surfaces:
		if str(surface.get("prop_type","")) == "wheelie_bin" and absf(float(surface.x)-float(wheelie.x))<0.1:
			lid = surface
	check.call(not lid.is_empty(),"wheelie bin registers a landable lid surface")
	if not lid.is_empty():
		gull.support = lid
		gull.state = BeachGull.State.GLIDE
		gull.position = Vector2(float(lid.x),float(lid.y)-float(Config.tuning.flight.feet_offset))
		gull.land()
		gull.facing = 1.0
		check.call(raids.nearby_bin()==wheelie,"landing on the wheelie lid unlocks its contents")
		for tap: int in int(Config.tuning.world.bin_pecks):
			raids.peck_cooldown = 0.0
			check.call(raids.peck(),"wheelie bin accepts lid peck %d" % (tap+1))
		check.call(int(wheelie.remaining)==starting_stock-int(Config.tuning.world.bin_burst),"wheelie bin releases the normal finite burst")
		check.call(raids.items.size()==int(Config.tuning.world.bin_burst),"wheelie bin uses the normal scatter count")
		check.call(not raids.items.is_empty() and is_equal_approx(float(raids.items[0].position.y),float(wheelie.content_y)+6.0),"wheelie contents emerge from its raised lid")
		wheelie.remaining = 1
		game.lesson = 3
		game._training_advance()
		check.call(int(wheelie.remaining)==wheelie_capacity,"tutorial reset restores the wheelie bin's larger capacity")

	# Ordinary bins retain their existing grounded, beside-the-bin interaction.
	raids.items.clear()
	gull.support = {}
	gull.state = BeachGull.State.GROUNDED
	gull.position = Vector2(float(ordinary.x)-10.0,gull.ground_y())
	gull.facing = 1.0
	raids.peck_cooldown = 0.0
	check.call(raids.nearby_bin()==ordinary and raids.peck(),"ordinary bin remains peckable from the sand")

	# Exercise the actual one-way landing resolver, not only the access predicate.
	var landing_gull: BeachGull = BeachGull.new()
	suite.add_child(landing_gull)
	landing_gull.setup_perches([{"type":"wheelie_bin","x":300.0,"y":160.0}])
	var landing_lid: Dictionary = landing_gull.perch_surfaces[0]
	landing_gull.position = Vector2(300.0,65.0)
	landing_gull.velocity = Vector2.ZERO
	landing_gull.aim = Vector2(300.0,float(landing_lid.y))
	for frame: int in 240:
		landing_gull.tick(1.0/60.0,0,0.0)
	check.call(landing_gull.is_supported_by("wheelie_bin",300.0),"ordinary descent lands and settles on the wheelie lid")
	landing_gull.queue_free()
	suite.main.clear_game()
	await suite.settle()
