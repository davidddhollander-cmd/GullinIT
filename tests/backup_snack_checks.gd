extends RefCounted
## Kiosk shoppers carry one backup snack: eaten (bench or standing reveal) after their preferred food is stolen.
const DT: float = 0.02
const BenchWander = preload("res://tests/bench_wander_checks.gd")

static func _step(game: BeachGame, time: float) -> void:
	BenchWander.step(game,time)

static func _until(game: BeachGame, limit: float, done: Callable) -> bool:
	for i: int in int(limit/DT):
		if done.call():
			return true
		_step(game,DT)
	return done.call()

static func _steal(host: Node, victim: BeachTarget) -> bool:
	var gull := BeachGull.new()
	host.add_child(gull)
	gull.position = victim.position
	var stolen: bool = victim.take(gull)
	gull.queue_free()
	return stolen

static func run(host: Node, check: Callable) -> void:
	var previous_audio: bool = bool(Config.tuning.juice.audio)
	Config.tuning.juice.audio = false
	var cfg: Dictionary = Config.tuning.backup_snack
	var game: BeachGame = BenchWander.new_game(host,8)
	var victim: BeachTarget = game.spawner.create("kiosk_customer",700.0,{"appearance":"shopper_mullet","food_id":"hotdog"})
	game.stalls.bind(victim)
	check.call(victim.preferred_food_id == "hotdog" and victim.backup_left == int(cfg.count) and victim.backup_id in cfg.foods,"shopper starts with one backup snack from the tuning list")
	check.call(_steal(host,victim) and victim.snack == BeachTarget.Snack.PENDING and victim.food_id == "hotdog","stealing the preferred food queues the backup snack")
	var got: bool = _until(game,20.0,func() -> bool: return victim.snack == BeachTarget.Snack.EATING)
	check.call(got and victim.food and victim.food_id == victim.backup_id and victim.backup_left == 0,"after the sulk the shopper holds their backup snack (%s)" % victim.food_id)
	var seat_used: bool = victim.bench_visit.phase != BenchVisit.Phase.NONE
	var finished: bool = _until(game,40.0,func() -> bool: return victim.snack == BeachTarget.Snack.NONE)
	check.call(finished and not victim.food and victim.food_id == "hotdog" and victim.respawn > 0.0,"the snack runs out after its bites: empty hands, preferred food restored (bench=%s)" % str(seat_used))
	var rebought: bool = _until(game,60.0,func() -> bool: return victim.food and victim.snack == BeachTarget.Snack.NONE)
	check.call(rebought and victim.food_id == "hotdog","the shopper then re-buys their preferred food")
	check.call(_steal(host,victim) and victim.snack == BeachTarget.Snack.NONE and victim.food_id == "hotdog","the backup snack is used once: the second preferred theft queues none")
	game.queue_free()

	# Losing the snack itself goes back to the normal re-buy flow and pays the snack's points.
	game = BenchWander.new_game(host,8)
	victim = game.spawner.create("kiosk_customer",700.0,{"appearance":"shopper_mullet","food_id":"hotdog"})
	game.stalls.bind(victim)
	victim.backup_id = "cookie"
	_steal(host,victim)
	_until(game,20.0,func() -> bool: return victim.snack == BeachTarget.Snack.EATING)
	var stolen_id: String = victim.food_id
	var thefts: int = victim.thefts
	check.call(_steal(host,victim) and stolen_id == "cookie" and victim.snack == BeachTarget.Snack.NONE and victim.food_id == "hotdog" and not victim.food and victim.thefts == thefts+1,"a stolen snack restores the preferred food and re-buys normally")
	game.queue_free()

	# Standing reveal (the old man has no seated art): behind the body at the hip, rising to the hand.
	game = BenchWander.new_game(host,8)
	victim = game.spawner.create("kiosk_customer",700.0,{"appearance":"old_man","food_id":"hotdog"})
	game.stalls.bind(victim)
	victim.backup_id = "crisps_bag"
	_steal(host,victim)
	var revealing: bool = _until(game,20.0,func() -> bool: return victim.snack == BeachTarget.Snack.REVEAL)
	_step(game,DT)
	check.call(revealing and victim.food_sprite.get_index() < victim.sprite.get_index() and is_equal_approx(victim.food_sprite.position.y,-12.0) and victim.food_sprite.scale.is_equal_approx(victim.food_base_scale*0.6),"standing reveal starts behind the body at hip height, 0.6x size")
	var frozen: Vector2 = victim.position
	_until(game,0.3,func() -> bool: return false)
	check.call(victim.position.is_equal_approx(frozen),"the shopper stands still while the snack comes out")
	var eating: bool = _until(game,2.0,func() -> bool: return victim.snack == BeachTarget.Snack.EATING)
	var expected: Vector2 = victim.food_sprite.position
	BeachgoerArt.align_food(victim)
	check.call(eating and victim.food_sprite.get_index() > victim.sprite.get_index() and victim.food_sprite.position.is_equal_approx(expected) and victim.food_sprite.position.y < -12.0 and victim.food_sprite.scale.is_equal_approx(victim.food_base_scale),"standing reveal ends at the hand anchor, full size, in front of the body")
	var done: bool = _until(game,30.0,func() -> bool: return victim.snack == BeachTarget.Snack.NONE)
	check.call(done and not victim.food and victim.food_id == "hotdog","standing snack is finished after its bites")
	game.queue_free()
	Config.tuning.juice.audio = previous_audio
