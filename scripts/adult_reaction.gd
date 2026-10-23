class_name AdultReaction
extends RefCounted
const THEFT_SURPRISE_TIME: float = 0.32
const FAILED_CHASE_ANGER_TIME: float = 0.9
var mode: String = ""
var timer: float = 0
var window: float = 0
var cooldown: float = 0
var near: Dictionary = {}
var focus: BeachGull
var home: float = 0
var swat: float = 0
var swat_timer: float = -1
var committed: bool = false
var escape_direction: float = 1.0

func _is_original_shopper(owner: BeachTarget) -> bool:
	return owner.kind == "kiosk_customer" and owner.shopper_appearance == "kiosk_customer"

func _uses_theft_reaction_pilot(owner: BeachTarget) -> bool:
	return _is_original_shopper(owner) or owner.kind == "pier_diner"

func theft(owner: BeachTarget, gull: BeachGull, perfect: bool = false) -> void:
	if owner.kind == "toddler" or owner.leaving:
		return
	if owner.kind == "sunbather" and owner.sleep_state != BeachTarget.SleepState.AWAKE:
		return
	if owner.kind == "sunbather" and mode in ["notice","chase"]:
		return
	if mode.is_empty():
		home = owner.position.x
	focus = gull
	committed = perfect and owner.kind in ["kiosk_customer","pier_diner"]
	if committed:
		home = owner.position.x
		escape_direction = signf(gull.velocity.x) if absf(gull.velocity.x)>1.0 else signf(gull.direction.x)
		if is_zero_approx(escape_direction):
			escape_direction = owner.facing
		if _uses_theft_reaction_pilot(owner):
			owner.facing = escape_direction
	mode = "notice" if owner.kind == "sunbather" else ("surprise" if committed and _uses_theft_reaction_pilot(owner) else "chase")
	if mode == "notice":
		timer = float(Config.tuning.world.sunbather_notice_delay)*owner.reaction_delay
	elif mode == "surprise":
		timer = THEFT_SURPRISE_TIME
	else:
		timer = float(Config.tuning.world.snatch_chase_time) if committed else 3.0
	swat_timer = -1.0
	window = 5

