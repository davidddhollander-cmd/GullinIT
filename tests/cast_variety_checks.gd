extends RefCounted

const PEOPLE_KINDS: Array[String] = ["kiosk_customer", "sunbather", "pier_diner"]
const EXPECTED_CASTS: Array[Dictionary] = [
	{"shoppers":["kiosk_customer"], "sunbathers":["female_blue"], "diners":[]},
	{"shoppers":["kiosk_customer", "shopper_sundress", "shopper_mullet"], "sunbathers":["male_red"], "diners":[]},
	{"shoppers":["shopper_mullet", "old_man", "kiosk_customer"], "sunbathers":["female_red"], "diners":["pier_diner"]},
	{"shoppers":["kiosk_customer", "shopper_sundress"], "sunbathers":["male_blue", "female_blue", "male_red"], "diners":[]},
	{"shoppers":["shopper_mullet", "old_man"], "sunbathers":[], "diners":["pier_diner", "pier_diner_b"]},
	{"shoppers":["kiosk_customer", "old_man", "shopper_sundress"], "sunbathers":["female_red"], "diners":["pier_diner", "pier_diner_b"]},
]

static func _look(target: BeachTarget) -> String:
	match target.kind:
		"kiosk_customer":
			return target.shopper_appearance
		"sunbather":
			return ("female_" if target.sunbather_female else "male_")+("blue" if target.sunbather_blue else "red")
		"pier_diner":
			return target.diner_appearance
	return ""

static func _looks(spawner: BeachSpawner, kind: String) -> Array:
	var looks: Array = []
	for t: BeachTarget in spawner.targets:
		if t.kind == kind:
			looks.append(_look(t))
	return looks

static func _all_people_looks(spawner: BeachSpawner) -> Array:
	var looks: Array = []
	for target: BeachTarget in spawner.targets:
		if target.kind in PEOPLE_KINDS:
			looks.append(_look(target))
	return looks

static func _all_distinct(looks: Array) -> bool:
	var seen: Dictionary = {}
	for look: Variant in looks:
		seen[look] = true
	return seen.size() == looks.size()

static func _same_looks(actual: Array, expected: Array) -> bool:
	var sorted_actual: Array = actual.duplicate()
	var sorted_expected: Array = expected.duplicate()
	sorted_actual.sort()
	sorted_expected.sort()
	return sorted_actual == sorted_expected

static func run(harness: Node, check: Callable) -> void:
	var holder := Node2D.new()
	harness.add_child(holder)
	var old_man_levels: int = 0
	for id: int in range(1,7):
		var definition: Dictionary = Config.levels[id-1].duplicate(true)
		var spawner := BeachSpawner.new()
		spawner.setup(holder,definition)
		var expected_cast: Dictionary = EXPECTED_CASTS[id-1]
		var expected: int = 0
		for spawn: Dictionary in definition.spawns:
			if spawn.type != "off_lead_dog":
				expected += 1
		check.call(spawner.targets.size() == expected,"level %d head count unchanged" % id)
		check.call(_same_looks(_looks(spawner,"kiosk_customer"),expected_cast.shoppers),"level %d shopper cast matches the rotation" % id)
		check.call(_same_looks(_looks(spawner,"sunbather"),expected_cast.sunbathers),"level %d sunbather cast matches the rotation" % id)
		check.call(_same_looks(_looks(spawner,"pier_diner"),expected_cast.diners),"level %d diner cast matches the rotation" % id)
		check.call(_all_distinct(_all_people_looks(spawner)),"level %d opens without two people sharing a look" % id)
		if id in [5,6]:
			check.call(_same_looks(_looks(spawner,"pier_diner"),PierDinerArt.APPEARANCES),"level %d opens with one of each diner look" % id)
		if "old_man" in _looks(spawner,"kiosk_customer"):
			old_man_levels += 1
		if id >= 3:
			var seated: bool = false
			for t: BeachTarget in spawner.targets:
				seated = seated or t.bench_visit.anchored()
			check.call(seated,"level %d still opens with a seated shopper" % id)
		# Every un-authored replacement chooses the missing look and preserves the no-duplicate cast.
		for step: int in 12:
			var pool: Array[BeachTarget] = []
			for t: BeachTarget in spawner.targets:
				if t.kind in PEOPLE_KINDS:
					pool.append(t)
			if pool.is_empty():
				break
			spawner._departed(pool[step % pool.size()])
			spawner.kiosk_timer = INF
			spawner.tick(10.0,float(step)*3.0)
			check.call(_all_distinct(_all_people_looks(spawner)),"level %d replacement keeps every person look unique (step %d)" % [id,step])
		for t: BeachTarget in spawner.targets:
			t.queue_free()
	check.call(old_man_levels >= 2,"old man appears in at least two levels")
	var spawner := BeachSpawner.new()
	var definition: Dictionary = Config.levels[2].duplicate(true)
	definition.spawns = []
	spawner.setup(holder,definition)
	var man := spawner.create("kiosk_customer",500,{"appearance":"old_man","food_id":"ice_cream"})
	check.call(man.sprite.scale == Vector2(0.3,0.3) and man.art_height() == 24.0,"old man is drawn 40% smaller than the adult scale")
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
