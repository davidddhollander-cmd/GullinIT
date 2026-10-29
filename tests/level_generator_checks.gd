extends RefCounted

static func run(check: Callable) -> void:
	var signatures: Dictionary = {}
	for number: int in range(1,8):
		var source: Dictionary = Config.read_json("res://data/levels/level_%02d.json" % number)
		var original: String = JSON.stringify(source)
		for variation: int in 20:
			var recipe: Dictionary = source.duplicate(true)
			recipe.seed = int(source.seed)+variation*100
			var level: Dictionary = BeachLevelGenerator.generate(recipe,Config.layout_rules)
			check.call(level == BeachLevelGenerator.generate(recipe,Config.layout_rules),"same seed reproduces complete layout")
			check.call(not JSON.stringify(level.spawns).contains("dog_owner"),"dog owner never spawns")
			_check_palms(check,level)
			if number <= 5:
				_check_opening_level(check,source,level,number)
			elif number == 6:
				_check_squall_level(check,source,level)
			elif bool(source.get("authored",false)):
				_check_boss_level(check,source,level)
			else:
				_check_later_level(check,level)
			if variation == 0:
				signatures[JSON.stringify(level.props)] = true
		check.call(JSON.stringify(source)==original,"generator leaves authored recipe intact")
	check.call(signatures.size()==7,"all seven levels have distinct scenery arrangements")

static func _check_palms(check: Callable, level: Dictionary) -> void:
	var palms: Array[float] = []
	var width: float = float(level.get("world",{}).get("width",Config.default_world.width))
	var palm_art: Dictionary = Config.sprites.beach_palm
	var half_width: float = float(palm_art.frame_w)*float(palm_art.get("visual_scale",1.0))*0.5
	for prop: Dictionary in level.props:
		if prop.type != "beach_palm":
			continue
		var x: float = float(prop.x)
		palms.append(x)
		check.call(x-half_width>=0 and x+half_width<=width,"palm crown remains inside level")
		for stand: Dictionary in level.props:
			if stand.type in ["kiosk","hotdog_stand"]:
				var art: Dictionary = Config.sprites[stand.type]
				var stand_half: float = float(art.frame_w)*float(art.get("visual_scale",1.0))*0.5
				check.call(absf(x-float(stand.x))>=half_width+stand_half+8.0,"palm clears stall and counter food")
	check.call(palms.size()>=1,"each playable level has a palm")
	palms.sort()
	for i: int in range(1,palms.size()):
		check.call(palms[i]-palms[i-1]>=140.0,"palms are spread along the route")

