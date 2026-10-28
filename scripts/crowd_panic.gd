class_name CrowdPanic
extends RefCounted
## Gang Call crowd reaction: look up at the warning, run from the player when the first gull hits,
## then walk back to the spot they left. While active it overrides every other reaction.
enum State { NONE, LOOK_UP, PANIC, RETURN }
const LOOK_UP_CLIPS: Array[StringName] = [&"look_up",&"surprise",&"alert"]
const PANIC_CLIPS: Array[StringName] = [&"panic_run",&"run",&"chase",&"walk"]
const TODDLER_LOOK_UP_CLIPS: Array[StringName] = [&"look_up",&"cry"]
const TODDLER_PANIC_CLIPS: Array[StringName] = [&"panic_run",&"cry_run"]
## Fallback walk cycles are played faster so they read as running.
const WALK_RUN_SCALE: float = 3.0
var state: State = State.NONE
var timer: float = 0.0
var stampede_pending: bool = false
var home: float = 0.0
var direction: float = 1.0
var bounds: Vector2 = Vector2.ZERO

static func settings() -> Dictionary:
	return Config.tuning.panic

## Everyone in range looks up; the dive that follows is timed by BeachBrash.
static func warn(targets: Array[BeachTarget], from_x: float) -> void:
	for target: BeachTarget in targets:
		if is_instance_valid(target) and absf(target.position.x-from_x) <= float(settings().panic_radius):
			target.panic.look_up(target)

## The first gull hit: everyone still looking up bolts away from the player.
static func stampede(targets: Array[BeachTarget], from_x: float) -> void:
	for target: BeachTarget in targets:
		if is_instance_valid(target) and target.panic.state == State.LOOK_UP:
			target.panic.stampede_pending = true
			target.panic.direction = signf(target.position.x-from_x) if not is_zero_approx(target.position.x-from_x) else -target.facing

## The gang was cancelled before it struck.
static func calm(targets: Array[BeachTarget]) -> void:
	for target: BeachTarget in targets:
		if is_instance_valid(target) and target.panic.state == State.LOOK_UP:
			target.panic.state = State.NONE

func look_up(owner: BeachTarget) -> void:
	if state != State.NONE or owner.is_loose() or owner.leaving:
		return
	state = State.LOOK_UP
	timer = float(settings().look_up_time)
	stampede_pending = false
	home = owner.position.x
	var width: float = float(Config.tuning.world.width)
	bounds = Vector2(20.0,width-20.0)
	if owner.kind == "pier_diner":
		bounds.x = minf(float(Config.tuning.world.pier_start),home)
	elif owner.kind == "sunbather":
		bounds = Vector2(minf(float(Config.tuning.world.beach_min_x),home),maxf(float(Config.tuning.world.beach_max_x),home))
		owner.sleep_state = BeachTarget.SleepState.AWAKE
		owner.stash_standing = true
		owner.rise_remaining = 0.0
	if owner.kind == "pier_diner" and owner.diner_meal == BeachTarget.DinerMeal.SEEK:
		owner.diner_meal = BeachTarget.DinerMeal.DINING
	# Existing interrupt paths: a bench visit stands up, a stall order is cancelled.
	owner.bench_visit.interrupt(owner)
	if owner.stall_service != null:
		owner.stall_service.abort(owner)
	_clear_reaction(owner)
	owner.toddler_run_speed = 0.0
	owner.queue_redraw()

## Panic outranks theft chases, swats and warnings; food in hand is left alone.
func _clear_reaction(owner: BeachTarget) -> void:
	owner.reaction.mode = ""
	owner.reaction.swat_timer = -1.0
	owner.reaction.committed = false
	owner.alert = 0.0
	owner.defense = 0.0
	owner.windup = -1.0
	owner.biting = 0.0
	owner.action_pose_time = 0.0
	owner.mum_swat_time = 0.0
	owner.lifeguard_whistle_time = 0.0

