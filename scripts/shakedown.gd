class_name BeachShakedown
extends RefCounted
## Great black-back power: untouchable, a rolling crowd panic, food shaken loose on contact, and raids on stall counters.

var brash: BeachBrash
var game: BeachGame
var clock: float = 0.0
var raided: Dictionary = {} ## FoodStall -> items spat this power
var base_capacity: int = 0
var gorging: bool = false
var impact_left: float = 0.0
var pulse: float = 0.0

func settings() -> Dictionary:
	return Config.tuning.shakedown

func start(owner: BeachBrash) -> void:
	brash = owner
	game = owner.game
	raided.clear()
	clock = 0.0
	game.player.steady_invulnerable = true
	game.player.invulnerable = maxf(game.player.invulnerable,brash.active_left)
	impact_left = 0.0
	pulse = 0.0
	brash.hits = 0
	var s: Dictionary = settings()
	var digestion: GullDigestion = game.player.digestion
	if not gorging:
		base_capacity = digestion.capacity
	gorging = true
	digestion.capacity = base_capacity+int(s.gorge_capacity)
	digestion.speed = float(s.gorge_digest)
	game.player.power_scale = float(s.bully_scale)
	if not game.player.sand_landed.is_connected(_landed):
		game.player.sand_landed.connect(_landed)
	_panic()
	_slam()
	if game.is_inside_tree():
		Audio.duck_music(true)
		game.get_tree().create_timer(float(s.duck_music)).timeout.connect(Audio.duck_music.bind(false))

## Firing shakes food loose from everyone close, with one Gang Call weight impact.
func _slam() -> void:
	var at: Vector2 = game.player.position
	var knocked: bool = _knock_around(float(settings().slam_radius)) > 0
	var t: Dictionary = Config.tuning.brash
	brash.hit_fx(at,Vector2(0,-1),knocked,int(t.hit_feathers),int(t.hit_crumbs),float(t.hit_shake),float(t.hit_stop))
	brash.dust_left = float(t.dust_time)

## Knocks food from people (and makes carriers drop) within radius of the gull; returns how many lost something.
func _knock_around(radius: float) -> int:
	var at: Vector2 = game.player.position
	var lift: float = float(settings().food_lift)
	var count: int = 0
	for target: BeachTarget in game.spawner.targets:
		if is_instance_valid(target) and target.food and at.distance_to(target.food_position()) <= radius and target.knock_food(game.player,lift):
			target.drop_retrieve = false
			game.effects.snatch_contact(target.food_position(),game.player.velocity,false)
			count += 1
	for pilot: RivalPilot in game.pilots:
		if pilot.carry_window > 0.0 and pilot.carried > 0 and at.distance_to(pilot.gull.position) <= radius:
			game._rival_drops_carry(pilot.gull,at)
			count += 1
	return count

func _landed(at: Vector2) -> void:
	if bool(Config.tuning.juice.shake) and GameState.options.shake:
		game.effects.shake = maxf(game.effects.shake,float(settings().land_shake))
	game.effects.sand_puff(at)

func tick(delta: float) -> void:
	game.player.invulnerable = maxf(game.player.invulnerable,brash.active_left)
	clock += delta
	if clock >= float(settings().panic_interval):
		clock -= float(settings().panic_interval)
		_panic()
	impact_left = maxf(0.0,impact_left-delta)
	_shake()
	_pulse(delta)

## The fear travels with the gull: warn and stampede around where it is now.
func _panic() -> void:
	CrowdPanic.warn(game.spawner.targets,game.player.position.x)
	CrowdPanic.stampede(game.spawner.targets,game.player.position.x)

func _shake() -> void:
	if _knock_around(float(settings().shake_radius)) > 0 and impact_left <= 0.0:
		impact_left = float(settings().impact_gap)
		var s: Dictionary = settings()
		brash.hit_fx(game.player.position,game.player.velocity,true,int(s.hit_feathers),int(s.hit_crumbs),float(s.hit_shake),float(s.hit_stop))