func tick(owner: BeachTarget, delta: float, gulls: Array[BeachGull]) -> bool:
	if owner.kind == "toddler" or owner.leaving:
		return false
	if owner.kind == "sunbather" and owner.sleep_state != BeachTarget.SleepState.AWAKE:
		return false
	window = maxf(0,window-delta)
	cooldown = maxf(0,cooldown-delta)
	swat = maxf(0,swat-delta)
	for gull: BeachGull in gulls:
		var close: bool = absf(gull.position.x-owner.position.x) < 38 and gull.position.y > 105 and gull.state != BeachGull.State.STUNNED
		if close and not near.get(gull,false) and mode.is_empty() and cooldown <= 0:
			if window > 0:
				theft(owner,gull)
			else:
				home = owner.position.x
				focus = gull
				mode = "warning"
				timer = (float(Config.tuning.world.sunbather_warning_time) if owner.kind == "sunbather" else 0.35) * owner.reaction_delay
				window = 5
				owner.alert = maxf(owner.alert,0.5)
		if close:
			near[gull] = true
		elif absf(gull.position.x-owner.position.x) > 52 or gull.position.y < 95:
			near[gull] = false
	if mode.is_empty():
		return false
	if owner.bench_visit.phase != BenchVisit.Phase.NONE:
		owner.bench_visit.interrupt(owner)
		if owner.bench_visit.anchored():
			owner.update_art_pose(false)
			return true
	if mode == "surprise":
		owner.facing = escape_direction
	elif is_instance_valid(focus) and mode in ["warning","notice"]:
		owner.facing = signf(focus.position.x-owner.position.x) if absf(focus.position.x-owner.position.x)>1 else owner.facing
	timer -= delta
	var moving: bool = false
	var whistle_pause: bool = owner.kind == "lifeguard" and owner.lifeguard_whistle_time > 0
	if mode == "surprise":
		if timer <= 0.0:
			# The full bounded pursuit begins after, rather than during, the readable beat.
			mode = "chase"
			timer = float(Config.tuning.world.snatch_chase_time)
	elif mode == "warning":
		if timer <= 0:
			# A warning only connects if the gull ignores it and stays within reach.
			if is_instance_valid(focus) and focus.position.distance_to(owner.position-Vector2(0,12)) < 24:
				_hit(owner)
			mode = "follow"
			timer = 0.3
	elif mode == "follow":
		if timer <= 0:
			mode = ""
	elif mode == "notice":
		if timer <= 0:
			owner.stash_standing = true
			mode = "chase"
			timer = 3
	elif mode == "chase":
		if not is_instance_valid(focus) or timer <= 0 or (not committed and (focus.position.y < 100 or absf(focus.position.x-home)>85)):
			mode = "give_up" if committed else "return"
			timer = (FAILED_CHASE_ANGER_TIME if _uses_theft_reaction_pilot(owner) else float(Config.tuning.world.snatch_give_up_time)) if committed else 0.0
			swat_timer = -1
			if _uses_theft_reaction_pilot(owner):
				owner.facing = escape_direction
		else:
			var reach: float = float(Config.tuning.world.snatch_chase_distance) if committed else 80.0
			var destination: float = clampf(focus.position.x,home-reach,home+reach)
			if committed and focus.position.y < 100 and absf(destination-owner.position.x)<12.0:
				destination = home+escape_direction*reach
			destination = clampf(destination,20.0,float(Config.tuning.world.width)-20.0)
			if owner.kind == "sunbather":
				destination = clampf(destination,float(Config.tuning.world.beach_min_x),float(Config.tuning.world.beach_max_x))
			owner.facing = signf(destination-owner.position.x) if absf(destination-owner.position.x)>1 else owner.facing
			moving = absf(destination-owner.position.x)>4
			if swat_timer >= 0:
				swat_timer -= delta
				if swat_timer <= 0:
					_hit(owner)
					swat_timer = -1
					swat = 1.2
			elif focus.position.distance_to(owner.position-Vector2(0,12)) < 24 and swat <= 0:
				swat_timer = maxf(0.4,0.4 * owner.reaction_delay)
			elif moving and not whistle_pause:
				owner.position.x = move_toward(owner.position.x,destination,(30.0 if owner.kind == "sunbather" else 45.0)*delta)
	elif mode == "give_up":
		if _uses_theft_reaction_pilot(owner):
			# Planted presentation only: this state never arms the swat timer or calls _hit().
			owner.facing = escape_direction
		if timer <= 0.0:
			committed = false
			cooldown = 1.0
			if owner.routine.enabled:
				owner.routine.resume(owner)
				mode = ""
			else:
				mode = "return"
	elif mode == "return":
		owner.facing = signf(home-owner.position.x) if absf(home-owner.position.x)>1 else owner.facing
		moving = absf(home-owner.position.x)>0.25
		if not whistle_pause:
			owner.position.x = move_toward(owner.position.x,home,30*delta)
		if not moving:
			owner.position.x = home
			mode = ""
			cooldown = 1
	if owner.kind == "sunbather":
		owner.sunbather_run_time += delta
		if mode == "warning":
			SunbatherArt.pose(owner,&"alert",clampi(int((0.38-timer)*10.0),0,3))
		elif mode == "notice":
			SunbatherArt.reaction_pose(owner,&"stand",0.0)
		elif mode.is_empty() and not owner.stash_active:
			owner.stash_standing = false
			SunbatherArt.pose(owner,&"rest",0)
		else:
			SunbatherArt.reaction_pose(owner,&"windup" if swat_timer >= 0 or mode == "follow" else (&"run" if moving else &"stand"),1.0 if mode == "follow" else 0.5,int(owner.sunbather_run_time*10)%7)
	else:
		owner.update_art_pose(moving)
		if owner.kind not in ["picnic_family","kiosk_customer","dog_owner","pier_diner","lifeguard"]:
			var pose: StringName = &"swat" if swat_timer >= 0 or mode == "warning" else (&"walk" if moving else &"eat")
			if owner.sprite.sprite_frames.has_animation(pose):
				owner.sprite.play(pose)
			owner.sprite.flip_h = owner.facing < 0
	owner.queue_redraw()
	return true

func _hit(owner: BeachTarget) -> void:
	if is_instance_valid(focus) and focus.position.distance_to(owner.position-Vector2(0,12)) < 24:
		if owner.kind in ["pier_diner","lifeguard","kiosk_customer"]:
			owner.action_pose_time = 0.28
		focus.stun(-1.0,owner.position)
		owner.mum_swat_time = 0.25