## Returns true while the person is under panic control for this frame.
func tick(owner: BeachTarget, delta: float, gulls: Array[BeachGull]) -> bool:
	if state == State.NONE:
		return false
	if state == State.RETURN and not owner.reaction.mode.is_empty():
		# A theft on the walk back is handled by the ordinary reaction.
		state = State.NONE
		return false
	if state != State.RETURN:
		_clear_reaction(owner)
	# A seated person finishes standing up before looking up or running.
	if owner.bench_visit.tick(owner,delta,gulls):
		return true
	var walk: float = float(Config.tuning.world.walk_speed)*owner.speed_mult
	var moving: bool = false
	match state:
		State.LOOK_UP:
			timer = maxf(0.0,timer-delta)
			if stampede_pending and timer <= 0.0:
				state = State.PANIC
				timer = float(settings().panic_time)
				owner.facing = direction
				owner.seeking_parent = false
				owner.toddler_cry_run_active = false
		State.PANIC:
			timer -= delta
			owner.facing = direction
			owner.position.x = clampf(owner.position.x+direction*walk*float(settings().panic_speed_mult)*delta,bounds.x,bounds.y)
			moving = true
			if timer <= 0.0:
				state = State.RETURN
		State.RETURN:
			var gap: float = home-owner.position.x
			if absf(gap) <= 0.25:
				owner.position.x = home
				state = State.NONE
				if owner.kind == "sunbather":
					SunbatherArt.reaction_pose(owner,&"stand",0.0)
				owner.update_art_pose(false)
				_resume_chase(owner,gulls)
				return false
			owner.facing = signf(gap)
			owner.position.x = move_toward(owner.position.x,home,walk*float(settings().return_speed_mult)*delta)
			moving = true
	owner.update_art_pose(moving)
	owner.queue_redraw()
	return true

## Back at their spot, people go after the nearest player gull (the ordinary chase) instead of idling.
func _resume_chase(owner: BeachTarget, gulls: Array[BeachGull]) -> void:
	var best: BeachGull
	for gull: BeachGull in gulls:
		if is_instance_valid(gull) and not gull.rival and (best == null or absf(gull.position.x-owner.position.x) < absf(best.position.x-owner.position.x)):
			best = gull
	if best != null:
		owner.reaction.theft(owner,best)

## First clip from the chain the sheet has. Sheets with drawn "_left" clips use them instead of flipping.
static func resolve(frames: SpriteFrames, chain: Array[StringName], facing: float) -> Dictionary:
	for clip: StringName in chain:
		if facing < 0.0 and frames.has_animation(StringName(String(clip)+"_left")):
			return {"clip":StringName(String(clip)+"_left"),"flip":false}
		if frames.has_animation(clip):
			return {"clip":clip,"flip":facing < 0.0}
	return {}

## Plays the look-up or panic pose for the family art scripts; false when the person isn't panicking.
static func present(target: BeachTarget) -> bool:
	var current: State = target.panic.state
	if current == State.NONE or (current == State.RETURN and target.kind != "sunbather"):
		return false
	var toddler: bool = target.kind == "toddler"
	var chain: Array[StringName]
	if current == State.PANIC:
		chain = TODDLER_PANIC_CLIPS if toddler else PANIC_CLIPS
	elif current == State.LOOK_UP:
		chain = TODDLER_LOOK_UP_CLIPS if toddler else LOOK_UP_CLIPS
	else:
		chain = [&"walk"]
	var pick: Dictionary = resolve(target.sprite.sprite_frames,chain,target.facing)
	if pick.is_empty():
		return false
	target.sprite.flip_h = pick.flip
	target.sprite.play(pick.clip,WALK_RUN_SCALE if String(pick.clip).begins_with("walk") and current == State.PANIC else 1.0)
	if target.kind == "sunbather":
		target.sprite.visible = true
		target.sprite.position = Vector2(0,-26)
		target.sprite.rotation = 0.0
	return true
