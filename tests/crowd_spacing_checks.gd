class_name CrowdSpacingChecks
extends RefCounted

static func run_checks(root: Node, check: Callable) -> void:
	check.call(float(Config.tuning.world.family_follow_spacing) >= 25.0, "walking toddler has room beside mum")
	check.call(float(Config.tuning.world.family_handover_distance) >= 24.0, "handover keeps both figures readable")
	var stage := Node2D.new()
	root.add_child(stage)
	var spawner := BeachSpawner.new()
	spawner.setup(stage, {
		"seed": 12, "id": 1, "time_limit": 90.0, "awareness_mult": 1.0,
		"props": [], "spawns": [
			{"type": "kiosk_customer", "x": 200.0},
			{"type": "kiosk_customer", "x": 202.0}
		]
	})
	var first: BeachTarget = spawner.targets[0]
	var second: BeachTarget = spawner.targets[1]
	spawner.apply_spacing(1.0)
	check.call(first.position.distance_to(second.position) >= 25.0, "overlapping adults receive separate visual positions")
	check.call(first.z_index != second.z_index, "crossing adults draw in depth order")
	var beach := BeachBackdrop.new()
	root.add_child(beach)
	beach.setup([{"type":"kiosk","x":228},{"type":"hotdog_stand","x":428}])
	for i: int in beach.stalls.size():
		var shell: AnimatedSprite2D = beach.prop_sprites[i]
		var stall: FoodStall = beach.stalls[i]
		check.call(second.z_index < shell.z_index and second.z_index < stall.z_index,"rear lane passes behind complete stall and vendor: "+str(i))
		check.call(first.z_index >= shell.z_index and first.z_index >= stall.z_index,"ground lane remains in front of the stall: "+str(i))
	for child: Node in beach.get_children():
		if child.get_script() == preload("res://scripts/stand_sign.gd"):
			check.call(second.z_index < child.z_index,"rear lane passes behind stall signs and awnings")
	beach.queue_free()
	spawner.reset_spacing()
	check.call(first.position == Vector2(200,160) and second.position == Vector2(202,160), "spacing leaves gameplay positions unchanged")
	second.position.x = 280.0
	spawner.apply_spacing(float(Config.tuning.world.lane_hold))
	check.call(second.position == Vector2(280,160), "visual offset clears once people part")
	stage.queue_free()
	_bench_lanes(root,check)
	_family_lane(root,check)
	_lane_hold(root,check)
	_bin_depth(root,check)
	_stand_spacing(root,check)

static func _lane_hold(root: Node, check: Callable) -> void:
	var stage := Node2D.new()
	root.add_child(stage)
	var spawner := BeachSpawner.new()
	var spawns: Array = []
	for i: int in 6:
		spawns.append({"type":"kiosk_customer","x":300.0+i*9.0})
	spawner.setup(stage,{"seed":3,"id":1,"time_limit":90.0,"awareness_mult":1.0,"props":[],"spawns":spawns})
	var hold: float = float(Config.tuning.world.lane_hold)
	var last_y: Dictionary = {}
	var last_change: Dictionary = {}
	var worst: float = INF
	var any_gap: float = INF
	var steps: int = 600
	for step: int in steps:
		for i: int in spawner.targets.size():
			# Walkers drift at different speeds so the crowd keeps reshuffling.
			spawner.targets[i].position.x = 300.0+i*9.0+float(step)/60.0*(6.0+i*2.0)*(1.0 if i%2==0 else -0.5)
		spawner.apply_spacing(1.0/60.0)
		var now: float = float(step)/60.0
		for target: BeachTarget in spawner.targets:
			var lane: float = float(spawner.lane_holds[target].y)
			if last_y.has(target) and not is_equal_approx(float(last_y[target]),lane):
				if last_change.has(target):
					any_gap = minf(any_gap,now-float(last_change[target]))
					if not bool(spawner.lane_holds[target].blocked):
						worst = minf(worst,now-float(last_change[target]))
				last_change[target] = now
			last_y[target] = lane
		spawner.reset_spacing()
	check.call(worst>=hold-0.05,"6-person crowd: no lane change within lane_hold of the previous one (shortest gap %.2f)" % worst)
	check.call(any_gap>=BeachSpawner.LANE_GRACE,"6-person crowd: even blocked walkers never flicker between lanes (shortest gap %.2f)" % any_gap)
	stage.queue_free()

