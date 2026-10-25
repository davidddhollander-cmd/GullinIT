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
var benches: BenchRegistry = BenchRegistry.new()
var lane_holds: Dictionary = {} # target -> {"y": held lane offset, "t": seconds left}
var depth_props: Array[Rect2] = [] # x-extent and base y (as position.y) of ground props
const DEPTH_PROP_TYPES: Array[String] = ["bin","wheelie_bin","beach_bench","beach_chair_blue","beach_castle","beach_rocks"]
const SUNBATHER_LOOKS: Array[String] = ["male_red","male_blue","female_red","female_blue"]
const BEHIND_PROP_Z: int = 0 # below ordinary scenery (z 1); crabs in the rear lane share it
const LANE_GRACE: float = 0.5 # seconds a held lane may stay blocked before the walker changes lane
const CROWD_OFFSETS: Array[Vector2] = [Vector2.ZERO, Vector2(26,-14), Vector2(-26,-14), Vector2(26,12), Vector2(-26,12), Vector2(52,0), Vector2(-52,0)]

func setup(owner_node: Node2D, definition: Dictionary) -> void:
	parent = owner_node
	level = definition
	rng.seed = int(level.seed)
	bag_rng.seed = int(level.seed) + 97
	benches.setup(level.props)
	depth_props.clear()
	for prop: Dictionary in level.props:
		if str(prop.type) in DEPTH_PROP_TYPES and Config.sprites.has(prop.type):
			var width: float = float(Config.sprites[prop.type].frame_w)*float(Config.sprites[prop.type].get("visual_scale",1.0))*0.4
			depth_props.append(Rect2(float(prop.x)-width,float(prop.get("y",160)),width*2.0,0.0))
	for spawn: Dictionary in level.spawns:
		if spawn.type == "off_lead_dog":
			continue # BeachGame owns the dog; it is not a BeachTarget.
		var target: BeachTarget = create(spawn.type,spawn.x,spawn)
		# Authored buyers beside a stall begin with its visible purchase. The
		# distant training/strolling snacks still represent earlier purchases.
		if str(spawn.type)=="kiosk_customer" and str(spawn.get("station","")) in ["ice_cream","hotdogs"]:
			target.food = false
			target.food_sprite.hide()
			target.respawn = 0.0
	_seat_starter()
	_link_families()
	kiosk_timer = Config.tuning.world.kiosk_rate

# Every level with a bench opens with one holding shopper already resting on the nearest one.
func _seat_starter() -> void:
	var best: BeachTarget = null
	var best_seat: Dictionary = {}
	var best_gap: float = INF
	# Prefer shoppers already holding food; otherwise hand the nearest one their own snack.
	for holding: bool in [true,false]:
		for target: BeachTarget in targets:
			if not target.bench_visit.enabled or (holding and not target.food) or target.food_id.is_empty() or not ShopperArt.supports_bench(target):
				continue
			for seat: Dictionary in benches.seats:
				var gap: float = absf(target.position.x-float(seat.ground.x))
				if gap < best_gap:
					best = target
					best_seat = seat
					best_gap = gap
		if best != null:
			break
	if best != null:
		best.food = true
		best.food_sprite.show()
		best.respawn = 0.0
		best.bench_visit.start_seated(best,best_seat)

func create(kind: String, x: float, spawn: Dictionary = {}) -> BeachTarget:
	var target: BeachTarget = BeachTarget.new()
	parent.add_child(target)
	if kind in ["kiosk_customer","sunbather","pier_diner"] and not spawn.has("appearance"):
		spawn = spawn.duplicate()
		spawn.appearance = _least_used_look(kind)
	target.setup(kind,x,rng,level.awareness_mult,spawn)
	target.routine.setup(target,level,spawn)
	target.bench_visit.registry = benches
	target.bench_visit.enabled = int(level.id) > 2 and kind == "kiosk_customer"
	if kind == "sunbather":
		target.bag_variant = _free_bag_variant()
	target.departed.connect(_departed)
	targets.append(target)
	target_created.emit(target)
	return target

# Look for this kind that the fewest people on the beach already wear; ties take list order.
func _least_used_look(kind: String) -> String:
	var looks: Array[String] = []
	match kind:
		"kiosk_customer":
			looks = ShopperArt.APPEARANCES
		"sunbather":
			looks = SUNBATHER_LOOKS
		"pier_diner":
			looks = PierDinerArt.APPEARANCES
		_:
			return ""
	var best: String = looks[0]
	var best_count: int = 1 << 30
	for look: String in looks:
		var count: int = 0
		for other: BeachTarget in targets:
			if is_instance_valid(other) and other.kind == kind and _target_look(other) == look:
				count += 1
		if count < best_count:
			best = look
			best_count = count
	return best

