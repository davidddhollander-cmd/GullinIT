class_name BenchVisit
extends RefCounted
## One simulation clock owns transitions and bites. No autonomous animation timers.
enum Phase { NONE, APPROACH, SIT, REST, STAND }
const TRANSITION: float = 0.5
var registry: BenchRegistry
var enabled: bool = false
var phase: Phase = Phase.NONE
var seat: Dictionary = {}
var timer: float = 0.0
var rest_time: float = 0.0
var bite: float = 0.0
var next_bite: float = 0.0
var cooldown: float = 0.0
var seat_facing: float = 1.0
var start_y: float = 160.0
var returning_to_lane: bool = false

func anchored() -> bool:
	return phase in [Phase.SIT,Phase.REST,Phase.STAND]

func eligible(owner: BeachTarget) -> bool:
	return enabled and registry != null and owner.kind == "kiosk_customer" and owner.food and not owner.leaving and not owner.service_locked and not owner.dropped_pending and owner.reaction.mode.is_empty() and owner.reaction.swat_timer < 0 and owner.recover <= 0 and owner.alert < 0.4 and ShopperArt.supports_bench(owner)

func consider(owner: BeachTarget, force: bool = false) -> bool:
	if phase != Phase.NONE or cooldown > 0 or not eligible(owner):
		return false
	# One roll per destination/purchase; never per frame.
	cooldown = owner.routine.random.randf_range(20.0,35.0)
	if not force and owner.routine.random.randf() >= 0.3:
		return false
	seat = registry.reserve(owner,owner.routine.bounds)
	if seat.is_empty():
		return false
	phase = Phase.APPROACH
	start_y = owner.position.y
	returning_to_lane = false
	return true

func interrupt(owner: BeachTarget) -> void:
	if phase == Phase.NONE or phase == Phase.STAND:
		return
	if phase == Phase.APPROACH:
		finish(owner)
	else:
		# Reverse from the current sit progress instead of popping to fully seated.
		timer = TRANSITION-timer if phase == Phase.SIT else TRANSITION
		phase = Phase.STAND
		bite = 0.0

func finish(owner: BeachTarget) -> void:
	if registry != null:
		registry.release(owner)
	returning_to_lane = true
	phase = Phase.NONE
	seat = {}
	cooldown = owner.routine.random.randf_range(20.0,35.0)
	owner.routine.resume(owner)

func tick(owner: BeachTarget, delta: float, gulls: Array[BeachGull]) -> bool:
	cooldown = maxf(0.0,cooldown-delta)
	if phase == Phase.NONE:
		if returning_to_lane:
			owner.position.y = move_toward(owner.position.y,start_y,float(Config.tuning.world.walk_speed)*owner.speed_mult*delta)
			returning_to_lane = not is_equal_approx(owner.position.y,start_y)
		return false
	if registry == null or not registry.owns(seat,owner):
		finish(owner)
		return false
	if not owner.food or owner.leaving or owner.service_locked or owner.dropped_pending or not owner.reaction.mode.is_empty():
		interrupt(owner)
		if phase == Phase.NONE:
			return false
	if phase == Phase.APPROACH:
		var before: float = owner.position.x
		var gap: float = float(seat.ground.x)-before
		if absf(gap) > 0.25:
			owner.facing = signf(gap)
		owner.position.x = move_toward(before,float(seat.ground.x),float(Config.tuning.world.walk_speed)*owner.speed_mult*delta)
		owner.position.y = move_toward(owner.position.y,float(seat.ground.y),float(Config.tuning.world.walk_speed)*owner.speed_mult*delta)
		owner.update_art_pose(not is_equal_approx(before,owner.position.x))
		# Existing proximity warning may cancel an approach immediately.
		if owner.reaction.tick(owner,delta,gulls):
			return true
		if owner.position.is_equal_approx(seat.ground):
			seat_facing = owner.facing
			phase = Phase.SIT
			timer = TRANSITION
	else:
		# Detect warnings, but freeze all standing reaction clocks until feet are free.
		owner.reaction.tick(owner,0.0,gulls)
		owner.facing = seat_facing
		if phase == Phase.SIT or phase == Phase.STAND:
			timer = maxf(0.0,timer-delta)
			if timer <= 0:
				if phase == Phase.STAND:
					finish(owner)
					owner.update_art_pose(false)
					return true
				phase = Phase.REST
				rest_time = owner.routine.random.randf_range(6.0,10.0)
				next_bite = 1.3
		elif phase == Phase.REST:
			rest_time -= delta
			bite = maxf(0.0,bite-delta)
			next_bite -= delta
			if next_bite <= 0:
				bite = 0.8
				next_bite = owner.routine.random.randf_range(2.0,3.5)
			if rest_time <= 0:
				interrupt(owner)
		owner.update_art_pose(false)
		if anchored():
			var weight: float = 1.0
			if phase == Phase.SIT:
				weight = progress()
			elif phase == Phase.STAND:
				weight = 1.0-progress()
			# Atlas seated hips sit ten world pixels above soles. Bench scale/y
			# comes from the actual prop rather than a universal ground constant.
			owner.position.y = lerpf(float(seat.ground.y),float(seat.hip.y)+10.0,weight)
	owner.queue_redraw()
	return true

func pose() -> StringName:
	match phase:
		Phase.SIT: return &"sit_down"
		Phase.STAND: return &"stand_up"
		_: return &"seated_eat" if bite > 0.0 else &"seated_idle"

func progress() -> float:
	if phase in [Phase.SIT,Phase.STAND]:
		return clampf(1.0-timer/TRANSITION,0.0,0.999)
	return clampf(1.0-bite/0.8,0.0,0.999) if bite > 0 else 0.0