static func _bin_depth(root: Node, check: Callable) -> void:
	var stage := Node2D.new()
	root.add_child(stage)
	var spawner := BeachSpawner.new()
	var props: Array = [{"type":"wheelie_bin","x":226}]
	spawner.setup(stage,{"seed":3,"id":1,"time_limit":90.0,"awareness_mult":1.0,"props":props,"spawns":[{"type":"kiosk_customer","x":200.0}]})
	var walker: BeachTarget = spawner.targets[0]
	var bin_z: int = 1
	for lane_y: float in [-14.0,12.0]:
		spawner.visual_offsets[walker] = Vector2(0,lane_y)
		spawner.lane_holds[walker] = {"y":lane_y,"t":10.0}
		walker.position = Vector2(200,160)
		spawner.apply_spacing(1.0) # held lane puts the walker 26 px along, level with the bin
		if lane_y < 0.0:
			check.call(walker.z_index < bin_z,"rear-lane walker draws behind a wheelie bin")
		else:
			check.call(walker.z_index > bin_z,"front-lane walker draws in front of a wheelie bin")
		spawner.reset_spacing()
	stage.queue_free()

static func _family_lane(root: Node, check: Callable) -> void:
	var stage := Node2D.new()
	root.add_child(stage)
	var spawner := BeachSpawner.new()
	spawner.setup(stage,{"seed":12,"id":1,"time_limit":90.0,"awareness_mult":1.0,"props":[],
		"spawns":[{"type":"picnic_family","x":200,"family_id":"test"},
		{"type":"toddler","x":201,"family_id":"test"},{"type":"toddler","x":199,"family_id":"test"}]})
	for locked: bool in [false,true]:
		for target: BeachTarget in spawner.targets:
			target.service_locked = locked
			spawner.visual_offsets[target] = Vector2(26,-14)
		spawner.apply_spacing(1.0/60.0)
		for target: BeachTarget in spawner.targets:
			check.call(target.position.y==160 and target.z_index==2,"family keeps ground lane even with prior rear offset/service lock")
		for i: int in spawner.targets.size():
			for j: int in range(i+1,spawner.targets.size()):
				check.call(absf(spawner.targets[i].position.x-spawner.targets[j].position.x)>=25,"mum and siblings do not overlap")
		for child: BeachTarget in spawner.targets[0].family_children:
			check.call(absf(child.position.x-spawner.targets[0].position.x)<=50,"siblings stay close to mum")
		spawner.reset_spacing()
		check.call(spawner.targets[0].position==Vector2(200,160) and spawner.targets[1].position==Vector2(201,160),"family spacing preserves simulation and handover positions")
	var second_mum := spawner.create("picnic_family",202,{"family_id":"crossing"})
	var second_child := spawner.create("toddler",203,{"family_id":"crossing"})
	second_child.family_parent = second_mum
	second_mum.family_children.append(second_child)
	spawner.benches.setup([{"type":"beach_bench","x":220,"y":153}])
	for step: int in 60:
		second_mum.position.x = 170+step
		second_child.position.x = second_mum.position.x+27
		spawner.apply_spacing(1.0/60.0)
		var separated: bool = true
		var grounded: bool = true
		for i: int in spawner.targets.size():
			grounded = grounded and spawner.targets[i].position.y==160
			for j: int in range(i+1,spawner.targets.size()):
				separated = separated and absf(spawner.targets[i].position.x-spawner.targets[j].position.x)>=25
		check.call(grounded and separated,"crossing families beside bench remain separated on ground lane")
		check.call(absf(second_child.position.x-second_mum.position.x)<=75,"crossing toddler stays within family group")
		spawner.reset_spacing()
	stage.queue_free()

