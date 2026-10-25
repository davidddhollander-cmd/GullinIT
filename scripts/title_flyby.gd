class_name TitleFlyby
extends Node2D
## Title backdrop life: a player gull glides across and now and then lands on the lamp pole;
## rival swoops at a sunbather; other gulls land on the sand and stroll; distant calls.
const SWOOP_TIME: float = 3.2
const LAMP_X: float = 212.0 ## beach_lamp prop, placed by main.gd
const LAMP_BASE_Y: float = 146.0
const LAMP_SCALE: float = 0.9 ## the 24x90 lamp sprite shrunk a touch for the title
const LAMP_PERCH: Vector2 = Vector2(LAMP_X + 3.0 * LAMP_SCALE, LAMP_BASE_Y - 88.0 * LAMP_SCALE) ## feet spot on the lamp head
const FEET_TO_SPRITE: Vector2 = Vector2(2.5, -4.5) ## sprite centre relative to the feet, facing right
const GLIDE_SPEED: float = 22.0
const WALK_SPEED: float = 9.0
const WALK_MIN_X: float = 226.0
const WALK_MAX_X: float = 308.0
var player: AnimatedSprite2D
var rival: AnimatedSprite2D
var clock: float = 0.0
var next_swoop: float = 6.0
var swoop: float = -1.0
var swoop_x: float = 270.0
# Player glider: glide -> land (on the lamp) -> perch -> leave -> glide.
var px: float = -30.0
var mode: String = "glide"
var mode_time: float = 0.0
var mode_from: Vector2 = Vector2.ZERO
var perch_hold: float = 6.0
var next_perch: float = 12.0
var next_call: float = 5.0
var walkers: Array[Dictionary] = []

func _ready() -> void:
	player = _gull("player_gull")
	rival = _gull("rival_gull")
	rival.visible = false
	for spec: Array in [["player_gull",173.0,9.0],["rival_gull",177.0,16.0]]:
		var sprite: AnimatedSprite2D = _gull(str(spec[0]))
		sprite.visible = false
		walkers.append({"sprite":sprite,"mode":"wait","time":0.0,"from":Vector2.ZERO,"feet":Vector2(0,float(spec[1])),"goal":260.0,"pause":0.0,"stay":0.0,"next":float(spec[2])})

func _gull(id: String) -> AnimatedSprite2D:
	var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
	sprite.sprite_frames = Config.frames(id)
	sprite.scale = Vector2.ONE * float(Config.sprites[id].get("visual_scale",1.0))
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.play(&"glide")
	add_child(sprite)
	return sprite

func _rest_position(feet: Vector2, facing: float) -> Vector2:
	return feet + Vector2(FEET_TO_SPRITE.x * facing,FEET_TO_SPRITE.y)

func _process(delta: float) -> void:
	clock += delta
	_tick_player(delta)
	_tick_swoop(delta)
	for walker: Dictionary in walkers:
		_tick_walker(walker,delta)
	_tick_calls()

## An occasional distant gull call, on the opening screen only.
func _tick_calls() -> void:
	if clock < next_call:
		return
	next_call = clock + randf_range(4.0,10.0)
	var host: Node = get_parent().get_parent() if get_parent() != null else null
	if host != null and str(host.get("screen")) == "title":
		Audio.play("gull_call",randf_range(0.85,1.15),-13.0)

func _glide_y() -> float:
	return 42.0 + sin(clock * 1.6) * 5.0

