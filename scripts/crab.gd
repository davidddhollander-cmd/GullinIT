class_name BeachCrab
extends BeachTarget
## Habitat is fixed at arrival; actual feet/catch positions follow the lane.
enum Phase { EMERGE, SCUTTLE, CAUGHT, EXIT }
enum Activity { WALK, PAUSE, NOTICE, ESCAPE, SETTLE }
var phase: Phase = Phase.EMERGE
var activity: Activity = Activity.PAUSE
var activity_time: float = 0.0
var clock: float = 0.0
var entry: String = "sea"
var start: Vector2
var home_bounds: Vector2
var travel: float = 1.0
var age: float = 0.0
var exit_clock: float = 0.0
var exit_start: Vector2
var settings: Dictionary
var full_scale: float = 0.5
var rear_y: float = 146.0
var front_y: float = 160.0
var lane_target: float = 146.0
var lane_time: float = 0.0
var threat_latched: bool = false
var threat_position: Vector2
var retreat_on_notice: bool = false
var escape_destination: float = 0.0

func prepare(at: Vector2, origin: String, direction: float, blue: bool, tuning: Dictionary, bounds: Vector2 = Vector2.ZERO, seed_value: int = 1) -> void:
	kind = "crab"
	info = {"twist":"crab"}
	food_id = "crab"
	food = false
	entry = origin
	travel = direction
	settings = tuning
	position = at
	start = at
	home_bounds = bounds if bounds != Vector2.ZERO else Vector2(at.x-40.0,at.x+40.0)
	rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	front_y = float(Config.tuning.world.ground)
	rear_y = front_y-float(settings.rear_offset)
	lane_target = rear_y
	lane_time = rng.randf_range(float(settings.rear_stay_min),float(settings.rear_stay_max))
	sprite = AnimatedSprite2D.new()
	var sprite_id: String = "crab_blue" if blue else "crab_red"
	sprite.sprite_frames = Config.frames(sprite_id)
	full_scale = float(Config.sprites[sprite_id].get("visual_scale",1.0))
	sprite.animation = &"idle"
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	food_sprite = sprite
	sprite.modulate.a = 0.0
	_update_depth()

func apply_depth(depth: float) -> void:
	sprite.scale = Vector2.ONE*full_scale*depth
	sprite.position.y = -20.0*full_scale*depth

func _update_depth() -> void:
	var depth: float
	if position.y<rear_y:
		depth = lerpf(float(settings.sea_scale),float(settings.rear_scale),clampf((position.y-132.0)/(rear_y-132.0),0.0,1.0))
	else:
		depth = lerpf(float(settings.rear_scale),1.0,clampf((position.y-rear_y)/(front_y-rear_y),0.0,1.0))
	apply_depth(depth)
	z_index = 1 if position.y<front_y-4.0 else 3

func _enter_activity(next: Activity, duration: float) -> void:
	activity = next
	activity_time = duration

func _near_gull(gulls: Array[BeachGull], distance: float) -> BeachGull:
	for gull: BeachGull in gulls:
		if is_instance_valid(gull) and gull.visible and gull.state!=BeachGull.State.STUNNED and gull.position.y>=float(settings.threat_height) and absf(gull.position.x-position.x)<=distance:
			return gull
	return null

func disturb(from: Vector2, human: bool = false) -> void:
	if phase != Phase.SCUTTLE:
		return
	if human and activity in [Activity.ESCAPE,Activity.SETTLE]:
		leave_scene()
		return
	if activity == Activity.NOTICE:
		retreat_on_notice = retreat_on_notice or human
		return
	if threat_latched:
		return
	threat_latched = true
	threat_position = from
	retreat_on_notice = human
	lane_target = rear_y
	_enter_activity(Activity.NOTICE,float(settings.notice_time))

func _escape() -> void:
	var duration: float = rng.randf_range(float(settings.escape_min),float(settings.escape_max))
	travel = signf(position.x-threat_position.x)
	if is_zero_approx(travel):
		travel = -1.0 if position.x>(home_bounds.x+home_bounds.y)*0.5 else 1.0
	escape_destination = clampf(position.x+travel*float(settings.speed)*float(settings.escape_speed_mult)*duration,home_bounds.x,home_bounds.y)
	if absf(escape_destination-position.x)<8.0:
		leave_scene()
		return
	lane_target = rear_y
	_enter_activity(Activity.ESCAPE,duration)

