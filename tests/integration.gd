extends Node
var failures: int = 0
var checks: int = 0
var main: Node
var capture: bool = false

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func _ready() -> void:
	call_deferred("run")

func eat_pending(game: BeachGame) -> void:
	# Existing source/collision fixtures advance eating explicitly. Timing and capacity
	# are tested separately with the real, unadvanced queue.
	game.player.digestion.tick(30,false)

func settle() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

func snapshot(label: String) -> void:
	await settle()
	if not capture:
		return
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	img.save_png("res://test-output/"+label+".png")

func layout(node: Node) -> void:
	for child: Node in node.get_children():
		if child is Control and child.is_visible_in_tree():
			if child is Button or child is Label or child is HSlider:
				var rect: Rect2 = child.get_global_rect()
				check(rect.end.x <= 321 and rect.end.y <= 181 and rect.position.x >= -1 and rect.position.y >= -1,"UI bounds: "+child.name+" "+str(rect))
		layout(child)

func menu_font_grid(node: Node) -> void:
	for child: Node in node.get_children():
		if child is Label or child is Button:
			var font_size: int = child.get_theme_font_size("font_size")
			check(font_size >= BeachUI.FONT_NATIVE and font_size % BeachUI.FONT_NATIVE == 0,"menu font uses native 8 px grid: "+child.text+" ("+str(font_size)+")")
			var minimum: Vector2 = child.get_combined_minimum_size()
			check(minimum.x <= child.size.x + 0.1 and minimum.y <= child.size.y + 0.1,"menu text fits control: "+child.text+" "+str(minimum)+" in "+str(child.size))
		menu_font_grid(child)

func run() -> void:
	GameState.unlock_all = false
	capture = OS.get_cmdline_user_args().has("--capture")
	DirAccess.make_dir_recursive_absolute("res://test-output")
	GameState.save_path = "res://test-output/integration-save.json"
	GameState.progress = {}
	main = preload("res://scenes/main.tscn").instantiate()
	add_child(main)
	await snapshot("title")
	layout(main.menus)
	menu_font_grid(main.menus)
	main._navigate("arcade")
	await snapshot("level-select")
	layout(main.menus)
	menu_font_grid(main.menus)
	main._navigate("options")
	await snapshot("options")
	layout(main.menus)
	menu_font_grid(main.menus)
	check(not GameState.unlocked(2),"level 2 starts locked")
	main.start_level(1)
	main.game.set_physics_process(false)
	await snapshot("training-intro")
	layout(main.game.overlay)
	main.game.intro = 0
	main.game.running = true
	main.game.input.enabled = true
	main.game.overlay.queue_redraw()
	await snapshot("training-lesson-0")
	layout(main.game.overlay)
	check(not main.game.overlay.training_panel.get_rect().intersects(Rect2(232,44,84,29)),"training panel clears NEXT LEVEL footprint")
	check(main.game.overlay.lesson_label.get_global_rect().intersection(main.game.overlay.lesson_prompt.get_global_rect()).size == Vector2.ZERO,"training title and prompt have separate rows")
	for lesson_index: int in range(1,5):
		main.game.lesson = lesson_index
		main.game.overlay.queue_redraw()
		await snapshot("training-lesson-%d" % lesson_index)
		layout(main.game.overlay)
		check(not main.game.overlay.training_panel.get_rect().intersects(Rect2(232,44,84,29)),"training panel clears NEXT LEVEL footprint")
		check(main.game.overlay.lesson_label.get_global_rect().intersection(main.game.overlay.lesson_prompt.get_global_rect()).size == Vector2.ZERO,"training title and prompt do not overlap in lesson %d" % lesson_index)
	main.game.input.touch_visible = true
	await snapshot("training-touch")
	layout(main.game.overlay)
	check(not main.game.overlay.training_panel.get_rect().intersects(Rect2(232,44,84,29)),"training panel clears NEXT LEVEL footprint")
	main.game.lesson = 5
	main.game.finish()
	await snapshot("training-complete")
	layout(main.menus)
	menu_font_grid(main.menus)
	main.clear_game()
	await settle()
	preload("res://tests/training_checks.gd").run(self,Callable(self,"check"))
	# Legacy mechanics exercise an ordinary run after training has been completed.
	GameState.progress["1"] = {"training_step":5,"training_complete":true}
	await input_checks()
	await mechanics_checks()
	await peck_checks()
	await sunbather_pickup_checks()
	await family_food_foundation_checks()
	await family_trip_checks()
	await refinement_checks()
	await landing_aim_checks()
	await perch_checks()
	await stash_raid_checks()
	preload("res://tests/sunbather_reactions_checks.gd").run_checks(Callable(self,"check"))
	preload("res://tests/retro_environment_checks.gd").run_checks(Callable(self,"check"))
	preload("res://tests/retro_adult_art_checks.gd").run_checks(Callable(self,"check"))
	preload("res://tests/crowd_spacing_checks.gd").run_checks(self, Callable(self,"check"))
	await sunbather_reaction_flow_checks()
	await art_checks()
	await food_checks()
	await toddler_art_checks()
	await female_sunbather_art_checks()
	await mum_art_checks()
	await extended_beach_checks()
	await beachgoer_art_checks()
	await pier_diner_art_checks()
	preload("res://tests/digestion_checks.gd").run(Callable(self,"check"))
	preload("res://tests/flight_dynamics_checks.gd").run(self,Callable(self,"check"))
	await digestion_reaction_checks()
	preload("res://tests/level_generator_checks.gd").run(Callable(self,"check"))
	await generated_layout_checks()
	var model: BeachScore = BeachScore.new()
	check(model.snatch(10,false,false,false)==10,"first snatch")
	check(model.snatch(20,true,true,true)==66,"additive bonuses before combo")
	model.tick(3.1)
	check(model.tier==0,"combo expires")
	model.stunned()
	check(model.stuns==1 and model.window==0,"stun resets combo")
	var first_result: Dictionary = model.result(Config.levels[0],false,75)
	check(first_result.clean==0,"no clean bonus after stun")
	await result_board_checks()
	GameState.record(1,400,3)
	check(GameState.unlocked(2),"passing unlocks next level")
	GameState.record(1,100,1)
	check(GameState.entry(1).best==400 and GameState.entry(1).stars==3,"best score never regresses")
	GameState.record(1,0,0,45)
	GameState.record(1,0,0,60)
	GameState.progress = {}
	GameState.load_progress()
	check(GameState.entry(1).casual_time==45 and GameState.entry(1).best==400,"save round trip separates casual and arcade")
	check(Config.reload_data(),"JSON reload")
	for i: int in range(1,7):
		main.start_level(i)
		var game: BeachGame = main.game
		game.set_physics_process(false)
		await settle()
		check(game.spawner.targets.size()==Config.levels[i-1].spawns.size(),"level %d spawns" % i)
		check(game.pilots.size()+game.pending_rivals.size()==Config.levels[i-1].rivals.size(),"level %d rivals" % i)
		if not game.pilots.is_empty():
			check(game.pilots[0].gull.position.x <= 320 and game.pilots[0].gull.visible,"first rival appears in the opening view")
		check(int(game.level.time_limit) >= 90,"level %d allows a full beach route" % i)
		game.intro = 0
		game.running = true
		game.input.enabled = true
		game.input.gamepad = true
		# Held-snack dives use a kiosk customer; sunbathers are now bag-only.
		var customer: BeachTarget = game.spawner.create("kiosk_customer",80)
		game.player.position = Vector2(55,95)
		game.player.aim = customer.food_position()
		game.player.dive(game.wind.direction)
		check(game.player.state==BeachGull.State.WINDUP,"dive windup")
		for frame: int in range(70):
			if game.player.state == BeachGull.State.STRIKE and not game.player.peck_used and game.player.beak().distance_to(customer.food_position()) < 16:
				game.player.attempt_peck()
			game.player.tick(1.0/60,game.wind.direction,game.wind.strength)
			BeachCollisions.resolve(game.player,game.spawner.targets,game.beach.props)
			eat_pending(game)
			if game.score.items > 0 and game.player.state == BeachGull.State.STRIKE:
				game.player.pullup()
		check(game.score.items>=1,"level %d actual swept dive snatch" % i)
		check(game.player.state==BeachGull.State.GLIDE or game.player.state==BeachGull.State.GROUNDED,"dive recovers")
		game.player.stun()
		check(game.score.stuns==1,"stun signal recorded")
		for frame: int in range(130):
			game.player.tick(1.0/60,0,0)
		check(game.player.state!=BeachGull.State.STUNNED,"stun recovers")
		game.player.position = Vector2(160,80)
		game.player.aim = Vector2(230,146)
		if i==1:
			game.camera_x = 640
			game.camera.position.x = 640
			game.beach.camera_x = 640
			game.player.position.x = 570
			game.beach.queue_redraw()
			game.running = true
			game.intro_dismissed_elapsed = 1.0
			game.overlay.queue_redraw()
			await snapshot("game-family")
			game.input.touch_visible = true
			await snapshot("game-touch")
			layout(game.overlay)
			main._navigate("pause")
			await snapshot("pause")
			layout(main.menus)
			menu_font_grid(main.menus)
			check(not game.is_physics_processing(),"pause stops simulation")
			main._navigate("resume")
			game.set_physics_process(false)
		if i==6:
			game.camera_x = 800
			game.camera.position.x = 800
			game.beach.camera_x = 800
			game.player.position = Vector2(750,80)
			game.player.aim = Vector2(885,146)
			game.beach.queue_redraw()
			await snapshot("game-pier")
			await target_checks(game)
			var pilot: RivalPilot = game.pilots[0]
			check(pilot.gull.detailed_art and pilot.gull.sprite.sprite_frames.get_frame_texture(&"glide",0).get_size().x > 100,"rival uses full-size gull artwork")
			pilot.gull.position = Vector2(800,65)
			await snapshot("rival-polished")
			pilot.took_food(25)
			pilot.tick(0.1,game.spawner.targets,{},game.wind)
			check(pilot.gull.visible and pilot.gull.position.x > 700 and pilot.gull.position.x < 900,"rival remains visible during retreat")
			check(pilot.mug()==25 and pilot.gull.state==BeachGull.State.STUNNED,"rival mugging window")
			check(pilot.mug()==0,"mug cannot duplicate score")
		# Allow hit-stop and slow motion while bounding the simulation.
		for frame: int in range(int((float(game.level.time_limit) + 30) * 60)):
			if not game.running:
				break
			game._physics_process(1.0/60)
		check(not game.running,"level %d timer completes" % i)
		var result_board := main.menus.get_child(0) as ResultBoard
		check(result_board != null and not result_board.complete,"result tally starts before final score reveal")
		if i == 6:
			await snapshot("results-start")
			for frame: int in range(35):
				await get_tree().process_frame
			await snapshot("results-mid")
		result_board.finish_tally()
		await snapshot("results" if i==6 else "result-%d" % i)
		layout(main.menus)
		menu_font_grid(main.menus)
	main.casual = true
	main.start_level(1)
	main.game.set_physics_process(false)
	main.game.intro = 0
	main.game.running = true
	main.game.elapsed = 500
	main.game._physics_process(1.0/60)
	check(main.game.running,"casual has no time limit")
	main.game.score.items = 15
	main.game._physics_process(1.0/60)
	check(not main.game.running,"casual completes at 15 snatches")
	(main.menus.get_child(0) as ResultBoard).finish_tally()
	await snapshot("results-casual")
	layout(main.menus)
	main._navigate("restart")
	check(main.game.score.points==0 and main.game.elapsed==0,"restart resets state")
	main.clear_game()
	main.queue_free()
	# Let the audio server release playback before shutting down a fast test run.
	for audio_player: Node in Audio.get_children():
		if audio_player is AudioStreamPlayer:
			audio_player.stop()
	await settle()
	await get_tree().create_timer(0.1).timeout
	DirAccess.remove_absolute(GameState.save_path)
	print("INTEGRATION: %d checks, %d failures" % [checks,failures])
	get_tree().quit(0 if failures==0 else 1)

func result_board_checks() -> void:
	main.menus.show()
	var poor := {"score": 20, "base": 20, "clean": 0, "stars": 0, "items": 2, "stuns": 1, "bonuses": {"Risky": 1, "Upwind": 0, "Mugged": 0}, "elapsed": 90.0, "casual": false}
	main.menus.results(Config.levels[0], poor)
	var board := main.menus.get_child(0) as ResultBoard
	check(board != null and board.rows.size() == 6,"result board builds every tally line")
	for index: int in range(1, board.rows.size()):
		check(not board.rows[index - 1].get_rect().intersects(board.rows[index].get_rect()),"result tally rows do not overlap: "+board.rows[index - 1].text+" / "+board.rows[index].text)
	check(not board.complete and board.buttons.all(func(button: Button) -> bool: return button.disabled),"result actions wait for tally or skip")
	var fish_origin := board.fish.position
	for step: int in range(25):
		board._process(0.1)
	check(board.complete and board.fish.position == fish_origin,"fish waits at its perch through the full natural tally")
	board._process(0.4)
	check(board.fish.visible and board.fish.position == fish_origin,"failure reaction launches fish from its reset origin")
	board.fish._process(0.2)
	check(board.fish.position != fish_origin and board.fish.rotation > 0.0,"launched fish follows a falling, spinning trajectory")

	# A second board exercises the real input dispatch path for tally skipping.
	main.menus.results(Config.levels[0], poor)
	board = main.menus.get_child(0) as ResultBoard
	action("ui_accept")
	await settle()
	check(is_instance_valid(board) and board.complete,"confirm skips tally without activating a focused result action")
	check(board.complete and board.rows[5].text.ends_with("20"),"total resolves as final tally beat without changing score")
	check(board.stars_label.text == "---","poor result reveals zero stars")
	board._process(0.4)
	await get_tree().process_frame
	check(board.fish.visible,"poor result gull ejects fish skeleton")
	board.fish._process(0.45)
	await snapshot("results-poor-reaction")

	# Retry during the tally hides this board. Gameplay confirm must never wake it.
	main.menus.results(Config.levels[0], poor)
	var hidden_board := main.menus.get_child(0) as ResultBoard
	main.start_level(1)
	check(not hidden_board.is_processing_input() and not hidden_board.is_processing(),"leaving results disables hidden tally input and processing")
	action("ui_accept")
	await settle()
	check(not hidden_board.complete and hidden_board.reaction_player == null,"gameplay input cannot finish a hidden board or start reaction audio")
	main.clear_game()
	main.menus.show()

	var good := {"score": 620, "base": 550, "clean": 70, "stars": 3, "items": 12, "stuns": 0, "bonuses": {"Risky": 4, "Upwind": 3, "Mugged": 2}, "elapsed": 90.0, "casual": false}
	main.menus.results(Config.levels[0], good)
	board = main.menus.get_child(0) as ResultBoard
	board.finish_tally()
	check(board.rows[0].text.ends_with("550") and board.rows[1].text.ends_with("+70") and board.rows[5].text.ends_with("620"),"earned plus clean equals displayed total")
	check(board.stars_label.text == "***","three-star result resolves all stars")
	board._process(0.25)
	await get_tree().process_frame
	check(absf(board.gull.rotation) > 0.001,"good result gull performs vigorous screech reaction")
	await snapshot("results-three-star-reaction")

	var practice := good.duplicate(true)
	practice.casual = true
	practice.clean = 0
	practice.score = practice.base
	practice.stars = 0
	practice.elapsed = 73.5
	var old_level_one: Variant = GameState.progress.get("1", null)
	GameState.progress["1"] = {"casual_time": 61.25}
	main.menus.results(Config.levels[0], practice)
	board = main.menus.get_child(0) as ResultBoard
	board.finish_tally()
	check(board.title_label.text == "PRACTICE COMPLETE!" and board.stars_label.text.is_empty() and board.rows[5].text.ends_with(str(practice.score)),"practice completion uses positive result and exact total")
	check("TIME 73.5" in board.hint_label.text and "BEST 61.3" in board.hint_label.text,"practice result distinguishes run time from saved best time")
	var previous_save_error := GameState.save_error
	GameState.save_error = "Progress could not be saved."
	main.menus.results(Config.levels[0], poor)
	board = main.menus.get_child(0) as ResultBoard
	board.finish_tally()
	check(board.hint_label.text == GameState.save_error and board.hint_label.get_combined_minimum_size().x <= board.hint_label.size.x,"save error remains readable inside result sign")
	GameState.save_error = previous_save_error
	if old_level_one == null:
		GameState.progress.erase("1")
	else:
		GameState.progress["1"] = old_level_one

