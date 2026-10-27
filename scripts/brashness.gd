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

func tuning() -> Dictionary:
	return Config.tuning.brash

func power() -> Dictionary:
	return game.player.species_stats().get("power",{})

func is_full() -> bool:
	return not power().is_empty() and meter >= 1.0

func add(amount: float) -> void:
	if power().is_empty() or not allies.is_empty():
		return
	meter = clampf(meter+amount,0.0,1.0)

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
	if not is_full():
		return false
	meter = 0.0
	var p: Dictionary = power()
	game.effects.message(game.player.position-Vector2(0,24),str(p.name)+"!",BeachUI.GOLD)
	Audio.play("gang_call",1.0,-2.0)
	CrowdPanic.warn(game.spawner.targets,game.player.position.x)
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
	return true

## Each ally follows two quadratic curves: a plunge from offscreen to the food, then a climb back out.
func tick(delta: float) -> void:
	var swoop: float = float(power().get("swoop_time",0.7))
	for ally: Dictionary in allies:
		ally.t += delta
		var gull: BeachGull = ally.gull
		if ally.t < 0.0:
			continue
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
			if is_instance_valid(ally.target) and ally.target.knock_food(gull):
				Audio.play("snatch",1.2,-4.0)
	for ally: Dictionary in allies.filter(func(a: Dictionary) -> bool: return a.t >= swoop*2.0):
		ally.gull.queue_free()
		allies.erase(ally)

func clear() -> void:
	if not panic_started:
		CrowdPanic.calm(game.spawner.targets)
	for ally: Dictionary in allies:
		ally.gull.queue_free()
	allies.clear()