static func _check_opening_level(check: Callable, source: Dictionary, level: Dictionary, number: int) -> void:
	check.call(level.spawns.size()==source.spawns.size(),"opening roster stays authored")
	check.call(level.props.size()==source.props.size(),"opening scenery stays authored")
	check.call(level.world==source.world and level.zones==source.zones,"opening geometry and signs stay authored")
	check.call(float(level.world.start_x)<float(level.spawns[0].x)-60,"opening route has breathing room")
	var family_positions: Dictionary = {}
	var children: Dictionary = {}
	var types: Array[String] = []
	for i: int in level.spawns.size():
		var spawn: Dictionary = level.spawns[i]
		var authored: Dictionary = source.spawns[i]
		types.append(str(spawn.type))
		check.call(spawn.type==authored.type and absf(float(spawn.x)-float(authored.x))<=3.0,"small seed variation preserves actor order")
		check.call(float(spawn.x)>20 and float(spawn.x)<float(level.world.width)-20,"opening actor remains inside map")
		if spawn.type == "picnic_family":
			family_positions[str(spawn.family_id)] = float(spawn.x)
		elif spawn.type == "toddler":
			children[str(spawn.family_id)] = float(spawn.x)
	for family_id: String in family_positions:
		check.call(children.has(family_id) and absf(float(family_positions[family_id])-float(children[family_id]))>=38.0,"each family has a nearby child with clear spacing")
	for a: int in level.spawns.size():
		for b: int in range(a+1,level.spawns.size()):
			check.call(absf(float(level.spawns[a].x)-float(level.spawns[b].x))>=35.0,"opening characters start separated")
	var kiosk_x: float = -1.0
	var stand_count: int = 0
	for prop: Dictionary in level.props:
		if prop.type in ["kiosk","hotdog_stand"]:
			stand_count += 1
			if prop.type == "kiosk":
				kiosk_x = float(prop.x)
	if number == 1:
		check.call(types==["kiosk_customer","sunbather","toddler","picnic_family"],"training route introduces snack, bag, then family")
		check.call(int(level.world.width)==800 and bool(level.tutorial),"training beach is short and tutorial enabled")
		check.call(stand_count==1 and kiosk_x>float(family_positions["family_1"]),"family has a kiosk further along the beach")
		check.call(level.rivals.is_empty(),"training beach has no rival")
	elif number == 2:
		check.call(types.count("picnic_family")==1 and types.count("toddler")==2 and types.count("sunbather")==1 and types.count("kiosk_customer")==3,"family beach has one mum with two toddlers, one sunbather and three shoppers")
		check.call(not types.has("dog_owner") and not types.has("pier_diner"),"family beach excludes promenade and pier actors")
		var left_stand: float = INF
		for prop: Dictionary in level.props:
			if prop.type == "kiosk":
				left_stand = minf(left_stand,float(prop.x))
		check.call(stand_count==2 and left_stand<float(family_positions["family_1"])-100.0 and kiosk_x>float(family_positions["family_1"])+300.0,"family beach has an ice-cream stand near the start and a far-end kiosk")
		check.call(int(level.world.promenade_start)==int(level.world.width) and int(level.world.pier_start)==int(level.world.width),"family beach remains all sand")
	elif number == 4:
		check.call(types==["sunbather","sunbather","sunbather","kiosk_customer","kiosk_customer","off_lead_dog"],"dog day is a sunbathers strip with two shoppers and exactly one off-lead dog")
		var dog_spawn: Dictionary = level.spawns[5]
		check.call(float(dog_spawn.home[0])>=float(level.world.start_x)+150.0 and float(dog_spawn.home[1])<float(level.world.promenade_start) and float(dog_spawn.x)>=float(dog_spawn.home[0]) and float(dog_spawn.x)<=float(dog_spawn.home[1]),"dog home zone is open sand away from the start")
		check.call(stand_count==2 and not bool(level.get("rivals_after_snatch",false)) and level.rivals.size()==1,"dog day keeps both stands and Gary from the start")
	elif number == 5:
		check.call(types==["kiosk_customer","kiosk_customer","pier_diner","pier_diner","toddler","picnic_family","off_lead_dog"],"three's a crowd has two shoppers, both pier diners and one mum with one toddler, plus a dog by the family")
		check.call(family_positions.size()==1 and children.size()==1,"level 5 adds exactly one linked family pair")
		check.call(stand_count==1 and kiosk_x<0.0 and not bool(level.get("rivals_after_snatch",false)) and level.rivals.size()==2,"three's a crowd has a single grill (no kiosk) and two rivals")
	else:
		check.call(types==["sunbather","kiosk_customer","kiosk_customer","kiosk_customer","pier_diner"],"boardwalk is a busy promenade of three shoppers and a diner, no families")
		check.call(not types.has("dog_owner") and not types.has("market_cleaner") and not types.has("lifeguard"),"boardwalk leaves later hazards for later levels")
		check.call(float(level.spawns[0].x)<float(level.world.promenade_start) and float(level.spawns[1].x)>float(level.world.promenade_start) and float(level.spawns[4].x)>float(level.world.pier_start),"boardwalk actors occupy their zones")
		check.call(stand_count==2 and bool(level.rivals_after_snatch),"boardwalk includes both stands and delayed Gary")

