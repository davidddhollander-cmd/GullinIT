extends RefCounted

static func _looks(spawner: BeachSpawner, kind: String) -> Array:
	var looks: Array = []
	for t: BeachTarget in spawner.targets:
		if t.kind == kind:
			looks.append(t.shopper_appearance if kind == "kiosk_customer" else ("female_" if t.sunbather_female else "male_")+("blue" if t.sunbather_blue else "red"))
	return looks

static func _distinct_ok(looks: Array, pool: int) -> bool:
	var seen: Dictionary = {}
	for look: Variant in looks:
		seen[look] = true
	return seen.size() == mini(looks.size(),pool)

static func run(harness: Node, check: Callable) -> void:
	var holder := Node2D.new()
	harness.add_child(holder)
	var old_man_levels: int = 0
	for id: int in range(2,7):
		var definition: Dictionary = Config.levels[id-1].duplicate(true)
		var spawner := BeachSpawner.new()
		spawner.setup(holder,definition)
		var expected: int = 0
		for spawn: Dictionary in definition.spawns:
			if spawn.type != "off_lead_dog":
				expected += 1
		check.call(spawner.targets.size() == expected,"level %d head count unchanged" % id)
		check.call(_distinct_ok(_looks(spawner,"kiosk_customer"),ShopperArt.APPEARANCES.size()),"level %d shoppers all look different" % id)
		check.call(_distinct_ok(_looks(spawner,"sunbather"),4),"level %d sunbathers all look different" % id)
		if "old_man" in _looks(spawner,"kiosk_customer"):
			old_man_levels += 1
		if id >= 3:
			var seated: bool = false
			for t: BeachTarget in spawner.targets:
				seated = seated or t.bench_visit.anchored()
			check.call(seated,"level %d still opens with a seated shopper" % id)
		# 120 s of departures, replacements and station refills keep duplicates at the minimum.
		for step: int in 40:
			var pool: Array[BeachTarget] = []
			for t: BeachTarget in spawner.targets:
				if t.kind in ["kiosk_customer","sunbather"]:
					pool.append(t)
			if pool.is_empty():
				break
			spawner._departed(pool[step % pool.size()])
			spawner.tick(10.0,float(step)*3.0)
			if step % 7 == 0 and spawner.targets.size() < 8:
				spawner.create("kiosk_customer",300)
			check.call(_distinct_ok(_looks(spawner,"kiosk_customer"),ShopperArt.APPEARANCES.size()),"level %d shopper looks stay minimal-duplicate (step %d)" % [id,step])
			check.call(_distinct_ok(_looks(spawner,"sunbather"),4),"level %d sunbather looks stay minimal-duplicate (step %d)" % [id,step])
		for t: BeachTarget in spawner.targets:
			t.queue_free()
	check.call(old_man_levels >= 2,"old man appears in at least two levels")
	var spawner := BeachSpawner.new()
	var definition: Dictionary = Config.levels[2].duplicate(true)
	definition.spawns = []
	spawner.setup(holder,definition)
	var man := spawner.create("kiosk_customer",500,{"appearance":"old_man","food_id":"ice_cream"})
	check.call(man.sprite.scale == Vector2(0.5,0.5) and man.art_height() == 40.0,"old man uses the adult scale")
	for facing: float in [1.0,-1.0]:
		man.facing = facing
		man.update_art_pose(true)
		check.call(man.sprite.animation == (&"walk" if facing > 0 else &"walk_left"),"old man walks both ways with his own clips")
	man.biting = 1.0
	man.update_art_pose(false)
	check.call(man.sprite.animation == &"eat","old man eats")
	man.biting = 0.0
	man.facing = 1.0
	man.action_pose_time = 0.14
	man.update_art_pose(false)
	check.call(man.sprite.animation == &"stick_hit","old man swats with the stick")
	man.action_pose_time = 0.0
	holder.queue_free()
