class_name BeachLightning
extends Node2D
## Kittiwake power (rough playtest build): slow-motion windup marks up to 2 foods per banked charge, then the gull becomes a bolt that
## snatches each mark in turn and lands mid-air. Self-contained: delete this file and its hooks to remove the power.
## Phases: WINDUP (marking, real-time clock) -> DASH (hidden gull, straight legs) -> LAND (brief immunity), then end_power.

enum Phase { IDLE, WINDUP, DASH, LAND }
const FONT: Font = preload("res://assets/fonts/gull_pixel.fnt")

var brash: BeachBrash
var game: BeachGame
var phase: Phase = Phase.IDLE
var marks: Array[BeachTarget] = []
var wind_left: float = 0.0 ## real seconds, not slowed by Engine.time_scale
var index: int = 0
var pause_left: float = 0.0
var land_left: float = 0.0
var trail: Array[Dictionary] = []
var heading: Vector2 = Vector2.RIGHT
var charges_spent: int = 1 ## set by BeachBrash.fire before start; each charge buys marks_per_charge marks
var slowed: bool = false ## this power has set Engine.time_scale
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func settings() -> Dictionary:
	return Config.tuning.lightning_strike

func max_marks() -> int:
	return charges_spent*int(settings().marks_per_charge)

func winding() -> bool:
	return phase == Phase.WINDUP

func start(owner: BeachBrash) -> void:
	brash = owner
	game = owner.game
	if get_parent() == null:
		brash.add_child(self)
	z_index = 20
	marks.clear()
	trail.clear()
	index = 0
	pause_left = 0.0
	phase = Phase.WINDUP
	var s: Dictionary = settings()
	wind_left = float(s.windup_time)
	Engine.time_scale = float(s.windup_time_scale)
	slowed = true
	if _auto():
		_auto_mark()
		wind_left = minf(wind_left,float(s.auto_hold)) # a short beat to see the reticles
	queue_redraw()

func _auto() -> bool:
	return game.player.control_mode == "casual" or (game.input != null and game.input.touch_active)

## Casual and touch: the nearest foods on screen, no aiming needed.
func _auto_mark() -> void:
	var seen: Array[BeachTarget] = []
	for target: BeachTarget in game.spawner.targets + game.stalls.portions:
		var at: Vector2 = target.food_position()
		if game.snatchable(target) and absf(at.x-game.camera_x) <= 160.0 and absf(at.y-game.camera_y) <= 90.0:
			seen.append(target)
	var from: Vector2 = game.player.position
	seen.sort_custom(func(a: BeachTarget, b: BeachTarget) -> bool: return a.food_position().distance_to(from) < b.food_position().distance_to(from))
	for target: BeachTarget in seen.slice(0,max_marks()):
		_mark(target)

func _mark(target: BeachTarget) -> void:
	marks.append(target)
	Audio.play("click",1.0+0.2*marks.size(),-4.0)

func tick(delta: float) -> void:
	_fade_trail(delta)
	match phase:
		Phase.WINDUP:
			_windup(delta)
		Phase.DASH:
			_dash(delta)
		Phase.LAND:
			land_left -= delta
			if land_left <= 0.0:
				brash.end_power(false)
	if is_instance_valid(brash) and brash.active_id == "lightning_strike":
		brash.active_left = wind_left if phase == Phase.WINDUP else 0.0
	queue_redraw()

func _windup(delta: float) -> void:
	if game.player.state == BeachGull.State.STUNNED:
		cancel() # hit while aiming: the strike fizzles and the meter comes back
		return
	wind_left -= delta/maxf(Engine.time_scale,0.05)
	var s: Dictionary = settings()
	if marks.size() < max_marks() and not _auto():
		var dir: Vector2 = game.player.aim-game.player.position
		if dir.length() < 1.0:
			dir = Vector2(game.player.facing,0)
		var found: BeachTarget = game.assist_target(game.player.position,dir,float(s.mark_range),deg_to_rad(float(s.mark_angle)),marks)
		if found != null:
			_mark(found)
	if marks.size() >= max_marks() or wind_left <= 0.0:
		end_windup()

## Second press, timeout or a full set of marks. With no marks the meter comes back.
func end_windup() -> void:
	if phase != Phase.WINDUP:
		return
	if marks.is_empty():
		cancel()
		return
	Engine.time_scale = 1.0
	slowed = false
	phase = Phase.DASH
	index = 0
	var player: BeachGull = game.player
	player.state = BeachGull.State.GLIDE # whatever it was doing (perched, diving) is dropped
	player.support = {}
	player.dashing = true
	player.visible = false
	player.steady_invulnerable = true
	player.invulnerable = 999.0
	heading = Vector2(player.facing,0)

