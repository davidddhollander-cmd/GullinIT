class_name BeachLevelGenerator
extends RefCounted
## Seeded, bounded stations keep variety inside a legible scene plan.
static func generate(definition: Dictionary, rules: Dictionary) -> Dictionary:
	var level: Dictionary = definition.duplicate(true)
	var random := RandomNumberGenerator.new()
	random.seed = int(level.seed)
	# The opening levels are paced as authored routes. Jitter is visual only and
	# never changes their roster, landmark order, or the space around the start.
	if int(level.id) <= 3:
		for spawn: Dictionary in level.spawns:
			spawn.x = float(spawn.x) + random.randi_range(-3,3)
		for prop: Dictionary in level.props:
			if prop.get("jitter", false):
				prop.x = float(prop.x) + random.randi_range(-3,3)
				prop.erase("jitter")
		level.layout_version = int(rules.version)
		return level
	var spawns: Array = level.spawns
	# Keep authored sibling support, but use a quieter roster in playable layouts.
	var retained: Array = []
	var child_counts: Dictionary = {}
	var retained_sunbathers: int = 0
	for spawn: Dictionary in spawns:
		if spawn.type == "sunbather":
			if retained_sunbathers >= rules.sunbather_centres.size():
				continue
			retained_sunbathers += 1
		elif spawn.type == "toddler":
			var family: String = str(spawn.get("family_id",""))
			if int(child_counts.get(family,0)) >= int(rules.children_per_family):
				continue
			child_counts[family] = int(child_counts.get(family,0))+1
		retained.append(spawn)
	spawns = retained
	level.spawns = spawns
	var props: Array = []
	var sun_count: int = 0
	var families: Dictionary = {}
	var kinds: Dictionary = {}
	for spawn: Dictionary in spawns:
		kinds[spawn.type] = true
		if spawn.type == "sunbather":
			sun_count += 1
		if spawn.type == "picnic_family":
			families[str(spawn.family_id)] = []
	for i: int in range(sun_count,rules.sunbather_centres.size()):
		spawns.append({"type":"sunbather"})
	for kind: String in ["pier_diner","seafood_vendor"]:
		if not kinds.has(kind):
			spawns.append({"type":kind})
	for spawn: Dictionary in spawns:
		if spawn.type == "toddler" and families.has(str(spawn.get("family_id",""))):
			families[str(spawn.family_id)].append(spawn)
	for id: String in families:
		if families[id].is_empty():
			var child: Dictionary = {"type":"toddler","family_id":id}
			spawns.append(child)
			families[id].append(child)
	var sun_index: int = 0
	var family_index: int = 0
	var customer_index: int = 0
	var stand_positions: Array = rules.stand_centres.duplicate()
	# Alternate shop order between seeds while retaining two separate stations.
	if int(level.seed)%2 == 0:
		stand_positions.reverse()
	var ice_x: float = float(stand_positions[0])+random.randi_range(-int(rules.jitter),int(rules.jitter))
	var hot_x: float = float(stand_positions[1])+random.randi_range(-int(rules.jitter),int(rules.jitter))
	props.append({"type":"kiosk","x":ice_x,"customer_x":ice_x+float(rules.customer_offset)})
	props.append({"type":"hotdog_stand","x":hot_x,"customer_x":hot_x+float(rules.customer_offset)})
	props.append({"type":"wheelie_bin","x":minf(ice_x,hot_x)-42.0})
	var appearances: Array = ["male_red","female_blue","female_red","male_blue"]
	for spawn: Dictionary in spawns:
		spawn.patrol_radius = 6.0 if spawn.type == "toddler" else float(rules.patrol_radius)
		match str(spawn.type):
			"sunbather":
				spawn.x = float(rules.sunbather_centres[sun_index])+random.randi_range(-int(rules.jitter),int(rules.jitter))
				spawn.appearance = str(spawn.get("appearance",appearances[(int(level.id)+sun_index)%4]))
				spawn.station = "sun_%d" % sun_index
				if (sun_index+int(level.id))%2 == 0:
					props.append({"type":"beach_parasol_blue" if random.randf()<0.5 else "beach_parasol","x":float(spawn.x)+25,"y":143})
				sun_index += 1
			"picnic_family":
				spawn.x = float(rules.family_centres[family_index])+random.randi_range(-int(rules.jitter),int(rules.jitter))
				spawn.station = str(spawn.family_id)
				var children: Array = families[str(spawn.family_id)]
				for i: int in children.size():
					children[i].x = float(spawn.x)+(-1 if i%2==0 else 1)*float(rules.family_spacing)
					children[i].station = str(spawn.family_id)
					children[i].patrol_radius = 6.0
				family_index += 1
			"kiosk_customer":
				var ice: bool = customer_index%2 == 0
				spawn.x = (ice_x if ice else hot_x)+float(rules.customer_offset)
				spawn.food_id = "ice_cream" if ice else "hotdog"
				spawn.station = "ice_cream" if ice else "hotdogs"
				customer_index += 1
			"dog_owner":
				spawn.x = 668+random.randi_range(-4,4)
				spawn.station = "promenade_entry"
			"pier_diner":
				spawn.x = 1018+random.randi_range(-6,6)
				spawn.station = "pier_dining"
			"seafood_vendor":
				spawn.x = 1180+random.randi_range(-6,6)
				spawn.station = "fish_counter"
			"lifeguard":
				spawn.x = 1138
				spawn.station = "lifeguard"
	for i: int in range(customer_index,2):
		spawns.append({"type":"kiosk_customer","x":(ice_x if i==0 else hot_x)+float(rules.customer_offset),"food_id":"ice_cream" if i==0 else "hotdog","station":"ice_cream" if i==0 else "hotdogs","patrol_radius":float(rules.patrol_radius)})
	props.append_array([{"type":"bin","x":325},{"type":"bin","x":620},
		{"type":"tower","x":1090},
		# Space three palms along the route, with full crowns inside the map and
		# clear of both serving windows even at the stands' maximum seed jitter.
		{"type":"beach_palm","x":32,"y":148},
		{"type":"beach_palm","x":350,"y":148},
		{"type":"beach_palm","x":965,"y":148},
		{"type":"beach_castle" if int(level.seed)%2 else "beach_rocks","x":495,"y":173},
		{"type":"beach_lamp","x":822,"y":151},{"type":"beach_bench","x":1250,"y":153},{"type":"bin","x":1218}])
	if int(level.id)>=5:
		for spawn: Dictionary in spawns:
			if spawn.type == "pier_diner":
				props.append({"type":"umbrella","x":spawn.x})
	level.props = props
	level.layout_version = int(rules.version)
	level.zones = [{"name":"SUNBATHERS","from":0,"to":330},{"name":"FAMILY BAY","from":330,"to":640},{"name":"PROMENADE","from":640,"to":960},{"name":"PIER DINING","from":960,"to":1280}]
	return level
