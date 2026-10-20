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
			{"type": "picnic_family", "x": 200.0},
			{"type": "picnic_family", "x": 202.0}
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
