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
	spawner.apply_spacing(1.0)
	check.call(second.position == Vector2(280,160), "visual offset clears once people part")
	stage.queue_free()
	_bench_lanes(root,check)
	_family_lane(root,check)

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
