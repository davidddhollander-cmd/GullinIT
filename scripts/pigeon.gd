class_name BeachPigeon
extends Node2D
## Level 4 pigeon. Loiters around its flock's home, walks to the nearest unclaimed thrown crumb and eats it in a few pecks.
## A gull dive bumps it (TUMBLE arc, spin and bounce, then the STUNNED crouch); Shakedown or a bump nearby scatters it: it flies up and off-screen,
## waits, then glides back in and lands at its home.
## Annoyed (AGGRO) it flies at the gull, bumps it and glides home. With no crumbs about it may peck a ground bin open (BIN_WALK, BIN_PECK).
## In the air (FLEE, AWAY, RETURN, AGGRO) it can neither be mugged nor eat. Tuning is the level's `feeding` block.
enum State { IDLE, SEEK, PECK, FLEE, AWAY, RETURN, LAND, STUNNED, TUMBLE, AGGRO, BIN_WALK, BIN_PECK }
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
var home: float = 0.0
var pecks_left: int = 0
var head_down: bool = true
var bin: Dictionary = {}
var tumble_bounced: bool = false
var circle_center: Vector2 = Vector2.ZERO ## scared: loops low over the beach around this point
var circle_angle: float = 0.0
var circle_y: float = 0.0
var circle_dir: float = 1.0

func setup(owner_feeding: BeachFeeding, art_name: String, home_x: float, seed_value: int) -> void:
	feeding = owner_feeding
	home = home_x
	cfg = feeding.cfg
	art_id = art_name
	rng.seed = seed_value
	var art: Dictionary = Config.sprites[art_id]
	position = Vector2(home_x,float(Config.tuning.world.ground))
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Config.frames(art_id)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE*float(art.visual_scale)
	sprite.position.y = float(art.sprite_offset_y)
	add_child(sprite)
	_idle()
	position.x = dest # start spread out from the rest of the flock

## x positions other pigeons should keep their distance from: where it is, where it is heading, where it will land.
func spots() -> Array[float]:
	if state in [State.AWAY,State.RETURN,State.LAND]:
		return [landing_x]
	return [position.x,dest] if state == State.IDLE else [position.x]

func grounded() -> bool:
	return state in [State.IDLE,State.SEEK,State.PECK,State.LAND]

func _idle() -> void:
	sprite.rotation = 0.0
	state = State.IDLE
	resting = true
	timer = rng.randf_range(float(cfg.idle_rest[0]),float(cfg.idle_rest[1]))
	dest = feeding.free_spot(self)

func _play(clip: StringName) -> void:
	sprite.flip_h = facing < 0.0
	if sprite.animation != clip or not sprite.is_playing():
		sprite.play(clip)

func _walk(to_x: float, speed: float, delta: float) -> bool:
	if absf(to_x-position.x) > 0.5:
		facing = signf(to_x-position.x)
	position.x = move_toward(position.x,to_x,speed*delta)
	return is_equal_approx(position.x,to_x)

## Struck by a dive: launched away in an arc (faster dives throw it further), spinning, bounces once, slides, then crouches stunned.
func bump(away: float, gull_speed: float = 0.0) -> void:
	release_crumb()
	state = State.TUMBLE
	tumble_bounced = false
	facing = -away if away != 0.0 else facing
	var boost: float = 1.0+float(cfg.tumble_gull_scale)*clampf(gull_speed/float(Config.tuning.flight.max_speed),0.0,1.0)
	vel = Vector2(away*float(cfg.tumble_speed),-float(cfg.tumble_up))*boost
	timer = float(cfg.bump_stun)
	_play(&"wingbeat")

## Annoyed by greedy gulls: take off and fly at the gull.
func annoy() -> void:
	release_crumb()
	state = State.AGGRO
	timer = float(cfg.aggro_time)

func go_home() -> void:
	landing_x = feeding.free_spot(self)
	state = State.RETURN

func release_crumb() -> void:
	if not bin.is_empty():
		bin.erase("pigeon")
		bin = {}
	if not crumb.is_empty():
		crumb.erase("claim")
		crumb = {}