func _tick_player(delta: float) -> void:
	mode_time += delta
	match mode:
		"glide":
			px += delta * GLIDE_SPEED
			if px > 350.0:
				px = -30.0
			player.position = Vector2(px,_glide_y())
			# Heading for the lamp with a few seconds of runway: come in to land.
			if clock >= next_perch and px > 130.0 and px < 160.0:
				mode = "land"
				mode_time = 0.0
				mode_from = player.position
		"land":
			var t: float = clampf(mode_time / 2.6,0.0,1.0)
			var target: Vector2 = _rest_position(LAMP_PERCH,1.0)
			var eased: float = t * t * (3.0 - 2.0 * t)
			player.position = mode_from.lerp(target,eased)
			player.play(&"glide" if t < 0.9 else &"idle")
			if t >= 1.0:
				mode = "perch"
				mode_time = 0.0
				perch_hold = randf_range(5.0,8.0)
				px = LAMP_PERCH.x
		"perch":
			player.play(&"idle")
			player.position = _rest_position(LAMP_PERCH,1.0)
			if mode_time >= perch_hold:
				mode = "leave"
				mode_time = 0.0
				mode_from = player.position
				player.play(&"glide")
		"leave":
			var t: float = clampf(mode_time / 1.6,0.0,1.0)
			px += delta * GLIDE_SPEED
			var rise: float = t * t * (3.0 - 2.0 * t)
			player.position = Vector2(px,lerpf(mode_from.y,_glide_y(),rise) - sin(t * PI) * 6.0)
			if t >= 1.0:
				mode = "glide"
				next_perch = clock + randf_range(14.0,24.0)

func _tick_swoop(delta: float) -> void:
	if swoop >= 0.0:
		swoop += delta / SWOOP_TIME
		if swoop >= 1.0:
			swoop = -1.0
			rival.visible = false
			next_swoop = clock + randf_range(8.0,12.0)
		else:
			rival.position = Vector2(swoop_x + 100.0 - 200.0 * swoop, 40.0 + 80.0 * sin(PI * swoop))
			rival.flip_h = true
	elif clock >= next_swoop:
		swoop = 0.0
		swoop_x = [255.0,285.0].pick_random()
		rival.visible = true

# Beach walker: wait -> fly in from the right -> stroll on the sand -> fly off.
func _tick_walker(walker: Dictionary, delta: float) -> void:
	var sprite: AnimatedSprite2D = walker.sprite
	walker.time += delta
	var feet: Vector2 = walker.feet
	match str(walker.mode):
		"wait":
			if clock >= float(walker.next):
				walker.mode = "in"
				walker.time = 0.0
				walker.goal = randf_range(WALK_MIN_X,WALK_MAX_X)
				walker.from = Vector2(350.0,randf_range(40.0,80.0))
				walker.stay = randf_range(9.0,16.0)
				sprite.visible = true
				sprite.play(&"glide")
		"in":
			var t: float = clampf(float(walker.time) / 3.0,0.0,1.0)
			var eased: float = 1.0 - (1.0 - t) * (1.0 - t)
			var target: Vector2 = _rest_position(Vector2(float(walker.goal),feet.y),-1.0)
			sprite.position = (walker.from as Vector2).lerp(target,eased)
			sprite.flip_h = true
			sprite.play(&"glide" if t < 0.92 else &"idle")
			if t >= 1.0:
				walker.mode = "walk"
				walker.time = 0.0
				walker.pause = 1.0
				feet.x = float(walker.goal)
				walker.feet = feet
		"walk":
			var facing: float = -1.0 if sprite.flip_h else 1.0
			if float(walker.pause) > 0.0:
				walker.pause -= delta
				sprite.play(&"idle")
			else:
				var dx: float = float(walker.goal) - feet.x
				if absf(dx) < 1.0:
					walker.pause = randf_range(1.0,2.5)
					walker.goal = randf_range(WALK_MIN_X,WALK_MAX_X)
				else:
					facing = signf(dx)
					feet.x += facing * WALK_SPEED * delta
					walker.feet = feet
					sprite.flip_h = facing < 0.0
					sprite.play(&"walk")
			sprite.position = _rest_position(feet,facing)
			if float(walker.time) >= float(walker.stay):
				walker.mode = "out"
				walker.time = 0.0
				walker.from = sprite.position
				sprite.flip_h = false
				sprite.play(&"fly")
		"out":
			var t: float = clampf(float(walker.time) / 3.2,0.0,1.0)
			sprite.position = (walker.from as Vector2).lerp(Vector2(350.0,30.0),t * t)
			if t >= 1.0:
				sprite.visible = false
				walker.mode = "wait"
				walker.next = clock + randf_range(6.0,14.0)
