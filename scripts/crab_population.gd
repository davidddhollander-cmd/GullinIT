class_name CrabPopulation
extends Node2D
signal crab_created(crab: BeachTarget)
var targets: Array[BeachTarget] = []
var random := RandomNumberGenerator.new()
var settings: Dictionary
var scenery: Array = []
var people_source: BeachSpawner
var enabled: bool = false
var wait: float = 0.0
var peck_wait: float = 0.0
var peck_attempted: bool = false
var serial: int = 0
var width: float = 0.0
var beach_bounds: Vector2

func setup(level: Dictionary, props: Array, people: BeachSpawner = null) -> void:
	settings = Config.tuning.crabs.duplicate(true)
	settings.merge(level.get("crabs",{}),true)
	enabled = bool(settings.get("enabled",false))
	scenery = props
	people_source = people
	var world: Dictionary = Config.default_world.duplicate(true)
	world.merge(level.get("world",{}),true)
	width = float(world.width)
	beach_bounds = Vector2(12.0,minf(width,minf(float(world.promenade_start),float(world.pier_start)))-12.0)
	random.seed = int(level.seed)+73021
	wait = float(settings.first_delay)

func tick(delta: float, camera_x: float, allow_spawning: bool = true, gulls: Array[BeachGull] = []) -> void:
	if delta <= 0.0:
		return
	peck_wait = maxf(0.0,peck_wait-delta)
	for target: BeachTarget in targets.duplicate():
		var crab: BeachCrab = target as BeachCrab
		if people_source != null:
			for person: BeachTarget in people_source.targets:
				if is_instance_valid(person) and not person.leaving and absf(person.position.x-crab.position.x)<float(settings.human_retreat_range):
					crab.disturb(person.position,true)
		crab.tick(delta,gulls)
	if not enabled or not allow_spawning:
		return
	wait -= delta
	if wait<=0 and targets.size()<int(settings.max_active):
		var origin: String = ["sea","left","right"][serial%3]
		var crab: BeachCrab = spawn(origin,camera_x)
		wait = random.randf_range(float(settings.interval_min),float(settings.interval_max)) if crab != null else float(settings.spawn_retry)

func _exclude(ranges: Array[Vector2], at: float, radius: float) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for span: Vector2 in ranges:
		if at+radius<=span.x or at-radius>=span.y:
			result.append(span)
		else:
			if at-radius>span.x:
				result.append(Vector2(span.x,at-radius))
			if at+radius<span.y:
				result.append(Vector2(at+radius,span.y))
	return result

func quiet_ranges() -> Array[Vector2]:
	var ranges: Array[Vector2] = []
	if beach_bounds.y<=beach_bounds.x:
		return ranges
	ranges.append(beach_bounds)
	for prop: Dictionary in scenery:
		var kind: String = str(prop.type)
		if kind in ["kiosk","hotdog_stand"]:
			ranges = _exclude(ranges,float(prop.x),64.0)
		elif kind in ["bin","wheelie_bin","beach_rocks","beach_castle","tower"]:
			ranges = _exclude(ranges,float(prop.x),24.0)
	if people_source != null:
		for person: BeachTarget in people_source.targets:
			if not is_instance_valid(person) or person.leaving:
				continue
			ranges = _exclude(ranges,person.position.x,float(settings.human_clearance))
			# Belongings keep their exclusion while their owner walks away.
			if person.kind == "sunbather":
				ranges = _exclude(ranges,person.stash_home_x,float(settings.human_clearance))
			elif person.kind == "picnic_family":
				ranges = _exclude(ranges,person.family_home,float(settings.human_clearance))
	return ranges

func clear_lane(x: float) -> bool:
	for span: Vector2 in quiet_ranges():
		if x>=span.x and x<=span.y:
			return true
	return false

func spawn(origin: String, camera_x: float, blue: bool = false) -> BeachCrab:
	if targets.size()>=int(settings.max_active):
		return null
	var ranges: Array[Vector2] = quiet_ranges()
	var left: float = clampf(camera_x-160.0,0.0,maxf(0.0,width-320.0))
	var right: float = minf(width,left+320.0)
	var x: float = left-12.0 if origin=="left" else right+12.0
	var pocket: Vector2 = Vector2.ZERO
	if origin in ["left","right"]:
		for span: Vector2 in ranges:
			if x>=span.x and x<=span.y and span.y-span.x>=24.0:
				pocket = span
				break
	if pocket == Vector2.ZERO:
		origin = "sea"
		var choices: Array[Vector2] = []
		for span: Vector2 in ranges:
			var visible: Vector2 = Vector2(maxf(span.x,left+12.0),minf(span.y,right-12.0))
			if visible.y-visible.x>=24.0:
				choices.append(visible)
		if choices.is_empty():
			return null
		var visible: Vector2 = choices[random.randi_range(0,choices.size()-1)]
		x = roundf(random.randf_range(visible.x+4.0,visible.y-4.0))
		for span: Vector2 in ranges:
			if x>=span.x and x<=span.y:
				pocket = span
				break
	for existing: BeachTarget in targets:
		if absf(existing.position.x-x)<float(settings.spawn_spacing):
			return null
	var radius: float = random.randf_range(float(settings.radius_min),float(settings.radius_max))
	var bounds: Vector2 = Vector2(maxf(pocket.x,x-radius),minf(pocket.y,x+radius))
	var crab := BeachCrab.new()
	add_child(crab)
	crab.prepare(Vector2(x,132.0 if origin=="sea" else float(Config.tuning.world.ground)-float(settings.rear_offset)),origin,-1.0 if origin=="right" else 1.0,blue or serial%2==1,settings,bounds,int(random.randi()))
	targets.append(crab)
	crab.departed.connect(remove)
	serial += 1
	crab_created.emit(crab)
	return crab

func remove(crab: BeachTarget) -> void:
	targets.erase(crab)
	crab.queue_free()

func peck(gull: BeachGull) -> bool:
	peck_attempted = false
	if peck_wait>0 or gull.state!=BeachGull.State.GROUNDED:
		return false
	for target: BeachTarget in targets.duplicate():
		var crab: BeachCrab = target as BeachCrab
		var feet_y: float = gull.position.y+float(Config.tuning.flight.feet_offset)
		if absf(feet_y-crab.position.y)<=6.0 and gull.beak().distance_to(crab.food_position())<=float(settings.peck_range) and crab.take(gull):
			peck_wait = float(settings.peck_cooldown)
			return true
	for target: BeachTarget in targets:
		if target.food and gull.beak().distance_to(target.food_position())<=float(settings.miss_range):
			peck_attempted = true
			target.knock_food(gull)
	if peck_attempted:
		peck_wait = float(settings.peck_cooldown)
	return false
