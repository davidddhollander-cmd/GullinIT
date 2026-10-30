class_name OffLeadDog
extends Node2D
## Level 4 terrier: wanders, warns, chases on the sand and in low flight, leaps, catches.
## It chases the nearest low gull (the player, or a rival when chase_rivals is on) and never touches food.
signal barked
signal caught
signal rival_caught(rival: BeachGull)
signal outrun
enum State { WANDER, SNIFF, WARN, CHASE, LEAP, CATCH, COOLDOWN }
var state: State = State.WANDER
var home: Vector2 = Vector2(250, 410)
var facing: float = 1.0
var timer: float = 0.0
var chase_time: float = 0.0
var bark_timer: float = 0.0
var leap_gap: float = 0.0
var air: float = 0.0
var destination: float = 0.0
var resting: bool = true
var paused: bool = false
var returning: bool = false
var cooldown_sniff: bool = false
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var sprite: AnimatedSprite2D
var prey: BeachGull ## current chase target, re-picked only while the dog is idle
var flee_to: float = NAN ## squall: run to this x (off the map) and stay there
var homecoming: bool = false ## flee_to is the way back; wander again on arrival

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

# Leash: the dog covers about half the beach (home +/- leash) and ignores gulls outside it.
func _in_leash(x: float) -> bool:
	var leash: float = float(_t().leash)
	return x >= home.x - leash and x <= home.y + leash

func _can_chase(gull: BeachGull) -> bool:
	return _in_leash(gull.position.x) and gull.state != BeachGull.State.STUNNED and gull.invulnerable <= 0.0

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
	position.x = clampf(move_toward(position.x, target_x, speed * delta), maxf(12.0, home.x - float(_t().leash)), minf(float(Config.tuning.world.width) - 12.0, home.y + float(_t().leash)))

# Nearest chaseable gull within notice range (player or rival); the player when nobody is close.
func _pick_prey(player: BeachGull, rivals: Array[BeachGull]) -> BeachGull:
	if state != State.WANDER and state != State.SNIFF and is_instance_valid(prey):
		return prey
	var best: BeachGull = player
	var best_gap: float = absf(player.position.x - position.x) if _can_chase(player) else INF
	if _t().get("chase_rivals", false):
		for rival: BeachGull in rivals:
			var gap: float = absf(rival.position.x - position.x)
			if _can_chase(rival) and gap <= float(_t().notice_radius) and gap < best_gap:
				best = rival
				best_gap = gap
	prey = best
	return best

func tick(delta: float, player: BeachGull, rivals: Array[BeachGull] = []) -> void:
	var t: Dictionary = _t()
	if not is_nan(flee_to):
		_face(flee_to)
		position.x = move_toward(position.x, flee_to, float(t.run_speed) * delta)
		_animate(&"run", 1.0)
		if homecoming and is_equal_approx(position.x, flee_to):
			flee_to = NAN
			homecoming = false
			_wander()
		return
	var gull: BeachGull = _pick_prey(player, rivals)
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
				bark_timer = float(t.bark_gap)
		State.CHASE:
			clip = &"run"
			chase_time += delta
			if not _in_leash(gull.position.x) or not _in_leash(position.x):
				_give_up(true)
			elif not _can_chase(gull) or absf(gull.position.x - position.x) > float(t.lose_radius) or chase_time >= float(t.chase_timeout):
				_give_up()
			else:
				# Above leap reach the dog shadows the gull's x and barks; it can't catch it.
				bark_timer -= delta
				if bark_timer <= 0.0:
					bark_timer = float(t.bark_gap)
					if gull_height(gull) >= float(t.leap_height):
						barked.emit()
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
			elif position.x < home.x or position.x > home.y:
				clip = &"run"
				rate = 0.5
				_move(clampf(position.x, home.x, home.y), float(t.run_speed) * 0.5 if returning else float(t.wander_speed), delta)
			else:
				returning = false
				clip = &"sniff"
			if timer <= 0.0 and not returning:
				_wander()
	_animate(clip, rate)

## Squall over: trot back to the middle of the home range, then wander as usual.
func come_home() -> void:
	if is_nan(flee_to):
		return
	flee_to = (home.x + home.y) * 0.5
	homecoming = true

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
	if gull.rival:
		rival_caught.emit(gull)
	else:
		caught.emit()

func _give_up(leashed: bool = false) -> void:
	if leashed:
		barked.emit()
	if leashed or chase_time >= float(_t().min_chase):
		outrun.emit()
	air = 0.0
	returning = leashed
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
