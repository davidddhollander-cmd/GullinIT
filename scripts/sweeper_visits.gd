class_name SweeperVisits
extends Node
## Schedules the sweeper's visits for levels with a "sweeper" block: a first arrival, a stay, an absence,
## and an early call when more than `call_litter` loose items lie on the sand.
signal arrived(sweeper: BeachSweeper)
var game: BeachGame
var settings: Dictionary
var enabled: bool = false
var sweeper: BeachSweeper
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var wait: float = 0.0
var stay: float = 0.0
var absent: float = 0.0
var visits: int = 0

func setup(owner_game: BeachGame, level: Dictionary) -> void:
	game = owner_game
	settings = Config.tuning.sweeper.duplicate(true)
	settings.merge(level.get("sweeper",{}),true)
	enabled = bool(settings.get("enabled",false))
	rng.seed = int(level.seed)+88211
	wait = float(settings.first_arrival)

func tick(delta: float, allow_spawning: bool) -> void:
	if not enabled or delta <= 0.0:
		return
	if is_instance_valid(sweeper):
		stay -= delta
		if stay <= 0.0 and not sweeper.leaving:
			sweeper.dismiss()
		return
	if not allow_spawning:
		return
	absent += delta
	wait -= delta
	var called: bool = absent >= float(settings.call_min_absence) and BeachSweeper.litter_count(game.stash_raids.items) > int(settings.call_litter)
	if wait <= 0.0 or called:
		_spawn()

func _spawn() -> void:
	var bounds: Array = settings.range
	var from: float = game.player.position.x
	# Run in from a side of the screen: the one inside his sand range and furthest from the gull.
	var left: float = game.camera_x-176.0
	var right: float = game.camera_x+176.0
	var left_ok: bool = left >= float(bounds[0])-20.0 and left <= float(bounds[1])
	var right_ok: bool = right >= float(bounds[0]) and right <= float(bounds[1])+20.0
	var x: float
	if left_ok and right_ok:
		x = left if absf(left-from) >= absf(right-from) else right
	elif left_ok or right_ok:
		x = left if left_ok else right
	else:
		x = clampf(right if game.camera_x > float(bounds[1]) else left,float(bounds[0])-20.0,float(bounds[1])+20.0) # camera is off the sand: come in from its end
	sweeper = BeachSweeper.new()
	game.actors.add_child(sweeper)
	sweeper.setup(game,x,int(game.level.seed)+11+visits)
	visits += 1
	stay = float(settings.dwell)
	absent = 0.0
	wait = INF
	sweeper.left.connect(func() -> void:
		wait = rng.randf_range(float(settings.absence[0]),float(settings.absence[1]))
		absent = 0.0
	)
	arrived.emit(sweeper)