static func _check_squall_level(check: Callable, source: Dictionary, level: Dictionary) -> void:
	var types: Array[String] = []
	for spawn: Dictionary in level.spawns:
		types.append(str(spawn.type))
		check.call(float(spawn.x)>20 and float(spawn.x)<float(level.world.width)-20,"squall actor remains inside map")
	check.call(level.props.size()==source.props.size() and level.zones==source.zones and level.world==source.world,"squall level stays hand-built")
	check.call(types.count("sunbather")==2 and types.count("picnic_family")==1 and types.count("kiosk_customer")==3 and types.count("pier_diner")==1 and types.count("off_lead_dog")==1 and not level.has("watergun_teens"),"squall cast: sunbathers, picnic family, kiosk customers, one diner, one dog, no teen")
	check.call(int(level.world.width)==1280 and int(level.world.pier_start)==int(level.world.width) and int(level.world.promenade_start)==760 and level.rivals.size()==2,"squall is a wide beach with a short promenade, no pier, and Gary and Chip")
	for a: int in level.spawns.size():
		for b: int in range(a+1,level.spawns.size()):
			check.call(absf(float(level.spawns[a].x)-float(level.spawns[b].x))>=35.0,"squall characters start separated")

static func _check_boss_level(check: Callable, source: Dictionary, level: Dictionary) -> void:
	check.call(level.spawns.size()==source.spawns.size() and level.props.size()==source.props.size() and level.zones==source.zones and level.world==source.world,"boss level stays hand-built")
	var types: Array[String] = []
	for spawn: Dictionary in level.spawns:
		types.append(str(spawn.type))
		check.call(float(spawn.x)>20 and float(spawn.x)<float(level.world.width)-20,"boss actor remains inside map")
	check.call(types.has("pier_diner") and types.count("kiosk_customer")==3,"boss level has the pier and promenade customers")
	for a: int in level.spawns.size():
		for b: int in range(a+1,level.spawns.size()):
			check.call(absf(float(level.spawns[a].x)-float(level.spawns[b].x))>=35.0,"boss characters start separated")

static func _check_later_level(check: Callable, level: Dictionary) -> void:
	var food_positions: Array[float] = []
	var family_ids: Dictionary = {}
	var toddler_count: int = 0
	var sunbather_count: int = 0
	for spawn: Dictionary in level.spawns:
		var x: float = float(spawn.x)
		check.call(x>20 and x<1260,"generated actor inside map")
		if spawn.type == "sunbather":
			sunbather_count += 1
			check.call(x<310,"sunbather stays in quiet sunbathing section")
			food_positions.append(x-30)
		elif spawn.type in ["toddler","picnic_family"]:
			check.call(x>360 and x<620,"families stay in their beach section")
			food_positions.append(x)
			if spawn.type == "picnic_family":
				family_ids[spawn.family_id] = x
		elif spawn.type == "kiosk_customer":
			check.call(x>=640 and x<960,"promenade food stays on promenade")
			food_positions.append(x)
		elif spawn.type == "pier_diner":
			check.call(x>=960,"pier dining stays on pier")
			food_positions.append(x)
	for spawn: Dictionary in level.spawns:
		if spawn.type == "toddler":
			toddler_count += 1
			check.call(family_ids.has(spawn.family_id) and is_equal_approx(absf(float(spawn.x)-float(family_ids[spawn.family_id])),44.0),"child has designated mum with breathing room")
	check.call(toddler_count==2 and sunbather_count==2,"later layout limits toddlers and sunbathers to two each")
	for a: int in level.spawns.size():
		for b: int in range(a+1,level.spawns.size()):
			check.call(absf(float(level.spawns[a].x)-float(level.spawns[b].x))>=28,"initial characters have clear separation")
	var stand_count: int = 0
	for prop: Dictionary in level.props:
		if prop.type in ["kiosk","hotdog_stand"]:
			stand_count += 1
			check.call(float(prop.x)>690 and float(prop.x)<930,"both stands are on promenade")
		if prop.type in ["bin","wheelie_bin"]:
			food_positions.append(float(prop.x))
	check.call(stand_count==2,"exactly two separate food stands")
	food_positions.sort()
	for i: int in range(1,food_positions.size()):
		check.call(food_positions[i]-food_positions[i-1]<=float(Config.layout_rules.max_food_gap),"no excessive gap between food sources")
