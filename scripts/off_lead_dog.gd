class_name OffLeadDog
extends Node2D
## Level 4 terrier: wanders, warns, chases on the sand and in low flight, leaps, catches.
## It only ever interacts with the player gull and never touches food or rivals.
signal barked
signal caught
signal outrun
enum State { WANDER, SNIFF, WARN, CHASE, LEAP, CATCH, COOLDOWN }
var state: State = State.WANDER
var home: Vector2 = Vector2(250, 410)
var facing: float = 1.0
var timer: float = 0.0
var chase_time: float = 0.0
var leap_gap: float = 0.0
var air: float = 0.0
var destination: float = 0.0
var resting: bool = true
var paused: bool = false
var cooldown_sniff: bool = false
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var sprite: AnimatedSprite2D

func setup(x: float, home_range: Array, seed_value: int) -> void:
	var art: Dictionary = Config.sprites.off_lead_dog
	rng.seed = seed_value
	home = Vector2(float(home_range[0]), float(home_range[1]))
	position = Vector2(x, float(Config.tuning.world.ground))
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Config.frames("off_lead_dog")
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * float(art.visual_scale)
	add_child(sprite)
	_wander()

func _t() -> Dictionary:
	return Config.tuning.off_lead_dog

# Height of the gull's body above the sand line.
func gull_height(gull: BeachGull) -> float:
	return float(Config.tuning.world.ground) - gull.position.y

func mouth() -> Vector2:
	return position + Vector2(facing * float(_t().mouth_x), float(_t().mouth_y) - air)

func _can_chase(gull: BeachGull) -> bool:
	return gull.state != BeachGull.State.STUNNED and gull.invulnerable <= 0.0 and gull_height(gull) < float(_t().chase_ceiling)

func _wander() -> void:
	state = State.WANDER
	resting = true
	timer = rng.randf_range(float(_t().rest_min), float(_t().rest_max))
	destination = rng.randf_range(home.x, home.y)

func _face(x: float) -> void:
	if absf(x - position.x) > 0.5:
		facing = signf(x - position.x)

func _move(target_x: float, speed: float, delta: float) -> void:
	_face(target_x)
	position.x = clampf(move_toward(position.x, target_x, speed * delta), 12.0, float(Config.tuning.world.width) - 12.0)

func tick(delta: float, gull: BeachGull) -> void:
	var t: Dictionary = _t()
	var notice: bool = _can_chase(gull) and absf(gull.position.x - position.x) <= float(t.notice_radius)
	leap_gap = maxf(0.0, leap_gap - delta)
	var clip: StringName = &"idle"
	var rate: float = 1.0
	match state:
		State.WANDER:
			if notice:
				_start_warn(gull)
			elif resting:
				timer -= delta
				if timer <= 0.0:
					resting = false
			else:
				clip = &"run"
				rate = 0.5
				_move(destination, float(t.wander_speed), delta)
				if is_equal_approx(position.x, destination):
					state = State.SNIFF
					timer = rng.randf_range(float(t.sniff_min), float(t.sniff_max))
		State.SNIFF:
			clip = &"sniff"
			timer -= delta
			if notice:
				_start_warn(gull)
			elif timer <= 0.0:
				_wander()
		State.WARN:
			# The bark and a planted pause are the fair warning before the run.
			_face(gull.position.x)
			timer -= delta
			if not _can_chase(gull):
				_wander()
			elif timer <= 0.0:
				state = State.CHASE
				chase_time = 0.0
		State.CHASE:
			clip = &"run"
			chase_time += delta
			if not _can_chase(gull) or position.distance_to(gull.position) > float(t.lose_radius):
				_give_up()
			else:
				_move(gull.position.x, float(t.run_speed), delta)
				_try_leap(gull)
				_try_catch(gull)
		State.LEAP:
			clip = &"leap"
			chase_time += delta
			timer -= delta
			var progress: float = 1.0 - maxf(timer, 0.0) / float(t.leap_time)
			air = sin(progress * PI) * float(t.leap_lift)
			position.x = clampf(position.x + facing * float(t.leap_speed) * delta, 12.0, float(Config.tuning.world.width) - 12.0)
			_try_catch(gull)
			if state == State.LEAP and timer <= 0.0:
				air = 0.0
				leap_gap = float(t.leap_cooldown)
				state = State.CHASE
		State.CATCH:
			clip = &"catch"
			timer -= delta
			if timer <= 0.0:
				_cooldown(true)
		State.COOLDOWN:
			timer -= delta
			if cooldown_sniff:
				clip = &"sniff"
			elif position.x < home.x - 20.0 or position.x > home.y + 20.0:
				clip = &"run"
				rate = 0.5
				_move(clampf(position.x, home.x, home.y), float(t.wander_speed), delta)
			else:
				clip = &"sniff"
			if timer <= 0.0:
				_wander()
	_animate(clip, rate)

func _start_warn(gull: BeachGull) -> void:
	state = State.WARN
	timer = float(_t().windup)
	_face(gull.position.x)
	barked.emit()

func _try_leap(gull: BeachGull) -> void:
	var height: float = gull_height(gull)
	var t: Dictionary = _t()
	var airborne: bool = height > float(Config.tuning.flight.feet_offset) + 2.0
	if leap_gap <= 0.0 and airborne and height < float(t.leap_height) and absf(gull.position.x - position.x) <= float(t.leap_range):
		_face(gull.position.x)
		state = State.LEAP
		timer = float(t.leap_time)

func _try_catch(gull: BeachGull) -> void:
	if not _can_chase(gull) or mouth().distance_to(gull.position) > float(_t().catch_radius):
		return
	gull.stun(-1.0, position)
	if gull.state != BeachGull.State.STUNNED:
		return
	air = 0.0
	state = State.CATCH
	timer = float(_t().catch_time)
	caught.emit()

func _give_up() -> void:
	if chase_time >= float(_t().min_chase):
		outrun.emit()
	air = 0.0
	_cooldown(false)

func _cooldown(sniff: bool) -> void:
	state = State.COOLDOWN
	cooldown_sniff = sniff
	timer = float(_t().cooldown)

func _animate(clip: StringName, rate: float) -> void:
	sprite.flip_h = facing < 0
	sprite.position.y = float(Config.sprites.off_lead_dog.sprite_offset_y) - air
	if sprite.animation != clip or (not sprite.is_playing() and clip != &"leap" and clip != &"catch"):
		sprite.play(clip)
	sprite.speed_scale = 0.0 if paused else rate