static func _bench_lanes(root: Node, check: Callable) -> void:
	var stage := Node2D.new()
	root.add_child(stage)
	var spawner := BeachSpawner.new()
	spawner.setup(stage,{"seed":12,"id":3,"time_limit":90.0,"awareness_mult":1.0,
		"props":[{"type":"beach_bench","x":220.0,"y":153.0}],
		"spawns":[{"type":"kiosk_customer","x":220.0},{"type":"kiosk_customer","x":222.0}]})
	var first: BeachTarget = spawner.targets[0]
	var walker: BeachTarget = spawner.targets[1]
	spawner.apply_spacing(1.0)
	check.call(walker.position.y >= 155.0,"empty bench blocks raised walking lane")
	check.call(first.position.distance_to(walker.position) >= 25.0,"bench detour still separates overlapping people")
	spawner.reset_spacing()
	# Enter the bench footprint while already in the rear lane. Blending toward
	# a valid destination must not leave the feet on the furniture mid-frame.
	spawner.visual_offsets[walker] = Vector2(26,-14)
	spawner.apply_spacing(1.0/60.0)
	check.call(walker.position.y >= 155.0,"old rear-lane offset cannot blend through bench")
	spawner.reset_spacing()
	for direction: float in [-1.0,1.0]:
		for step: int in 100:
			var x: float = 220.0+direction*(100.0-step*2.0)
			first.position = Vector2(x,160)
			walker.position = Vector2(x+2,160)
			spawner.apply_spacing(1.0/60.0)
			for target: BeachTarget in [first,walker]:
				if absf(target.position.x-220.0) < 37.0:
					check.call(target.position.y >= 155.0,"both crossing directions keep feet in front of bench")
			spawner.reset_spacing()
	first.position = Vector2(220,153)
	first.bench_visit.seat = spawner.benches.reserve(first,Vector2(0,600))
	first.bench_visit.phase = BenchVisit.Phase.REST
	walker.position = Vector2(222,160)
	spawner.apply_spacing(1.0)
	check.call(first.position == Vector2(220,153),"seated visitor retains exact seat anchor")
	check.call(walker.position.y >= 155.0,"occupied bench blocks raised lane too")
	spawner.reset_spacing()
	# Rendered prop scale and a nonstandard vertical placement define the block.
	var old_scale: Variant = Config.sprites.beach_bench.get("visual_scale",null)
	Config.sprites.beach_bench.visual_scale = 2.0
	spawner.benches.setup([{"type":"beach_bench","x":220.0,"y":174.0}])
	first.bench_visit.phase = BenchVisit.Phase.NONE
	first.position = Vector2(220,180)
	walker.position = Vector2(222,180)
	spawner.apply_spacing(1.0)
	check.call(walker.position.y >= 176.0,"bench block follows scaled width and authored base height")
	if old_scale == null:
		Config.sprites.beach_bench.erase("visual_scale")
	else:
		Config.sprites.beach_bench.visual_scale = old_scale
	stage.queue_free()

## Stands keep their distance so each serving window has its own crowd room.
static func _stand_spacing(root: Node, check: Callable) -> void:
	var min_gap: float = 140.0
	var clear: float = 50.0
	for level: Dictionary in Config.levels:
		var stands: Array = level.props.filter(func(prop: Dictionary) -> bool: return prop.type in ["kiosk","hotdog_stand","fish_chips_stand"])
		for i: int in stands.size():
			for j: int in range(i+1,stands.size()):
				check.call(absf(float(stands[i].x)-float(stands[j].x)) >= min_gap,"level %d stands %d and %d keep %d px apart" % [level.id,int(stands[i].x),int(stands[j].x),int(min_gap)])
			for spawn: Dictionary in level.spawns:
				if spawn.type in ["pier_diner","seafood_vendor","off_lead_dog","sunbather","picnic_family","toddler"]:
					check.call(absf(float(spawn.x)-float(stands[i].customer_x)) >= clear,"level %d %s at %d clear of stand %d customer slot" % [level.id,spawn.type,int(spawn.x),int(stands[i].x)])
	var stage := Node2D.new()
	root.add_child(stage)
	var spawner := BeachSpawner.new()
	spawner.setup(stage,{"seed":1,"id":1,"time_limit":90.0,"awareness_mult":1.0,"props":[],"spawns":[{"type":"sunbather","x":100.0}]})
	var sleeper: BeachTarget = spawner.targets[0]
	var rival := BeachGull.new()
	rival.rival = true
	rival.state = BeachGull.State.GROUNDED
	rival.position = Vector2(105,160)
	sleeper._tick_sleep(0.0,[rival])
	check.call(sleeper.sleep_state == BeachTarget.SleepState.WAKING,"rival standing on a sleeping sunbather wakes them at once")
	rival.free()
	stage.queue_free()
