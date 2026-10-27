class_name BeachRoutine
extends RefCounted
## One-dimensional walks share the beach's existing ground line and crowd spacing.
enum Phase { WALK, PAUSE }
var enabled: bool = false
var phase: Phase = Phase.WALK
var anchor: float = 0.0
var destination: float = 0.0
var pause: float = 0.0
var bounds: Vector2 = Vector2.ZERO
var profile: Dictionary = {}
var legs: int = 0
var random: RandomNumberGenerator = RandomNumberGenerator.new()

func setup(owner: BeachTarget, level: Dictionary, spawn: Dictionary) -> void:
	profile = Config.tuning.routines.get(owner.kind,{}).duplicate()
	if profile.is_empty() or int(level.id) == 1:
		return
	enabled = true
	anchor = owner.position.x
	random.seed = int(level.seed) + int(anchor*17) + owner.kind.hash()
	bounds = Vector2(20.0,float(Config.tuning.world.width)-20.0)
	var promenade: float = float(Config.tuning.world.promenade_start)
	if int(level.id) == 2:
		# Preserve the authored teaching areas, including the isolated snack kiosk.
		if spawn.has("bounds"):
			bounds = Vector2(float(spawn.bounds[0]),float(spawn.bounds[1]))
		elif str(spawn.get("station","")) == "ice_cream":
			bounds.x = 795.0
		else:
			bounds = Vector2(420.0,570.0)
	elif owner.kind == "pier_diner":
		bounds.x = maxf(20.0,float(Config.tuning.world.pier_start)-100.0)
	elif owner.kind in ["kiosk_customer","dog_owner"]:
		bounds.x = minf(anchor,maxf(20.0,promenade))
	if owner.kind == "lifeguard":
		for prop: Dictionary in level.props:
			if prop.type == "tower":
				anchor = float(prop.x)
				break
	anchor = clampf(anchor,bounds.x,bounds.y)
	_choose(owner)
	# Stagger people who begin at the same food station.
	if owner.kind in ["pier_diner","dog_owner"] or random.randf() < 0.35:
		_rest(owner)

func tick(owner: BeachTarget, delta: float) -> bool:
	if phase == Phase.PAUSE:
		pause = maxf(0.0,pause-delta)
		if pause <= 0.0:
			_choose(owner)
		return false
	var before: float = owner.position.x
	if absf(destination-before) > 0.25:
		owner.facing = signf(destination-before)
	owner.position.x = move_toward(before,destination,float(Config.tuning.world.walk_speed)*owner.speed_mult*delta)
	if is_equal_approx(owner.position.x,destination):
		legs += 1
		_rest(owner)
	return not is_equal_approx(before,owner.position.x)

func purchased(owner: BeachTarget, at: float) -> void:
	if not enabled:
		return
	anchor = clampf(at,bounds.x,bounds.y)
	legs = 0
	_choose(owner)
	# The next stop is away from the serving window, even near a map edge.
	if absf(destination-owner.position.x) < 60.0:
		destination = clampf(anchor+(-1.0 if anchor>(bounds.x+bounds.y)*0.5 else 1.0)*float(profile.min_distance),bounds.x,bounds.y)
	owner.bench_visit.consider(owner)

func resume(owner: BeachTarget) -> void:
	if enabled:
		_choose(owner)

func dining_returned(owner: BeachTarget) -> void:
	if not enabled:
		return
	# The meal source never becomes the diner's new strolling/dining home.
	anchor = owner.diner_home
	destination = anchor
	legs = 0
	_rest(owner)

func _choose(owner: BeachTarget) -> void:
	phase = Phase.WALK
	var radius: float = random.randf_range(float(profile.min_distance),float(profile.max_distance))
	if owner.kind == "kiosk_customer" and bounds.y-bounds.x >= 400.0 and random.randf() < 0.2:
		radius = random.randf_range(240.0,300.0)
	var left: float = maxf(bounds.x,anchor-radius)
	var right: float = minf(bounds.y,anchor+radius)
	if owner.kind == "pier_diner" and legs >= 2:
		destination = anchor
		legs = -1
	elif owner.kind == "lifeguard" and legs >= 2:
		destination = anchor
		legs = -1
	else:
		# Alternate sides with varied endpoints; avoid tiny reversals after service.
		destination = right if owner.position.x <= anchor else left
		if absf(destination-owner.position.x) < 20.0:
			destination = left if destination == right else right

func _rest(owner: BeachTarget) -> void:
	phase = Phase.PAUSE
	var eating: bool = owner.food and owner.kind == "kiosk_customer"
	pause = random.randf_range(4.0,8.0) if eating else random.randf_range(float(profile.pause_min),float(profile.pause_max))
	if owner.kind == "pier_diner" and absf(owner.position.x-anchor) < 2.0:
		pause = random.randf_range(6.0,12.0)
	owner.bench_visit.consider(owner)