func cancel() -> void:
	brash.meter += charges_spent
	brash.powers_fired = maxi(0,brash.powers_fired-1)
	brash.end_power(false)

func _dash(delta: float) -> void:
	if pause_left > 0.0:
		pause_left -= delta
		return
	var player: BeachGull = game.player
	var budget: float = float(settings().dash_speed)*delta
	while budget > 0.0 and index < marks.size():
		var mark: BeachTarget = marks[index]
		if not _live(mark):
			_fizzle()
			return
		var goal: Vector2 = mark.food_position()
		var gap: float = player.position.distance_to(goal)
		heading = (goal-player.position).normalized() if gap > 0.001 else heading
		player.facing = 1 if heading.x >= 0.0 else -1
		var move: float = minf(gap,budget)
		_step(player.position+heading*move)
		budget -= move
		if gap <= move+0.001:
			if not mark.take(player):
				_fizzle() # lost in the instant of contact
				return
			index += 1
	if index >= marks.size():
		_land()

func _live(mark: BeachTarget) -> bool:
	return is_instance_valid(mark) and mark.is_inside_tree() and game.snatchable(mark)

func _fizzle() -> void:
	if index < marks.size():
		index += 1
	pause_left = float(settings().fizzle_pause)
	game.effects.pixelfx_hit_spark(game.player.position,Vector2.UP)
	Audio.play("click",0.7,-3.0)

## Move the hidden gull and leave a jagged bolt segment behind it.
func _step(to: Vector2) -> void:
	var player: BeachGull = game.player
	var from: Vector2 = player.position
	player.position = to
	player.velocity = heading*float(settings().dash_speed)
	var mid: Vector2 = from.lerp(to,0.5)+heading.orthogonal()*rng.randf_range(-4.0,4.0)
	trail.append({"pts":PackedVector2Array([from,mid,to]),"age":0.0})

func _land() -> void:
	var player: BeachGull = game.player
	phase = Phase.LAND
	player.dashing = false
	player.visible = true
	var cap: float = float(Config.tuning.flight.max_speed)*player.species_speed()
	player.velocity = heading*minf(float(settings().dash_speed),cap)
	player.state = BeachGull.State.GLIDE
	player.previous_beak = player.beak()
	player.sweep_beak = player.beak()
	player.invulnerable = float(settings().land_invulnerable)
	land_left = float(settings().land_invulnerable)
	pause_left = 0.0

func _fade_trail(delta: float) -> void:
	for seg: Dictionary in trail:
		seg.age += delta
	trail = trail.filter(func(seg: Dictionary) -> bool: return seg.age < float(settings().bolt_fade))

## Pause: the windup's slow motion is dropped for the menu and put back on resume.
func set_paused(value: bool) -> void:
	if phase == Phase.WINDUP:
		Engine.time_scale = 1.0 if value else float(settings().windup_time_scale)

func fraction() -> float:
	return clampf(wind_left/float(settings().windup_time),0.0,1.0) if phase == Phase.WINDUP else 1.0

func label() -> String:
	return "AIM" if phase == Phase.WINDUP else "ZAP"

## Every end path (level end, clear, finish, cancel): a clean gull, clock and screen.
func end(_snap: bool = true) -> void:
	if slowed:
		slowed = false
		Engine.time_scale = 1.0
	if game != null and is_instance_valid(game.player):
		game.player.dashing = false
		game.player.visible = true
		game.player.steady_invulnerable = false
		if phase != Phase.IDLE:
			game.player.invulnerable = 0.0
	phase = Phase.IDLE
	marks.clear()
	trail.clear()
	queue_redraw()

func _draw() -> void:
	for seg: Dictionary in trail:
		var fade: float = 1.0-float(seg.age)/float(settings().bolt_fade)
		draw_polyline(seg.pts,Color(0.45,0.8,1.0,0.6*fade),3.0)
		draw_polyline(seg.pts,Color(1,1,0.85,fade),1.0)
	if phase != Phase.WINDUP:
		return
	for i: int in marks.size():
		var mark: BeachTarget = marks[i]
		if not is_instance_valid(mark):
			continue
		var at: Vector2 = mark.food_position().round()
		PickupShine.draw_target_corners(self,at,Vector2(8,8),true)
		draw_string(FONT,at+Vector2(-3,-11),str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,8,BeachUI.INK)
		draw_string(FONT,at+Vector2(-4,-12),str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,8,BeachUI.GOLD)
