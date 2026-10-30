extends RefCounted

static func run(host: Node, check: Callable) -> void:
	GameState.progress = {}
	host.main.start_level(1)
	var game: BeachGame = host.main.game
	game.set_physics_process(false)
	game._physics_process(float(Config.tuning.world.intro_time)+1.0)
	check.call(not game.running and game.intro > 0 and not game.input.enabled,"tutorial waits for explicit start without running in background")
	game.set_paused(true)
	game.set_paused(false)
	game.set_physics_process(false)
	check.call(not game.input.enabled,"resuming before confirmation keeps gameplay controls disabled")
	game.overlay.start_button.pressed.emit()
	check.call(game.running and game.input.enabled,"tutorial start button enables controls")
	check.call(game.training and not game.casual and game.lesson == 0 and game.player.state == BeachGull.State.GROUNDED,"first visit starts grounded training without a timer")
	check.call(game.training_text().contains("Space") or game.training_text().contains("FLAP"),"first lesson explains takeoff: "+game.training_text())
	check.call(game.training_target().x > game.player.position.x,"first lesson points into open sky: "+str(game.training_target())+" / "+str(game.player.position))
	game._training_tick(0.1)
	check.call(game.lesson == 0,"training does not advance without takeoff and steering")
	game.elapsed = 1000.0
	game.score.items = 15
	game._physics_process(0.01)
	check.call(game.running and game.lesson == 0,"training ignores arcade time and Practice snatch quota")
	# Take off first, then release flap and steer: the actions need not overlap.
	game.input.touch_active = true
	game.input.aim_finger = 7
	game.input.stick_anchor = Vector2(100,100)
	game.input.stick_pos = Vector2(100,84)
	game.input.touch_climb = true
	for frame: int in range(90):
		game._physics_process(1.0/60)
	check.call(game.player.position.y < 110 and game.lesson == 0,"vertical takeoff waits for steering")
	check.call(game.training_text().contains("Steer right"),"takeoff updates the tip with the remaining steering action")
	game.input.touch_climb = false
	game.input.stick_pos = Vector2(124,96)
	for frame: int in range(40):
		game._physics_process(1.0/60)
	check.call(game.lesson == 1 and int(GameState.entry(1).get("training_step",0)) == 1,"takeoff and steer saves lesson checkpoint")
	game.overlay._process(0)
	check.call(game.overlay.lesson_label.text.contains("LESSON 2/%d" % BeachGame.TRAINING_LESSONS) and game.overlay.lesson_prompt.text.contains("aim down"),"landing tip replaces first tip after takeoff then steering")
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
	check.call(game.lesson == 4,"bag food collection advances to bin lesson")
	check.call(game.training_text().contains("bin"),"bin lesson explains the new action")
	game._scrap_collected(Vector2.ZERO,"crumbs")
	check.call(game.lesson == 4,"ordinary scraps cannot skip the bin lesson")
	game.player.state = BeachGull.State.GROUNDED
	game.player.position = Vector2(float(game.stash_raids.bins[0].x),game.player.ground_y())
	for tap: int in range(int(Config.tuning.world.bin_pecks)):
		game.stash_raids.peck_cooldown = 0
		game._peck()
		check.call(game.lesson == (5 if tap == int(Config.tuning.world.bin_pecks)-1 else 4),"bin lesson waits for the full peck sequence")
	check.call(not game.stash_raids.items.is_empty(),"bin lesson releases real scraps and litter")
	game.stash_raids.items.clear()
	# Wheelie bin lesson: pecking from the sand does nothing; the lid unlocks better trash.
	var wheelie: Dictionary = game.training_bin(true)
	check.call(not wheelie.is_empty() and float(wheelie.x) > 756.0 and float(wheelie.x) < float(game.level.world.width) - 12.0,"training wheelie bin stands right of the stand by the screen edge: "+str(wheelie.get("x")))
	check.call(game.lesson == BeachGame.WHEELIE_LESSON and game.training_text().contains("wheelie"),"wheelie lesson follows the ordinary bin lesson")
	check.call(game.training_target().y < float(Config.tuning.world.ground) - 25.0,"wheelie lesson ring marks the raised lid")
	game.player.support = {}
	game.player.state = BeachGull.State.GROUNDED
	game.player.position = Vector2(float(wheelie.x) - 10.0,game.player.ground_y())
	check.call(game.training_text().contains("Too low"),"standing beside the wheelie bin explains the lid rule")
	for tap: int in range(int(Config.tuning.world.bin_pecks)):
		game.stash_raids.peck_cooldown = 0
		game._peck()
	check.call(game.lesson == BeachGame.WHEELIE_LESSON and game.stash_raids.items.is_empty(),"wheelie lesson cannot be passed from the sand")
	var lid: Dictionary = {}
	for surface: Dictionary in game.player.perch_surfaces:
		if str(surface.get("prop_type","")) == "wheelie_bin":
			lid = surface
	game.player.support = lid
	game.player.state = BeachGull.State.GLIDE
	game.player.position = Vector2(float(lid.x),float(lid.y) - float(Config.tuning.flight.feet_offset))
	game.player.land()
	for tap: int in range(int(Config.tuning.world.bin_pecks)):
		game.stash_raids.peck_cooldown = 0
		game._peck()
		check.call(game.lesson == (BeachGame.SECOND_SWOOP_LESSON if tap == int(Config.tuning.world.bin_pecks)-1 else BeachGame.WHEELIE_LESSON),"wheelie lesson waits for the full lid peck sequence")
	check.call(game.training_dummy() == null and game.pilots.is_empty(),"no dummy gull appears before the bump lesson")
	var wheelie_food: int = 0
	for item: Dictionary in game.stash_raids.items:
		if not bool(item.get("garbage",false)):
			wheelie_food += 1
	check.call(wheelie_food >= 2,"wheelie bin burst is mostly food: %d of %d" % [wheelie_food,game.stash_raids.items.size()])
	game.stash_raids.items.clear()
	game.player.support = {}
	game.player.state = BeachGull.State.GLIDE
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
	check.call(game.lesson == BeachGame.BUMP_LESSON and game.running and results.is_empty(),"second clean swoop leads on to the bump lesson")
	var dummy: RivalPilot = game.training_dummy()
	check.call(dummy != null and dummy.dummy and game.pilots.size() == 1 and dummy.carry_window <= 0.0,"bump lesson spawns one empty-beaked dummy gull")
	game.overlay._process(0)
	check.call(game.overlay.lesson_label.text.contains("LESSON 8/9") and game.training_text().contains("dummy gull") and game.training_target() == dummy.gull.position,"bump lesson names the action and rings the dummy")
	# The dummy only patrols its lap: it never hunts, dives, steals or mugs.
	for frame: int in range(240):
		dummy.tick(1.0/60,[customer],{},game.wind)
	check.call(dummy.dives == 0 and dummy.thefts == 0 and dummy.mode == RivalPilot.Mode.PATROL and dummy.gull.position.x > 80.0 and dummy.gull.position.x < 560.0,"dummy gull patrols without hunting or diving: "+str(dummy.gull.position))
	var hit_from: Vector2 = Vector2(200,56)
	dummy.gull.state = BeachGull.State.GLIDE
	dummy.gull.invulnerable = 0.0
	dummy.gull.position = hit_from
	game.player.state = BeachGull.State.GLIDE
	game.player.previous_beak = hit_from - Vector2(0,10)
	game.player.sweep_beak = hit_from + Vector2(0,10)
	game._mugging()
	check.call(game.lesson == BeachGame.BUMP_LESSON,"flying through the dummy without diving does not bump it")
	game.player.state = BeachGull.State.STRIKE
	game._mugging()
	check.call(game.lesson == BeachGame.MUG_LESSON and dummy.gull.state == BeachGull.State.STUNNED and int(GameState.entry(1).get("training_step",0)) == BeachGame.MUG_LESSON,"dive into the empty-beaked dummy bumps it and advances to the mug lesson")
	game.player.digestion.snacks.clear()
	game.player.digestion.rest = 0.0
	check.call(game.training_text().contains("through the dummy") and dummy.dummy_food == BeachGame.DUMMY_FOOD,"mug lesson arms the dummy with food")
	# The mug window stays open only while the dummy is flying again.
	dummy.tick(1.0/60,[],{},game.wind)
	check.call(dummy.carry_window <= 0.0 or dummy.gull.state != BeachGull.State.STUNNED,"a tumbling dummy is not muggable yet")
	dummy.gull.state = BeachGull.State.GLIDE
	dummy.tick(1.0/60,[],{},game.wind)
	check.call(dummy.carry_window > 0.0 and dummy.carried > 0 and dummy.gull.carry_source.call() == BeachGame.DUMMY_FOOD,"recovered dummy visibly carries a muggable snack")
	game.player.digestion.snacks.clear()
	game.player.digestion.rest = 0.0
	dummy.gull.position = hit_from
	game.player.state = BeachGull.State.GLIDE
	game._mugging()
	check.call(game.lesson == BeachGame.MUG_LESSON,"gliding past the dummy's snack does not mug it")
	var feathers_before: int = GameState.feathers()
	game.player.state = BeachGull.State.STRIKE
	game._mugging()
	var entry: Dictionary = GameState.entry(1)
	check.call(game.player.digestion.snacks.size() == 1 and dummy.dummy_food.is_empty(),"mug lesson takes the dummy's snack")
	check.call(game.lesson == BeachGame.TRAINING_LESSONS and not game.running and results.size() == 1,"mugging the dummy finishes training exactly once")
	check.call(GameState.feathers() == feathers_before + 1 and int(results[0].get("feathers_earned",0)) == 1,"first completion pays one Feather")
	check.call(not GameState.complete_training() and GameState.feathers() == feathers_before + 1,"completing the course again pays no Feather")
	check.call(bool(entry.get("training_complete",false)) and int(entry.get("training_step",0)) == BeachGame.TRAINING_LESSONS and GameState.unlocked(2),"completion persists checkpoint and unlocks family beach: "+str(entry))
	check.call(not entry.has("best") and not entry.has("stars") and not entry.has("casual_time") and (results.size() == 1 and results[0].stars == 0),"training completion grants no stars or practice record")
	host.main.start_level(1)
	check.call(not host.main.game.training,"completed Training Day can be replayed as a regular run")
	host.main.start_level(1,true)
	check.call(host.main.game.training and host.main.game.lesson == 0,"train again explicitly restarts the first lesson")
	# Reproduce the player's normal route with an already-completed save.
	var completed_entry: Dictionary = GameState.entry(1)
	host.main._navigate("select")
	var training_button: Button
	for button: Button in host.main.menus.find_children("*","Button",true,false):
		if button.text.contains("TRAINING"):
			training_button = button
			break
	check.call(is_instance_valid(training_button) and training_button.text.contains("REPLAY LESSONS"),"completed Training Day card clearly offers the lessons")
	if is_instance_valid(training_button):
		training_button.pressed.emit()
	game = host.main.game
	game.set_physics_process(false)
	check.call(game.training and game.lesson == 0 and not game.casual,"normal Training Day selection replays lessons on a completed save")
	game.overlay.start_button.pressed.emit()
	game.overlay._process(0)
	check.call(game.overlay.training_panel.visible and game.overlay.lesson_prompt.text.contains("take off"),"first tip is visible when replaying through the level card")
	Input.action_press("climb")
	Input.action_press("aim_up")
	for frame: int in range(50):
		game._physics_process(1.0/60)
	Input.action_release("climb")
	Input.action_release("aim_up")
	Input.action_press("aim_right")
	for frame: int in range(40):
		game._physics_process(1.0/60)
	Input.action_release("aim_right")
	game.overlay._process(0)
	check.call(game.lesson == 1 and game.overlay.training_panel.visible and game.overlay.lesson_prompt.text.contains("aim down"),"second tip appears after takeoff and steering on a completed save")
	check.call(GameState.entry(1) == completed_entry,"replaying tips preserves completed progress and existing records")
	host.main._navigate("restart")
	check.call(host.main.game.training and host.main.game.lesson == 0,"restarting a replay keeps tutorial tips enabled")
	# A save stopped at the bump or mug lesson resumes with the dummy gull already flying.
	GameState.progress = {"1":{"training_step":BeachGame.BUMP_LESSON}}
	host.main.start_level(1)
	game = host.main.game
	game.set_physics_process(false)
	check.call(game.training and game.lesson == BeachGame.BUMP_LESSON and game.training_dummy() != null and game.training_dummy().dummy_food.is_empty(),"retry at the bump lesson resumes with an empty-beaked dummy")
	GameState.progress = {"1":{"training_step":BeachGame.MUG_LESSON}}
	host.main.start_level(1)
	game = host.main.game
	game.set_physics_process(false)
	check.call(game.lesson == BeachGame.MUG_LESSON and game.training_dummy() != null and game.training_dummy().dummy_food == BeachGame.DUMMY_FOOD,"retry at the mug lesson resumes with the dummy carrying food")
	host.main.start_level(2)
	game = host.main.game
	game.set_physics_process(false)
	check.call(game.pilots.is_empty() and game.pending_rivals.size() == 1,"Gary waits offscreen until the first swallowed snack")
	game._swallowed({"id":"ice_cream"})
	check.call(game.pending_rivals.is_empty() and game.pilots.size() == 1 and game.pilots[0].gull.visible,"first swallowed snack releases Gary once")
	game._swallowed({"id":"ice_cream"})
	check.call(game.pilots.size() == 1,"later food does not spawn duplicate rivals")
	host.main.clear_game()
	GameState.progress = {}
