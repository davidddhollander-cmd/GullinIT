class_name BeachBrash
extends Node2D
## Brashness: bold play (direct snatches, muggings, screeching from a high perch) fills a
## meter; a screech or the power button on a full meter fires the species power.
## Herring: Gang Call, a few herring gulls swoop in and knock food out of beachgoers' hands.

var game: BeachGame
var meter: float = 0.0
var allies: Array[Dictionary] = []
var vantage_shown: bool = false
var panic_started: bool = false
var dust_left: float = 0.0
var dust_clock: float = 0.0
var hits: int = 0
var active_id: String = "" ## the running timed power ("" when none)
var active_left: float = 0.0
var powers_fired: int = 0
var shakedown: BeachShakedown = BeachShakedown.new()

func tuning() -> Dictionary:
	return Config.tuning.brash

func power() -> Dictionary:
	return game.player.species_stats().get("power",{})

func is_full() -> bool:
	return not power().is_empty() and meter >= 1.0

func active() -> bool:
	return not active_id.is_empty()

## Meter gain for a play style; each species' power.fill scales it.
func earn(key: String) -> void:
	add(float(tuning()[key])*float(power().get("fill",{}).get(key,1.0)))

func add(amount: float) -> void:
	if power().is_empty() or not allies.is_empty() or active():
		return
	var was_full: bool = meter >= 1.0
	meter = clampf(meter+amount,0.0,1.0)
	if meter >= 1.0 and not was_full:
		# Ready sting: a sharp call and a pop over the gull.
		Audio.play("gull_call",1.35,-4.0)
		game.effects.message(game.player.position-Vector2(0,22),"READY!",BeachUI.GOLD)

## Pixels above the sand multiply the screech fill: a lamp pole or stand roof is the loudest stage.
func vantage_mult() -> float:
	var sand: float = float(Config.tuning.world.ground)-float(Config.tuning.flight.feet_offset)
	var height: float = maxf(0.0,sand-game.player.position.y)
	return clampf(1.0+height*float(tuning().vantage_per_px),1.0,float(tuning().vantage_max))

func screech_tick(delta: float) -> void:
	var mult: float = vantage_mult()
	if mult > 1.2 and not vantage_shown:
		vantage_shown = true
		game.effects.message(game.player.position-Vector2(0,22),"HIGH PERCH x%.1f" % mult,BeachUI.GOLD)
	add(float(tuning().screech_per_sec)*mult*delta)

func screech_ended() -> void:
	vantage_shown = false

func fire() -> bool:
	if not is_full() or game.player.state == BeachGull.State.STUNNED:
		return false
	meter = 0.0
	var p: Dictionary = power()
	if str(p.id) != "shakedown": # Shakedown announces itself with the big callout
		game.effects.message(game.player.position-Vector2(0,24),str(p.name)+"!",BeachUI.GOLD)
	Audio.play(str(p.get("sound","gang_call")),float(p.get("pitch",1.0)),-2.0)
	game.effects.sound_wave(game.player.beak())
	powers_fired += 1
	game.track("power_fired",{"power":str(p.id),"level":int(game.level.get("id",0))})
	if str(p.id) == "shakedown":
		active_id = "shakedown"
		active_left = float(p.duration)
		shakedown.start(self)
	else:
		_gang_call(p)
	return true

func _gang_call(p: Dictionary) -> void:
	CrowdPanic.warn(game.spawner.targets,game.player.position.x)
	for target: BeachTarget in game.spawner.targets:
		if is_instance_valid(target) and target.panic.state == CrowdPanic.State.LOOK_UP:
			game.effects.message(target.position-Vector2(0,48),"!",BeachUI.GOLD,0.6,6.0)
	hits = 0
	panic_started = false
	var lead: float = float(CrowdPanic.settings().lead_time)
	var targets: Array[BeachTarget] = []
	for target: BeachTarget in game.spawner.targets:
		if game.snatchable(target) and absf(target.position.x-game.camera_x) < 170.0:
			targets.append(target)
	targets.sort_custom(func(a: BeachTarget, b: BeachTarget) -> bool: return absf(a.position.x-game.player.position.x) < absf(b.position.x-game.player.position.x))
	for i: int in int(p.allies):
		var side: float = -1.0 if i%2 == 0 else 1.0
		var target: BeachTarget = targets[i] if i < targets.size() else null
		var hit: Vector2 = target.food_position() if target != null else Vector2(game.camera_x+(i-1)*70.0,float(Config.tuning.world.ground)-30.0)
		var gull: BeachGull = BeachGull.new()
		gull.species = "herring"
		gull.state = BeachGull.State.GLIDE
		gull.z_index = 4
		gull.visible = false
		game.add_child(gull)
		var start: Vector2 = Vector2(hit.x-side*120.0,-20.0)
		gull.position = start
		allies.append({"gull":gull,"target":target,"start":start,"hit":hit,"end":Vector2(hit.x+side*140.0,-30.0),"t":-lead-float(p.stagger)*i,"knocked":false})

