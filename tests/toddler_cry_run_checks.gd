extends RefCounted
class_name ToddlerCryRunChecks

static func run(check: Callable, toddler: BeachTarget) -> void:
	var parent: BeachTarget = toddler.family_parent
	if not is_instance_valid(parent):
		check.call(false,"toddler reaction test needs its designated mum")
		return
	var saved_position: Vector2 = toddler.position
	var saved_food: bool = toddler.food
	var saved_recover: float = toddler.recover
	var saved_cry_timer: float = toddler.toddler_cry_timer
	var saved_run_speed: float = toddler.toddler_run_speed
	var saved_active: bool = toddler.toddler_cry_run_active
	var saved_seeking: bool = toddler.seeking_parent
	var saved_trip: BeachTarget.FamilyTrip = parent.family_trip
	var saved_trip_timer: float = parent.family_trip_timer
	var duration: float = float(Config.tuning.world.toddler_cry_duration)
	for rate: int in [30,60,120]:
		parent.family_trip = BeachTarget.FamilyTrip.GATHER
		parent.family_trip_timer = duration + 1.0
		toddler.food = false
		toddler.position.x = parent.position.x + 100.0
		toddler.recover = 3.0
		toddler.toddler_cry_timer = duration
		toddler.toddler_run_speed = 0.0
		toddler.toddler_cry_run_active = true
		toddler.seeking_parent = false
		var before: float = toddler.position.x
		var cry_steps: int = int(ceil(duration*rate))
		for frame: int in range(maxi(0,cry_steps-1)):
			toddler.tick(1.0/rate,[])
		check.call(toddler.position.x < before,"toddler moves while crying at %d Hz" % rate)
		check.call(toddler.sprite.animation == &"walk" and toddler.toddler_cry_run_active,"crying run uses moving legs at %d Hz" % rate)
		toddler.tick(1.0/rate,[])
		check.call(toddler.position.x < before,"crying toddler continues moving at %d Hz" % rate)
		check.call(toddler.sprite.animation != &"cry","cry pose finishes before movement at %d Hz" % rate)
		var first_speed: float = toddler.toddler_run_speed
		var first_distance: float = absf(parent.position.x-toddler.position.x)
		toddler.tick(1.0/rate,[])
		check.call(absf(parent.position.x-toddler.position.x) < first_distance,"toddler starts toward mum after crying at %d Hz" % rate)
		check.call(toddler.toddler_run_speed > first_speed,"toddler accelerates into the run at %d Hz" % rate)
		# A near-mum approach remains clamped and never crosses her position.
		toddler.position.x = parent.position.x + 0.1
		toddler.toddler_cry_timer = 0.0
		toddler.recover = 0.0
		toddler._tick_toddler_cry_run(1.0/rate)
		check.call(toddler.position.x >= parent.position.x,"toddler cannot overshoot mum at %d Hz" % rate)
	toddler.position = saved_position
	toddler.food = saved_food
	toddler.recover = saved_recover
	toddler.toddler_cry_timer = saved_cry_timer
	toddler.toddler_run_speed = saved_run_speed
	toddler.toddler_cry_run_active = saved_active
	toddler.seeking_parent = saved_seeking
	parent.family_trip = saved_trip
	parent.family_trip_timer = saved_trip_timer
	toddler.update_art_pose()
