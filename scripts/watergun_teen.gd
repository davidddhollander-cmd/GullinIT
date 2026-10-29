class_name WatergunTeen
extends Node2D
## Levels 4-6 water-gun teenager. He patrols, spots the nearest gull (the player or a rival),
## shouts a warning, runs to firing range, plants his feet on a held aim pose, then fires one
## telegraphed water shot and keeps pressing until he is out of water or loses the gull.
## Unlike the terrier he never touches a gull: every threat is a projectile that can be dodged.
signal spotted(gull: BeachGull)
signal fired(shot: BeachWaterShot, direction: Vector2)
signal splashed(at: Vector2)
signal hit(gull: BeachGull)
signal gave_up
enum State { PATROL, SPOT, PURSUE, AIM, FIRE, RECOVER, GIVE_UP }
var state: State = State.PATROL
var home: Vector2 = Vector2(600, 700)
var facing: float = 1.0
var timer: float = 0.0
var shot_gap: float = 0.0
var rearm: float = 0.0
var engage_time: float = 0.0
var shots_fired: int = 0
var destination: float = 0.0
var resting: bool = true
var paused: bool = false
var aim_clip: StringName = &"shoot_level"
var target: BeachGull
var shots: Array[BeachWaterShot] = []
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var sprite: AnimatedSprite2D

func setup(x: float, home_range: Array, seed_value: int) -> void:
	var art: Dictionary = Config.sprites.watergun_teen
	rng.seed = seed_value
	home = Vector2(float(home_range[0]),float(home_range[1]))
	position = Vector2(x,float(Config.tuning.world.ground))
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Config.frames("watergun_teen")
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE*float(art.visual_scale)
	add_child(sprite)
	_patrol()

func _t() -> Dictionary:
	return Config.tuning.watergun_teen

func _shooting() -> Dictionary:
	return Config.sprites.watergun_teen.shooting

# Height of the barrel when he stands level, used to choose the aim pose.
func muzzle_level_y() -> float:
	var art: Dictionary = Config.sprites.watergun_teen
	var anchor: Array = _shooting().muzzle_anchors_source_px.shoot_level[int(_shooting().fire_frame_offset)]
	return position.y+float(art.sprite_offset_y)+(float(anchor[1])-float(art.frame_h)*0.5)*float(art.visual_scale)

func _in_leash(x: float) -> bool:
	var leash: float = float(_t().leash)
	return x >= home.x-leash and x <= home.y+leash

# A gull is a valid mark while it is in the leash, within aiming height and not already down.
func can_target(gull: BeachGull) -> bool:
	return is_instance_valid(gull) and gull.visible and gull.state != BeachGull.State.STUNNED and gull.invulnerable <= 0.0 \
		and _in_leash(gull.position.x) and absf(gull.position.y-muzzle_level_y()) <= float(_t().aim_max_dy)

func _nearest(gulls: Array[BeachGull], radius: float) -> BeachGull:
	var best: BeachGull
	var best_gap: float = INF
	for gull: BeachGull in gulls:
		var gap: float = gull.position.distance_to(position)
		if can_target(gull) and gap <= radius and gap < best_gap:
			best = gull
			best_gap = gap
	return best

func _face(x: float) -> void:
	if absf(x-position.x) > 0.5:
		facing = signf(x-position.x)

func _move(target_x: float, speed: float, delta: float) -> void:
	_face(target_x)
	position.x = clampf(move_toward(position.x,target_x,speed*delta),maxf(12.0,home.x-float(_t().leash)),minf(float(Config.tuning.world.width)-12.0,home.y+float(_t().leash)))

func _patrol() -> void:
	state = State.PATROL
	target = null
	resting = true
	timer = rng.randf_range(float(_t().rest_min),float(_t().rest_max))
	destination = rng.randf_range(home.x,home.y)

# Aim pose follows the mark's height against the level barrel.
func aim_clip_for(gull: BeachGull) -> StringName:
	var band: float = float(_t().aim_band)
	var offset: float = gull.position.y-muzzle_level_y()
	if offset < -band:
		return &"shoot_high"
	if offset > band:
		return &"shoot_low"
	return &"shoot_level"

func muzzle() -> Vector2:
	var art: Dictionary = Config.sprites.watergun_teen
	var anchor: Array = _shooting().muzzle_anchors_source_px[str(aim_clip)][int(_shooting().fire_frame_offset)]
	var half: float = float(art.frame_w)*0.5
	return position+Vector2(facing*(float(anchor[0])-half)*float(art.visual_scale),float(art.sprite_offset_y)+(float(anchor[1])-float(art.frame_h)*0.5)*float(art.visual_scale))