func _target_look(target: BeachTarget) -> String:
	match target.kind:
		"kiosk_customer":
			return target.shopper_appearance
		"sunbather":
			return _sunbather_look(target)
		"pier_diner":
			return target.diner_appearance
	return ""

func _sunbather_look(target: BeachTarget) -> String:
	return ("female_" if target.sunbather_female else "male_")+("blue" if target.sunbather_blue else "red")

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
	benches.release(target)
	replacements.append({"type":target.kind,"delay":float(Config.tuning.world.replacement_delay)})
	targets.erase(target)
	visual_offsets.erase(target)
	lane_holds.erase(target)
	previous_x.erase(target)
	target.queue_free()

func reset_spacing() -> void:
	# Keep the simulation on its original ground line. Only the rendered scene
	# receives a short depth step when two people would occupy the same pixels.
	for target: BeachTarget in targets:
		if is_instance_valid(target):
			var offset: Vector2 = visual_offsets.get(target,Vector2.ZERO)
			target.position -= offset

func _ground_lane_family(target: BeachTarget) -> bool:
	return target.kind in ["picnic_family","toddler"]

func _family_offset(target: BeachTarget, placed: Dictionary) -> Vector2:
	# Families own the ground lane. Choose the closest horizontal gap, including
	# during handovers/service; these offsets never change simulation positions.
	var desired_x: float = target.position.x
	var preferred_side: float = 1.0
	if is_instance_valid(target.family_parent):
		var gap: float = target.position.x-target.family_parent.position.x
		preferred_side = signf(gap) if absf(gap)>0.25 else (-1.0 if target.family_slot%2==0 else 1.0)
		# Follow mum's rendered displacement when another family occupies her
		# original spot, so the children do not stay behind on the other side.
		desired_x += Vector2(placed.get(target.family_parent,Vector2.ZERO)).x
	var candidates: Array[float] = [desired_x]
	for other: BeachTarget in placed:
		var at: Vector2 = other.position+Vector2(placed[other])
		if absf(target.position.y-at.y) >= 14.0:
			continue
		var space: float = 25.0 if target.kind=="toddler" or other.kind=="toddler" else 30.0
		candidates.append(at.x-space)
		candidates.append(at.x+space)
	for seat: Dictionary in benches.seats:
		var bounds: Rect2 = seat.walking_bounds
		candidates.append(bounds.position.x-0.1)
		candidates.append(bounds.end.x)
	var best := Vector2.ZERO
	var best_score: float = INF
	for x: float in candidates:
		if x < 12.0 or x > float(Config.tuning.world.width)-12.0:
			continue
		var candidate := Vector2(x-target.position.x,0)
		if not benches.clear_walking_offset(target.position,candidate).is_equal_approx(candidate):
			continue
		var clear: bool = true
		for other: BeachTarget in placed:
			var at: Vector2 = other.position+Vector2(placed[other])
			var space: float = 25.0 if target.kind=="toddler" or other.kind=="toddler" else 30.0
			if absf(target.position.y-at.y)<14.0 and absf(x-at.x)<space-0.01:
				clear = false
				break
		var score: float = absf(x-desired_x)+(0.01 if (x-desired_x)*preferred_side<0 else 0.0)
		if clear and score<best_score:
			best = candidate
			best_score = score
	return best

# First crowd offset that is clear of benches and already placed people; lane_y limits it to one lane.
func _free_offset(target: BeachTarget, placed: Dictionary, lane_y: float = NAN) -> Variant:
	for candidate: Vector2 in CROWD_OFFSETS:
		if not is_nan(lane_y) and not is_equal_approx(candidate.y,lane_y):
			continue
		if not benches.clear_walking_offset(target.position,candidate).is_equal_approx(candidate):
			continue
		var clear: bool = true
		for other: BeachTarget in placed:
			if absf(target.position.x-other.position.x) > 75.0:
				continue
			var other_offset: Vector2 = placed[other]
			var min_x: float = 25.0 if target.kind == "toddler" or other.kind == "toddler" else 30.0
			if absf(target.position.x+candidate.x-other.position.x-other_offset.x) < min_x and absf(target.position.y+candidate.y-other.position.y-other_offset.y) < 14.0:
				clear = false
				break
		if clear:
			return candidate
	return null

