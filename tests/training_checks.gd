extends RefCounted

static func run(host: Node, check: Callable) -> void:
	GameState.progress = {}
	host.main.start_level(1)
	var game: BeachGame = host.main.game
	game.set_physics_process(false)
	game._physics_process(3.0)
	check.call(not game.running and game.intro > 0 and not game.input.enabled,"tutorial waits for explicit start without running in background")
	game.set_paused(true)
	game.set_paused(false)
	game.set_physics_process(false)
	check.call(not game.input.enabled,"resuming before confirmation keeps gameplay controls disabled")
	game.overlay.start_button.pressed.emit()
	check.call(game.running and game.input.enabled,"tutorial start button enables controls")
	check.call(game.training and not game.casual and game.lesson == 0 and game.player.state == BeachGull.State.GROUNDED,"first visit starts grounded training without a timer")
	check.call(not game._can_screech(),"Training Day never turns a held peck into a screech")
	check.call(game.training_text().contains("W/Up") or game.training_text().contains("FLAP"),"first lesson explains takeoff: "+game.training_text())
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
	for target: BeachTarget in game.spawner.targets:
		if target.kind == "kiosk_customer":
			customer = target
	check.call(is_instance_valid(customer),"training route provides a held snack")
	# Toddler lesson: peck his ice cream off, then walk over the cone.
	var toddler: BeachTarget = game.lesson_toddler()
	check.call(toddler != null and toddler.food and game.training_target() == toddler.food_position(),"the toddler holds an ice cream and the ring marks it")
	game.player.state = BeachGull.State.GROUNDED
	game.player.support = {}
	game.player.facing = 1.0
	game.player.position += (toddler.food_position() - Vector2(8,0)) - game.player.beak()
	check.call(game.stash_raids.nearby_toddler() == toddler and game.training_text().contains("peck his ice cream"),"beside the toddler the strip names the peck key")
	check.call(game.peck_pause == false,"pop-ups off: the toddler lesson never freezes")
	# Task 100: the lesson 3 ring turns green exactly when the real peck range test passes.
	check.call(game.training_ring_green(),"lesson 3 ring is green with the beak in peck range")
	var in_range_pos: Vector2 = game.player.position
	game.player.position.x -= float(Config.tuning.world.peck_reach) + 8.0
	check.call(not game.training_ring_green() and game.stash_raids.nearby_toddler() == null,"lesson 3 ring stays gold when the beak is out of peck range")
	game.player.position = in_range_pos
	check.call(game.training_ring_green(),"lesson 3 ring turns green again when the gull returns")
	game.lesson = BeachGame.BIN_LESSON
	check.call(not game.training_ring_green(),"the bin lesson ring stays gold away from the bin")
	game.lesson = BeachGame.TODDLER_LESSON
	var ring_lines: Array = []
	for variant: String in ["default","touch"]:
		ring_lines.append(Config.trainer.training.lessons[2].how[variant])
		ring_lines.append(Config.trainer.training.lessons[2].strip[variant])
	check.call(ring_lines.all(func(line: String) -> bool: return line.contains("ring")) and ring_lines.size() == 4,"lesson 3 card and strip text mention the ring in every variant")
	# A direct beak snatch of the cone also finishes the lesson (else the empty toddler soft-locks it); rewind afterwards.
	check.call(toddler.take(game.player) and game.lesson == BeachGame.BIN_LESSON,"snatching the toddler's cone directly advances the lesson")
	game.lesson = BeachGame.TODDLER_LESSON
	toddler.food = true
	toddler.food_sprite.show()
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
	check.call(not game.training_ring_green() and game.stash_raids.nearby_bin().is_empty(),"bin lesson ring stays gold out of the bin's reach")
	game.training_miss_hint = 0.0
	game.player.position = Vector2(float(plain_bin.x),game.player.ground_y())
	check.call(game.training_ring_green() and not game.stash_raids.nearby_bin().is_empty(),"bin lesson ring turns green once a peck would reach the bin")
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
	var results: Array[Dictionary] = []
	game.level_finished.connect(func(result: Dictionary) -> void: results.append(result))
	var feathers_before: int = GameState.feathers()
	game._training_tick(0.1)
	check.call(game.lesson == BeachGame.TRAINING_LESSONS and not game.running and results.size() == 1,"clean swoop and safe pullup finish training exactly once")
	check.call(GameState.feathers() == feathers_before + 1 and int(results[0].get("feathers_earned",0)) == 1,"first completion pays one Feather")
	check.call(not GameState.complete_training() and GameState.feathers() == feathers_before + 1,"completing the course again pays no Feather")
	var entry: Dictionary = GameState.entry(1)
	check.call(bool(entry.get("training_complete",false)) and int(entry.get("training_step",0)) == BeachGame.TRAINING_LESSONS and GameState.unlocked(2),"completion persists checkpoint and unlocks family beach: "+str(entry))
	check.call(not entry.has("best") and not entry.has("stars") and not entry.has("casual_time") and results[0].stars == 0,"training completion grants no stars or practice record")
	check.call(game.training_dummy() == null,"Training Day has no sparring dummy any more")
	# Dive lesson ring: green while the dive line is on the snack or the beak is in peck reach, gold otherwise.
	game.lesson = BeachGame.DIVE_LESSON
	game.player.state = BeachGull.State.GROUNDED
	check.call(not game.training_ring_green(),"dive lesson ring is gold while the gull is not diving")
	var snack: Vector2 = game.training_target()
	game.player.state = BeachGull.State.STRIKE
	game.player.position = snack - Vector2(0,60)
	game.player.direction = Vector2.DOWN
	check.call(game.aim_lines_up() and game.training_ring_green(),"dive lesson ring is green when the dive line is on the snack")
	game.player.direction = Vector2.RIGHT
	game.player.position = snack + Vector2(0,-200)
	check.call(not game.training_ring_green(),"dive lesson ring stays gold when the dive line misses the snack")
	game.player.state = BeachGull.State.GROUNDED
	# A landed gull after a clean snatch still passes after a few seconds.
	game.running = true
	game.lesson = BeachGame.DIVE_LESSON
	game.training_clean_snatch = true
	game.training_snatch_age = 0.0
	game.player.state = BeachGull.State.GROUNDED
	game._training_tick(3.9)
	check.call(game.lesson == BeachGame.DIVE_LESSON,"grounded gull does not pass the swoop lesson immediately")
	game._training_tick(0.2)
	check.call(game.lesson == BeachGame.TRAINING_LESSONS,"clean snatch passes the swoop lesson after the fallback delay")
	# A knocked-off snack also passes and explains that a first miss is normal.
	game.running = true
	game.lesson = BeachGame.DIVE_LESSON
	game.training_clean_snatch = false
	game.player.state = BeachGull.State.STRIKE
	game._food_knocked(customer,"ice_cream",Vector2(100,150),Vector2.ZERO)
	check.call(game.lesson == BeachGame.DIVE_LESSON,"knocked snack waits before the next card")
	game._training_tick(3.4)
	check.call(game.lesson == BeachGame.DIVE_LESSON,"next card is not early")
	game._training_tick(0.2)
	check.call(game.lesson == BeachGame.TRAINING_LESSONS and game.training_miss_hint > 0.0 and game.training_text().contains("First miss"),"knocked snack passes the swoop lesson with a first-miss hint")
	game.overlay._process(0)
	check.call(game.overlay.trainer_portrait.visible and game.overlay.trainer_portrait.texture != null,"first-miss hint shows the trainer portrait")
	game.training_miss_hint = 0.0
	game.stash_raids.items.clear()
	game.stash_raids.items.clear()
	game.player.digestion.tick(30,false)
	game.player.support = {}
	game.player.state = BeachGull.State.GLIDE
	customer.food = false
	customer.food_sprite.hide()
	customer.dropped_pending = true
	customer.dropped_item = {"recovered":false}
	game._training_tick(5.0)
	check.call(customer.food and not customer.dropped_pending and bool(customer.dropped_item.is_empty()),"training restores missed customer snack after delay")
	host.main.start_level(1)
	check.call(not host.main.game.training,"completed Training Day can be replayed as a regular run")
	host.main.start_level(1,true)
	check.call(host.main.game.training and host.main.game.lesson == 0,"train again explicitly restarts the first lesson")
	# Reproduce the player's normal route with an already-completed save.
	var completed_entry: Dictionary = GameState.entry(1)
	host.main._navigate("select")
	var training_button: Button = host.main.menus.find_child("Level01",true,false) as Button
	var status: Label = training_button.find_child("Status",true,false) as Label if training_button != null else null
	check.call(status != null and status.text.contains("REPLAY LESSONS"),"completed Training Day card clearly offers the lessons")
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
	# Save v3 (the toddler lesson): the old "resume at the mug" step 4 became 5. Save v4 moved the mug lesson to level 2,
	# so a save waiting there (or beyond) has finished Training Day; other steps and finished courses are untouched.
	var saved_progress: Dictionary = GameState.progress.duplicate(true)
	GameState.progress = {"1": {"training_step": 4}}
	GameState.migrate_progress(2)
	check.call(bool(GameState.entry(1).get("training_complete",false)) and int(GameState.entry(1).training_step) == BeachGame.TRAINING_LESSONS,"a v2 save waiting at the old mug counts as a finished Training Day")
	GameState.progress = {"1": {"training_step": 3}}
	GameState.migrate_progress(2)
	check.call(int(GameState.entry(1).training_step) == 3 and not GameState.entry(1).has("training_complete"),"other unfinished steps keep their number")
	GameState.progress = {"1": {"training_step": 4, "training_complete": true}}
	GameState.migrate_progress(2)
	check.call(int(GameState.entry(1).training_step) == 4,"a finished course is not remapped")
	for old_step: int in [5,7,8]:
		GameState.progress = {"1":{"training_step":old_step}}
		GameState.migrate_progress(3)
		check.call(bool(GameState.entry(1).get("training_complete",false)) and int(GameState.entry(1).training_step) == BeachGame.TRAINING_LESSONS and GameState.unlocked(2),"a v3 save at step %d is migrated to a finished Training Day" % old_step)
		GameState.progress = {"1":{"training_step":old_step}}
		GameState.migrate_progress(4)
		check.call(not GameState.entry(1).has("training_complete") and int(GameState.entry(1).training_step) == old_step,"a current-version save is not migrated again")
	GameState.progress = {"1":{"training_step":BeachGame.TRAINING_LESSONS-1}}
	host.main.start_level(1)
	game = host.main.game
	game.set_physics_process(false)
	check.call(game.training and game.lesson == BeachGame.DIVE_LESSON and game.training_dummy() == null,"a save at the dive lesson resumes there with no dummy")
	GameState.progress = saved_progress
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
	GameState.progress = {"2": {"screech_lesson_complete": true}}
	host.main.start_level(2)
	game = host.main.game
	game.set_physics_process(false)
	check.call(game.pilots.is_empty() and game.pending_rivals.is_empty() and not game.level.has("rivals_after_snatch"),"level 2 has no Gary in the timed run")
	game._swallowed({"id":"ice_cream"})
	check.call(game.pilots.is_empty() and game.entry_pilot == null,"level 2's first snack releases nobody")
	host.main.start_level(3)
	game = host.main.game
	game.set_physics_process(false)
	check.call(game.pending_rivals.is_empty() and game.pilots.size() == 1 and game.pilots[0].gull.rival_name == "Gary","level 3: Gary is on the beach from the start")
	game.dismiss_intro()
	check.call(game.entry_pilot == game.pilots[0] and game.entry_profile.entry == "fly_in","level 3: Gary makes his fly-in debut as the run starts")
	game._swallowed({"id":"ice_cream"})
	game._swallowed({"id":"ice_cream"})
	check.call(game.pilots.size() == 1,"later food does not spawn duplicate rivals")
	host.main.clear_game()
	GameState.progress = {}
