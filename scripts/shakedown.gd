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
var rear_left: float = 0.0 ## seconds of the pre-slam hold still to run; the power clock waits for it
var stomp_index: int = 0
var scared: Array = [] ## dogs and teens sent running; come_home() on every end path

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
	if not game.player.sand_landed.is_connected(_landed):
		game.player.sand_landed.connect(_landed)
	_panic()
	rear_left = float(s.rear_time)
	game.player.rearing = true
	if _show_fx():
		game.overlay.set_dim(float(s.rear_dim),0.08)
	if rear_left <= 0.0:
		_slam()
	if game.is_inside_tree():
		Audio.duck_music(true)
		game.get_tree().create_timer(float(s.duck_music)).timeout.connect(Audio.duck_music.bind(false))

func _show_fx() -> bool:
	return bool(Config.tuning.juice.shake) and GameState.options.shake

## The hold runs on the power's own clock, so a hit-stop, pause or level end can never fire the slam twice or late.
func rear_tick(delta: float) -> void:
	game.player.invulnerable = maxf(game.player.invulnerable,brash.active_left)
	rear_left = maxf(0.0,rear_left-delta)
	if rear_left <= 0.0:
		_slam()

## The hold ends: the bird turns enraged and big, a ring crosses the slam radius and everyone close loses their food.
func _slam() -> void:
	var s: Dictionary = settings()
	var player: BeachGull = game.player
	var at: Vector2 = player.position
	rear_left = 0.0
	player.rearing = false
	player.power_scale = float(s.bully_scale)
	player.set_enraged(true)
	stomp_index = _stomp_index()
	if _show_fx():
		game.overlay.set_dim(0.0,float(s.dim_fade))
		game.overlay.white_frame()
	game.effects.ring(at,float(s.slam_radius),float(s.slam_ring_time),float(s.slam_ring_width),Color("fff4da"))
	game.effects.ring(at,float(s.slam_radius),float(s.slam_ring_time),1.0,Color("fff4da"),float(s.slam_ring2_lag))
	game.effects.ground_slam(at,player.facing)
	_mark_stalls()
	var knocked: bool = _knock_around(float(s.slam_radius),true) > 0
	var t: Dictionary = Config.tuning.brash
	brash.hit_fx(at,Vector2(0,-1),knocked,0,int(t.hit_crumbs),float(t.hit_shake),float(t.hit_stop))
	brash.dust_left = float(t.dust_time)

## Knocks food from people (and makes carriers drop) within radius of the gull; returns how many lost something.
## `flat` measures sideways only, so a slam from high in the air reaches everyone beneath it.
func _knock_around(radius: float, flat: bool = false) -> int:
	var at: Vector2 = game.player.position
	var lift: float = float(settings().food_lift)
	var count: int = 0
	for target: BeachTarget in game.spawner.targets:
		if is_instance_valid(target) and target.food and _gap(at,target.food_position(),flat) <= radius and target.knock_food(game.player,lift):
			target.drop_retrieve = false
			target.hit_flash()
			game.effects.snatch_contact(target.food_position(),game.player.velocity,false)
			count += 1
	for pilot: RivalPilot in game.pilots:
		if pilot.carry_window > 0.0 and pilot.carried > 0 and _gap(at,pilot.gull.position,flat) <= radius:
			game._rival_drops_carry(pilot.gull,at)
			game.effects.feather_burst(pilot.gull.position,Vector2(signf(pilot.gull.position.x-at.x),-1.0)*20.0,int(settings().hit_feathers))
			count += 1
	return count

static func _gap(from: Vector2, to: Vector2, flat: bool) -> float:
	return absf(from.x-to.x) if flat else from.distance_to(to)

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
		game.effects.ring(game.player.position,float(settings().panic_ring_radius),float(settings().panic_ring_time),1.0,Color(1,0.96,0.85,float(settings().panic_ring_alpha)))
	impact_left = maxf(0.0,impact_left-delta)
	_duck_stalls()
	_mark_stalls()
	_shake()
	_pulse(delta)
	_stomp()

func _stomp_index() -> int:
	return floori(game.player.walk_phase/float(settings().stomp_steps))

