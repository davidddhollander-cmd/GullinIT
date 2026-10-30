class_name BeachRain
extends Node2D
## Weather scenery for the squall: streaks tied to the camera in a far and a near layer, slanted by the
## wind, near drops splashing on the sand with the watergun splash art, and lightning. Not a character.
const FAR: Color = Color(0.6, 0.7, 0.86, 0.3)
const NEAR: Color = Color(0.8, 0.88, 1.0, 0.55)
const HEAD: Color = Color(0.95, 0.98, 1.0, 0.85)
const SPLASH_SCALE: float = 0.5
const SPLASH_FPS: float = 14.0
const SPLASH_FRAMES: int = 5
const MAX_SPLASHES: int = 40
var intensity: float = 0.0
var slant: float = 0.0
var drops: int = 150
var rain: Array[Dictionary] = []
var splashes: Array[Dictionary] = [] ## {x (world), y, t}
var splash_frames: SpriteFrames
var strike_age: float = -1.0 ## seconds since the last lightning strike, -1 when none is showing
var strikes: int = 0
var bolt: PackedVector2Array
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	splash_frames = Config.frames("water_splash")
	rng.seed = 6116
	for i: int in drops:
		var near: bool = i % 3 == 0
		rain.append({
			"x": rng.randf_range(-10.0, 330.0), "y": rng.randf_range(-20.0, 190.0), "near": near,
			"speed": rng.randf_range(250.0, 320.0) if near else rng.randf_range(160.0, 220.0),
			"length": rng.randf_range(6.0, 11.0) if near else rng.randf_range(2.0, 5.0),
			"alpha": rng.randf_range(0.55, 1.0),
			"land": rng.randf_range(146.0, 178.0) if near else 196.0,
		})

func strike() -> void:
	strike_age = 0.0
	strikes += 1
	# The crack lands on the flash; the two recordings alternate, each slightly re-pitched.
	Audio.play("thunder_%d" % (1 + strikes % 2), rng.randf_range(0.9, 1.05), -2.0)
	bolt = PackedVector2Array()
	var at := Vector2(rng.randf_range(40.0, 280.0), -2.0)
	bolt.append(at)
	var bottom: float = rng.randf_range(56.0, 76.0)
	while at.y < bottom:
		at += Vector2(rng.randf_range(-9.0, 9.0), rng.randf_range(5.0, 11.0))
		bolt.append(at.round())

func tick(delta: float, amount: float, wind_slant: float, camera_x: float) -> void:
	intensity = amount
	slant = wind_slant
	position = Vector2(camera_x - 160.0, 0.0)
	var drift: float = slant / 12.0
	var splashing: bool = bool(Config.tuning.juice.particles)
	for i: int in int(rain.size() * intensity):
		var drop: Dictionary = rain[i]
		var fall: float = float(drop.speed) * delta
		drop.y += fall
		drop.x = fposmod(float(drop.x) + fall * drift + 10.0, 340.0) - 10.0
		if drop.y >= float(drop.land):
			if drop.near and splashing and splashes.size() < MAX_SPLASHES and rng.randf() < 0.5:
				splashes.append({"x": position.x + float(drop.x), "y": float(drop.land), "t": 0.0})
			drop.y = rng.randf_range(-30.0, -4.0)
			drop.x = rng.randf_range(-10.0, 330.0)
	for i: int in range(splashes.size() - 1, -1, -1):
		splashes[i].t += delta
		if splashes[i].t * SPLASH_FPS >= SPLASH_FRAMES:
			splashes.remove_at(i)
	if strike_age >= 0.0:
		strike_age += delta
		if strike_age > 0.6:
			strike_age = -1.0
	visible = amount > 0.01 or strike_age >= 0.0 or not splashes.is_empty()
	if visible:
		queue_redraw()

## Double flicker: a sharp flash, a dark beat, then a softer flash that fades.
func _flash_alpha() -> float:
	if strike_age < 0.0:
		return 0.0
	if strike_age < 0.07:
		return 0.42
	if strike_age < 0.14:
		return 0.06
	return maxf(0.0, 0.3 * (1.0 - (strike_age - 0.14) / 0.4))

func _draw() -> void:
	var fade: float = clampf(intensity * 1.5, 0.0, 1.0)
	var along: Vector2 = Vector2(slant / 12.0, 1.0).normalized()
	for i: int in int(rain.size() * intensity):
		var drop: Dictionary = rain[i]
		var head := Vector2(float(drop.x), float(drop.y))
		var tail: Vector2 = head - along * float(drop.length)
		var base: Color = NEAR if drop.near else FAR
		draw_line(tail.round(), head.round(), Color(base, base.a * float(drop.alpha) * fade), 1.0)
		if drop.near:
			draw_rect(Rect2(head.round(), Vector2.ONE), Color(HEAD, HEAD.a * float(drop.alpha) * fade))
	var size: Vector2 = Vector2(24.0, 24.0) * SPLASH_SCALE
	for splash: Dictionary in splashes:
		var texture: Texture2D = splash_frames.get_frame_texture(&"impact", int(float(splash.t) * SPLASH_FPS))
		# The crown sits at the bottom of its frame: rest its base on the landing spot.
		var at := Vector2(float(splash.x) - position.x - size.x * 0.5, float(splash.y) - size.y)
		draw_texture_rect(texture, Rect2(at.round(), size), false, Color(1.0, 1.0, 1.0, 0.8))
	var flash: float = _flash_alpha()
	if flash > 0.0:
		draw_rect(Rect2(-10.0, -10.0, 340.0, 200.0), Color(0.92, 0.95, 1.0, flash))
	if strike_age >= 0.0 and strike_age < 0.3 and bolt.size() > 1:
		draw_polyline(bolt, Color(0.7, 0.82, 1.0, 0.6), 3.0)
		draw_polyline(bolt, Color.WHITE, 1.0)
