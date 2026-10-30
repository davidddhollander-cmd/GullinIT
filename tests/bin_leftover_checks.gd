extends RefCounted
## Exercise real bin drops through pickup, digestion, scoring and depletion.
const LEFTOVERS := ["half_eaten_doughnut", "half_eaten_sandwich", "half_eaten_pizza"]

static func run(suite: Node, check: Callable) -> void:
	var available: bool = true
	for id: String in LEFTOVERS:
		check.call(Config.foods.has(id), "bin leftover is registered: " + id)
		available = available and Config.foods.has(id)
	if not available:
		return
	suite.main.start_level(2)
	var game: BeachGame = suite.main.game
	game.set_physics_process(false)
	game.intro = 0
	game.running = true
	var raids: BeachStashRaids = game.stash_raids
	for target: BeachTarget in game.spawner.targets:
		if target.kind == "sunbather":
			target.stash_remaining = 0
	var bin: Dictionary = raids.bins[0]
	var gull: BeachGull = game.player
	gull.position = Vector2(float(bin.x)-10, gull.ground_y())
	gull.facing = 1
	gull.land()
	var taps: int = 0
	while int(bin.remaining) > 0 and taps < 20:
		raids.peck_cooldown = 0
		check.call(raids.peck(), "bin releases mixed leftovers through normal peck input")
		taps += 1
	check.call(taps == 12 and raids.items.size() == 9, "nine bin objects still take three four-peck bursts")
	var counts: Dictionary = {}
	var rubbish: int = 0
	for item: Dictionary in raids.items:
		if bool(item.garbage):
			rubbish += 1
		else:
			counts[Config.food_family(item.food_id)] = int(counts.get(Config.food_family(item.food_id), 0))+1
	check.call(rubbish == 4 and int(counts.get("crumbs", 0)) == 2, "bin retains two crumbs and four inert litter objects")
	for id: String in LEFTOVERS:
		check.call(int(counts.get(id, 0)) == 1, "each full bin contains one " + id)
	var drops: Array[Dictionary] = raids.items.duplicate(true)
	# Show the real dropped items together on the sand at their gameplay scale.
	gull.position.x = float(bin.x)-75
	for index: int in raids.items.size():
		var item: Dictionary = raids.items[index]
		item.position = Vector2(float(bin.x)-56+index*14, float(Config.tuning.world.ground)-4)
		item.grounded = true
		item.velocity = Vector2.ZERO
		item.age = 0.3
	game.camera_x = clampf(float(bin.x), 160, float(Config.tuning.world.width)-160)
	game.camera.position.x = game.camera_x
	game.beach.camera_x = game.camera_x
	raids.queue_redraw()
	await suite.snapshot("bin-leftovers")
	raids.items.clear()
	for id: String in LEFTOVERS:
		var selected: Dictionary = {}
		for drop: Dictionary in drops:
			if Config.food_family(drop.food_id) == id:
				selected = drop.duplicate(true)
		if selected.is_empty():
			continue
		gull.position = Vector2(float(bin.x)-10, gull.ground_y())
		gull.land()
		gull.previous_beak = gull.beak()
		gull.sweep_beak = gull.beak()
		selected.position = Vector2(gull.beak().x, float(Config.tuning.world.ground)-4)
		selected.grounded = true
		selected.velocity = Vector2.ZERO
		selected.age = 0.0
		raids.items.append(selected)
		var points: int = game.score.points
		raids.tick(0.29)
		check.call(raids.items.size() == 1 and gull.digestion.snacks.is_empty(), "new bin leftover keeps pickup protection: " + id)
		raids.tick(0.011)
		check.call(raids.items.is_empty() and gull.digestion.snacks.size() == 1, "bin leftover enters digestion once eligible: " + id)
		check.call(game.score.points == points, "bin leftover scores only after swallowing: " + id)
		if not gull.digestion.snacks.is_empty():
			check.call(bool(gull.digestion.snacks[0].get("scrap", false)), "bin leftover retains scrap scoring metadata: " + id)
		gull.digestion.tick(0.49, false)
		check.call(game.score.points == points, "small leftover has the normal half-second eating time: " + id)
		gull.digestion.tick(0.01, false)
		check.call(game.score.points == points+int(Config.foods[id].points) and game.score.items == 0 and game.score.tier == 0, "bin leftover gives its value without snatch or combo credit: " + id)
		raids.tick(0)
		gull.digestion.tick(1, false)
		check.call(game.score.points == points+int(Config.foods[id].points), "bin leftover cannot score twice: " + id)
	# A full mouth leaves the new food on the sand until digestion makes room.
	for index: int in 4:
		gull.digestion.collect("crumbs")
	var waiting: Dictionary = {"owner":null, "source":"bin", "food_id":LEFTOVERS[0], "garbage":false, "position":Vector2(gull.beak().x, 156), "velocity":Vector2.ZERO, "grounded":true, "age":1.0}
	raids.items.append(waiting)
	raids.tick(0)
	check.call(raids.items.size() == 1, "bin leftovers wait when digestion capacity is full")
	gull.digestion.tick(30, false)
	raids.tick(0)
	check.call(raids.items.is_empty(), "waiting bin leftover is collectible once there is room")
	gull.digestion.tick(30, false)
	raids.peck_cooldown = 0
	check.call(raids.peck() and raids.items.is_empty() and int(bin.remaining) == 0, "empty bin cannot create more leftovers")
	suite.main.start_level(2)
	check.call(int(suite.main.game.stash_raids.bins[0].remaining) == 9, "retry restores the finite mixed bin contents")
	suite.main.clear_game()
	await suite.settle()