## Each ally follows two quadratic curves: a plunge from offscreen to the food, then a climb back out.
func tick(delta: float) -> void:
	if active():
		if shakedown.rear_left > 0.0:
			shakedown.rear_tick(delta) # the power's clock starts after the hold
		else:
			active_left -= delta
			if active_left <= 0.0:
				end_power(false)
			else:
				shakedown.tick(delta)
	var swoop: float = float(power().get("swoop_time",0.7))
	for ally: Dictionary in allies:
		ally.t += delta
		var gull: BeachGull = ally.gull
		if ally.t < 0.0:
			continue
		if not gull.visible:
			Audio.play("gust",1.7,-6.0)
		gull.visible = true
		var before: Vector2 = gull.position
		var plunge: bool = ally.t < swoop
		var u: float = clampf(ally.t/swoop,0.0,1.0) if plunge else clampf((ally.t-swoop)/swoop,0.0,1.0)
		var from: Vector2 = ally.start if plunge else ally.hit
		var to: Vector2 = ally.hit if plunge else ally.end
		var control: Vector2 = Vector2(to.x,from.y) if plunge else Vector2(from.x,to.y)
		gull.position = from.lerp(control,u).lerp(control.lerp(to,u),u)
		gull.velocity = (gull.position-before)/maxf(delta,0.001)
		gull.facing = 1 if gull.velocity.x >= 0.0 else -1
		gull.sprite.flip_h = gull.facing < 0
		gull.sprite.play(&"dive" if plunge and u > 0.45 else &"fly")
		gull.sprite.rotation = clampf(gull.velocity.angle() if gull.facing > 0 else gull.velocity.angle()-PI,-1.2,1.2) if plunge and u > 0.45 else 0.0
		if not plunge and not ally.knocked:
			ally.knocked = true
			if not panic_started:
				panic_started = true
				CrowdPanic.stampede(game.spawner.targets,game.player.position.x)
				dust_left = float(tuning().dust_time)
			_impact(ally,gull)
	_dust(delta)
	queue_redraw()
	for ally: Dictionary in allies.filter(func(a: Dictionary) -> bool: return a.t >= swoop*2.0):
		ally.gull.queue_free()
		allies.erase(ally)

## Each gang hit lands harder than the last: feathers, sand, a screen punch and a rising cry.
func _impact(ally: Dictionary, gull: BeachGull) -> void:
	var t: Dictionary = tuning()
	var knocked: bool = is_instance_valid(ally.target) and ally.target.knock_food(gull,float(t.food_lift))
	if knocked:
		ally.target.hit_flash()
	hit_fx(ally.hit,gull.velocity,knocked,int(t.hit_feathers),int(t.hit_crumbs),float(t.hit_shake),float(t.hit_stop))

## The shared impact bundle (Gang Call hits, Shakedown slam and shakes); each hit counts toward the rising cry.
func hit_fx(at: Vector2, velocity: Vector2, knocked: bool, feathers: int, crumbs: int, shake: float, stop: float) -> void:
	var t: Dictionary = tuning()
	var fx: BeachEffects = game.effects
	var step: int = mini(hits,int(t.hit_cap))
	if feathers > 0: # 0 means the caller's own gull is the one hitting: no feathers
		fx.feather_burst(at,velocity,feathers+step*int(t.hit_feathers_per_hit))
	if knocked:
		fx.food_crumble(at,velocity,crumbs) # on top of the knock's own crumble
	fx.sand_puff(Vector2(at.x,float(Config.tuning.world.ground)))
	if bool(Config.tuning.juice.shake) and GameState.options.shake:
		fx.shake = maxf(fx.shake,shake)
	if bool(Config.tuning.juice.hitstop):
		fx.freeze = maxf(fx.freeze,stop)
	Audio.play("gull_hit_%d" % (step%3+1),1.0+0.1*step,-3.0 if knocked else -7.0)
	hits += 1

## Panicked runners kick up sand for the first second of the stampede.
func _dust(delta: float) -> void:
	if dust_left <= 0.0:
		return
	dust_left -= delta
	dust_clock -= delta
	if dust_clock > 0.0:
		return
	dust_clock = float(tuning().dust_gap)
	for target: BeachTarget in game.spawner.targets:
		if is_instance_valid(target) and target.panic.state == CrowdPanic.State.PANIC:
			game.effects.sand_puff(target.position,true)

## Gang shadows race across the sand toward their targets before each gull appears
## (once visible, each gull draws its own shadow).
func _draw() -> void:
	var sand: float = float(Config.tuning.world.ground)
	var lead: float = float(tuning().shadow_lead)
	for ally: Dictionary in allies:
		if ally.t < -lead or ally.t >= 0.0:
			continue
		var near: float = 1.0+ally.t/lead
		draw_set_transform(Vector2(lerpf(ally.start.x,ally.hit.x,0.4*near),sand),0,Vector2(1,0.25))
		draw_circle(Vector2.ZERO,lerpf(16,9,near),Color(0.09,0.18,0.22,lerpf(0.06,0.24,near)))
		draw_set_transform(Vector2.ZERO)

func end_power(snap: bool = true) -> void:
	if active_id == "shakedown":
		shakedown.end(snap)
	active_id = ""
	active_left = 0.0

func clear() -> void:
	end_power()
	if not panic_started:
		CrowdPanic.calm(game.spawner.targets)
	for ally: Dictionary in allies:
		ally.gull.queue_free()
	allies.clear()