## Mugged by the gull: fly up and away from it, then stay gone until the return delay is over.
func scatter(away: float) -> void:
	release_crumb()
	state = State.FLEE
	facing = away if away != 0.0 else (1.0 if rng.randf() < 0.5 else -1.0)
	vel = Vector2(facing*float(cfg.flee_speed[0]),-float(cfg.flee_speed[1]))
	timer = float(cfg.return_delay)
	circle_y = rng.randf_range(float(cfg.circle_y[0]),float(cfg.circle_y[1]))

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
				if not resting and float(cfg.bin_chance) > 0.0 and rng.randf() < float(cfg.bin_chance):
					bin = feeding.claim_bin(self)
					if not bin.is_empty():
						state = State.BIN_WALK
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
					pecks_left = int(cfg.pecks)
					head_down = true
					timer = float(cfg.peck_time)
		State.PECK: # head down for peck_time, head up for peck_gap, `pecks` times; the gull can steal it until the last
			_play(&"peck" if head_down else &"idle")
			timer -= delta
			if bool(crumb.get("gone",false)):
				crumb = {}
				_idle()
			elif timer <= 0.0:
				if head_down:
					pecks_left -= 1
					if pecks_left <= 0:
						crumb.gone = true
						crumb = {}
						_idle()
						return
				head_down = not head_down
				timer = float(cfg.peck_time) if head_down else float(cfg.peck_gap)
		State.STUNNED:
			_play(&"stunned")
			timer -= delta
			if timer <= 0.0:
				_idle()
		State.TUMBLE: # arc, bounce once off the sand, slide to a stop, then crouch for what is left of bump_stun
			timer -= delta
			var width: float = float(Config.tuning.world.width)
			vel.y += float(cfg.tumble_gravity)*delta
			position += vel*delta
			if position.y < ground:
				sprite.rotation += signf(vel.x if vel.x != 0.0 else facing)*float(cfg.tumble_spin)*delta
			if position.x < 12.0 or position.x > width-12.0:
				position.x = clampf(position.x,12.0,width-12.0)
				vel.x = 0.0
			if position.y >= ground:
				position.y = ground
				if not tumble_bounced:
					tumble_bounced = true
					vel.y = -absf(vel.y)*float(cfg.tumble_bounce)
					Audio.play("click")
				else:
					vel.y = 0.0
					vel.x = move_toward(vel.x,0.0,float(cfg.tumble_drag)*delta)
					sprite.rotation = 0.0
					_play(&"stunned")
					if vel.x == 0.0:
						state = State.STUNNED
		State.AGGRO:
			_play(&"wingbeat")
			var gull: BeachGull = feeding.game.player
			timer -= delta
			var to_gull: Vector2 = gull.position-position
			if absf(to_gull.x) > 0.5:
				facing = signf(to_gull.x)
			if gull.state == BeachGull.State.STUNNED or timer <= 0.0 or to_gull.length() > float(cfg.aggro_range):
				go_home()
			elif absf(to_gull.x) <= float(cfg.aggro_hit[0]) and absf(to_gull.y) <= float(cfg.aggro_hit[1]):
				feeding.pigeon_bumps_gull(self)
				go_home()
			else:
				position += to_gull.normalized()*float(cfg.aggro_speed)*delta
		State.BIN_WALK:
			if int(bin.remaining) <= 0:
				release_crumb()
				_idle()
			else:
				_play(&"walk")
				var side: float = signf(position.x-float(bin.x))
				if _walk(float(bin.x)+(side if side != 0.0 else 1.0)*float(cfg.bin_stand),float(cfg.pigeon_speed),delta):
					facing = -side if side != 0.0 else -1.0
					state = State.BIN_PECK
					head_down = true
					timer = float(cfg.peck_time)
		State.BIN_PECK: # same head-down/head-up rhythm; each peck rattles the bin, the last one spills it
			_play(&"peck" if head_down else &"idle")
			timer -= delta
			if int(bin.remaining) <= 0:
				release_crumb()
				_idle()
			elif timer <= 0.0:
				if head_down and feeding.game.stash_raids.peck_bin_as_pigeon(bin,facing) and int(bin.pecks) == 0:
					release_crumb()
					_idle()
					return
				head_down = not head_down
				timer = float(cfg.peck_time) if head_down else float(cfg.peck_gap)
		State.FLEE:
			_play(&"wingbeat")
			position += vel*delta
			timer -= delta
			if position.y <= circle_y: # level off low and start looping instead of leaving the screen
				state = State.AWAY
				var r: Vector2 = Vector2(cfg.circle_r[0],cfg.circle_r[1])
				circle_angle = PI if facing > 0.0 else 0.0
				circle_dir = facing
				var width: float = float(Config.tuning.world.width)
				circle_center = Vector2(clampf(position.x+facing*r.x,r.x+10.0,width-r.x-10.0),position.y)
		State.AWAY:
			_play(&"wingbeat")
			timer -= delta
			circle_angle += float(cfg.circle_speed)*delta*circle_dir # loop on upward from where it levelled off
			var r: Vector2 = Vector2(cfg.circle_r[0],cfg.circle_r[1])
			var target: Vector2 = circle_center+Vector2(cos(circle_angle)*r.x,sin(circle_angle)*r.y)
			var to_target: Vector2 = target-position
			if absf(to_target.x) > 0.3:
				facing = signf(to_target.x)
			position = position.move_toward(target,float(cfg.flee_speed[0])*1.6*delta)
			if timer <= 0.0:
				landing_x = feeding.free_spot(self)
				state = State.RETURN
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
