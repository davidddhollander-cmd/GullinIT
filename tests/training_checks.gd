extends RefCounted

static func run(host: Node, check: Callable) -> void:
	GameState.progress = {}
	host.main.start_level(1)
	var game: BeachGame = host.main.game
	game.set_physics_process(false)
	game.intro = 0
	game.running = true
	check.call(game.training and not game.casual and game.lesson == 0 and game.player.state == BeachGull.State.GROUNDED,"first visit starts grounded training without a timer")
	check.call(game.training_text().contains("SPACE") or game.training_text().contains("FLAP"),"first lesson explains takeoff: "+game.training_text())
	check.call(game.training_target().x > game.player.position.x,"first lesson points into open sky: "+str(game.training_target())+" / "+str(game.player.position))
	game._training_tick(0.1)
	check.call(game.lesson == 0,"training does not advance without takeoff and steering")
	game.elapsed = 1000.0
	game.score.items = 15
	game._physics_process(0.01)
	check.call(game.running and game.lesson == 0,"training ignores arcade time and Practice snatch quota")
	game.player.climb = true
	game.player.position = Vector2(115,90)
	game._training_tick(0.1)
	check.call(game.lesson == 1 and int(GameState.entry(1).get("training_step",0)) == 1,"takeoff and steer saves lesson checkpoint")
	game.player.state = BeachGull.State.GLIDE
	game._scrap_collected(Vector2(60,156),"crumbs")
	check.call(game.lesson == 1,"airborne crumb pickup does not satisfy landing lesson")
	game.player.state = BeachGull.State.GROUNDED
	game._scrap_collected(Vector2(60,156),"crumbs")
	check.call(game.lesson == 2 and int(GameState.entry(1).get("training_step",0)) == 2,"grounded crumb pickup advances to the first swoop")
	game.finish()
	check.call(game.training and game.running and not GameState.entry(1).has("best"),"early finish cannot skip lessons or record a score")
	host.main._navigate("restart")
	game = host.main.game
	game.set_physics_process(false)
	game.intro = 0
	game.running = true
	check.call(game.training and game.lesson == 2 and game.player.state == BeachGull.State.GLIDE,"retry resumes saved lesson in flight")
	var customer: BeachTarget
	var sunbather: BeachTarget
	for target: BeachTarget in game.spawner.targets:
		if target.kind == "kiosk_customer":
			customer = target
		elif target.kind == "sunbather":
			sunbather = target
	check.call(is_instance_valid(customer) and is_instance_valid(sunbather),"training route provides held snack and picnic bag")
	game.player.state = BeachGull.State.STRIKE
	game.player.position.y = 120
	game.player.velocity.y = 50
	customer.last_theft_direct = false
	game._snatched(customer,game.player,false)
	game._training_tick(0.1)
	check.call(game.lesson == 2 and not game.training_clean_snatch,"loose food does not count as a clean swoop")
	customer.last_theft_direct = true
	game._snatched(customer,game.player,false)
	game._training_tick(0.1)
	check.call(game.lesson == 2 and game.training_clean_snatch,"direct snack theft still requires an upward escape")
	game.player.position.y = 80
	game.player.velocity.y = -25
	game._training_tick(0.1)
	check.call(game.lesson == 3,"clean swoop and safe pullup advance to picnic bag")
	game.stash_raids.bag_collected.emit()
	check.call(game.lesson == 3,"picnic lesson requires starting a bag raid")
	game.training_raid_started = true
	game.stash_raids.collected.emit(Vector2.ZERO,"crumbs",true)
	check.call(game.lesson == 3,"bin scrap cannot satisfy picnic bag lesson")
	game.stash_raids.bag_collected.emit()
	check.call(game.lesson == 4,"bag food collection after raid advances to unassisted swoop")
	customer.food = false
	customer.food_sprite.hide()
	customer.dropped_pending = true
	customer.dropped_item = {"recovered":false}
	sunbather.stash_remaining = 0
	game.stash_raids.items.append({"owner":sunbather})
	game._training_tick(5.0)
	check.call(customer.food and not customer.dropped_pending and bool(customer.dropped_item.is_empty()),"training restores missed customer snack after delay")
	check.call(sunbather.stash_remaining == 0,"training does not duplicate a bag while its food is loose")
	game.stash_raids.items.clear()
	game._training_tick(5.0)
	check.call(sunbather.stash_remaining == int(Config.tuning.world.sunbather_stash_size),"training restores exhausted bag after loose food clears")
	var results: Array[Dictionary] = []
	game.level_finished.connect(func(result: Dictionary) -> void: results.append(result))
	game.player.state = BeachGull.State.STRIKE
	game.player.position.y = 80
	game.player.velocity.y = -20
	game._training_snatch(customer)
	game._training_tick(0.1)
	var entry: Dictionary = GameState.entry(1)
	check.call(game.lesson == 5 and not game.running and results.size() == 1,"final clean swoop finishes training exactly once")
	check.call(bool(entry.get("training_complete",false)) and int(entry.get("training_step",0)) == 5 and GameState.unlocked(2),"completion persists checkpoint and unlocks family beach: "+str(entry))
	check.call(not entry.has("best") and not entry.has("stars") and not entry.has("casual_time") and (results.size() == 1 and results[0].stars == 0),"training completion grants no stars or practice record")
	host.main.start_level(1)
	check.call(not host.main.game.training,"completed Training Day can be replayed as a regular run")
	host.main.start_level(1,true)
	check.call(host.main.game.training and host.main.game.lesson == 0,"train again explicitly restarts the first lesson")
	host.main.start_level(3)
	game = host.main.game
	game.set_physics_process(false)
	check.call(game.pilots.is_empty() and game.pending_rivals.size() == 1,"Gary waits offscreen until the first swallowed snack")
	game._swallowed({"id":"ice_cream"})
	check.call(game.pending_rivals.is_empty() and game.pilots.size() == 1 and game.pilots[0].gull.visible,"first swallowed snack releases Gary once")
	game._swallowed({"id":"ice_cream"})
	check.call(game.pilots.size() == 1,"later food does not spawn duplicate rivals")
	host.main.clear_game()
	GameState.progress = {}
