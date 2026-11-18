class_name BeachPigeon
extends Node2D
## Level 4 pigeon. Loiters near the crumb lady, walks to the nearest unclaimed thrown crumb and eats it.
## A gull dive scatters it: it flies up and off-screen, waits, then glides back in and lands by the lady.
## In the air (FLEE, AWAY, RETURN) it can neither be mugged nor eat. Tuning is the level's `feeding` block.
enum State { IDLE, SEEK, PECK, FLEE, AWAY, RETURN, LAND }
var state: State = State.IDLE
var cfg: Dictionary
var feeding: BeachFeeding
var art_id: String = "pigeon_a"
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var sprite: AnimatedSprite2D
var facing: float = 1.0
var timer: float = 0.0
var dest: float = 0.0
var resting: bool = true
var crumb: Dictionary = {}
var vel: Vector2 = Vector2.ZERO
var landing_x: float = 0.0

func setup(owner_feeding: BeachFeeding, art_name: String, x: float, seed_value: int) -> void:
	feeding = owner_feeding
	cfg = feeding.cfg
	art_id = art_name
	rng.seed = seed_value
	var art: Dictionary = Config.sprites[art_id]
	position = Vector2(x,float(Config.tuning.world.ground))
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Config.frames(art_id)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE*float(art.visual_scale)
	sprite.position.y = float(art.sprite_offset_y)
	add_child(sprite)
	_idle()

func grounded() -> bool:
	return state in [State.IDLE,State.SEEK,State.PECK,State.LAND]

func _idle() -> void:
	state = State.IDLE
	resting = true
	timer = rng.randf_range(float(cfg.idle_rest[0]),float(cfg.idle_rest[1]))
	dest = feeding.lady.position.x+rng.randf_range(-float(cfg.wander),float(cfg.wander))

func _play(clip: StringName) -> void:
	sprite.flip_h = facing < 0.0
	if sprite.animation != clip or not sprite.is_playing():
		sprite.play(clip)

func _walk(to_x: float, speed: float, delta: float) -> bool:
	if absf(to_x-position.x) > 0.5:
		facing = signf(to_x-position.x)
	position.x = move_toward(position.x,to_x,speed*delta)
	return is_equal_approx(position.x,to_x)

## Mugged by the gull: fly up and away from it, then stay gone until the return delay is over.
func scatter(away: float) -> void:
	if not crumb.is_empty():
		crumb.erase("claim")
		crumb = {}
	state = State.FLEE
	facing = away if away != 0.0 else (1.0 if rng.randf() < 0.5 else -1.0)
	vel = Vector2(facing*float(cfg.flee_speed[0]),-float(cfg.flee_speed[1]))
	timer = float(cfg.return_delay)

func tick(delta: float) -> void:
	var ground: float = float(Config.tuning.world.ground)
	match state:
		State.IDLE:
			crumb = feeding.claim_crumb(self)
			if not crumb.is_empty():
				state = State.SEEK
			elif resting:
				_play(&"idle")
				timer -= delta
				resting = timer > 0.0
			else:
				_play(&"walk")
				if _walk(dest,float(cfg.pigeon_speed)*float(cfg.wander_speed_mult),delta):
					_idle()
		State.SEEK:
			if bool(crumb.get("gone",false)):
				crumb = {}
				_idle()
			else:
				_play(&"walk")
				if _walk(float(crumb.x),float(cfg.pigeon_speed),delta):
					state = State.PECK
					timer = float(cfg.peck_time)
		State.PECK:
			_play(&"peck")
			timer -= delta
			if bool(crumb.get("gone",false)):
				crumb = {}
				_idle()
			elif timer <= 0.0:
				crumb.gone = true
				crumb = {}
				_idle()
		State.FLEE:
			_play(&"wingbeat")
			position += vel*delta
			timer -= delta
			if position.y <= float(cfg.ceiling):
				state = State.AWAY
				visible = false
		State.AWAY:
			timer -= delta
			if timer <= 0.0:
				landing_x = feeding.lady.position.x+rng.randf_range(-float(cfg.wander),float(cfg.wander))
				var side: float = 1.0 if rng.randf() < 0.5 else -1.0
				position = Vector2(landing_x+side*float(cfg.return_dx),float(cfg.ceiling))
				facing = -side
				state = State.RETURN
				visible = true
		State.RETURN:
			_play(&"glide")
			var to_ground: Vector2 = Vector2(landing_x,ground)-position
			position += to_ground.normalized()*minf(float(cfg.glide_speed)*delta,to_ground.length())
			if to_ground.length() <= 0.5:
				position = Vector2(landing_x,ground)
				state = State.LAND
				timer = float(cfg.land_time)
		State.LAND:
			_play(&"land")
			timer -= delta
			if timer <= 0.0:
				_idle()