func action(name: String) -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = name
	event.pressed = true
	get_viewport().push_input(event)
	event = InputEventAction.new()
	event.action = name
	event.pressed = false
	get_viewport().push_input(event)

func click_at(point: Vector2) -> void:
	for pressed: bool in [true,false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.pressed = pressed
		get_viewport().push_input(event,true)

func mechanics_checks() -> void:
	main.start_level(1)
	var game: BeachGame = main.game
	game.set_physics_process(false)
	game.intro = 0
	game.running = true
	var gull: BeachGull = game.player
	gull.position = Vector2(300,60)
	gull.aim = gull.position
	var sand_before: int = game.effects.particles.size()
	for frame: int in range(240):
		gull.tick(1.0/60,0,0)
	check(gull.state == BeachGull.State.GROUNDED and is_equal_approx(gull.position.y,gull.ground_y()),"released flap descends and lands")
	check(game.effects.particles.size() == sand_before+5,"sand landing makes one restrained puff")
	var landed_x: float = gull.position.x
	gull.aim.x = landed_x + 100
	for frame: int in range(30):
		gull.tick(1.0/60,1,0.8)
	check(gull.position.x > landed_x + 10 and gull.position.y == gull.ground_y(),"ground movement right stays on sand")
	check(absf(gull.velocity.x) <= 28 and float(Config.tuning.flight.ground_speed) <= float(Config.tuning.flight.max_speed) * 0.25,"walking is much slower than flying")
	check(gull.sprite.visible and gull.sprite.animation == &"walk" and gull.walk_phase > 0,"grounded gull uses supplied walking frames")
	await snapshot("walking-feet")
	gull.aim.x = gull.position.x - 100
	for frame: int in range(60):
		gull.tick(1.0/60,0,0)
	check(gull.position.x < landed_x and gull.state == BeachGull.State.GROUNDED,"ground movement left")
	gull.aim.x = gull.position.x
	for frame: int in range(60):
		gull.tick(1.0/60,1,1)
	check(is_zero_approx(gull.velocity.x),"ground rest is not pushed by wind")
	gull.position.x = float(game.scraps.crumbs[0].x) - gull.facing * float(Config.tuning.dive.beak_offset)
	game.scraps.tick(0,gull)
	eat_pending(game)
	check(game.score.points == int(Config.foods.crumbs.points),"walking collects ground scrap points")
	game.scraps.tick(0,gull)
	eat_pending(game)
	check(game.score.points == int(Config.foods.crumbs.points),"scrap cannot be collected twice")
	check(game.score.items == 0,"scraps do not substitute for practice snatches")
	game.scraps.tick(float(Config.tuning.world.scrap_respawn),gull)
	eat_pending(game)
	game.scraps.tick(0,gull)
	eat_pending(game)
	check(game.score.points == 2 * int(Config.foods.crumbs.points),"ground scraps replenish after delay")
	await snapshot("ground-scraps")
	gull.climb = true
	gull.tick(1.0/60,0,0)
	check(gull.state == BeachGull.State.GLIDE and gull.position.y < gull.ground_y(),"flap takes off from ground")
	check(game.effects.particles.size() == sand_before+10,"sand takeoff makes one restrained puff")
	check(gull.sprite.visible,"takeoff restores flying sprite")
	gull.climb = false
	var impact_speeds: Array[float] = []
	for height: float in [135.0,25.0]:
		gull.state = BeachGull.State.GLIDE
		gull.position = Vector2(300,height)
		gull.velocity = Vector2.ZERO
		gull.cooldown = 0
		gull.aim = Vector2(300,220)
		game.score.points = 100
		gull.dive(0)
		var peak: float = 0
		for frame: int in range(180):
			gull.tick(1.0/60,0,0)
			peak = maxf(peak,gull.dive_speed)
			if gull.state in [BeachGull.State.GROUNDED,BeachGull.State.STUNNED]:
				break
		impact_speeds.append(peak)
		if height > 100:
			check(gull.state == BeachGull.State.GROUNDED and game.score.points == 100,"short slow dive lands without point loss")
		else:
			check(gull.state == BeachGull.State.STUNNED and game.score.points == 0,"fast beak-first ground crash clears current points")
			check(game.score.stuns == 1 and game.score.window == 0,"crash counted once and resets combo")
	check(impact_speeds[1] > impact_speeds[0] + 80,"higher dive progressively gains more speed")
	check(not GameState.entry(1).has("best") and not GameState.entry(1).has("stars"),"crash does not write saved records")
	for hz: int in [30,60,120]:
		gull.state = BeachGull.State.GLIDE
		gull.position = Vector2(300,25)
		gull.velocity = Vector2.ZERO
		gull.cooldown = 0
		gull.aim = Vector2(300,220)
		game.score.points = 100
		gull.dive(0)
		for frame: int in range(hz * 3):
			gull.tick(1.0/hz,0,0)
			if gull.state == BeachGull.State.STUNNED:
				break
		check(game.score.points == 0 and gull.position.y <= gull.ground_y(),"fast crash cannot tunnel below sand at %d Hz" % hz)
	gull.state = BeachGull.State.STRIKE
	gull.position = Vector2(300,gull.ground_y()-1)
	gull.direction = Vector2(1,0.2).normalized()
	gull.aim = gull.position + gull.direction * 100
	gull.dive_speed = 300
	game.score.points = 100
	gull.tick(1.0/30,0,0)
	check(gull.state == BeachGull.State.GROUNDED and game.score.points == 100,"fast shallow feet-first landing keeps score")
	check(absf(gull.velocity.x) <= float(Config.tuning.flight.ground_speed),"landing immediately caps speed to walking pace")
	gull.state = BeachGull.State.STRIKE
	gull.position = Vector2(300,120)
	gull.direction = Vector2(1,-1).normalized()
	gull.dive_speed = 220
	var previous_speed: float = gull.dive_speed
	var slowing: bool = true
	for frame: int in range(12):
		gull.aim = gull.position + Vector2(100,-100)
		gull.tick(1.0/60,0,0)
		slowing = slowing and gull.dive_speed < previous_speed
		previous_speed = gull.dive_speed
	check(slowing and gull.dive_speed < 160 and gull.velocity.y < 0,"upward swoop noticeably slows every step while still rising")
	gull.state = BeachGull.State.GLIDE
	gull.position = Vector2(300,30)
	gull.velocity = Vector2.ZERO
	gull.cooldown = 0
	gull.aim = Vector2(350,200)
	gull.dive(0)
	for frame: int in range(32):
		gull.tick(1.0/60,0,0)
	var down_y: float = gull.position.y
	var down_speed: float = gull.dive_speed
	check(down_speed > float(Config.tuning.dive.start_speed),"dive accelerates over time")
	for frame: int in range(40):
		gull.aim = gull.position + Vector2(100,-120)
		gull.tick(1.0/60,0,0)
	check(gull.position.y < down_y and gull.velocity.y < 0,"aiming upward turns dive into a rising swoop")
	check(gull.dive_speed < down_speed,"rising swoop spends speed")
	check(gull.state != BeachGull.State.STUNNED,"controlled swoop avoids crash")
	# Steer through a real target and retain the dive after collecting food.
	gull.state = BeachGull.State.GLIDE
	gull.position = Vector2(55,95)
	gull.velocity = Vector2.ZERO
	gull.cooldown = 0
	var held_target: BeachTarget = game.spawner.create("kiosk_customer",80)
	gull.aim = held_target.food_position()
	gull.dive(0)
	for frame: int in range(90):
		if gull.state == BeachGull.State.STRIKE and not gull.peck_used and gull.beak().distance_to(held_target.food_position()) < 16:
			gull.attempt_peck()
		gull.tick(1.0/60,0,0)
		BeachCollisions.resolve(gull,game.spawner.targets,game.beach.props)
		eat_pending(game)
		if game.score.items > 0:
			break
	check(game.score.items == 1 and gull.state == BeachGull.State.STRIKE,"food collection leaves swoop under player control")
	game.overlay.queue_redraw()
	await snapshot("controlled-dive")
	main.clear_game()
	await settle()

func peck_checks() -> void:
	main.start_level(1)
	var game: BeachGame = main.game
	game.set_physics_process(false)
	game.intro = 0
	game.running = true
	var gull: BeachGull = game.player
	var target: BeachTarget = game.spawner.create("kiosk_customer",80)
	target.food_id = "hotdog"
	target.food = true
	target.refresh_art()
	var at: Vector2 = target.food_position()
	gull.state = BeachGull.State.STRIKE
	gull.sweep_state = BeachGull.State.STRIKE
	gull.previous_beak = at-Vector2(15,0)
	gull.sweep_beak = at+Vector2(15,0)
	BeachCollisions.resolve(gull,[target],[])
	check(target.food and target.thefts == 0,"crossing held food without a peck does not steal")
	check(gull.attempt_peck() and not gull.attempt_peck(),"one peck attempt per dive")
	gull.peck_sweep_active = true
	BeachCollisions.resolve(gull,[target],[])
	check(not target.food and target.thefts == 1 and not gull.peck_sweep_active,"timed beak contact steals once")
	eat_pending(game)
	target.food = true
	target.food_sprite.show()
	target.defense = 0
	target.recover = 0
	gull.peck_used = false
	gull.peck_time = 0
	gull.peck_sweep_active = false
	at = target.food_position()
	gull.previous_beak = at+Vector2(-15,10)
	gull.sweep_beak = at+Vector2(15,10)
	BeachCollisions.resolve(gull,[target],[])
	check(target.food and game.stash_raids.items.is_empty(),"an unarmed near pass cannot knock food loose")
	check(gull.attempt_peck(),"next dive can arm another peck")
	gull.peck_sweep_active = true
	gull.peck_time = 0.0
	BeachCollisions.resolve(gull,[target],[])
	check(not target.food and target.dropped_pending and target.thefts == 1 and game.stash_raids.items.size() == 1,"glancing peck creates one owned loose snack without scoring")
	check(is_equal_approx(float(Config.foods.hotdog.reclaim_chance),0.5),"hotdog recovery is a 50 percent roll")
	target.drop_retrieve = false
	var item: Dictionary = game.stash_raids.items[0]
	item.grounded = true
	item.age = float(Config.tuning.world.stash_pickup_delay)
	item.velocity = Vector2.ZERO
	item.position = gull.beak()
	gull.state = BeachGull.State.GLIDE
	gull.previous_beak = item.position
	gull.sweep_beak = item.position
	game.stash_raids.tick(0.01)
	eat_pending(game)
	check(game.stash_raids.items.is_empty() and target.thefts == 2 and game.score.items == 2,"ground pickup claims the knocked snack exactly once")
	for food_id: String in ["ice_cream","crisps_bag"]:
		var owner: BeachTarget = game.spawner.create("kiosk_customer",130 if food_id == "ice_cream" else 170)
		owner.food_id = food_id
		owner.food = true
		owner.refresh_art()
		check(owner.knock_food(gull),"glancing hit drops "+food_id)
		check(owner.drop_retrieve == (food_id == "crisps_bag"),"ground recovery rule for "+food_id)
		var loose: Dictionary = game.stash_raids.items.back()
		loose.grounded = true
		loose.age = float(Config.tuning.world.stash_pickup_delay)
		loose.velocity = Vector2.ZERO
		loose.position = owner.position+Vector2(12,-3)
		for frame: int in range(100):
			owner.tick(1.0/60,[])
		check(owner.food == (food_id == "crisps_bag") and owner.dropped_pending == (food_id == "ice_cream"),"owner follows its recovery rule for "+food_id)
		game.stash_raids.tick(0.01)
	check(game.score.items == 2,"owner recovery and unclaimed ice cream award no extra score")
	main.clear_game()
	await settle()

func sunbather_pickup_checks() -> void:
	main.start_level(2)
	var game: BeachGame = main.game
	game.set_physics_process(false)
	game.intro = 0
	game.running = true
	var gull: BeachGull = game.player
	var bag_owner: BeachTarget = game.spawner.targets[0]
	var stock: int = bag_owner.stash_remaining
	check(not bag_owner.food and bag_owner.food_id.is_empty() and not bag_owner.food_sprite.visible,"sunbather has no exposed snack")
	check(stock == int(Config.tuning.world.sunbather_stash_size),"all sunbather snacks start inside picnic bag")
	bag_owner.tick(60,[])
	check(not bag_owner.food and bag_owner.stash_remaining == stock,"waiting cannot expose picnic bag food")
	check(not bag_owner.take(gull) and game.score.items == 0,"direct sunbather theft cannot bypass pecking")
	eat_pending(game)
	gull.land()
	gull.position.x = bag_owner.stash_position().x-10
	gull.previous_beak = gull.beak()
	gull.sweep_beak = gull.beak()
	BeachCollisions.resolve(gull,[bag_owner],[])
	eat_pending(game)
	check(game.score.items == 0,"walking to picnic bag alone awards no food")
	gull.position.x = bag_owner.stash_home_x+30
	game.overlay.queue_redraw()
	await snapshot("sunbather-picnic-bag")
	# Keep held-food sweep regression coverage on a target that still carries food.
	var sleeper: BeachTarget = game.spawner.create("kiosk_customer",300)
	# Ground contact with the same food position does not bypass other targets.
	var family: BeachTarget = game.spawner.create("picnic_family",300)
	family.food = true
	family.defense = 0
	gull.state = BeachGull.State.GROUNDED
	gull.position = Vector2(275,gull.ground_y())
	gull.velocity = Vector2.ZERO
	gull.aim = Vector2(330,gull.ground_y())
	for frame: int in range(45):
		gull.tick(1.0/60,0,0)
		BeachCollisions.resolve(gull,[family],[])
		eat_pending(game)
	check(family.food,"walking cannot steal from an awake defensive target")
	# A fast final dive frame crosses the snack and lands before collision resolve.
	sleeper.position.x = 300
	sleeper.patrol_home = 300
	sleeper.food_id = "crisps_box"
	sleeper.food = true
	sleeper.leaving = false
	sleeper.thefts = 0
	sleeper.refresh_art()
	game.score = BeachScore.new()
	gull.state = BeachGull.State.STRIKE
	gull.position = Vector2(sleeper.food_position().x-8,125)
	gull.direction = Vector2(0.4,1).normalized()
	gull.aim = gull.position+Vector2(35,55)
	gull.dive_speed = 150
	gull.climb = false
	gull.peck_used = false
	gull.attempt_peck()
	gull.tick(0.2,0,0)
	check(gull.state != BeachGull.State.STRIKE,"landing-frame fixture exits strike before collision resolution")
	BeachCollisions.resolve(gull,[sleeper],[])
	eat_pending(game)
	check(not sleeper.food and game.score.items == 1,"landing-frame dive still steals crossed held food")
	# A rising swoop remains eligible while its beak travels upward through food.
	sleeper.food_id = "crisps_bag"
	sleeper.food = true
	sleeper.leaving = false
	sleeper.thefts = 0
	sleeper.refresh_art()
	game.score = BeachScore.new()
	gull.state = BeachGull.State.STRIKE
	gull.position = sleeper.food_position()+Vector2(-30,12)
	gull.direction = Vector2(1,-0.35).normalized()
	gull.aim = Vector2(340,132)
	gull.dive_speed = 300
	gull.peck_used = false
	gull.attempt_peck()
	gull.tick(0.1,0,0)
	BeachCollisions.resolve(gull,[sleeper],[])
	eat_pending(game)
	check(not sleeper.food and game.score.items == 1,"rising swoop steals held food")
	# A beak-first crash keeps its score reset and cannot award the crossed food.
	sleeper.food = true
	game.score = BeachScore.new()
	game.score.points = 100
	gull.state = BeachGull.State.STRIKE
	gull.position = Vector2(295,125)
	gull.direction = Vector2(0.4,1).normalized()
	gull.aim = Vector2(330,180)
	gull.dive_speed = 300
	gull.invulnerable = 0
	gull.tick(0.2,0,0)
	check(gull.state == BeachGull.State.STUNNED and game.score.points == 0,"crash fixture applies penalty before collision resolution")
	BeachCollisions.resolve(gull,[sleeper],[])
	eat_pending(game)
	check(sleeper.food and game.score.items == 0 and game.score.points == 0,"crash frame cannot award crossed sunbather food")
	# A nearby pass outside the combined pickup ellipse remains a miss.
	sleeper.food = true
	game.score = BeachScore.new()
	gull.invulnerable = 0
	gull.state = BeachGull.State.STRIKE
	gull.position = Vector2(270,125)
	gull.direction = Vector2.RIGHT
	gull.aim = Vector2(350,125)
	gull.dive_speed = 180
	gull.tick(1.0/12,0,0)
	BeachCollisions.resolve(gull,[sleeper],[])
	eat_pending(game)
	check(sleeper.food and game.score.items == 0,"dive outside pickup ellipse misses")
	main.clear_game()
	await settle()

func add_test_sibling(game: BeachGame) -> void:
	# Exercise sibling support without adding crowds to the playable roster.
	for mum: BeachTarget in game.spawner.targets:
		if mum.kind == "picnic_family" and mum.family_id == "family_1":
			var child: BeachTarget = game.spawner.create("toddler",mum.position.x+44,{"family_id":"family_1"})
			child.family_parent = mum
			mum.family_children.append(child)
			return

func family_food_foundation_checks() -> void:
	var original_insist_chance: float = float(Config.tuning.world.family_ice_cream_chance)
	main.start_level(2)
	Config.tuning.world.family_ice_cream_chance = 0.0
	var game: BeachGame = main.game
	game.set_physics_process(false)
	game.intro = 0
	game.running = true
	var mum: BeachTarget
	var other_mum: BeachTarget
	var siblings: Array[BeachTarget] = []
	add_test_sibling(game)
	for target: BeachTarget in game.spawner.targets:
		if target.family_id == "family_1" and target.kind == "picnic_family":
			mum = target
		elif target.family_id == "family_2" and target.kind == "picnic_family":
			other_mum = target
		elif target.family_id == "family_1" and target.kind == "toddler":
			siblings.append(target)
	check(is_instance_valid(mum) and is_instance_valid(other_mum) and siblings.size() == 2,"level data links two siblings to an explicit mum")
	check(siblings[0].family_parent == mum and siblings[1].family_parent == mum,"siblings share their designated supply")
	check(mum.supply_crisps == 1 and mum.supply_cookies == 2 and mum.food_id == "crisps_bag","mum has two total crisp bags including held bag plus two-cookie reserve")
	# Stealing mum's held bag cannot make it available to a child again.
	mum.defense = 0
	check(mum.take(game.player),"mum's held crisp bag remains normally stealable")
	eat_pending(game)
	check(mum.supply_crisps == 1,"stealing held bag does not duplicate reserve stock")
	# Finish her reaction before this isolated stock/handover fixture relocates her.
	game.player.position.y = 70
	for frame: int in 300:
		mum.tick(1.0/60,[])
	mum.position.x = 500
	siblings[0].position.x = 100
	other_mum.alert = 0
	check(siblings[0].take(game.player),"distant toddler snack theft begins family replacement")
	eat_pending(game)
	check(mum.alert == 1 and other_mum.alert == 0,"cry alerts only the designated mum across distance")
	var start_x: float = siblings[0].position.x
	siblings[0].tick(1.0/60,[])
	check(siblings[0].seeking_parent and siblings[0].position.x != start_x,"robbed toddler immediately runs crying toward mum")
	for frame: int in 40:
		siblings[0].tick(1.0/60,[])
	check(siblings[0].sprite.animation == &"walk","seeking toddler uses walking feet after crying")
	for frame: int in range(1800):
		siblings[0].tick(1.0/60,[])
		if siblings[0].handover_timer > 0 and absf(siblings[0].position.x-mum.position.x) < 20:
			game.camera_x = mum.position.x
			game.camera.position.x = mum.position.x
			game.beach.camera_x = mum.position.x
			await snapshot("family-handover")
		if siblings[0].food:
			break
	check(siblings[0].position.x > start_x + 300,"distant toddler visibly approaches own mum")
	check(is_equal_approx(siblings[0].position.x,mum.position.x-float(Config.tuning.world.family_handover_distance)) and siblings[0].facing == 1 and mum.facing == -1,"handover uses a fixed approach point with family facing each other")
	check(siblings[0].food_id == "crisps_bag" and mum.supply_crisps == 0,"handover debits one shared crisp exactly once")
	for frame: int in range(60):
		siblings[0].tick(1.0/60,[])
	check(mum.supply_crisps == 0,"completed handover cannot debit twice")
	var settled_home: float = siblings[0].patrol_home
	for frame: int in range(240):
		siblings[0].tick(1.0/60,[])
	check(absf(siblings[0].position.x-settled_home) <= 36,"distant handover rebases a stable local patrol")
	check(siblings[1].take(game.player),"second sibling can request from same mum")
	eat_pending(game)
	for frame: int in range(1200):
		siblings[1].tick(1.0/60,[])
		if siblings[1].food:
			break
	check(siblings[1].food_id == "cookie" and mum.supply_cookies == 1,"siblings fall back to finite cookie reserve without duplication")
	# Consume final cookie, then verify empty stock delegates to the mum's trip.
	check(siblings[0].take(game.player),"first sibling can request final cookie")
	eat_pending(game)
	for frame: int in range(1200):
		siblings[0].tick(1.0/60,[])
		if siblings[0].food:
			break
	check(siblings[0].food_id == "cookie" and mum.supply_cookies == 0,"final cookie transfers once: "+str({"child_food":siblings[0].food,"child_id":siblings[0].food_id,"cookies":mum.supply_cookies,"trip":mum.family_trip}))
	check(siblings[0].take(game.player),"empty-stock request begins family shopping")
	eat_pending(game)
	check(mum.family_trip == BeachTarget.FamilyTrip.GATHER and not siblings[0].seeking_parent,"mum owns empty-stock trip while child joins family formation: "+str({"trip":mum.family_trip,"seeking":siblings[0].seeking_parent,"cookies":mum.supply_cookies}))
	Config.tuning.world.family_ice_cream_chance = original_insist_chance
	# Sunbather supply stays sealed until pecked; it is not a held-food source.
	var sleeper: BeachTarget = game.spawner.targets[0]
	var expected_total: int = int(Config.tuning.world.sunbather_stash_size)
	check(sleeper.kind == "sunbather" and sleeper.stash_remaining == expected_total,"sunbather keeps full finite picnic supply")
	sleeper.tick(float(Config.tuning.world.respawn_max)+1.0,[])
	check(not sleeper.food and sleeper.stash_remaining == expected_total,"sunbather never removes a snack automatically")
	main.clear_game()
	await settle()

func family_trip_checks() -> void:
	main.start_level(2)
	var game: BeachGame = main.game
	game.set_physics_process(false)
	game.intro = 0
	game.running = true
	var mum: BeachTarget
	var siblings: Array[BeachTarget] = []
	add_test_sibling(game)
	for target: BeachTarget in game.spawner.targets:
		if target.family_id == "family_1" and target.kind == "picnic_family":
			mum = target
		elif target.family_id == "family_1" and target.kind == "toddler":
			siblings.append(target)
	check(mum.family_kiosk_x >= 775 and siblings.size() == 2,"two-child mum receives far beach stand position and both siblings")
	# Preserve one sibling's existing food while the empty sibling triggers shopping.
	siblings[0].food = false
	siblings[0].food_sprite.hide()
	siblings[0].seeking_parent = false
	var preserved_food: String = siblings[1].food_id
	mum.food = false
	mum.food_sprite.hide()
	mum.supply_crisps = 0
	mum.supply_cookies = 0
	mum.request_family_help(siblings[0])
	check(mum.family_trip == BeachTarget.FamilyTrip.GATHER,"empty supply starts deterministic gather state")
	game.camera_x = clampf(mum.position.x,160,800)
	game.camera.position.x = game.camera_x
	game.beach.camera_x = game.camera_x
	game.beach.queue_redraw()
	await snapshot("family-gathering")
	var saw_stand: bool = false
	var saw_buy: bool = false
	for frame: int in range(2400):
		mum.tick(1.0/60,[])
		for child: BeachTarget in siblings:
			child.tick(1.0/60,[])
		if mum.family_trip == BeachTarget.FamilyTrip.BUY:
			saw_stand = is_equal_approx(mum.position.x,mum.family_kiosk_x)
			if not saw_buy:
				game.camera_x = mum.family_kiosk_x
				game.camera.position.x = mum.family_kiosk_x
				game.beach.camera_x = mum.family_kiosk_x
				game.beach.queue_redraw()
				await snapshot("family-kiosk")
			saw_buy = true
		if mum.family_trip == BeachTarget.FamilyTrip.RETURN:
			break
	check(saw_stand and saw_buy,"purchase happens only after whole family reaches stand")
	check(siblings[0].food and siblings[0].purchase_trip_serial == mum.family_trip_serial,"missing child visibly owns purchased food on return")
	check(siblings[1].food and siblings[1].food_id == preserved_food and siblings[1].purchase_trip_serial == -1,"existing sibling food is preserved and not tagged as purchase")
	check(mum.food and mum.food_id == "crisps_bag" and mum.supply_crisps == 1,"purchase refills exactly two mum crisps inclusive of visible held bag")
	check(mum.purchased_on_trip == 3,"purchase debit is one missing-child food plus two mum crisps")
	for frame: int in range(75):
		mum.tick(1.0/60,[])
		for child: BeachTarget in siblings:
			child.tick(1.0/60,[])
	check(mum.facing < 0 and mum.sprite.animation == &"carry_left" and mum.food_position().x < mum.position.x,"returning mum uses drawn left-facing carry art and keeps food in the travel hand")
	mum.facing = 1
	mum.update_art_pose(true)
	check(not mum.sprite.flip_h and mum.food_position().x > mum.position.x,"right-facing mum mirrors carried art and swept pickup together")
	mum.facing = -1
	mum.update_art_pose(true)
	# Travelling keeps the ordinary alert, shield and swat lifecycle active.
	mum.alert = 1.0
	mum.defense = 0.0
	mum.recover = 0.0
	game.player.state = BeachGull.State.GLIDE
	game.player.invulnerable = 0.0
	game.player.position = mum.food_position()+Vector2(0,2)
	mum.tick(0.01,[game.player])
	check(mum.family_trip == BeachTarget.FamilyTrip.RETURN and mum.reaction.mode == "warning" and game.player.state != BeachGull.State.STUNNED,"returning mum warns before swatting")
	game.camera_x = mum.position.x
	game.camera.position.x = mum.position.x
	game.beach.camera_x = mum.position.x
	game.beach.queue_redraw()
	await snapshot("family-return")
	# The visible carried food follows the normal take path and aborts this attempt.
	mum.defense = 0
	mum.recover = 0
	game.player.state = BeachGull.State.STRIKE
	game.player.sweep_state = BeachGull.State.STRIKE
	game.player.peck_sweep_active = true
	game.player.grounded_sweep = false
	game.player.previous_beak = mum.food_position()-Vector2(12,0)
	game.player.sweep_beak = mum.food_position()+Vector2(12,0)
	BeachCollisions.resolve(game.player,[mum],game.beach.props)
	eat_pending(game)
	check(not mum.food,"new visible mum purchase is reachable by normal swept collision during return")
	check(mum.family_trip == BeachTarget.FamilyTrip.RETREAT,"new-purchase theft changes return into retreat")
	for frame: int in range(75):
		mum.tick(1.0/60,[])
		for child: BeachTarget in siblings:
			child.tick(1.0/60,[])
	game.camera_x = clampf(mum.position.x,160,800)
	game.camera.position.x = game.camera_x
	game.beach.camera_x = game.camera_x
	game.beach.queue_redraw()
	await snapshot("family-retreat")
	for frame: int in range(4800):
		mum.tick(1.0/60,[])
		for child: BeachTarget in siblings:
			child.tick(1.0/60,[])
		if mum.family_trip == BeachTarget.FamilyTrip.COOLDOWN:
			break
	check(mum.family_trip == BeachTarget.FamilyTrip.COOLDOWN and mum.family_trip_timer > 1.0,"family waits away from stand after failed purchase")
	check(mum.supply_crisps == 1,"failed carry keeps finite reserve available without duplication")
	var wait_before: float = mum.family_trip_timer
	mum.tick(0.25,[])
	check(mum.family_trip == BeachTarget.FamilyTrip.COOLDOWN and mum.family_trip_timer < wait_before,"retreat cannot immediately loop back to stand")
	# A pre-existing sibling item is not purchase-tagged and cannot abort this attempt.
	check(siblings[1].take(game.player),"pre-existing sibling food remains stealable during cooldown")
	eat_pending(game)
	check(mum.family_trip == BeachTarget.FamilyTrip.COOLDOWN,"pre-existing food theft does not masquerade as failed purchase")
	main.clear_game()
	await settle()
	# A one-child family uses the same lifecycle without assuming a sibling exists.
	main.start_level(4)
	game = main.game
	game.set_physics_process(false)
	var one_mum: BeachTarget
	var one_child: BeachTarget
	for target: BeachTarget in game.spawner.targets:
		if target.family_id == "family_1" and target.kind == "picnic_family":
			one_mum = target
		elif target.family_id == "family_1" and target.kind == "toddler":
			one_child = target
	check(is_instance_valid(one_mum) and is_instance_valid(one_child) and one_mum.family_children.size() == 1,"one-child family links without orphaning")
	one_mum.food = false
	one_mum.supply_crisps = 0
	one_mum.supply_cookies = 0
	one_child.food = false
	one_mum.request_family_help(one_child)
	for frame: int in range(3600):
		one_mum.tick(1.0/60,[])
		one_child.tick(1.0/60,[])
		if one_mum.family_trip == BeachTarget.FamilyTrip.IDLE:
			break
	check(one_mum.family_trip == BeachTarget.FamilyTrip.IDLE and one_child.food,"one-child family completes stand trip and returns normally")
	check(one_child.purchase_trip_serial == -1 and one_mum.purchase_trip_serial == -1,"successful return clears purchase tags for later ordinary theft")
	main.clear_game()
	await settle()
	main.start_level(2)
	game = main.game
	game.set_physics_process(false)
	for target: BeachTarget in game.spawner.targets:
		if target.family_id == "family_1" and target.kind == "picnic_family":
			check(target.supply_crisps == 1 and target.supply_cookies == 2,"retry creates clean family stock")
		if target.kind == "sunbather":
			check(not target.food and not target.food_sprite.visible and target.stash_remaining == int(Config.tuning.world.sunbather_stash_size),"retry creates sealed sunbather stash with full stock")
	main.clear_game()
	await settle()

func input_checks() -> void:
	main.start_level(1)
	main.game.set_physics_process(false)
	await settle()
	await snapshot("flight-instructions")
	layout(main.game.overlay)
	check(not main.game.overlay.training_panel.get_rect().intersects(Rect2(232,44,84,29)),"training panel clears NEXT LEVEL footprint")
	main.game._physics_process(float(Config.tuning.world.intro_time)+1.0)
	check(not main.game.running and main.game.intro > 0 and main.game.elapsed == 0,"first level waits indefinitely for start button")
	action("dive")
	action("peck")
	click_at(Vector2(5,165))
	check(not main.game.running and not main.game.input.enabled,"gameplay buttons and clicks outside start button cannot dismiss first intro")
	var start_button: Button = main.game.overlay.start_button
	check(start_button.text == "LET'S GULL IT" and start_button.has_focus(),"start button is labelled and focused for keyboard and controller")
	click_at(start_button.get_global_rect().get_center())
	check(main.game.running and main.game.input.enabled and main.game.player.state == BeachGull.State.GLIDE,"start button click begins level without a dive")
	check(not main.game.overlay.intro_panel.visible,"start button hides opening menu immediately")
	action("dive")
	check(main.game.player.state == BeachGull.State.WINDUP,"dive input reaches player")
	action("pause")
	check(main.screen == "pause" and not main.game.input.enabled,"pause input disables controls")
	var paused_state: BeachGull.State = main.game.player.state
	action("dive")
	check(main.game.player.state == paused_state,"paused dive input ignored")
	action("pause")
	check(main.screen == "game" and main.game.is_physics_processing(),"pause input resumes simulation")
	action("restart")
	check(main.game.intro > 0 and main.game.score.points == 0,"restart input creates fresh run")
	main.game.set_physics_process(false)
	await settle()
	action("ui_accept")
	check(main.game.running and main.game.player.state == BeachGull.State.GLIDE,"keyboard and controller confirmation activate focused start button")
	var touch: InputEventScreenTouch = InputEventScreenTouch.new()
	touch.index = 0
	touch.position = Vector2(230,160)
	touch.pressed = true
	get_viewport().push_input(touch, true)
	check(main.game.input.touch_climb,"touch climb press")
	touch = InputEventScreenTouch.new()
	touch.index = 0
	touch.position = Vector2(230,160)
	touch.pressed = false
	get_viewport().push_input(touch, true)
	check(not main.game.input.touch_climb,"touch climb release")
	main._navigate("restart")
	main.game.set_physics_process(false)
	await settle()
	var start_point: Vector2 = main.game.overlay.start_button.get_global_rect().get_center()
	for pressed: bool in [true,false]:
		var start_touch: InputEventScreenTouch = InputEventScreenTouch.new()
		start_touch.index = 0
		start_touch.position = start_point
		start_touch.pressed = pressed
		get_viewport().push_input(start_touch,true)
	check(main.game.running and not main.game.input.touch_climb and not main.game.input.touch_dive and not main.game.input.touch_peck,"touch start activates button without carrying gameplay input")
	main.clear_game()
	await settle()

func target_checks(game: BeachGame) -> void:
	eat_pending(game)
	var target: BeachTarget = game.spawner.create("kiosk_customer",300)
	target.food = true
	target.thefts = 0
	target.take(game.player)
	eat_pending(game)
	for frame: int in 1200:
		target.tick(1.0/60,[])
	check(target.food,"unrelated NPC food still replenishes")
	target.take(game.player)
	eat_pending(game)
	check(not target.leaving and target.reaction.mode == "chase","repeat theft starts a chase rather than permanent departure")
	var family: BeachTarget = game.spawner.create("picnic_family",430,{"family_id":"test_family"})
	family.alert = 1
	family.tick(0.01,game.gulls)
	check(family.defense>0 and not family.take(game.player),"alert parent shields food")
	eat_pending(game)
	var toddler: BeachTarget = game.spawner.create("toddler",431,{"family_id":"test_family"})
	toddler.family_parent = family
	family.family_children.append(toddler)
	family.alert = 0
	toddler.take(game.player)
	eat_pending(game)
	check(family.alert==1,"cry alerts designated parent")
	game.player.state = BeachGull.State.GLIDE
	game.player.invulnerable = 0
	game.player.position = family.food_position()
	family.tick(0.01,game.gulls)
	family.tick(0.4,game.gulls)
	check(game.player.state==BeachGull.State.STUNNED,"parent swats after warning")
	var vendor: BeachTarget = game.spawner.create("seafood_vendor",890)
	vendor.alert = 1
	game.player.state = BeachGull.State.GLIDE
	game.player.invulnerable = 0
	game.player.position = vendor.food_position()
	vendor.tick(0.01,game.gulls)
	check(vendor.reaction.mode == "warning" and game.player.state!=BeachGull.State.STUNNED,"broom telegraph precedes damage")
	vendor.tick(0.7,game.gulls)
	vendor.tick(0.01,game.gulls)
	check(game.player.state==BeachGull.State.STUNNED,"broom hits after telegraph")
	var wind: BeachWind = BeachWind.new()
	wind.setup(Config.levels[5])
	wind.countdown = 1.01
	wind.tick(0.02)
	check(wind.warned,"gust warns one second ahead")
	var before: int = wind.direction
	wind.tick(1.0)
	check(wind.direction==-before,"level 6 gust flips direction")
	wind.tick(0.5)
	check(wind.strength>wind.base,"gust ramps strength")




func physics_gull(at: Vector2 = Vector2(300,100), speed: Vector2 = Vector2.ZERO) -> BeachGull:
	var gull: BeachGull = BeachGull.new()
	add_child(gull)
	gull.position = at
	gull.velocity = speed
	gull.aim = at + Vector2(100,0)
	return gull

func stash_raid_checks() -> void:
	for definition: Dictionary in Config.levels:
		var world: Dictionary = definition.get("world",{})
		var promenade_start: float = float(world.get("promenade_start",Config.tuning.world.promenade_start))
		var pier_start: float = float(world.get("pier_start",Config.tuning.world.pier_start))
		for spawn: Dictionary in definition.spawns:
			if spawn.type == "sunbather":
				check(float(spawn.x) < promenade_start,"sunbather level placement remains on sand before promenade")
		for prop: Dictionary in definition.props:
			if prop.type == "bin":
				check(float(prop.x) < pier_start,"peckable bin remains before the pier")
	main.start_level(2)
	var game: BeachGame = main.game
	game.set_physics_process(false)
	game.intro = 0
	game.running = true
	var owner: BeachTarget = game.spawner.targets[0]
	var raids: BeachStashRaids = game.stash_raids
	var gull: BeachGull = game.player
	var stock: int = owner.stash_remaining
	check(owner.sprite.sprite_frames.get_frame_count(&"rise") == 7 and owner.sprite.sprite_frames.get_frame_count(&"run") == 7,"supplied sunbather sheet has seven rise and run frames")
	var has_blue_sunbather: bool = false
	for target: BeachTarget in game.spawner.targets:
		if target.kind == "sunbather" and target.sunbather_blue:
			has_blue_sunbather = true
	check(has_blue_sunbather,"sunbathers use supplied blue colour variation")
	await snapshot("sunbather-new-rest")
	gull.land()
	gull.position.x = owner.stash_position().x-10
	gull.facing = 1
	gull.previous_beak = gull.beak()
	gull.sweep_beak = gull.beak()
	check(raids.nearby_stash() == owner,"grounded gull finds nearby finite stash")
	check(raids.peck(),"first tap pecks stash")
	check(owner.bag_squish_time > 0.0 and Audio.streams.has("bag_thump"),"bag peck starts squish and fabric thump")
	var first_bag_strength: float = owner.bag_squish_strength
	var first_bag_pitch: float = (Audio.get_children().back() as AudioStreamPlayer).pitch_scale
	var first_wake: float = raids.raids[owner].wake
	check(not raids.peck(),"peck recovery prevents instant repeat")
	raids.tick(float(Config.tuning.world.peck_cooldown))
	eat_pending(game)
	check(raids.items.is_empty(),"single peck does not eject food")
	var repeat_event: InputEventKey = InputEventKey.new()
	repeat_event.physical_keycode = KEY_E
	repeat_event.pressed = true
	repeat_event.echo = true
	game._unhandled_input(repeat_event)
	check(raids.raids[owner].pecks == 1,"held keyboard repeat does not peck again")
	check(raids.peck(),"second tap pecks stash")
	check(owner.bag_squish_strength > first_bag_strength and (Audio.get_children().back() as AudioStreamPlayer).pitch_scale > first_bag_pitch,"bag squish and pitch build toward release")
	raids.tick(float(Config.tuning.world.peck_cooldown))
	eat_pending(game)
	check(raids.peck() and raids.items.size() == 2,"third tap ejects finite burst")
	check(game.effects.particles.size() >= 6 and Audio.streams.has("stash_release"),"bag release has a small crumb burst and sound")
	check(owner.bag_release_bounce and Audio.streams.has("release_accent"),"final bag hit adds rebound and distinct accent")
	check(owner.stash_remaining+raids.items.size() == stock,"scattered food debited exactly once from stash")
	check(raids.items[0].velocity.x < 0 and raids.items[1].velocity.x > 0,"snacks scatter in different directions")
	var scattered_start: Vector2 = raids.items[0].position
	var items_before_grace: int = game.score.items
	for frame: int in 15:
		raids.tick(1.0/60)
		eat_pending(game)
		game.effects.tick(1.0/60)
	check(raids.items.size() == 2 and game.score.items == items_before_grace,"new raid snacks cannot be collected during their first 0.25 seconds")
	check(raids.items[0].position != scattered_start and raids.items[0].velocity.y > -95,"protected raid snacks still fly and fall normally")
	game.overlay.queue_redraw()
	await snapshot("stash-scatter")
	check(raids.raids[owner].wake < first_wake,"repeated pecks make sunbather respond sooner")
	gull.position = Vector2(400,60)
	gull.state = BeachGull.State.GLIDE
	gull.previous_beak = gull.beak()
	gull.sweep_beak = gull.beak()
	check(not raids.peck(),"airborne gull cannot peck a bag")
	raids.raids[owner].wake = 0.3
	raids.tick(0)
	eat_pending(game)
	check(owner.sprite.animation == &"rise" and owner.sprite.frame > 0,"wake countdown drives getting-up frames")
	game.effects.texts.clear()
	game.effects.queue_redraw()
	await snapshot("sunbather-new-wake")
	raids.tick(0.35)
	eat_pending(game)
	check(owner.sprite.visible and owner.stash_standing and owner.sprite.animation in [&"run",&"run_left",&"rise",&"pickup"],"awakened owner runs, waits upright or bends according to food position")
	await snapshot("sunbather-new-run")
	var saw_standing: bool = false
	for frame: int in 600:
		raids.tick(1.0/60)
		eat_pending(game)
		game.effects.tick(1.0/60)
		saw_standing = saw_standing or owner.stash_standing
		if frame == 150:
			await snapshot("stash-retrieval")
	check(saw_standing and raids.items.is_empty() and owner.stash_remaining == stock,"standing owner retrieves grounded food back into finite stash")
	check(not owner.stash_active and not owner.stash_standing and owner.sprite.visible and is_equal_approx(owner.position.x,owner.stash_home_x),"owner returns to fixed bag and resting pose")
	check(game.score.items == 0,"owner recovery awards player no points or practice credit")
	# Awake retrieval is brisk, while food and the owner stay within the sand boundary.
	gull.position = Vector2(400,60)
	gull.state = BeachGull.State.GLIDE
	owner.position.x = 100
	owner.stash_active = true
	raids.raids[owner] = {"pecks":0,"wake":0.0,"awake":true,"swat":0.0}
	raids.items.append({"owner":owner,"food_id":"cookie","position":Vector2(140,156.5),"velocity":Vector2.ZERO,"grounded":true,"age":float(Config.tuning.world.stash_pickup_delay)})
	raids.tick(0.5)
	eat_pending(game)
	check(is_equal_approx(owner.position.x,120),"awakened sunbather retrieves snacks at faster 40 pixel speed")
	check(owner.position.x < 320 and float(raids.items[0].position.x) <= float(Config.tuning.world.beach_scatter_max_x),"sunbather retrieval and scattered snack stay on beach strip")
	raids.items.clear()
	raids.raids.erase(owner)
	owner.position.x = owner.stash_home_x
	owner.stash_active = false
	owner.stash_standing = false
	owner.sprite.visible = true
	# An already-awake owner must keep tracking protected food instead of ending the raid.
	gull.position = Vector2(400,60)
	gull.state = BeachGull.State.GLIDE
	gull.previous_beak = gull.beak()
	gull.sweep_beak = gull.beak()
	owner.stash_active = true
	raids.raids[owner] = {"pecks":0,"wake":0.0,"awake":true,"swat":0.0}
	raids.items.append({"owner":owner,"food_id":"cookie","position":Vector2(owner.stash_home_x,156.5),"velocity":Vector2.ZERO,"grounded":true,"age":0.0})
	raids.tick(0.1)
	eat_pending(game)
	check(raids.raids.has(owner) and raids.items.size() == 1 and is_equal_approx(float(raids.items[0].age),0.1),"awake owner keeps protected snack pending without retrieving it")
	raids.items.clear()
	raids.raids.erase(owner)
	owner.stash_active = false
	owner.stash_standing = false
	owner.sprite.visible = true
	# Pickup grace applies independently in air and on the ground, including a partial threshold frame.
	gull.state = BeachGull.State.GLIDE
	gull.position = Vector2(160,80)
	gull.previous_beak = gull.beak()
	gull.sweep_beak = gull.beak()
	raids.items.append({"owner":owner,"food_id":"cookie","position":gull.beak(),"velocity":Vector2.ZERO,"grounded":false,"age":0.299})
	var grace_score: int = game.score.items
	raids.tick(0.001)
	eat_pending(game)
	check(raids.items.is_empty() and game.score.items == grace_score+1,"airborne raid snack becomes collectible at exactly 0.3 seconds")
	raids.items.append({"owner":owner,"food_id":"cookie","position":gull.beak(),"velocity":Vector2(1000,0),"grounded":false,"age":0.29})
	raids.tick(0.02)
	eat_pending(game)
	check(raids.items.size() == 1 and game.score.items == grace_score+1,"threshold-crossing sweep cannot collect over the protected part of a large frame")
	raids.items.clear()
	gull.land()
	gull.position.x = 160
	gull.previous_beak = gull.beak()
	gull.sweep_beak = gull.beak()
	raids.items.append({"owner":owner,"food_id":"cookie","position":Vector2(gull.beak().x,156.5),"velocity":Vector2.ZERO,"grounded":true,"age":0.0})
	raids.tick(0.299)
	eat_pending(game)
	check(raids.items.size() == 1 and game.score.items == grace_score+1,"grounded raid snack remains protected before 0.3 seconds")
	raids.tick(0.001)
	eat_pending(game)
	check(raids.items.is_empty() and game.score.items == grace_score+2,"grounded raid snack becomes collectible at 0.3 seconds")
	gull.state = BeachGull.State.GLIDE
	gull.position = Vector2(160,80)
	gull.previous_beak = gull.beak()
	gull.sweep_beak = gull.beak()
	raids.items.append({"owner":owner,"food_id":"cookie","position":gull.beak(),"velocity":Vector2.ZERO,"grounded":false,"age":0.3})
	raids.items.append({"owner":owner,"food_id":"cookie","position":gull.beak(),"velocity":Vector2.ZERO,"grounded":false,"age":0.0})
	raids.tick(0)
	eat_pending(game)
	check(raids.items.size() == 1 and is_zero_approx(float(raids.items[0].age)) and game.score.items == grace_score+3,"older raid snack is collectible while a new snack remains protected")
	raids.items.clear()
	# Catch one finite snack in the air, then pick up another on the ground.
	for grounded: bool in [false,true,true]:
		owner.stash_remaining -= 1
		gull.position = Vector2(160,80) if not grounded else Vector2(160,gull.ground_y())
		gull.state = BeachGull.State.GLIDE if not grounded else BeachGull.State.GROUNDED
		gull.previous_beak = gull.beak()
		gull.sweep_beak = gull.beak()
		raids.items.append({"owner":owner,"food_id":"cookie","position":gull.beak() if not grounded else Vector2(gull.beak().x,156.5),"velocity":Vector2.ZERO,"grounded":grounded,"age":float(Config.tuning.world.stash_pickup_delay)})
		var before: int = game.score.items
		raids.tick(0)
		eat_pending(game)
		check(raids.items.is_empty() and game.score.items == before+1,"raid snack collected once in air or on ground")
		raids.tick(0)
		eat_pending(game)
		check(game.score.items == before+1,"claimed raid food cannot be scored twice")
	check(owner.stash_remaining == 0,"gull collections permanently deplete stash")
	gull.position.x = owner.stash_position().x-10
	gull.land()
	raids.peck_cooldown = 0
	var empty_item_count: int = raids.items.size()
	check(raids.peck() and raids.items.size() == empty_item_count and owner.stash_remaining == 0,"empty bag responds without generating food")
	check(not raids.peck(),"empty bag tap keeps the normal peck cooldown")
	var empty_cue_count: int = 0
	for cue: Dictionary in game.effects.texts:
		if cue.text == "EMPTY":
			empty_cue_count += 1
	check(empty_cue_count == 1 and Audio.streams.has("empty_tap"),"empty bag shows one fading cue and hollow tap")
	raids.tick(float(Config.tuning.world.peck_cooldown))
	check(raids.peck(),"empty bag accepts another deliberate tap")
	empty_cue_count = 0
	for cue: Dictionary in game.effects.texts:
		if cue.text == "EMPTY":
			empty_cue_count += 1
	check(empty_cue_count == 1,"repeated empty taps refresh one cue instead of stacking")
	game.effects.tick(0.52)
	var fading_empty: bool = false
	for cue: Dictionary in game.effects.texts:
		if cue.text == "EMPTY":
			fading_empty = float(cue.life) > 0.0 and float(cue.life) < float(cue.fade_time)
	check(fading_empty,"EMPTY cue holds, then enters its short fade")
	game.effects.tick(0.21)
	empty_cue_count = 0
	for cue: Dictionary in game.effects.texts:
		if cue.text == "EMPTY":
			empty_cue_count += 1
	check(empty_cue_count == 0,"EMPTY cue disappears after fading")
	var text_count_before_disabled: int = game.effects.texts.size()
	Config.tuning.juice.floating_text = false
	game.effects.empty_message(owner.stash_position()-Vector2(0,10))
	check(game.effects.texts.size() == text_count_before_disabled,"EMPTY cue respects floating-text option")
	Config.tuning.juice.floating_text = true
	var available_bin: Dictionary = raids.bins[0]
	var original_bin_x: float = float(available_bin.x)
	available_bin.x = gull.beak().x
	raids.peck_cooldown = 0
	check(raids.peck() and int(available_bin.pecks) == 1,"stocked bin takes priority over nearby empty bag")
	available_bin.x = original_bin_x
	available_bin.pecks = 0
	owner.reaction = AdultReaction.new()
	# A newly disturbed owner can catch and swat a grounded gull.
	owner.stash_remaining = 1
	owner.alert = 1
	raids.peck_cooldown = 0
	check(raids.peck(),"alert owner stash still accepts deliberate peck")
	gull.position.x = owner.position.x
	gull.invulnerable = 0
	raids.tick(float(Config.tuning.world.stash_wake_min)+0.1)
	eat_pending(game)
	check(gull.state != BeachGull.State.STUNNED,"sunbather warns before swat can hit")
	for frame: int in 45:
		raids.tick(1.0/60)
		eat_pending(game)
		if gull.state == BeachGull.State.STUNNED:
			break
	check(gull.state == BeachGull.State.STUNNED,"awakened owner swats nearby raider")
	# Beach bins scatter a finite crumb-heavy mix plus rubbish after deliberate taps.
	raids.items.clear()
	raids.raids.clear()
	owner.reaction = AdultReaction.new()
	owner.stash_active = false
	owner.stash_standing = false
	owner.sprite.visible = true
	var bin: Dictionary = raids.bins[0]
	var bin_stock: int = int(bin.remaining)
	gull.land()
	gull.position.x = float(bin.x)-10
	gull.facing = 1
	gull.previous_beak = gull.beak()
	gull.sweep_beak = gull.beak()
	check(raids.nearby_bin() == bin,"grounded gull finds beach trash bin")
	var first_bin_strength: float = 0.0
	var first_bin_pitch: float = 0.0
	for tap_index: int in int(Config.tuning.world.bin_pecks):
		check(raids.peck(),"separate tap pecks trash bin")
		if tap_index == 0:
			check(game.beach.bin_wobble.max() > 0.0 and Audio.streams.has("bin_rattle"),"bin peck starts foot-pivot wobble and rattle")
			first_bin_strength = game.beach.bin_wobble_strength.max()
			first_bin_pitch = (Audio.get_children().back() as AudioStreamPlayer).pitch_scale
		if tap_index < int(Config.tuning.world.bin_pecks)-1:
			raids.tick(float(Config.tuning.world.peck_cooldown))
			eat_pending(game)
	check(raids.items.size() == int(Config.tuning.world.bin_burst) and int(bin.remaining) == bin_stock-int(Config.tuning.world.bin_burst),"four bin pecks eject one finite three-object burst")
	check(game.beach.bin_wobble_strength.max() > first_bin_strength and game.beach.bin_release_bounce.has(true),"bin wobble grows and final hit bounces")
	check((Audio.get_children().back() as AudioStreamPlayer).stream == Audio.streams.release_accent and first_bin_pitch < 1.0,"bin taps rise in pitch before release accent")
	var crumb_count: int = 0
	var rubbish_count: int = 0
	for item: Dictionary in raids.items:
		if bool(item.get("garbage",false)):
			rubbish_count += 1
		else:
			crumb_count += 1
	check(crumb_count > rubbish_count and rubbish_count > 0,"bin burst is mostly crumbs with visible non-food rubbish")
	var protected_count: int = raids.items.size()
	raids.tick(0.25)
	eat_pending(game)
	check(raids.items.size() == protected_count,"bin crumbs retain 0.3 second pickup protection while scattering")
	game.effects.texts.clear()
	game.effects.particles.clear()
	game.effects.queue_redraw()
	game.camera_x = 280
	game.camera.position.x = 280
	game.beach.camera_x = 280
	game.beach.queue_redraw()
	game.overlay.queue_redraw()
	await snapshot("bin-peck-scatter")
	gull.position.x = 200
	raids.tick(0.05)
	eat_pending(game)
	var garbage_index: int = -1
	var crumb_index: int = -1
	for i: int in raids.items.size():
		if bool(raids.items[i].get("garbage",false)):
			garbage_index = i
		elif crumb_index < 0:
			crumb_index = i
	check(garbage_index >= 0 and crumb_index >= 0,"bin creates both collectible crumbs and inert litter")
	raids.items[garbage_index].position = Vector2(gull.beak().x,157.5)
	raids.items[garbage_index].grounded = true
	raids.items[garbage_index].velocity = Vector2.ZERO
	var before_garbage: int = raids.items.size()
	var before_bin_points: int = game.score.points
	var before_bin_snatches: int = game.score.items
	raids.tick(0)
	eat_pending(game)
	check(raids.items.size() == before_garbage and game.score.points == before_bin_points,"gull cannot eat or score visible bin rubbish")
	# Find the crumb again because reverse iteration/removal can change indices.
	for i: int in raids.items.size():
		if not bool(raids.items[i].get("garbage",false)):
			raids.items[i].position = Vector2(gull.beak().x,157.5)
			raids.items[i].grounded = true
			raids.items[i].velocity = Vector2.ZERO
			break
	raids.tick(0)
	eat_pending(game)
	check(game.score.points == before_bin_points+int(Config.foods.crumbs.points) and game.score.items == before_bin_snatches,"bin crumbs award low scrap points without combo or practice credit")
	# Empty bins cannot create an endless source of crumbs or litter.
	gull.position.x = float(bin.x)-10
	while int(bin.remaining) > 0:
		raids.peck_cooldown = 0
		check(raids.peck(),"bin remains peckable while finite contents remain")
	var exhausted_count: int = raids.items.size()
	raids.peck_cooldown = 0
	check(raids.peck() and raids.items.size() == exhausted_count and int(bin.remaining) == 0,"empty bin responds without ejecting crumbs or garbage")
	check(not raids.peck(),"empty bin tap keeps the normal peck cooldown")
	game.input.enabled = true
	var tap: InputEventScreenTouch = InputEventScreenTouch.new()
	tap.index = 4
	tap.position = Vector2(180,160)
	tap.pressed = true
	game.input._input(tap)
	check(game.input.touch_peck and not game.input.touch_climb,"separate touch peck does not flap")
	game.set_paused(true)
	check(not game.input.touch_peck,"pause clears queued peck")
	main.start_level(1)
	check(main.game.stash_raids.items.is_empty() and main.game.stash_raids.raids.is_empty(),"retry clears scattered food, rubbish and owner pursuit")
	check(int(main.game.stash_raids.bins[0].remaining) == int(Config.tuning.world.bin_stash_size),"retry restores fresh finite bin supply")
	main.clear_game()
	await settle()

func perch_checks() -> void:
	for hz: int in [30,60,120]:
		for pole: bool in [false,true]:
			var gull: BeachGull = physics_gull(Vector2(300,45),Vector2.ZERO)
			gull.setup_perches([{"type":"beach_lamp" if pole else "kiosk","x":300,"y":160}])
			var surface: Dictionary = gull.perch_surfaces[0]
			gull.aim = Vector2(300,surface.y)
			for frame: int in hz*4:
				gull.tick(1.0/hz,1,0.3)
			check(gull.state==BeachGull.State.GROUNDED and not gull.support.is_empty(),"downward aim lands on roof/pole in wind at %d Hz" % hz)
			check(is_equal_approx(gull.position.y+float(Config.tuning.flight.feet_offset),float(surface.y)),"feet align with perch top")
			gull.aim.x = 400
			for frame: int in hz*2:
				gull.tick(1.0/hz,0,0)
			check((not gull.support.is_empty())==pole,"roof edge releases while pole holds standing gull")
			gull.climb = true
			gull.tick(1.0/hz,0,0)
			check(gull.state==BeachGull.State.GLIDE and gull.support.is_empty(),"flap releases perch immediately")
			gull.queue_free()
		var diver: BeachGull = physics_gull(Vector2(300,65),Vector2(0,230))
		diver.setup_perches([{"type":"kiosk","x":300}])
		var surface_y: float = diver.perch_surfaces[0].y
		diver.state = BeachGull.State.STRIKE
		diver.direction = Vector2.DOWN
		diver.dive_speed = 230
		diver.aim = Vector2(300,160)
		for frame: int in hz:
			diver.tick(1.0/hz,0,0)
			if diver.position.y > float(surface_y)+10.0:
				break
		check(diver.state==BeachGull.State.STRIKE and diver.support.is_empty() and diver.position.y > float(surface_y),"fast swoop passes through the roof without crashing or landing at %d Hz" % hz)
		diver.queue_free()
	main.start_level(1)
	var game: BeachGame = main.game
	game.set_physics_process(false)
	game.intro = 0
	var roof: Dictionary = game.player.perch_surfaces[0]
	game.player.position = Vector2(roof.x,65)
	game.player.velocity = Vector2.ZERO
	game.player.aim = Vector2(roof.x,roof.y)
	for frame: int in 240:
		game.player.tick(1.0/60,0,0)
	game.camera.position.x = roof.x
	game.camera_x = roof.x
	game.beach.camera_x = roof.x
	game.beach.queue_redraw()
	await snapshot("perching-stand-roof")
	check(not game.player.support.is_empty(),"generated stand provides working perch")
	game.player.digestion.collect("ice_cream")
	game.player.digestion.tick(0.5,game.player.state==BeachGull.State.GROUNDED)
	check(game.player.digestion.progress>=0.99,"perched digestion receives grounded speed boost")
	game.player.dive(0)
	check(game.player.state==BeachGull.State.WINDUP and game.player.support.is_empty(),"dive leaves perch using existing windup")
	for frame: int in 30:
		game.player.tick(1.0/60,0,0)
	check(game.player.support.is_empty(),"intentional dive does not recatch its departure surface")
	game.player.state = BeachGull.State.GLIDE
	game.player.position = Vector2(roof.x,float(roof.y)+15)
	game.player.velocity = Vector2(0,-35)
	game.player.climb = true
	game.player.tick(0.1,0,0)
	check(game.player.support.is_empty(),"approach from below cannot snap onto roof")
	game.player.climb = false
	game.player.state = BeachGull.State.STRIKE
	game.player.position = Vector2(roof.x,65)
	game.player.direction = Vector2.DOWN
	game.player.dive_speed = 230
	game.player.velocity = Vector2(0,230)
	game.player.aim = Vector2(roof.x,160)
	game.score.points = 100
	for frame: int in 60:
		game.player.tick(1.0/60,0,0)
		if game.player.position.y > float(roof.y)+10.0:
			break
	check(game.score.points==100 and game.player.state==BeachGull.State.STRIKE and game.player.support.is_empty(),"swooping through a stand roof costs nothing")
	main.clear_game()
	await settle()

func landing_aim_checks() -> void:
	var landing_times: Array[float] = []
	for hz: int in [30,60,120]:
		var gull: BeachGull = physics_gull(Vector2(300,45),Vector2(120,0))
		gull.aim = Vector2(300,Config.tuning.world.ground)
		check(gull.landing_aim(),"downward ground aim requests landing")
		var elapsed: float = 0
		var peak_sink: float = 0
		while elapsed < 5 and gull.state != BeachGull.State.GROUNDED:
			gull.tick(1.0/hz,0,0)
			elapsed += 1.0/hz
			peak_sink = maxf(peak_sink,gull.velocity.y)
		check(gull.state == BeachGull.State.GROUNDED and absf(gull.position.x-300) < 5,"downward aim brakes sideways motion and lands near cursor at %dHz" % hz)
		check(peak_sink > float(Config.tuning.flight.max_descent) and peak_sink <= float(Config.tuning.flight.landing_speed)+0.1,"landing descends deliberately at bounded speed")
		check(gull.state != BeachGull.State.STUNNED and gull.dive_speed == 0,"gentle landing never enters a dive or crash")
		landing_times.append(elapsed)
		gull.queue_free()
	check(absf(landing_times[0]-landing_times[2]) < 0.15,"landing timing consistent across physics rates")
	var gull: BeachGull = physics_gull(Vector2(300,60))
	gull.aim = Vector2(300,160)
	for frame: int in 30:
		gull.tick(1.0/60,0,0)
	check(gull.velocity.y > float(Config.tuning.flight.max_descent),"downward aim sinks faster than passive glide")
	gull.climb = true
	check(not gull.landing_aim(),"flapping overrides landing aim")
	for frame: int in 120:
		gull.tick(1.0/60,0,0)
	check(gull.state == BeachGull.State.GLIDE and gull.velocity.y < 0,"flapping cancels descent and climbs")
	gull.climb = false
	gull.aim = gull.position+Vector2(60,30)
	check(not gull.landing_aim(),"ordinary diagonal aiming does not engage landing")
	gull.aim = gull.position+Vector2(0,60)
	gull.dive(0)
	check(gull.state == BeachGull.State.WINDUP and not gull.landing_aim(),"explicit dive takes priority over gentle landing")
	gull.queue_free()
	main.start_level(1)
	var game: BeachGame = main.game
	game.set_physics_process(false)
	game.intro = 0
	game.running = true
	game.score.points = 123
	game.player.position = Vector2(140,45)
	game.player.velocity = Vector2.ZERO
	game.player.aim = Vector2(140,160)
	for frame: int in 30:
		game.player.tick(1.0/60,1,1)
	game.overlay.queue_redraw()
	await snapshot("aim-to-land")
	for frame: int in 240:
		if game.player.state == BeachGull.State.GROUNDED:
			break
		game.player.tick(1.0/60,1,1)
	check(game.player.state == BeachGull.State.GROUNDED and absf(game.player.position.x-140) < 8,"landing steers against wind toward cursor")
	check(game.score.points == 123,"gentle landing preserves score")
	game.player.climb = true
	game.player.tick(1.0/60,0,0)
	check(game.player.state == BeachGull.State.GLIDE and game.player.velocity.y < 0,"flap still takes off with ground cursor unchanged")
	main.clear_game()
	await settle()

func refinement_checks() -> void:
	var gull: BeachGull = physics_gull(Vector2(300,100),Vector2(80,-100))
	gull.pullup()
	var before: Vector2 = gull.velocity
	gull.tick(1.0/60,0,0)
	check(gull.velocity.distance_to(before) < 2,"leaving swoop preserves momentum without sudden speed change")
	for frame: int in range(24):
		gull.aim = gull.position + Vector2(100,0)
		gull.tick(1.0/60,0,0)
	check(gull.velocity.x < 80 and gull.velocity.y > -100 and gull.velocity.y < 0,"coasting slows and rises without auto acceleration")
	gull.climb = true
	for frame: int in range(12):
		gull.tick(1.0/60,0,0)
	check(not gull.coasting and gull.velocity.x > 80,"flapping restores powered flight")
	gull.queue_free()
	gull = physics_gull(Vector2(300,50),Vector2(60,200))
	gull.pullup()
	gull.climb = true
	gull.tick(1.0/60,0,0)
	check(gull.velocity.y > 190 and gull.velocity.y < 200,"flapping out of downward dive brakes without snapping speed")
	gull.queue_free()
	gull = physics_gull(Vector2(300,80),Vector2(100,10))
	gull.aim = Vector2(400,160)
	gull.dive(0)
	var start: Vector2 = gull.position
	gull.tick(0.1,0,0)
	check(gull.state == BeachGull.State.WINDUP and gull.position.x >= start.x+9 and gull.position.y > start.y,"dive preparation keeps moving")
	gull.queue_free()
	var rates: Array[float] = []
	for slope: float in [0.001,-0.001,-0.15,-0.8]:
		gull = physics_gull()
		gull.state = BeachGull.State.STRIKE
		gull.direction = Vector2(sqrt(1-slope*slope),slope)
		gull.aim = gull.position+gull.direction*100
		gull.dive_speed = 220
		gull.tick(1.0/120,0,0)
		rates.append((220-gull.dive_speed)*120)
		gull.queue_free()
	check(absf(rates[0]-rates[1]) < 2,"braking changes smoothly through level flight")
	check(rates[3] > rates[2] and rates[2] > rates[1],"steeper climbs progressively spend more speed")
	var controller: GullInput = GullInput.new()
	add_child(controller)
	controller.gamepad = true
	gull = physics_gull()
	gull.land()
	Input.action_press("aim_right")
	controller.update_player(gull,160)
	gull.tick(0.1,0,0)
	check(gull.velocity.x > 0,"controller stick walks on ground")
	Input.action_release("aim_right")
	controller.update_player(gull,160)
	gull.tick(0.1,0,0)
	check(is_zero_approx(gull.velocity.x),"released controller stick stops walking")
	gull.state = BeachGull.State.STRIKE
	gull.direction = Vector2(1,-1).normalized()
	gull.dive_speed = 100
	controller.update_player(gull,160)
	check((gull.aim-gull.position).normalized().is_equal_approx(gull.direction),"released controller stick preserves swoop direction")
	gull.state = BeachGull.State.GLIDE
	gull.velocity = Vector2(50,-20)
	controller.update_player(gull,160)
	check((gull.aim-gull.position).normalized().is_equal_approx(gull.velocity.normalized()),"released stick preserves ordinary airborne heading")
	controller.queue_free()
	gull.queue_free()
	# Same downward speed has the same result around the old angle cutoff.
	for slope: float in [0.64,0.66]:
		for speed: float in [220,300]:
			gull = physics_gull(Vector2(300,153))
			gull.state = BeachGull.State.STRIKE
			gull.direction = Vector2(sqrt(1-slope*slope),slope)
			gull.aim = gull.position + gull.direction*100
			gull.dive_speed = speed
			gull.tick(1.0/60,0,0)
			check((gull.state == BeachGull.State.STUNNED) == (speed == 300),"crash severity follows downward impact at slope %.2f speed %.0f" % [slope,speed])
			gull.queue_free()
	gull = physics_gull(Vector2(300,100))
	gull.state = BeachGull.State.STRIKE
	gull.direction = Vector2.DOWN
	gull.velocity = Vector2(0,130)
	check(gull.crash_warning() and gull.crash_risk() < 1,"warning appears before dangerous impact speed")
	gull.direction = Vector2.RIGHT
	gull.velocity = Vector2(300,0)
	check(not gull.crash_warning(),"horizontal speed alone does not warn of a ground crash")
	gull.queue_free()
	for hz: int in [30,60,120]:
		gull = physics_gull()
		gull.wind_force = 1
		gull.aim = gull.position
		gull.tick(1.0/hz,-1,1)
		check(gull.wind_force > 0 and absf(gull.wind_force-1) <= float(Config.tuning.wind.response)/hz + 0.0001,"wind reversal blends at %d Hz" % hz)
		for frame: int in range(hz*2):
			gull.aim = gull.position
			gull.tick(1.0/hz,-1,1)
		check(is_equal_approx(gull.wind_force,-1),"wind finishes reversing at %d Hz" % hz)
		gull.queue_free()
	var pushes: Array[float] = []
	for flight_state: BeachGull.State in [BeachGull.State.GLIDE,BeachGull.State.WINDUP,BeachGull.State.STRIKE]:
		gull = physics_gull()
		gull.state = flight_state
		gull.wind_force = 1
		gull.direction = Vector2.DOWN
		# Neutral aim isolates wind drift from intentional landing steering.
		gull.aim = gull.position
		gull.timer = 1
		gull.dive_speed = 80
		gull.tick(1.0/60,1,1)
		pushes.append(gull.position.x-300)
		gull.queue_free()
	check(is_equal_approx(pushes[0],pushes[1]) and is_equal_approx(pushes[1],pushes[2]),"wind push is consistent across flight modes")
	await settle()
	main.start_level(1)
	main.game.set_physics_process(false)
	main.game.intro = 0
	main.game.running = true
	main.game.player.position = Vector2(140,90)
	main.game.player.state = BeachGull.State.STRIKE
	main.game.player.direction = Vector2.DOWN
	main.game.player.velocity = Vector2(0,150)
	main.game.player.dive_speed = 150
	main.game.player.aim = Vector2(140,170)
	main.game.player.tick(0,0,0)
	main.game.overlay.queue_redraw()
	await snapshot("crash-warning")
	layout(main.game.overlay)
	check(not main.game.overlay.training_panel.get_rect().intersects(Rect2(232,44,84,29)),"training panel clears NEXT LEVEL footprint")
	main.clear_game()
	await settle()

func food_checks() -> void:
	var categories: Dictionary = {"small":0,"medium":0,"large":0}
	for id: String in Config.foods:
		var definition: Dictionary = Config.foods[id]
		categories[definition.category] += 1
		var frame: AtlasTexture = Config.frames(definition.sprite).get_frame_texture(&"idle",0) as AtlasTexture
		check(frame != null and Rect2(Vector2.ZERO,frame.atlas.get_size()).encloses(frame.region),"food artwork is inside atlas: "+id)
		check(Vector2(definition.size[0],definition.size[1]) == Vector2(definition.pickup_radius[0],definition.pickup_radius[1])*2,"pickup size matches food artwork: "+id)
	check(categories == {"small":3,"medium":3,"large":2},"all eight foods belong to requested categories")
	main.start_level(1)
	var game: BeachGame = main.game
	game.set_physics_process(false)
	game.intro = 0
	game.running = true
	var gull: BeachGull = game.player
	gull.position.y = gull.ground_y()
	gull.land()
	var chip: Dictionary = game.scraps.crumbs[2]
	check(chip.food_id == "single_chip","ground has single chips alongside crumbs")
	gull.position.x = float(chip.x)-gull.facing*float(Config.tuning.dive.beak_offset)
	game.scraps.tick(0,gull)
	eat_pending(game)
	check(game.score.points == 5 and game.score.items == 0 and game.score.tier == 0,"chip pickup awards five without practice or combo credit")
	game.scraps.tick(0,gull)
	eat_pending(game)
	check(game.score.points == 5,"chip cannot be collected twice before respawn")
	var target: BeachTarget = game.spawner.create("kiosk_customer",80)
	for id: String in ["crisps_box","ice_cream","crisps_bag","hotdog","fried_fish"]:
		target.food_id = id
		target.refresh_art()
		game.score = BeachScore.new()
		gull.upwind = false
		game._snatched(target,gull,false)
		eat_pending(game)
		check(game.score.points == int(Config.foods[id].points) and game.score.items == 1,"snatch uses food value: "+id)
		game.score = BeachScore.new()
		var expected: BeachScore = BeachScore.new()
		game._snatched(target,gull,true)
		eat_pending(game)
		check(game.score.points == expected.snatch(int(Config.foods[id].points),true,false,false),"risk bonus stays separate: "+id)
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = 18
	for kind: String in Config.targets:
		var person: BeachTarget = BeachTarget.new()
		add_child(person)
		person.setup(kind,100,random,1)
		check((not person.food and person.food_id.is_empty()) if Config.targets[kind].foods.is_empty() else Config.targets[kind].foods.has(person.food_id),"person holds allowed food: "+kind)
		person.queue_free()
	await snapshot("food-gameplay")
	main.clear_game()
	await settle()
	var gallery: Control = preload("res://tests/food_preview.gd").new()
	add_child(gallery)
	await snapshot("food-preview")
	gallery.queue_free()
	await settle()

func sunbather_reaction_flow_checks() -> void:
	main.start_level(2)
	var game: BeachGame = main.game
	game.set_physics_process(false)
	game.intro = 0
	game.running = true
	var raids: BeachStashRaids = game.stash_raids
	var owner: BeachTarget = game.spawner.targets[0]
	var gull: BeachGull = game.player
	for target: BeachTarget in game.spawner.targets:
		target.visible = target == owner
	gull.position = Vector2(220,65)
	gull.previous_beak = gull.beak()
	gull.sweep_beak = gull.beak()
	owner.stash_remaining = 0
	owner.stash_active = true
	raids.raids[owner] = {"pecks":0,"wake":0.0,"awake":true,"swat":0.0}
	raids.items.append({"owner":owner,"food_id":"cookie","position":Vector2(owner.position.x+25,156.5),"velocity":Vector2.ZERO,"grounded":true,"age":1.0})
	for frame: int in 120:
		raids.tick(1.0/60)
		eat_pending(game)
		if str(raids.raids[owner].get("action","")) == "pickup":
			break
	check(raids.items.size() == 1 and owner.stash_remaining == 0,"snack stays available when owner begins bending")
	raids.tick(SunbatherArt.PICKUP_PAUSE*0.7)
	eat_pending(game)
	check(raids.items.size() == 1 and owner.sprite.animation == &"pickup" and owner.sprite.frame >= 2,"pickup bends without lying down or prematurely claiming food")
	await snapshot("sunbather-bending")
	gull.land()
	gull.position.x = float(raids.items[0].position.x)-float(Config.tuning.dive.beak_offset)*gull.facing
	gull.previous_beak = gull.beak()
	gull.sweep_beak = gull.beak()
	raids.tick(0)
	eat_pending(game)
	check(raids.items.is_empty(),"gull can win snack during owner's bend")
	gull.position = Vector2(220,65)
	gull.previous_beak = gull.beak()
	gull.sweep_beak = gull.beak()
	raids.tick(SunbatherArt.PICKUP_PAUSE)
	eat_pending(game)
	check(owner.stash_remaining == 0,"interrupted pickup cannot duplicate food into bag")
	owner.reaction = AdultReaction.new()
	for frame: int in 180:
		raids.tick(1.0/60)
		eat_pending(game)
		if raids.raids.has(owner) and str(raids.raids[owner].get("action","")) == "settle":
			break
	check(raids.raids.has(owner) and owner.stash_standing,"return uses a settling phase before resting")
	raids.tick(SunbatherArt.SETTLE_TIME*0.5)
	eat_pending(game)
	await snapshot("sunbather-settling")
	raids.tick(SunbatherArt.SETTLE_TIME)
	eat_pending(game)
	check(not raids.raids.has(owner) and owner.sprite.animation == &"rest","settling ends in the original resting pose")
	# An empty bag still has an owner who can warn and swat a nearby raider.
	for escape: bool in [true,false]:
		owner.stash_active = true
		raids.raids[owner] = {"pecks":0,"wake":0.0,"awake":true,"swat":0.0}
		gull.land()
		gull.invulnerable = 0
		gull.position.x = owner.position.x+5
		raids.tick(0.01)
		eat_pending(game)
		check(gull.state != BeachGull.State.STUNNED and str(raids.raids[owner].get("action","")) == "swat_windup","swat begins with warning even without loose food")
		raids.tick(SunbatherArt.SWAT_WINDUP*0.4)
		eat_pending(game)
		check(gull.state != BeachGull.State.STUNNED,"warning pose does not deal early damage")
		await snapshot("sunbather-swat-warning")
		if escape:
			gull.position.x = 250
		raids.tick(SunbatherArt.SWAT_WINDUP)
		eat_pending(game)
		check((gull.state == BeachGull.State.STUNNED) != escape,"swat checks actual gull position at impact")
		await snapshot("sunbather-swat-impact")
		raids.raids.clear()
	owner.reaction = AdultReaction.new()
	main.clear_game()
	await settle()

func female_sunbather_art_checks() -> void:
	main.start_level(1)
	var game: BeachGame = main.game
	game.set_physics_process(false)
	game.intro = 0
	game.running = true
	var women: Array[BeachTarget] = [game.spawner.create("sunbather",170,{"appearance":"female_blue"}),game.spawner.create("sunbather",265,{"appearance":"female_red"})]
	check(women[0].sunbather_female and women[0].sunbather_blue and women[1].sunbather_female and not women[1].sunbather_blue,"both female colours appear alongside male sunbathers")
	for target: BeachTarget in game.spawner.targets:
		target.visible = target.kind == "sunbather" or target == game.spawner.targets[1]
	game.spawner.targets[1].position.x = 120
	for woman: BeachTarget in women:
		for pose: StringName in [&"rest",&"rise",&"run"]:
			var frames: SpriteFrames = woman.sprite.sprite_frames
			for i: int in frames.get_frame_count(pose):
				var atlas: AtlasTexture = frames.get_frame_texture(pose,i)
				check(Rect2(Vector2.ZERO,atlas.atlas.get_size()).encloses(atlas.region),"female frame stays inside source sheet")
	await snapshot("female-sunbathers-rest")
	for woman: BeachTarget in women:
		SunbatherArt.pose(woman,&"rise",3)
	await snapshot("female-sunbathers-rise")
	for i: int in 7:
		for woman: BeachTarget in women:
			woman.stash_standing = true
			woman.facing = -1 if woman.sunbather_blue else 1
			SunbatherArt.pose(woman,&"run",i)
			woman.queue_redraw()
			var height: float = woman.sprite.sprite_frames.get_frame_texture(&"run",i).get_height()*woman.sprite.scale.y
			check(is_zero_approx(woman.sprite.position.y+height*0.5-6.0),"female running feet align to ground")
		await snapshot("female-sunbathers-run-%d" % i)
	for woman: BeachTarget in women:
		woman.position.x -= 12
		SunbatherArt.reaction_pose(woman,&"bend",0.8)
		woman.queue_redraw()
	await snapshot("female-sunbathers-bending")
	main.clear_game()
	await settle()

func generated_layout_checks() -> void:
	var layouts: Array = []
	var moved_far: int = 0
	for number: int in range(1,7):
		main.start_level(number)
		var game: BeachGame = main.game
		game.set_physics_process(false)
		game.running = true
		game.intro = 0
		layouts.append(game.level)
		var world_width: float = float(game.beach.world.get("width",Config.tuning.world.width))
		for sign: Dictionary in game.beach.sign_layouts():
			var board: Rect2 = sign.rect
			var zone: Dictionary = sign.zone
			check(board.position.x >= float(zone.from) and board.end.x <= float(zone.to) and board.end.x <= world_width,"level %d sign %s inside zone/world" % [number,sign.name])
			for sprite: AnimatedSprite2D in game.beach.prop_sprites:
				var texture: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
				var dimensions: Vector2 = texture.get_size()*sprite.scale.abs()
				var rect := Rect2(sprite.position-dimensions*0.5,dimensions)
				check(not board.intersects(rect),"level %d sign %s clears actual prop sprite %s" % [number,sign.name,sprite.position])
			for actor: BeachTarget in game.spawner.targets:
				if actor.kind == "toddler":
					continue
				var texture: Texture2D = actor.sprite.sprite_frames.get_frame_texture(actor.sprite.animation,actor.sprite.frame)
				var height: float = texture.get_height()*absf(actor.sprite.scale.y)
				var head: float = minf(160-height,actor.position.y+actor.sprite.position.y-height*0.5)
				check(board.end.y <= head,"level %d sign %s above %s standing sprite band" % [number,sign.name,actor.kind])
			if absi(int(sign.shift)) > 40:
				moved_far += 1
				print("SIGN SHIFT: level %d %s %+d px (x=%d)" % [number,sign.name,int(sign.shift),int(board.position.x)])
		game.training = true
		check(game.overlay._you_marker_visible(),"YOU marker remains visible during Training Day")
		game.training = false
		game.intro_dismissed_elapsed = 4.5
		check(not game.overlay._you_marker_visible(),"YOU marker is absent 4.5 seconds after intro outside training")
		for point: Vector2 in [Vector2(-20,0),Vector2(160,70),Vector2(350,180)]:
			var marker: Rect2 = game.overlay.you_marker_rect(point)
			check(marker.position.y >= 30 and marker.position.x >= 0 and marker.end.x <= 320 and marker.end.y <= 180,"YOU tag remains below HUD and on screen")
		var count: int = game.spawner.targets.size()
		for i: int in 30:
			game.spawner.tick(10,40)
		check(game.spawner.targets.size()==count,"occupied stations do not accumulate new customers")
		var views: Array = [[160,"sunbathers"],[480,"families"],[800,"promenade"],[1120,"pier"]]
		if number == 1:
			views = [[160,"open-sand"],[400,"snack-and-bag"],[640,"family-bay"]]
		elif number == 2:
			views = [[160,"sunbathers"],[480,"first-family"],[720,"second-family"],[880,"snack-kiosk"]]
		elif number == 3:
			views = [[160,"quiet-beach"],[600,"promenade-snacks"],[800,"dog-walk"],[1080,"pier-dining"]]
		if number <= 3:
			for legacy: Array in [[160,"sunbathers"],[480,"families"],[800,"promenade"],[1120,"pier"]]:
				var already_present: bool = false
				for current: Array in views:
					already_present = already_present or current[1] == legacy[1]
				if not already_present:
					views.append([clampf(float(legacy[0]),160,world_width-160),legacy[1]])
		for view: Array in views:
			# Reframe only screenshot fixtures so readable boards aren't sliced at an edge.
			var framed_x: float = float(view[0])
			var found_frame: bool = false
			for shift: int in range(0,161):
				for direction: int in [1,-1]:
					var candidate: float = clampf(float(view[0])+shift*direction,160,world_width-160)
					var clear: bool = true
					for sign: Dictionary in game.beach.sign_layouts():
						var board: Rect2 = sign.rect
						var left: float = candidate-160
						var right: float = candidate+160
						if board.end.x > left and board.position.x < right and (board.position.x < left+2 or board.end.x > right-2):
							clear = false
					if clear:
						framed_x = candidate
						found_frame = true
						break
				if found_frame:
					break
			view[0] = framed_x
			check(found_frame,"overview has no sliced sign: level %d %s" % [number,view[1]])
			game.camera_x = float(view[0])
			game.camera.position.x = float(view[0])
			game.beach.camera_x = float(view[0])
			game.player.position = Vector2(float(view[0])-70,70)
			game.beach.queue_redraw()
			await snapshot("layout-%d-%s" % [number,view[1]])
		main.clear_game()
		await settle()
	var file: FileAccess = FileAccess.open("res://test-output/generated-levels.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(layouts,"  "))

func digestion_reaction_checks() -> void:
	main.start_level(1)
	var game: BeachGame = main.game
	game.set_physics_process(false)
	game.running = true
	game.intro = 0
	for actor: BeachTarget in game.spawner.targets:
		actor.hide()
	var gull: BeachGull = game.player
	gull.position = Vector2(160,90)
	var customer: BeachTarget = game.spawner.create("kiosk_customer",210,{"food_id":"ice_cream"})
	check(customer.take(gull) and game.score.points==0 and gull.digestion.snacks.size()==1,"real theft reserves snack without immediate points")
	gull.digestion.collect("cookie")
	gull.digestion.collect("single_chip")
	var blocked: BeachTarget = game.spawner.create("kiosk_customer",260,{"food_id":"ice_cream"})
	check(not blocked.take(gull) and blocked.food and blocked.thefts==0,"full belly leaves target food and theft counter intact")
	gull.digestion.tick(0.4,false)
	game.overlay.queue_redraw()
	await snapshot("digestion-snack-queue")
	game.score.points = 12
	gull.invulnerable = 0
	gull.stun()
	check(game.score.points==7 and gull.digestion.snacks.size()==2 and gull.digestion.progress==0,"swat loses five and only current snack")
	check(game.stash_raids.items.size()==1 and game.stash_raids.items[0].food_id=="ice_cream","swat scatters the unscored snack")
	gull.stun()
	check(game.score.points==7 and game.stash_raids.items.size()==1,"stunned gull cannot be penalized twice")
	gull.digestion.tick(1,false)
	var dropped: Dictionary = game.stash_raids.items[0]
	gull.state = BeachGull.State.GLIDE
	gull.position = Vector2(150,80)
	gull.previous_beak = gull.beak()
	gull.sweep_beak = gull.beak()
	dropped.position = gull.beak()
	dropped.velocity = Vector2.ZERO
	dropped.age = 0.3
	game.stash_raids.tick(0)
	check(game.stash_raids.items.is_empty() and gull.digestion.snacks.size()==1 and gull.digestion.progress==0,"dropped snack is recovered once with reset progress")
	var points_before: int = game.score.points
	gull.digestion.tick(1.49,false)
	check(game.score.points==points_before,"recovered medium snack must be eaten anew")
	gull.digestion.tick(0.01,false)
	check(game.score.points>points_before,"recovered snack scores only on swallowing")
	gull.digestion.collect("hotdog")
	gull.digestion.tick(3,false)
	game.overlay.queue_redraw()
	await snapshot("digestion-large-meal")
	game.score.points = 3
	gull.state = BeachGull.State.GLIDE
	gull.invulnerable = 0
	gull.stun()
	check(game.score.points==0 and game.stash_raids.items.is_empty() and gull.digestion.rest>0,"empty-mouth hit clamps penalty and preserves swallowed meal")
	# Independent approaches, real chase movement, height escape and return.
	var adult: BeachTarget = game.spawner.create("kiosk_customer",100)
	gull.state = BeachGull.State.GLIDE
	gull.position = Vector2(130,140)
	adult.tick(0.01,[gull])
	check(adult.reaction.mode=="warning","first approach warns")
	for frame: int in 40:
		adult.tick(0.02,[gull])
	check(adult.reaction.mode.is_empty(),"hovering is not repeated approaches")
	gull.position.x = 165
	adult.tick(0.01,[gull])
	gull.position.x = 130
	adult.tick(0.01,[gull])
	check(adult.reaction.mode=="chase","second entry within five seconds starts chase")
	for frame: int in 10:
		adult.tick(0.02,[gull])
	check(adult.position.x>100 and adult.position.x<=180,"adult chases within home bounds")
	gull.position.y = 70
	for frame: int in 180:
		adult.tick(1.0/60,[gull])
		if adult.reaction.mode.is_empty():
			break
	check(adult.reaction.mode.is_empty() and is_equal_approx(adult.position.x,adult.reaction.home),"high flight ends chase and adult returns home")
	adult.reaction.theft(adult,gull)
	gull.position = Vector2(150,140)
	for frame: int in 400:
		adult.tick(1.0/60,[])
		if adult.reaction.mode.is_empty():
			break
	check(adult.reaction.mode.is_empty() and is_equal_approx(adult.position.x,adult.reaction.home),"chase times out and returns even with low gull")
	gull.digestion.tick(10,false)
	gull.digestion.collect("cookie")
	gull.digestion.collect("single_chip")
	gull.state = BeachGull.State.GLIDE
	gull.invulnerable = 0
	gull.position = Vector2(110,148)
	adult.reaction = AdultReaction.new()
	game.score.points = 20
	adult.tick(0.01,[gull])
	check(game.score.points==20,"warning has no early penalty")
	adult.tick(0.4,[gull])
	check(gull.state==BeachGull.State.STUNNED and game.score.points==15 and gull.digestion.snacks.size()==1 and game.stash_raids.items.size()==1,"actual adult swat stuns, penalizes and drops only current snack")
	var sleeper: BeachTarget = game.spawner.create("sunbather",280)
	sleeper.reaction.theft(sleeper,gull)
	check(sleeper.reaction.mode=="wake" and sleeper.reaction.timer>0.5,"sunbather takes longer to wake for chase")
	game.set_paused(true)
	var paused_progress: float = gull.digestion.progress
	await settle()
	check(gull.digestion.progress==paused_progress,"pause preserves digestion progress")
	main.clear_game()
	await settle()
	main.start_level(1)
	main.game.set_physics_process(false)
	check(main.game.player.digestion.snacks.is_empty() and main.game.player.digestion.rest==0,"restart clears carried food and digestion")
	main.clear_game()
	await settle()

func beachgoer_art_checks() -> void:
	for key: String in ["kiosk_customer","dog"]:
		var frames: SpriteFrames = Config.frames(key)
		var definition: Dictionary = Config.sprites[key]
		for animation: StringName in frames.get_animation_names():
			for index: int in frames.get_frame_count(animation):
				var texture: AtlasTexture = frames.get_frame_texture(animation,index) as AtlasTexture
				check(texture.get_size() == Vector2(definition.frame_w,definition.frame_h),"beachgoer aligned frame canvas")
				check(Rect2(Vector2.ZERO,texture.atlas.get_size()).encloses(texture.region),"beachgoer atlas stays inside sheet")
		check(frames.get_frame_texture(&"idle",0).atlas.get_image().get_mipmap_count() > 0,"beachgoer source has mipmaps")
	main.start_level(4)
	var game: BeachGame = main.game
	game.set_physics_process(false)
	game.intro = 0
	game.running = true
	for target: BeachTarget in game.spawner.targets:
		target.hide()
	var customer: BeachTarget = game.spawner.create("kiosk_customer",150,{"food_id":"ice_cream"})
	var owner: BeachTarget = game.spawner.create("dog_owner",245)
	game.player.position = Vector2(50,70)
	customer.tick(0.1,[])
	check(customer.sprite.animation == &"walk","customer walks while carrying food")
	owner.tick(0.1,[])
	check(owner.sprite.animation == &"idle","dog and owner rest when stationary")
	await snapshot("polished-customer-and-dog")
	for target: BeachTarget in [customer,owner]:
		target.facing = -1
		target.update_art_pose(true)
		check(target.sprite.flip_h and target.food_position().x < target.position.x,"beachgoer food mirrors with art")
		target.sprite.frame = 1
		check(target.food_position().x < target.position.x,"food follows next mirrored walk frame")
		target.facing = 1
		target.update_art_pose(false)
	owner.alert = 1
	owner.update_art_pose(false)
	owner.sprite.pause()
	owner.sprite.frame = 1
	check(owner.sprite.animation == &"bark","alert dog shows barking warning")
	await snapshot("polished-dog-warning")
	var food_at: Vector2 = customer.food_position()
	game.player.state = BeachGull.State.STRIKE
	game.player.sweep_state = BeachGull.State.STRIKE
	game.player.peck_sweep_active = true
	game.player.grounded_sweep = false
	game.player.direction = Vector2(1,0)
	game.player.previous_beak = food_at-Vector2(15,0)
	game.player.sweep_beak = food_at+Vector2(15,0)
	BeachCollisions.resolve(game.player,[customer],[])
	eat_pending(game)
	check(not customer.food and not customer.food_sprite.visible,"visible customer snack is stolen through swept collision")
	var before: float = customer.position.x
	customer.tick(0.1,[])
	check(customer.position.x == before and customer.sprite.animation == &"angry","customer plants feet for brief theft reaction")
	await snapshot("polished-customer-theft")
	customer.tick(0.5,[])
	check(customer.reaction.mode.is_empty() and is_equal_approx(customer.position.x,customer.reaction.home),"robbed customer gives up when gull flies high and returns")
	owner.leaving = true
	owner.update_art_pose(true)
	check(owner.sprite.animation == &"walk","departing owner and dog use walk cycle")
	main.clear_game()
	await settle()

func pier_diner_art_checks() -> void:
	var frames: SpriteFrames = PierDinerArt.frames()
	for motion: StringName in [&"walk", &"run", &"eat"]:
		check(frames.get_frame_count(motion) == 4,"retro diner has a four-frame "+String(motion)+" cycle")
	for animation: StringName in frames.get_animation_names():
		var definition: Dictionary = Config.sprites.pier_diner_motion if animation in [&"walk", &"run", &"eat"] else Config.sprites.pier_diner
		for index: int in frames.get_frame_count(animation):
			var texture: AtlasTexture = frames.get_frame_texture(animation,index) as AtlasTexture
			check(texture.get_size() == Vector2(definition.frame_w,definition.frame_h),"retro diner uses an aligned frame canvas")
			check(Rect2(Vector2.ZERO,texture.atlas.get_size()).encloses(texture.region),"retro diner atlas frame stays inside source")
	main.start_level(1)
	var game: BeachGame = main.game
	game.set_physics_process(false)
	game.intro = 0
	game.running = true
	for other: BeachTarget in game.spawner.targets:
		other.hide()
	var diner: BeachTarget = game.spawner.create("pier_diner",1040)
	game.camera_x = 1040
	game.camera.position = Vector2(1040,90)
	game.beach.camera_x = 1040
	game.player.position = Vector2(50,70)
	check(diner.sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST,"retro diner keeps crisp nearest-neighbour pixels")
	check(diner.sprite.animation == &"idle" and diner.food_position().x > diner.position.x,"retro diner starts calm with food in forward hand")
	var idle_food_y: float = diner.food_position().y
	diner.art_time = 3.1
	diner.update_art_pose()
	check(diner.sprite.animation == &"eat","calm diner periodically eats the held snack")
	diner.sprite.pause()
	diner.sprite.frame = 1
	check(diner.food_position().y < idle_food_y - 5,"fish follows the eating hand toward the mouth")
	await snapshot("retro-diner-eat")
	diner.art_time = 0
	diner.reaction.mode = "return"
	diner.reaction.home = 1040
	diner.position.x = 1070
	diner.reaction.tick(diner,0.1,[])
	check(diner.sprite.animation == &"walk" and diner.position.x < 1070,"returning diner plays its walk cycle")
	diner.sprite.pause()
	diner.sprite.frame = 1
	await snapshot("retro-diner-walk")
	diner.position.x = 1040
	diner.reaction.mode = "chase"
	diner.reaction.timer = 3
	diner.reaction.focus = game.player
	game.player.position = Vector2(1100,140)
	diner.reaction.tick(diner,0.1,[game.player])
	check(diner.sprite.animation == &"run" and diner.position.x > 1040,"chasing diner plays its faster run cycle")
	diner.sprite.pause()
	diner.sprite.frame = 1
	await snapshot("retro-diner-run")
	diner.position.x = 1040
	game.player.position = Vector2(50,70)
	diner.reaction.mode = ""
	diner.alert = 0.2
	diner.update_art_pose()
	check(diner.sprite.animation == &"notice","diner first shows suspicion")
	diner.alert = 0.6
	diner.update_art_pose()
	check(diner.sprite.animation == &"watch","diner visibly tracks rising awareness")
	diner.alert = 1.0
	diner.update_art_pose()
	check(diner.sprite.animation == &"alert" and diner.food_position().x < diner.position.x,"diner points out the gull while holding food in the other hand")
	await snapshot("retro-diner-alert")
	diner.reaction.swat_timer = 0.2
	diner.update_art_pose()
	check(diner.sprite.animation == &"windup" and diner.food_position().x > diner.position.x,"diner warns with a raised swat hand")
	await snapshot("retro-diner-windup")
	diner.reaction.swat_timer = -1
	diner.action_pose_time = 0.28
	diner.update_art_pose()
	check(diner.sprite.animation == &"swat" and diner.food_position().x < diner.position.x,"diner shows an actual swat with food in the other hand")
	await snapshot("retro-diner-swat")
	diner.action_pose_time = 0
	diner.reaction.focus = game.player
	game.player.position = diner.position-Vector2(10,12)
	diner.reaction._hit(diner)
	check(diner.action_pose_time > 0 and game.player.state == BeachGull.State.STUNNED,"actual diner hit triggers visible swat pose")
	diner.action_pose_time = 0
	diner.alert = 0
	diner.facing = -1
	diner.update_art_pose()
	check(diner.sprite.animation == &"idle" and diner.sprite.flip_h and diner.food_position().x < diner.position.x,"diner food mirrors with its facing")
	main.clear_game()
	await settle()

func extended_beach_checks() -> void:
	check(Config.tuning.world.width == 1280 and Config.tuning.world.promenade_start == 640,"late-game beach retains promenade and pier")
	for level: Dictionary in Config.levels:
		var stands: Dictionary = {}
		var world: Dictionary = level.get("world",{})
		var width: float = float(world.get("width",Config.tuning.world.width))
		for prop: Dictionary in level.props:
			check(float(prop.x) >= 0 and float(prop.x) < width,"map prop stays inside level world")
			if prop.type in ["kiosk","hotdog_stand"]:
				stands[prop.type] = prop.x
		check(stands.has("kiosk") and (int(level.id) <= 2 or stands.has("hotdog_stand")),"each level has its authored food stands")
	main.start_level(4)
	var game: BeachGame = main.game
	game.set_physics_process(false)
	game.intro = 0
	game.running = true
	for target: BeachTarget in game.spawner.targets:
		if target.kind == "picnic_family":
			var kiosk: Dictionary = game.level.props.filter(func(prop: Dictionary) -> bool: return prop.type == "kiosk")[0]
			check(target.family_kiosk_x == float(kiosk.x),"family trips reach generated ice cream stand")
	var saw_hotdog: bool = false
	for target: BeachTarget in game.spawner.targets:
		if target.kind == "kiosk_customer" and target.food_id == "hotdog":
			saw_hotdog = true
	check(saw_hotdog,"hot dog stand has a customer carrying stealable food")
	for view: Array in [[160,"extended-beach-west"],[480,"extended-beach-ice-cream"],[800,"extended-beach-hotdogs"],[1120,"extended-beach-pier"]]:
		game.camera_x = float(view[0])
		game.camera.position.x = float(view[0])
		game.beach.camera_x = float(view[0])
		game.player.position.x = float(view[0])-70
		game.beach.queue_redraw()
		await snapshot(str(view[1]))
	main.clear_game()
	await settle()

func mum_art_checks() -> void:
	var frames: SpriteFrames = Config.frames("parent")
	for animation: StringName in frames.get_animation_names():
		for index: int in frames.get_frame_count(animation):
			var texture: AtlasTexture = frames.get_frame_texture(animation,index) as AtlasTexture
			check(texture.get_size() == Vector2(64,64),"mum frames share the native 64-pixel canvas")
			check(Rect2(Vector2.ZERO,texture.atlas.get_size()).encloses(texture.region),"mum frame stays inside source sheet")
	check(frames.get_frame_texture(&"idle",0).atlas.get_image().get_mipmap_count() == 0,"mum source remains crisp without mipmaps")
	main.start_level(1)
	var game: BeachGame = main.game
	game.set_physics_process(false)
	game.intro = 0
	game.running = true
	var mum: BeachTarget
	for target: BeachTarget in game.spawner.targets:
		if target.kind == "picnic_family" and not is_instance_valid(mum):
			mum = target
		else:
			target.hide()
	mum.position.x = 160
	game.player.position = Vector2(45,70)
	mum.food = false
	mum.food_sprite.hide()
	mum.defense = 0
	mum.alert = 0
	mum.family_trip = BeachTarget.FamilyTrip.TO_STAND
	mum.tick(0.1,[])
	check(mum.sprite.animation == &"walk","empty-handed mum walks toward stand")
	await snapshot("mum-walking")
	mum.food = true
	mum.food_sprite.show()
	mum.family_trip = BeachTarget.FamilyTrip.RETURN
	mum.family_home = 80
	mum.tick(0.1,[])
	check(mum.sprite.animation == &"carry_left" and not mum.sprite.flip_h,"returning mum carries with drawn left-facing frames")
	check(mum.food_position().x < mum.position.x,"carried food follows mirrored hand")
	await snapshot("mum-carrying")
	mum.family_trip = BeachTarget.FamilyTrip.BUY
	mum.family_trip_timer = 5
	mum.tick(0.01,[])
	check(mum.sprite.animation == &"idle","mum stops walking while buying")
	mum.sprite.set_frame_and_progress(0,0.5)
	mum.tick(0.01,[])
	check(mum.sprite.frame_progress >= 0.5,"stationary trip does not reset pose each tick")
	mum.handover_timer = 1
	mum.update_art_pose(false)
	mum.sprite.pause()
	mum.sprite.frame = 2
	check(mum.food_sprite.position == Vector2(-16,-10),"handover lowers separate snack to child's height")
	await snapshot("mum-handover")
	mum.defense = 1
	mum.update_art_pose(false)
	check(mum.sprite.animation == &"shield","defense shows protected food pose")
	await snapshot("mum-shielding")
	mum.mum_swat_time = 0.25
	mum.update_art_pose(false)
	check(mum.sprite.animation == &"swat","active swat takes priority over shield")
	await snapshot("mum-swat")
	mum.handover_timer = 0
	mum.defense = 0
	mum.tick(0.3,[])
	check(mum.sprite.animation != &"swat","swat pose clears after its brief reaction")
	main.clear_game()
	await settle()

func toddler_art_checks() -> void:
	var frames: SpriteFrames = Config.frames("toddler")
	for animation: StringName in frames.get_animation_names():
		for index: int in frames.get_frame_count(animation):
			var texture: AtlasTexture = frames.get_frame_texture(animation,index) as AtlasTexture
			check(texture.get_size() == Vector2(362,362),"toddler frame shares aligned canvas")
			check(Rect2(Vector2.ZERO,texture.atlas.get_size()).encloses(texture.region),"toddler atlas region within sheet")
			check(texture.margin.position.y + texture.region.size.y == 362,"toddler feet aligned at frame baseline")
	main.start_level(1)
	var game: BeachGame = main.game
	game.set_physics_process(false)
	game.intro = 0
	game.running = true
	var toddler: BeachTarget
	for target: BeachTarget in game.spawner.targets:
		if target.kind == "toddler":
			toddler = target
			break
	check(is_equal_approx(toddler.art_height(),27.15*0.7),"toddler is thirty percent smaller with aligned feet")
	check(toddler.sprite.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS,"toddler alone uses smooth mipmapped minification")
	var toddler_source: Texture2D = frames.get_frame_texture(&"idle",0).atlas
	check(toddler_source.get_image().get_mipmap_count() > 0,"toddler source imports mip levels for stable high-resolution downsampling")
	toddler.tick(0.2,[])
	check(toddler.sprite.animation == &"eat" and toddler.food_sprite.visible,"toddler eating pause holds separate ice cream")
	var paused_x: float = toddler.position.x
	toddler.tick(0.2,[])
	check(toddler.position.x == paused_x,"eating pose plants feet")
	# Keep one quality-reference capture unobstructed and at the real gameplay
	# size. Other beach actors can overlap this small character during normal play.
	for target: BeachTarget in game.spawner.targets:
		target.visible = target == toddler
	toddler.position.x = 160.0
	toddler.patrol_home = 160.0
	toddler.z_index = 20
	paused_x = toddler.position.x
	await snapshot("toddler-render-quality")
	await snapshot("toddler-eating")
	toddler.art_time = 2.0
	toddler.tick(0.1,[])
	check(toddler.sprite.animation == &"walk" and toddler.position.x > paused_x,"toddler walking pose follows movement")
	toddler.sprite.set_frame_and_progress(2,0.2)
	toddler.tick(0.01,[])
	check(toddler.sprite.frame == 2,"walking animation not restarted by generic target fallback")
	toddler.facing = -1
	toddler.tick(0.1,[])
	check(toddler.sprite.flip_h and toddler.food_position().x < toddler.position.x,"left-facing toddler mirrors hand and pickup together")
	var family: BeachTarget = toddler.family_parent
	# This art/handover fixture relocates the child for its close-up. Keep its
	# parent nearby instead of depending on the authored level's family position.
	family.position.x = 245
	family.family_home = 245
	check(toddler.take(game.player),"polished toddler food remains stealable")
	eat_pending(game)
	check(toddler.sprite.animation == &"cry" and not toddler.food_sprite.visible and family.alert == 1,"theft shows crying without baked-in ice cream and alerts parent")
	paused_x = toddler.position.x
	toddler.tick(0.2,[])
	check(toddler.position.x != paused_x and toddler.seeking_parent,"robbed toddler runs and cries immediately")
	toddler.sprite.frame = 3
	await snapshot("toddler-crying")
	ToddlerCryRunChecks.run(Callable(self,"check"),toddler)
	for frame: int in range(600):
		toddler.tick(1.0/60,[])
		if frame == 60:
			await snapshot("toddler-running-to-mum")
		if toddler.food:
			break
	check(toddler.food and toddler.food_sprite.visible and toddler.sprite.animation != &"cry","visible mum handover ends crying pose: "+str({"food":toddler.food,"visible":toddler.food_sprite.visible,"animation":toddler.sprite.animation,"trip":family.family_trip,"supply":family.supply_cookies}))
	toddler.take(game.player)
	eat_pending(game)
	toddler.tick(0.1,[])
	check(not toddler.leaving and toddler.seeking_parent,"repeat theft sends toddler back to mum without permanent departure")
	main.clear_game()
	await settle()
	var gallery: Control = preload("res://tests/toddler_preview.gd").new()
	add_child(gallery)
	await snapshot("toddler-sheet-preview")
	gallery.queue_free()
	await settle()

func art_checks() -> void:
	var frames: SpriteFrames = Config.frames("player_gull")
	for animation: StringName in frames.get_animation_names():
		for index: int in range(frames.get_frame_count(animation)):
			var frame: AtlasTexture = frames.get_frame_texture(animation,index) as AtlasTexture
			check(frame != null and frame.get_size() == Vector2(240,200),"gull frames share an aligned canvas")
			check(Rect2(Vector2.ZERO,frame.atlas.get_size()).encloses(frame.region),"gull crop stays within source sheet")
	main.start_level(1)
	var game: BeachGame = main.game
	game.set_physics_process(false)
	game.intro = 0
	game.running = true
	var gull: BeachGull = game.player
	gull.position = Vector2(140,gull.ground_y())
	gull.land()
	gull.aim = gull.position
	gull.tick(0,0,0)
	check(gull.sprite.animation == &"idle" and gull.sprite.visible,"standing displays reference idle pose")
	game.overlay.queue_redraw()
	await snapshot("gull-standing")
	gull.aim.x += 100
	for frame: int in range(15):
		gull.tick(1.0/60,0,0)
	var first_frame: int = gull.sprite.frame
	for frame: int in range(10):
		gull.tick(1.0/60,0,0)
	check(gull.sprite.frame != first_frame and gull.sprite.flip_h,"walking advances supplied feet and faces right")
	game.overlay.queue_redraw()
	await snapshot("gull-walking")
	gull.aim.x = gull.position.x - 100
	for frame: int in range(15):
		gull.tick(1.0/60,0,0)
	check(not gull.sprite.flip_h,"left walking uses the original left-facing sequence")
	gull.climb = true
	for frame: int in range(25):
		gull.tick(1.0/60,0,0)
	check(gull.sprite.animation == &"climb" and is_equal_approx(gull.sprite.scale.x,0.18),"takeoff uses new wing frames at consistent scale")
	game.overlay.queue_redraw()
	await snapshot("gull-flight")
	gull.climb = false
	gull.position = Vector2(150,80)
	gull.state = BeachGull.State.STRIKE
	gull.direction = Vector2(1,1).normalized()
	gull.aim = Vector2(230,160)
	gull.dive_speed = 150
	gull.tick(0,0,0)
	check(gull.sprite.animation == &"dive" and is_equal_approx(gull.sprite.rotation,PI/4),"dive artwork follows swoop angle")
	game.overlay.queue_redraw()
	await snapshot("gull-dive")
	main.clear_game()
	await settle()