func apply_spacing(delta: float) -> void:
	var placed: Dictionary = {}
	var ordered: Array[BeachTarget] = []
	# People standing still hold their place; walkers and chasers step around.
	for target: BeachTarget in targets:
		if is_instance_valid(target) and target.bench_visit.anchored():
			ordered.append(target)
	# Place parents then children before walkers, so other people go around the
	# family instead of splitting it between depth lanes.
	for kind: String in ["picnic_family","toddler"]:
		for target: BeachTarget in targets:
			if is_instance_valid(target) and target.kind==kind and not target.bench_visit.anchored():
				ordered.append(target)
	for target: BeachTarget in targets:
		if is_instance_valid(target) and not _ground_lane_family(target) and not target.bench_visit.anchored() and absf(target.position.x-float(previous_x.get(target,target.position.x))) <= 0.1:
			ordered.append(target)
	for target: BeachTarget in targets:
		if is_instance_valid(target) and not _ground_lane_family(target) and not target.bench_visit.anchored() and absf(target.position.x-float(previous_x.get(target,target.position.x))) > 0.1:
			ordered.append(target)
	for target: BeachTarget in ordered:
		var desired: Vector2 = Vector2.ZERO
		if _ground_lane_family(target):
			placed[target] = _family_offset(target,placed)
			continue
		if target.service_locked or target.bench_visit.anchored():
			placed[target] = desired
			continue
		desired = benches.clear_walking_offset(target.position,desired)
		var hold: Dictionary = lane_holds.get(target,{})
		hold.t = float(hold.get("t",0.0))-delta
		var pick: Variant = null
		if hold.has("y"):
			# Lanes are sticky: drift home only once the hold is over, otherwise keep the current lane while it is clear.
			if hold.t <= 0.0 and not is_zero_approx(float(hold.y)):
				pick = _free_offset(target,placed,0.0)
			if pick == null:
				pick = _free_offset(target,placed,float(hold.y))
		# Someone passing through the lane is waited out briefly before stepping aside.
		hold.wait = 0.0 if pick != null else float(hold.get("wait",0.0))+delta
		hold.blocked = false
		if pick == null and (not hold.has("y") or hold.wait >= LANE_GRACE):
			hold.blocked = hold.t > 0.0 # the held lane is taken: release it early
			pick = _free_offset(target,placed)
		if pick == null and hold.has("offset"):
			pick = benches.clear_walking_offset(target.position,hold.offset) # nowhere clear: keep the spot and overlap briefly
		if pick != null:
			desired = pick
		hold.offset = desired
		if not hold.has("y"):
			hold.y = desired.y
			hold.t = 0.0
		elif not is_equal_approx(float(hold.y),desired.y):
			hold.y = desired.y
			hold.t = float(Config.tuning.world.lane_hold)
		lane_holds[target] = hold
		placed[target] = desired
	for target: BeachTarget in ordered:
		var old_offset: Vector2 = visual_offsets.get(target,Vector2.ZERO)
		var next_offset: Vector2 = Vector2.ZERO if target.service_locked or target.bench_visit.anchored() else old_offset.move_toward(placed[target],float(Config.tuning.world.lane_shift_speed)*delta)
		if _ground_lane_family(target):
			# Do not interpolate through another family member, or retain an old
			# rear-lane offset after this rule becomes active.
			next_offset = placed[target]
		elif not target.service_locked and not target.bench_visit.anchored():
			# A walker may enter the footprint already using the rear lane, or
			# interpolate across it even though the destination lane is clear.
			next_offset = benches.clear_walking_offset(target.position,next_offset)
		previous_x[target] = target.position.x
		visual_offsets[target] = next_offset
		target.position += next_offset
		# The nearer feet cover the farther feet when paths briefly cross.
		target.z_index = 1 if next_offset.y < -4.0 else (3 if next_offset.y > 4.0 else 2)
		# Y-sort against ground props: feet above the prop's base pass behind it, level or below pass in front.
		for prop: Rect2 in depth_props:
			if absf(target.position.x-(prop.position.x+prop.size.x*0.5)) < prop.size.x*0.5+6.0:
				target.z_index = BEHIND_PROP_Z if target.position.y < prop.position.y-4.0 else maxi(target.z_index,3)
				break

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
