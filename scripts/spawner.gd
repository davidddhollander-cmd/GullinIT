class_name BeachSpawner
extends RefCounted
signal target_created(target: BeachTarget)
var targets: Array[BeachTarget] = []
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var parent: Node2D
var level: Dictionary
var kiosk_timer: float = 0.0
var replacements: Array[Dictionary] = []
var visual_offsets: Dictionary = {}
var previous_x: Dictionary = {}
var bag_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var shopper_serial: int = 0
const CROWD_OFFSETS: Array[Vector2] = [Vector2.ZERO, Vector2(26,-14), Vector2(-26,-14), Vector2(26,12), Vector2(-26,12), Vector2(52,0), Vector2(-52,0)]

func setup(owner_node: Node2D, definition: Dictionary) -> void:
	parent = owner_node
	level = definition
	rng.seed = int(level.seed)
	bag_rng.seed = int(level.seed) + 97
	shopper_serial = 0
	for spawn: Dictionary in level.spawns:
		var target: BeachTarget = create(spawn.type,spawn.x,spawn)
		# Authored buyers beside a stall begin with its visible purchase. The
		# distant training/strolling snacks still represent earlier purchases.
		if str(spawn.type)=="kiosk_customer" and str(spawn.get("station","")) in ["ice_cream","hotdogs"]:
			target.food = false
			target.food_sprite.hide()
			target.respawn = 0.0
	_link_families()
	kiosk_timer = Config.tuning.world.kiosk_rate

func create(kind: String, x: float, spawn: Dictionary = {}) -> BeachTarget:
	var target: BeachTarget = BeachTarget.new()
	parent.add_child(target)
	if kind == "kiosk_customer":
		spawn = spawn.duplicate()
		if not spawn.has("appearance"):
			spawn.appearance = ShopperArt.APPEARANCES[shopper_serial % ShopperArt.APPEARANCES.size()]
		shopper_serial += 1
	target.setup(kind,x,rng,level.awareness_mult,spawn)
	target.routine.setup(target,level,spawn)
	if kind == "sunbather":
		target.bag_variant = _free_bag_variant()
	target.departed.connect(_departed)
	targets.append(target)
	target_created.emit(target)
	return target

# Random bag style that no other sunbather in the level is using; reuses the least-used style if all are taken.
func _free_bag_variant() -> int:
	var counts: Array[int] = []
	counts.resize(BeachTarget.BAG_TEXTURES.size())
	counts.fill(0)
	for other: BeachTarget in targets:
		if other.kind == "sunbather":
			counts[other.bag_variant] += 1
	var fewest: int = counts.min()
	var choices: Array[int] = []
	for variant: int in counts.size():
		if counts[variant] == fewest:
			choices.append(variant)
	return choices[bag_rng.randi_range(0,choices.size()-1)]

func _link_families() -> void:
	var parents: Dictionary = {}
	var stand_x: float = 520.0
	for prop: Dictionary in level.props:
		if prop.type == "kiosk":
			stand_x = float(prop.x)
			break
	for target: BeachTarget in targets:
		if target.kind == "picnic_family" and not target.family_id.is_empty():
			parents[target.family_id] = target
			target.family_kiosk_x = stand_x
	for target: BeachTarget in targets:
		if target.kind != "toddler" or target.family_id.is_empty():
			continue
		var parent_target: BeachTarget = parents.get(target.family_id) as BeachTarget
		if is_instance_valid(parent_target):
			target.family_parent = parent_target
			parent_target.family_children.append(target)

func _departed(target: BeachTarget) -> void:
	replacements.append({"type":target.kind,"delay":float(Config.tuning.world.replacement_delay)})
	targets.erase(target)
	visual_offsets.erase(target)
	previous_x.erase(target)
	target.queue_free()

func reset_spacing() -> void:
	# Keep the simulation on its original ground line. Only the rendered scene
	# receives a short depth step when two people would occupy the same pixels.
	for target: BeachTarget in targets:
		if is_instance_valid(target):
			var offset: Vector2 = visual_offsets.get(target,Vector2.ZERO)
			target.position -= offset

func apply_spacing(delta: float) -> void:
	var placed: Dictionary = {}
	var ordered: Array[BeachTarget] = []
	# People standing still hold their place; walkers and chasers step around.
	for target: BeachTarget in targets:
		if is_instance_valid(target) and absf(target.position.x-float(previous_x.get(target,target.position.x))) <= 0.1:
			ordered.append(target)
	for target: BeachTarget in targets:
		if is_instance_valid(target) and absf(target.position.x-float(previous_x.get(target,target.position.x))) > 0.1:
			ordered.append(target)
	for target: BeachTarget in ordered:
		var desired: Vector2 = Vector2.ZERO
		if target.service_locked:
			placed[target] = desired
			continue
		for candidate: Vector2 in CROWD_OFFSETS:
			var clear: bool = true
			for other: BeachTarget in placed:
				if absf(target.position.x-other.position.x) > 75.0:
					continue
				var other_offset: Vector2 = placed[other]
				var min_x: float = 25.0 if target.kind == "toddler" or other.kind == "toddler" else 30.0
				if absf(target.position.x+candidate.x-other.position.x-other_offset.x) < min_x and absf(candidate.y-other_offset.y) < 14.0:
					clear = false
					break
			if clear:
				desired = candidate
				break
		placed[target] = desired
	for target: BeachTarget in ordered:
		var old_offset: Vector2 = visual_offsets.get(target,Vector2.ZERO)
		var next_offset: Vector2 = Vector2.ZERO if target.service_locked else old_offset.move_toward(placed[target],300.0*delta)
		previous_x[target] = target.position.x
		visual_offsets[target] = next_offset
		target.position += next_offset
		# The nearer feet cover the farther feet when paths briefly cross.
		target.z_index = 1 if next_offset.y < -4.0 else (3 if next_offset.y > 4.0 else 2)

func tick(delta: float, elapsed: float) -> void:
	for i: int in range(replacements.size()-1,-1,-1):
		replacements[i].delay -= delta
		if replacements[i].delay <= 0:
			var later: bool = rng.randf() < clampf(elapsed/float(level.time_limit),0.0,1.0)
			var x: float = float(Config.tuning.world.width)-20 if later else 20
			var target: BeachTarget = create(replacements[i].type,x)
			target.facing = -1 if later else 1
			replacements.remove_at(i)
	if int(level.id) >= 4:
		kiosk_timer -= delta
		if kiosk_timer <= 0:
			kiosk_timer = Config.tuning.world.kiosk_rate
			if targets.size() < int(Config.tuning.world.max_targets):
				var stands: Array[Dictionary] = []
				for prop: Dictionary in level.props:
					if prop.type in ["kiosk","hotdog_stand"]:
						stands.append(prop)
				if stands.is_empty():
					return
				var stand: Dictionary = stands[rng.randi_range(0,stands.size()-1)]
				var arrival_x: float = float(stand.get("customer_x",stand.x))
				for existing: BeachTarget in targets:
					if absf(existing.position.x-arrival_x) < float(Config.layout_rules.arrival_clearance):
						return
				var customer: BeachTarget = create("kiosk_customer",arrival_x,{"food_id":"hotdog" if stand.type == "hotdog_stand" else "ice_cream","patrol_radius":float(Config.layout_rules.patrol_radius)})
				customer.food = false
				customer.food_sprite.hide()
				customer.respawn = 0.0
				customer.facing = -1 if rng.randf() < 0.5 else 1