func _advance_lane(delta: float) -> void:
	if activity in [Activity.WALK,Activity.PAUSE] and not threat_latched:
		lane_time -= delta
		if lane_time<=0.0:
			lane_target = front_y if lane_target==rear_y else rear_y
			lane_time = rng.randf_range(float(settings.rear_stay_min),float(settings.rear_stay_max)) if lane_target==rear_y else rng.randf_range(float(settings.front_stay_min),float(settings.front_stay_max))
	position.y = move_toward(position.y,lane_target,float(settings.lane_speed)*delta)
	_update_depth()

func tick(delta: float, gulls: Array[BeachGull]) -> void:
	if delta<=0.0 or phase==Phase.CAUGHT:
		return
	clock += delta
	sprite.frame = int(clock*(12.0 if activity==Activity.ESCAPE else 8.0))%6
	if phase==Phase.EXIT:
		exit_clock += delta
		var retreat: float = clampf(exit_clock/float(settings.retreat_time),0.0,1.0)
		position = exit_start.lerp(Vector2(exit_start.x,132.0),retreat)
		_update_depth()
		sprite.modulate.a = 1.0-retreat
		if retreat>=1.0:
			departed.emit(self)
		return
	age += delta
	if age>=float(settings.lifetime):
		leave_scene()
		return
	if phase==Phase.EMERGE:
		var progress: float = clampf(clock/float(settings.emerge_time),0.0,1.0)
		sprite.modulate.a = minf(1.0,progress*3.0)
		position.y = lerpf(start.y,rear_y,smoothstep(0.0,1.0,progress))
		if entry!="sea":
			position.x = clampf(position.x+travel*float(settings.speed)*delta,home_bounds.x,home_bounds.y)
		_update_depth()
		if progress>=1.0:
			phase = Phase.SCUTTLE
			food = true
			_enter_activity(Activity.PAUSE,0.3)
		return
	var nearby: BeachGull = _near_gull(gulls,float(settings.threat_range))
	var remaining_threat: BeachGull = _near_gull(gulls,float(settings.threat_reset_range))
	if remaining_threat==null and activity in [Activity.WALK,Activity.PAUSE]:
		threat_latched = false
	if nearby!=null:
		disturb(nearby.position)
	_advance_lane(delta)
	activity_time -= delta
	match activity:
		Activity.WALK:
			position.x = clampf(position.x+travel*float(settings.speed)*delta,home_bounds.x,home_bounds.y)
			if activity_time<=0.0 or position.x<=home_bounds.x or position.x>=home_bounds.y:
				travel *= -1.0
				_enter_activity(Activity.PAUSE,rng.randf_range(0.4,0.8))
		Activity.PAUSE:
			if activity_time<=0.0:
				_enter_activity(Activity.WALK,rng.randf_range(1.0,2.0))
		Activity.NOTICE:
			sprite.frame = 0
			if activity_time<=0.0:
				if retreat_on_notice:
					leave_scene()
				elif nearby!=null:
					_escape()
				else:
					_enter_activity(Activity.SETTLE,float(settings.settle_time))
		Activity.ESCAPE:
			position.x = move_toward(position.x,escape_destination,float(settings.speed)*float(settings.escape_speed_mult)*delta)
			if activity_time<=0.0 or is_equal_approx(position.x,escape_destination):
				_enter_activity(Activity.SETTLE,float(settings.settle_time))
		Activity.SETTLE:
			if activity_time<=0.0:
				if remaining_threat!=null:
					leave_scene()
				else:
					threat_latched = false
					lane_time = rng.randf_range(float(settings.rear_stay_min),float(settings.rear_stay_max))
					_enter_activity(Activity.PAUSE,0.4)

func take(gull: BeachGull) -> bool:
	if phase!=Phase.SCUTTLE or not food or not gull.can_collect_food(food_id):
		return false
	food = false
	phase = Phase.CAUGHT
	last_theft_direct = gull.state==BeachGull.State.STRIKE
	last_theft_handover = false
	food_sprite.hide()
	snatched.emit(self,gull,false)
	departed.emit(self)
	return true

func knock_food(gull: BeachGull) -> bool:
	# A nearby miss scares live prey, but never creates a dropped snack.
	if phase==Phase.SCUTTLE and activity!=Activity.ESCAPE and gull.can_collect_food(food_id):
		threat_position = gull.position
		threat_latched = true
		_escape()
	return false

func leave_scene() -> void:
	if phase in [Phase.EXIT,Phase.CAUGHT]:
		return
	food = false
	leaving = true
	exit_start = position
	exit_clock = 0.0
	phase = Phase.EXIT

func _draw() -> void:
	pass