## Slow tint pulse; in the last end_warning seconds it speeds up and ticks each beat.
func _pulse(delta: float) -> void:
	var s: Dictionary = settings()
	var warning: bool = brash.active_left <= float(s.end_warning)
	var before: float = pulse
	pulse += delta*(float(s.pulse_fast) if warning else float(s.pulse_speed))
	var tint: Array = s.bully_tint
	game.player.power_tint = Color.WHITE.lerp(Color(float(tint[0]),float(tint[1]),float(tint[2])),0.5+0.5*sin(pulse*TAU))
	if warning and floorf(pulse) > floorf(before):
		Audio.play("click",float(s.tick_pitch),-4.0)

func stall_at(x: float) -> FoodStall:
	var best: FoodStall
	var gap: float = FoodStall.COUNTER_REACH
	for stall: FoodStall in game.beach.stalls:
		if absf(stall.position.x-x) <= gap:
			gap = absf(stall.position.x-x)
			best = stall
	return best

## A grounded peck at a stall counter (sand or roof) spits one food item; true when the peck is spent here.
func peck() -> bool:
	var stall: FoodStall = stall_at(game.player.beak().x)
	if stall == null:
		return false
	var raids: BeachStashRaids = game.stash_raids
	var window: Vector2 = stall.position+Vector2(0,-28)
	if raids.peck_cooldown > 0.0 or not game.running:
		return true
	var count: int = int(raided.get(stall,0))
	if count >= int(settings().raid_cap):
		return raids._peck_empty(window)
	if count == 0:
		game.stalls.raid(stall)
	raided[stall] = count+1
	raids.peck_cooldown = float(Config.tuning.world.peck_cooldown)
	var foods: Array = settings().raid_foods
	game.effects.peck_contact(window,Vector2(game.player.facing,-0.35),float(count+1)/float(settings().raid_cap),"bin")
	game.effects.release_burst(window,true)
	stall.rattle()
	Audio.play("bin_rattle",0.9+0.2*float(count)/float(settings().raid_cap))
	var from: Vector2 = window+Vector2(0,6)
	var rise: float = raids.rng.randf_range(65,95)
	raids.items.append({"owner":null,"source":"raid","food_id":str(foods[raids.rng.randi_range(0,foods.size()-1)]),"position":from,"velocity":Vector2(_spit_speed(from,rise,count),-rise),"grounded":false,"age":0.0})
	raids.queue_redraw()
	return true

## Horizontal speed that lands the spat food within reach of the gull (on the sand beneath it when it is on the roof).
func _spit_speed(from: Vector2, rise: float, count: int) -> float:
	var player: BeachGull = game.player
	var ground: float = float(Config.tuning.world.ground)
	var on_roof: bool = player.position.y < ground-float(Config.tuning.flight.feet_offset)-20.0
	var aim_x: float = (player.position.x if on_roof else player.beak().x)+(float(count%3)-1.0)*float(settings().raid_reach)*0.5
	var gravity: float = float(Config.tuning.world.stash_gravity)
	var fall: float = (rise+sqrt(rise*rise+2.0*gravity*maxf(ground-6.0-from.y,1.0)))/gravity
	return clampf((aim_x-from.x)/fall,-float(settings().raid_speed_max),float(settings().raid_speed_max))

func end(snap: bool) -> void:
	if gorging:
		game.player.digestion.capacity = base_capacity
		game.player.digestion.speed = 1.0
		gorging = false
	var player: BeachGull = game.player
	player.power_scale = 1.0
	player.power_tint = Color.WHITE
	player.sprite.scale = Vector2.ONE*(player.art_scale if player.detailed_art else 1.0)
	if player.sand_landed.is_connected(_landed):
		player.sand_landed.disconnect(_landed)
	game.player.steady_invulnerable = false
	game.player.invulnerable = 0.0
	game.player.sprite.modulate.a = 1.0
	for stall: FoodStall in game.beach.stalls:
		stall.ducked = false
		if snap:
			stall.snap_duck()
	raided.clear()