func tick(delta: float, gulls: Array[BeachGull]) -> void:
	var t: Dictionary = _t()
	_tick_shots(delta,gulls)
	shot_gap = maxf(0.0,shot_gap-delta)
	rearm = maxf(0.0,rearm-delta)
	var clip: StringName = &"idle"
	match state:
		State.PATROL:
			var mark: BeachGull = _nearest(gulls,float(t.notice_radius)) if rearm <= 0.0 else null
			if mark != null:
				target = mark
				_face(mark.position.x)
				state = State.SPOT
				timer = float(t.alert_time)
				spotted.emit(mark)
			elif resting:
				timer -= delta
				if timer <= 0.0:
					resting = false
			else:
				clip = &"walk"
				_move(destination,float(t.wander_speed),delta)
				if is_equal_approx(position.x,destination):
					_patrol()
		State.SPOT:
			clip = &"alert"
			if is_instance_valid(target):
				_face(target.position.x)
			timer -= delta
			if not can_target(target):
				_patrol()
			elif timer <= 0.0:
				state = State.PURSUE
				engage_time = 0.0
				shots_fired = 0
				shot_gap = 0.0
		State.PURSUE:
			clip = &"run"
			engage_time += delta
			target = _keep_or_swap(gulls)
			if target == null or engage_time >= float(t.chase_timeout) or shots_fired >= int(t.shots_per_engagement):
				_give_up()
			else:
				var gap: float = absf(target.position.x-position.x)
				_face(target.position.x)
				if gap > float(t.fire_range):
					_move(target.position.x,float(t.run_speed),delta)
				elif shot_gap <= 0.0:
					_begin_aim()
				else:
					clip = &"idle" # planted and reloading between pulses
		State.AIM:
			if not can_target(target):
				state = State.PURSUE
			else:
				# The pose is held on its first frame: this is the dodge window.
				_face(target.position.x)
				aim_clip = aim_clip_for(target)
				timer -= delta
				if timer <= 0.0:
					state = State.FIRE
					timer = float(t.muzzle_time)
					_fire()
		State.FIRE:
			timer -= delta
			if timer <= 0.0:
				state = State.RECOVER
				timer = float(t.recover_time)
		State.RECOVER:
			timer -= delta
			if timer <= 0.0:
				state = State.PURSUE
				shot_gap = float(t.shot_cooldown)
		State.GIVE_UP:
			clip = &"angry"
			timer -= delta
			if timer <= 0.0:
				_patrol()
	_animate(clip)

# Keeps the current mark while it stays valid; otherwise takes the nearest one in range.
func _keep_or_swap(gulls: Array[BeachGull]) -> BeachGull:
	var lose: float = float(_t().lose_radius)
	if can_target(target) and target.position.distance_to(position) <= lose:
		return target
	return _nearest(gulls,float(_t().notice_radius))

func _begin_aim() -> void:
	state = State.AIM
	timer = float(_t().aim_time)
	aim_clip = aim_clip_for(target)

func _fire() -> void:
	var t: Dictionary = _t()
	var from: Vector2 = muzzle()
	var speed: float = float(t.shot_speed)
	# Lead part of the gull's motion so a steady flyer is hit, but a swerve still dodges.
	var aim_point: Vector2 = target.position+target.velocity*(from.distance_to(target.position)/speed)*float(t.lead)
	var direction: Vector2 = aim_point-from
	direction = Vector2(facing*maxf(absf(direction.x),4.0),direction.y).normalized()
	var shot: BeachWaterShot = BeachWaterShot.new()
	var radius: Array = t.hit_radius
	shot.setup(from,direction*speed,float(t.shot_range),Vector2(float(radius[0]),float(radius[1])))
	get_parent().add_child(shot)
	shots.append(shot)
	shots_fired += 1
	fired.emit(shot,direction)

func _tick_shots(delta: float, gulls: Array[BeachGull]) -> void:
	for i: int in range(shots.size()-1,-1,-1):
		var shot: BeachWaterShot = shots[i]
		if not is_instance_valid(shot):
			shots.remove_at(i)
			continue
		var victim: BeachGull = shot.tick(delta,gulls)
		if victim == null and not shot.landed:
			continue
		if victim != null:
			victim.stun(float(_t().hit_stun),position)
		splashed.emit(shot.position)
		if victim != null and victim.state == BeachGull.State.STUNNED:
			hit.emit(victim)
		shots.remove_at(i)
		shot.queue_free()

func _give_up() -> void:
	state = State.GIVE_UP
	timer = float(_t().give_up_time)
	rearm = float(_t().rearm_time)
	target = null
	gave_up.emit()

func _animate(clip: StringName) -> void:
	sprite.flip_h = facing < 0
	sprite.position.y = float(Config.sprites.watergun_teen.sprite_offset_y)
	if state == State.AIM or state == State.FIRE or state == State.RECOVER:
		# The state machine drives these frames so the fire frame is exact: aim, fire, recover.
		sprite.animation = aim_clip
		sprite.frame = 0 if state == State.AIM else (int(_shooting().fire_frame_offset) if state == State.FIRE else 2)
		sprite.pause()
	elif sprite.animation != clip or (not sprite.is_playing() and clip != &"angry"):
		sprite.play(clip)
	sprite.speed_scale = 0.0 if paused else 1.0
