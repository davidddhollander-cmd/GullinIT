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
	check.call(not game._can_screech(),"Training Day never turns a held peck into a screech")
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
	game.input.stick_pos = GullInput.FLY_STICK_CENTER + Vector2(0,-16)
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
	check.call(game.lesson == BeachGame.TODDLER_LESSON and int(GameState.entry(1).get("training_step",0)) == 2,"grounded crumb pickup advances to the toddler lesson")
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
	# Toddler lesson: peck his ice cream off, then walk over the cone.
	var toddler: BeachTarget = game.lesson_toddler()
	check.call(toddler != null and toddler.food and game.training_target() == toddler.food_position(),"the toddler holds an ice cream and the ring marks it")
	game.player.state = BeachGull.State.GROUNDED
	game.player.support = {}
	game.player.facing = 1.0
	game.player.position += (toddler.food_position() - Vector2(8,0)) - game.player.beak()
	check.call(game.stash_raids.nearby_toddler() == toddler and game.training_text().contains("peck his ice cream"),"beside the toddler the strip names the peck key")
	check.call(game.peck_pause == false,"pop-ups off: the toddler lesson never freezes")
	game.stash_raids.peck_cooldown = 0
	game._peck()
	check.call(not toddler.food and toddler.dropped_pending and not toddler.drop_retrieve and game.lesson == BeachGame.TODDLER_LESSON,"pecking the toddler's ice cream drops it and the lesson waits")
	check.call(not toddler.dropped_item.is_empty() and game.training_target() == toddler.dropped_item.position and game.training_text().contains("Walk over"),"the dropped cone is ringed and the strip says to eat it")
	var middle: InputEventMouseButton = InputEventMouseButton.new()
	middle.button_index = MOUSE_BUTTON_MIDDLE
	check.call(InputMap.event_is_action(middle,"peck"),"the middle mouse button is a peck button")
	check.call(toddler.leaving and toddler.one_shot and toddler.facing == 1.0,"the pecked toddler runs away from the gull")
	game.camera_x = 160.0
	toddler.position.x = 160.0 + BeachGame.TODDLER_EXIT_MARGIN + 5.0
	var toddler_count: int = game.spawner.targets.size()
	game._toddler_lesson_tick(0.016)
	check.call(game.spawner.targets.size() == toddler_count - 1 and game.spawner.replacements.is_empty(),"he vanishes past the screen edge and no replacement walks in")
	check.call(game.training_target() == game.toddler_cone.position and game.training_text().contains("Walk over"),"the ring and strip follow the cone after he has gone")
	# A cone lost before it is eaten brings back a toddler, so the lesson can always be finished.
	game.toddler_cone.recovered = true
	game._toddler_lesson_tick(0.016)
	check.call(game.lesson_toddler() != null and game.lesson == BeachGame.TODDLER_LESSON,"a lost cone brings a fresh toddler")
	toddler = game.lesson_toddler()
	game.stash_raids.items.clear()
	game.player.state = BeachGull.State.GROUNDED
	game.player.facing = 1.0
	game.player.position += (toddler.food_position() - Vector2(8,0)) - game.player.beak()
	game.stash_raids.peck_cooldown = 0
	game._peck()
	# Walk onto the real cone: the toddler is gone, yet the pickup still counts.
	var cone: Dictionary = game.toddler_cone
	check.call(cone.owner == null and not game.stash_raids.items.is_empty(),"the cone is plain floor food once he has gone")
	cone.age = 5.0
	cone.grounded = true
	cone.velocity = Vector2.ZERO
	game.player.digestion.snacks.clear()
	game.player.digestion.rest = 0.0
	game.player.state = BeachGull.State.GROUNDED
	game.player.position += Vector2(cone.position) - game.player.beak()
	game.stash_raids.tick(0.1)
	check.call(game.stash_raids.items.is_empty(),"walking onto the cone eats it")
	check.call(game.lesson == BeachGame.BIN_LESSON and int(GameState.entry(1).get("training_step",0)) == BeachGame.BIN_LESSON,"eating the dropped cone leads straight to the bin lesson")
	game.stash_raids.items.clear()
	check.call(game.training_text().contains("bin"),"bin lesson explains the new action")
	game._scrap_collected(Vector2.ZERO,"crumbs")
	check.call(game.lesson == BeachGame.BIN_LESSON,"ordinary scraps cannot skip the bin lesson")
	game.player.state = BeachGull.State.GROUNDED
	var plain_bin: Dictionary = game.training_bin(false)
	game.player.position = Vector2(float(plain_bin.x),game.player.ground_y())
	game.player.position.x += game.player.position.x - game.player.beak().x + float(Config.tuning.world.peck_reach) + 10.0
	for attempt: int in range(2):
		game.training_miss_hint = 0.0
		game.stash_raids.peck_cooldown = 0
		game._peck()
		check.call(game.lesson == BeachGame.BIN_LESSON and game.training_text().contains("Closer"),"a peck just out of the bin's reach says land closer, try %d" % (attempt+1))
	game.training_miss_hint = 0.0
	game.player.position = Vector2(float(plain_bin.x),game.player.ground_y())
	for tap: int in range(int(Config.tuning.world.bin_pecks)):
		game.stash_raids.peck_cooldown = 0
		game._peck()
		check.call(game.lesson == (BeachGame.DIVE_LESSON if tap == int(Config.tuning.world.bin_pecks)-1 else BeachGame.BIN_LESSON),"bin lesson waits for the full peck sequence")
	check.call(not game.stash_raids.items.is_empty(),"bin lesson releases real scraps and litter")
	game.stash_raids.items.clear()
	game.player.state = BeachGull.State.STRIKE
	game.player.position.y = 120
	game.player.velocity.y = 50
	customer.last_theft_direct = false
	game._snatched(customer,game.player,false)
	game._training_tick(0.1)
	check.call(game.lesson == BeachGame.DIVE_LESSON and not game.training_clean_snatch,"loose food does not count as a clean swoop")
	customer.last_theft_direct = true
	game._snatched(customer,game.player,false)
	game._training_tick(0.1)
	check.call(game.lesson == BeachGame.DIVE_LESSON and game.training_clean_snatch,"direct snack theft still requires an upward escape")
	game.player.position.y = 80
	game.player.velocity.y = -25
	game._training_tick(0.1)
	check.call(game.lesson == BeachGame.MUG_LESSON,"clean swoop and safe pullup advance to the rival dummy")
	# A landed gull after a clean snatch still passes after a few seconds.
	game.lesson = BeachGame.DIVE_LESSON
	game.training_clean_snatch = true
	game.training_snatch_age = 0.0
	game.player.state = BeachGull.State.GROUNDED
	game._training_tick(3.9)
	check.call(game.lesson == BeachGame.DIVE_LESSON,"grounded gull does not pass the swoop lesson immediately")
	game._training_tick(0.2)
	check.call(game.lesson == BeachGame.MUG_LESSON,"clean snatch passes the swoop lesson after the fallback delay")
	# A knocked-off snack also passes and explains that a first miss is normal.
	game.lesson = BeachGame.DIVE_LESSON
	game.training_clean_snatch = false
	game.player.state = BeachGull.State.STRIKE
	game._food_knocked(customer,"ice_cream",Vector2(100,150),Vector2.ZERO)
	check.call(game.lesson == BeachGame.DIVE_LESSON,"knocked snack waits before the next card")
	game._training_tick(3.4)
	check.call(game.lesson == BeachGame.DIVE_LESSON,"next card is not early")
	game._training_tick(0.2)
	check.call(game.lesson == BeachGame.MUG_LESSON and game.training_miss_hint > 0.0 and game.training_text().contains("First miss"),"knocked snack passes the swoop lesson with a first-miss hint")
	game.overlay._process(0)
	check.call(game.overlay.trainer_portrait.visible and game.overlay.trainer_portrait.texture != null,"first-miss hint shows the trainer portrait")
	game.training_miss_hint = 0.0
	game.stash_raids.items.clear()
	check.call(game.lesson == BeachGame.MUG_LESSON,"the first dive leads straight to the rival dummy")
	game.stash_raids.items.clear()
	var dummy: RivalPilot = game.training_dummy()
	check.call(dummy != null and dummy.dummy and game.pilots.size() == 1 and dummy.dummy_food == BeachGame.DUMMY_FOOD,"the mug lesson spawns one dummy gull holding food")
	game.player.digestion.tick(30,false) # the earlier snacks are digested: a full belly shows the full-stomach line instead
	game.overlay._process(0)
	check.call(game.overlay.lesson_label.text.contains("LESSON %d/%d" % [BeachGame.MUG_LESSON+1,BeachGame.TRAINING_LESSONS]) and game.training_text().contains("through the dummy") and game.training_target() == dummy.gull.position,"mug lesson names the action and rings the dummy")
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
	check.call(game.lesson == BeachGame.MUG_LESSON,"flying through the dummy without diving does not count")
	# The mug window stays open while the dummy flies.
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
	# A save stopped at the mug lesson resumes with the dummy flying; old saves from the longer course land here too.
	# Save v3 (the toddler lesson): the old "resume at the mug" step 4 is now 5; other steps and finished courses are untouched.
	var saved_progress: Dictionary = GameState.progress.duplicate(true)
	GameState.progress = {"1": {"training_step": 4}}
	GameState.migrate_progress(2)
	check.call(int(GameState.entry(1).training_step) == BeachGame.MUG_LESSON,"a v2 save waiting at the mug resumes at the new mug lesson")
	GameState.progress = {"1": {"training_step": 3}}
	GameState.migrate_progress(2)
	check.call(int(GameState.entry(1).training_step) == 3,"other unfinished steps keep their number")
	GameState.progress = {"1": {"training_step": 4, "training_complete": true}}
	GameState.migrate_progress(2)
	check.call(int(GameState.entry(1).training_step) == 4,"a finished course is not remapped")
	GameState.progress = saved_progress
	for old_step: int in [BeachGame.MUG_LESSON,7,8]:
		GameState.progress = {"1":{"training_step":old_step}}
		host.main.start_level(1)
		game = host.main.game
		game.set_physics_process(false)
		check.call(game.lesson == BeachGame.MUG_LESSON and game.training_dummy() != null and game.training_dummy().dummy_food == BeachGame.DUMMY_FOOD,"a save at step %d resumes the mug lesson with the dummy carrying food" % old_step)
	# Missing the dummy repeats the tip; after three misses it hovers still.
	dummy = game.training_dummy()
	for miss: int in range(1,BeachGame.MUG_RESCUE_MISSES+1):
		game.training_miss_hint = 0.0
		game.player.state = BeachGull.State.STRIKE
		game._mug_miss_check()
		game.player.state = BeachGull.State.GLIDE
		game._mug_miss_check()
		check.call(game.lesson == BeachGame.MUG_LESSON and game.training_miss_hint > 0.0 and game.training_text().contains("dive straight through"),"missed dive %d repeats the mug tip" % miss)
		check.call((dummy.dummy_hold != Vector2.INF) == (miss == BeachGame.MUG_RESCUE_MISSES),"the dummy only hovers after %d misses" % BeachGame.MUG_RESCUE_MISSES)
	dummy.gull.state = BeachGull.State.GLIDE
	var hover: Vector2 = dummy.dummy_hold
	for frame: int in range(30):
		dummy.tick(1.0/60,[],{},game.wind)
	check.call(dummy.gull.position == hover,"the rescued dummy hovers in place")
	# With nothing to steal (a full belly behaves the same), a bump passes the lesson as well.
	dummy.dummy_food = ""
	dummy.carry_window = 0.0
	dummy.gull.state = BeachGull.State.GLIDE
	dummy.gull.invulnerable = 0.0
	game.player.state = BeachGull.State.STRIKE
	game.player.dive_speed = float(Config.tuning.dive.max_speed) # task 074: a real dive is fast enough to bump
	game.player.previous_beak = hover - Vector2(0,10)
	game.player.sweep_beak = hover + Vector2(0,10)
	game._mugging()
	check.call(game.lesson == BeachGame.TRAINING_LESSONS,"bumping the dummy also finishes the mug lesson")
	# Real levels repeat the bin and mug tips until the player has managed the move once.
	GameState.options.tips = []
	host.main.start_level(2)
	game = host.main.game
	game.set_physics_process(false)
	var lid_bin: Dictionary = game.training_bin(true)
	game.player.state = BeachGull.State.GROUNDED
	game.player.support = {}
	game.player.position = Vector2(float(lid_bin.x)-10.0,game.player.ground_y())
	var tip_count: Callable = func(text: String) -> int: return game.effects.texts.filter(func(entry: Dictionary) -> bool: return str(entry.text) == text).size()
	var low_tip: String = str(Config.trainer.tips.wheelie_low)
	game._peck()
	check.call(tip_count.call(low_tip) == 1,"pecking beside a wheelie bin shows the lid tip in a real level")
	game.elapsed += float(Config.tuning.juice.tip_time) + 0.1
	game._peck()
	check.call(tip_count.call(low_tip) == 2,"the lid tip repeats on the next failed peck")
	game.stash_raids.bin_opened.emit(str(lid_bin.type))
	game.elapsed += float(Config.tuning.juice.tip_time) + 0.1
	game._peck()
	check.call(tip_count.call(low_tip) == 2,"the lid tip stops once a wheelie bin has been opened")
	GameState.options.tips = []
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
