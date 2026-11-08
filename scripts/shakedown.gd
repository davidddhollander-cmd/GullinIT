class_name BeachShakedown
extends RefCounted
## Great black-back power: untouchable, a rolling crowd panic, food shaken loose on contact, and raids on stall counters.

var brash: BeachBrash
var game: BeachGame
var clock: float = 0.0
var raided: Dictionary = {} ## FoodStall -> items spat this power

func settings() -> Dictionary:
	return Config.tuning.shakedown

func start(owner: BeachBrash) -> void:
	brash = owner
	game = owner.game
	raided.clear()
	clock = 0.0
	game.player.steady_invulnerable = true
	game.player.invulnerable = maxf(game.player.invulnerable,brash.active_left)
	_panic()

func tick(delta: float) -> void:
	game.player.invulnerable = maxf(game.player.invulnerable,brash.active_left)
	clock += delta
	if clock >= float(settings().panic_interval):
		clock -= float(settings().panic_interval)
		_panic()
	_shake()

## The fear travels with the gull: warn and stampede around where it is now.
func _panic() -> void:
	CrowdPanic.warn(game.spawner.targets,game.player.position.x)
	CrowdPanic.stampede(game.spawner.targets,game.player.position.x)

func _shake() -> void:
	var at: Vector2 = game.player.position
	var radius: float = float(settings().shake_radius)
	for target: BeachTarget in game.spawner.targets:
		if is_instance_valid(target) and target.food and at.distance_to(target.food_position()) <= radius and target.knock_food(game.player):
			game.effects.snatch_contact(target.food_position(),game.player.velocity,false)
			Audio.play("snatch",1.2,-6.0)
	for pilot: RivalPilot in game.pilots:
		if pilot.carry_window > 0.0 and pilot.carried > 0 and at.distance_to(pilot.gull.position) <= radius:
			game._rival_drops_carry(pilot.gull,at)

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
	var side: float = -1.0 if count%2 == 0 else 1.0
	game.effects.peck_contact(window,Vector2(game.player.facing,-0.35),float(count+1)/float(settings().raid_cap),"bin")
	game.effects.release_burst(window,true)
	Audio.play("bin_rattle",0.9+0.2*float(count)/float(settings().raid_cap))
	raids.items.append({"owner":null,"source":"raid","food_id":str(foods[raids.rng.randi_range(0,foods.size()-1)]),"position":window+Vector2(0,6),"velocity":Vector2(side*raids.rng.randf_range(35,65),-raids.rng.randf_range(65,95)),"grounded":false,"age":0.0})
	raids.queue_redraw()
	return true

func end(snap: bool) -> void:
	game.player.steady_invulnerable = false
	game.player.invulnerable = 0.0
	game.player.sprite.modulate.a = 1.0
	for stall: FoodStall in game.beach.stalls:
		stall.ducked = false
		if snap:
			stall.snap_duck()
	raided.clear()