## A heavy footfall every stomp_steps of walk phase while the bird walks on the ground.
func _stomp() -> void:
	var player: BeachGull = game.player
	var index: int = _stomp_index()
	var landed: bool = index != stomp_index and player.state == BeachGull.State.GROUNDED and absf(player.velocity.x) > 1.0
	stomp_index = index
	if landed:
		game.effects.sand_puff(player.position+Vector2(0,float(Config.tuning.flight.feet_offset)))
		if _show_fx():
			game.effects.shake = maxf(game.effects.shake,float(settings().stomp_shake))

## The fear travels with the gull: warn and stampede around where it is now.
func _panic() -> void:
	CrowdPanic.warn(game.spawner.targets,game.player.position.x)
	CrowdPanic.stampede(game.spawner.targets,game.player.position.x)
	CrowdPanic.pulse(game.spawner.targets,game.player.position.x)
	_scare()

## Dogs and teens near the gull run from it until the power ends. The sweeper is not scared. A squall's own flight is left alone.
func _scare() -> void:
	var at: float = game.player.position.x
	var radius: float = float(CrowdPanic.settings().panic_radius)
	var actors: Array = []
	actors.append_array(game.dogs)
	actors.append_array(game.teens)
	for actor: Node2D in actors:
		if is_instance_valid(actor) and is_nan(actor.flee_to) and absf(actor.position.x-at) <= radius:
			actor.flee_to = clampf(at+(1.0 if actor.position.x >= at else -1.0)*radius*1.5,12.0,float(Config.tuning.world.width)-12.0)
			scared.append(actor)

func _shake() -> void:
	if _knock_around(float(settings().shake_radius)) > 0 and impact_left <= 0.0:
		impact_left = float(settings().impact_gap)
		var s: Dictionary = settings()
		brash.hit_fx(game.player.position,game.player.velocity,true,0,int(s.hit_crumbs),float(s.hit_shake),float(s.hit_stop))

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

## A vendor ducks while the gull is within duck_reach sideways of the stall, and comes back up when it leaves.
func _duck_stalls() -> void:
	for stall: FoodStall in game.beach.stalls:
		if absf(stall.position.x-game.player.position.x) <= float(settings().duck_reach):
			if not stall.ducked:
				game.stalls.raid(stall)
		else:
			stall.ducked = false

## Stalls with raids left show the steal corners; they go at the cap and when the power ends.
func _mark_stalls() -> void:
	for stall: FoodStall in game.beach.stalls:
		stall.set_marker(gorging and rear_left <= 0.0 and int(raided.get(stall,0)) < int(settings().raid_cap))

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
	_mark_stalls()
	raids.peck_cooldown = float(Config.tuning.world.peck_cooldown)
	if count+1 == int(settings().raid_cap):
		game.effects.pixelfx("pixelfx_crit_hit",window,Vector2(game.player.facing,0))
		game.effects.shout(window-Vector2(0,12),"CLEANED OUT!",BeachUI.GOLD)
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
	var was_big: bool = player.power_scale > 1.0
	rear_left = 0.0
	player.rearing = false
	player.set_enraged(false)
	if is_instance_valid(game.overlay):
		game.overlay.set_dim(0.0)
	player.power_scale = 1.0
	player.power_tint = Color.WHITE
	player.sprite.scale = Vector2.ONE*(player.art_scale if player.detailed_art else 1.0)
	if was_big and not snap:
		var s: Dictionary = settings()
		var shrink: float = float(s.bully_scale)-1.0
		player.squash(shrink,shrink,float(s.deflate_time))
		game.effects.feather_burst(player.position,Vector2(0,-1)*20.0,int(s.deflate_feathers))
		Audio.play("gust",float(s.deflate_pitch),-6.0)
	if player.sand_landed.is_connected(_landed):
		player.sand_landed.disconnect(_landed)
	game.player.steady_invulnerable = false
	game.player.invulnerable = 0.0
	game.player.sprite.modulate.a = 1.0
	for stall: FoodStall in game.beach.stalls:
		stall.ducked = false
		stall.set_marker(false)
		if snap:
			stall.snap_duck()
	raided.clear()
	for actor: Node2D in scared:
		# During a squall the dog is still sheltering; the squall's own clear brings it home.
		if is_instance_valid(actor) and not (actor is OffLeadDog and game.squall != null and game.squall.phase == BeachSquall.Phase.SQUALL):
			actor.come_home()
	scared.clear()
