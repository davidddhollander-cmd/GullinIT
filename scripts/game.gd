class_name BeachGame
extends Node2D
signal level_finished(result: Dictionary)
signal pause_requested
var level: Dictionary
var casual: bool = false
var elapsed: float = 0.0
var running: bool = false
var intro: float = 0.0
var camera_x: float = 160.0
var debug: bool = false
var player: BeachGull
var gulls: Array[BeachGull] = []
var pilots: Array[RivalPilot] = []
var wind: BeachWind = BeachWind.new()
var score: BeachScore = BeachScore.new()
var spawner: BeachSpawner = BeachSpawner.new()
var beach: BeachBackdrop
var scraps: BeachScraps
var stash_raids: BeachStashRaids
var actors: Node2D
var effects: BeachEffects
var input: GullInput
var camera: Camera2D
var overlay: BeachOverlay
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var last_near: float = -10.0
var training: bool = false
var lesson: int = 0
var training_clean_snatch: bool = false
var training_raid_started: bool = false
var training_reset_clock: float = 0.0
var pending_rivals: Array = []

func setup(definition: Dictionary, is_casual: bool, force_training: bool = false) -> void:
	level = definition
	Config.apply_level_world(level)
	training = bool(level.get("tutorial",false)) and (force_training or not bool(GameState.entry(1).get("training_complete",false)))
	lesson = 0 if force_training else clampi(int(GameState.entry(1).get("training_step",0)),0,4)
	casual = is_casual and not training
	rng.seed = int(level.seed) + 91
	wind.setup(level)
	wind.gust_warning.connect(_gust)
	beach = BeachBackdrop.new()
	beach.sunset = int(level.id) == 6
	add_child(beach)
	beach.setup(level.props,level.get("zones",[]),level.get("world",{}))
	scraps = BeachScraps.new()
	add_child(scraps)
	scraps.collected.connect(_scrap_collected)
	actors = Node2D.new()
	actors.y_sort_enabled = true
	add_child(actors)
	spawner.target_created.connect(_wire_target)
	spawner.setup(actors,level)
	player = BeachGull.new()
	player.digestion_enabled = true
	player.digestion.swallowed.connect(_swallowed)
	player.name = "Player"
	add_child(player)
	player.position = Vector2(Config.tuning.world.start_x,Config.tuning.world.start_y)
	player.setup_perches(level.props)
	_wire_sand(player)
	player.gull_stunned.connect(_stunned)
	player.ground_crashed.connect(_crashed)
	player.dive_started.connect(func() -> void: Audio.play("dive"))
	player.peck_started.connect(func() -> void:
		effects.message(player.beak(),"PECK!",BeachUI.GOLD)
		Audio.play("click")
	)
	gulls.append(player)
	stash_raids = BeachStashRaids.new()
	add_child(stash_raids)
	stash_raids.setup(self)
	stash_raids.collected.connect(func(at: Vector2, food_id: String, scrap: bool) -> void:
		if scrap:
			_scrap_collected(at,food_id)
		else:
			player.digestion.collect(food_id)
	)
	stash_raids.bag_collected.connect(func() -> void:
		if training and lesson == 3 and training_raid_started:
			_training_advance()
	)
	pending_rivals = level.rivals.duplicate(true)
	if not bool(level.get("rivals_after_snatch",false)):
		_release_rivals()
	effects = BeachEffects.new()
	add_child(effects)
	input = GullInput.new()
	add_child(input)
	input.touch_visible = DisplayServer.is_touchscreen_available() or bool(GameState.options.touch)
	camera = Camera2D.new()
	add_child(camera)
	camera.position = Vector2(160,90)
	var canvas: CanvasLayer = CanvasLayer.new()
	add_child(canvas)
	overlay = BeachOverlay.new()
	canvas.add_child(overlay)
	overlay.setup(self)
	intro = Config.tuning.world.intro_time
	if training:
		player.position = Vector2(70,player.ground_y())
		player.state = BeachGull.State.GROUNDED
		if lesson >= 2:
			player.position = Vector2(180,70)
			player.state = BeachGull.State.GLIDE
	Config.reloaded.connect(_reload)

func _release_rivals() -> void:
	for profile: Dictionary in pending_rivals:
		var rival: BeachGull = BeachGull.new()
		rival.rival = true
		add_child(rival)
		rival.position = Vector2(clampf(player.position.x+90,30,float(Config.tuning.world.width)-30),65)
		_wire_sand(rival)
		gulls.append(rival)
		var pilot: RivalPilot = RivalPilot.new()
		pilot.setup(rival,profile,rng)
		pilots.append(pilot)
	pending_rivals.clear()

func _wire_sand(gull: BeachGull) -> void:
	gull.sand_landed.connect(func(at: Vector2) -> void: effects.sand_puff(at))
	gull.sand_departed.connect(func(at: Vector2) -> void: effects.sand_puff(at, true))

func _wire_target(target: BeachTarget) -> void:
	target.snatched.connect(_snatched)
	target.cried.connect(_cry)
	target.whistled.connect(_whistle)
	target.food_knocked.connect(_food_knocked)

func _food_knocked(target: BeachTarget, food_id: String, at: Vector2, impulse: Vector2) -> void:
	stash_raids.add_knocked_food(target,food_id,at,impulse)
	effects.message(at,"DROPPED!",Color("ef725c"))
	effects.impact(at,false)

func _reload() -> void:
	level = Config.levels[int(level.id)-1]
	Config.apply_level_world(level)
	wind.base = level.wind.strength
	wind.gusts = level.wind.gusts
	wind.flip = level.wind.flip
	if wind.phase < 0:
		wind.direction = level.wind.dir
		wind.strength = wind.base
	for target: BeachTarget in spawner.targets:
		target.awareness_mult = float(level.awareness_mult) * target.encounter_awareness
	effects.message(player.position,"DATA RELOADED")

func _physics_process(delta: float) -> void:
	if intro > 0:
		intro -= delta
		if intro <= 0:
			running = true
			input.enabled = true
	if not running:
		overlay.queue_redraw()
		return
	effects.tick(delta)
	if effects.freeze > 0:
		return
	var step: float = delta * (float(Config.tuning.juice.slow_scale) if effects.slow > 0 else 1.0)
	spawner.reset_spacing()
	elapsed += step
	wind.tick(step)
	score.tick(step)
	input.update_player(player,camera_x)
	if input.touch_dive:
		input.touch_dive = false
		player.dive(wind.direction)
	if input.touch_peck:
		input.touch_peck = false
		_peck()
	player.tick(step,wind.direction,wind.strength)
	if player.state != BeachGull.State.STUNNED:
		player.digestion.tick(step,player.state == BeachGull.State.GROUNDED)
	scraps.tick(step,player)
	var claims: Dictionary = {}
	for pilot: RivalPilot in pilots:
		if is_instance_valid(pilot.target) and pilot.target.food:
			claims[pilot.target] = pilot
	for pilot: RivalPilot in pilots:
		pilot.tick(step,spawner.targets,claims,wind)
	for target: BeachTarget in spawner.targets.duplicate():
		target.tick(step,gulls)
	stash_raids.tick(step)
	for gull: BeachGull in gulls:
		if gull.visible:
			BeachCollisions.resolve(gull,spawner.targets,beach.props)
	_mugging()
	_near_misses()
	spawner.tick(step,elapsed)
	spawner.apply_spacing(step)
	camera_x = lerpf(camera_x,clampf(player.position.x,160,float(Config.tuning.world.width)-160),1-pow(1-float(Config.tuning.world.camera_lerp),step*60))
	camera.position = Vector2(roundf(camera_x),90)
	camera.offset = Vector2(sin(effects.clock*65),cos(effects.clock*73))*effects.shake
	beach.camera_x = camera_x
	beach.wind_dir = int(signf(player.wind_force))
	beach.strength = absf(player.wind_force)
	beach.tick(step)
	overlay.queue_redraw()
	if training:
		_training_tick(step)
	elif (casual and score.items >= int(Config.tuning.score.casual_items)) or (not casual and elapsed >= float(level.time_limit)):
		finish()

func _unhandled_input(event: InputEvent) -> void:
	if intro > 0 and event.is_pressed() and not event is InputEventMouseMotion:
		intro = 0
		running = true
		input.enabled = true
		get_viewport().set_input_as_handled()
		return
	if running and event.is_action_pressed("dive"):
		input.update_player(player,camera_x)
		player.dive(wind.direction)
	if running and event.is_action_pressed("peck") and not event.is_echo():
		_peck()
	if event.is_action_pressed("debug"):
		debug = not debug
	if event.is_action_pressed("reload"):
		if not Config.reload_data():
			effects.message(player.position,"RELOAD FAILED - CHECK JSON")

func _peck() -> void:
	if player.state == BeachGull.State.STRIKE:
		player.attempt_peck()
	elif player.state == BeachGull.State.GROUNDED:
		if training and lesson == 3 and stash_raids.nearby_stash() != null:
			training_raid_started = true
		stash_raids.peck()

func set_paused(value: bool) -> void:
	set_physics_process(not value)
	set_process_unhandled_input(not value)
	input.enabled = not value
	input.clear_touch()
	for gull: BeachGull in gulls:
		gull.sprite.speed_scale = 0 if value else 1
	for target: BeachTarget in spawner.targets:
		target.sprite.speed_scale = 0 if value else 1

func _snatched(target: BeachTarget, gull: BeachGull, risky: bool) -> void:
	if gull == player:
		if training and target.last_theft_direct and player.state == BeachGull.State.STRIKE:
			_training_snatch(target)
		player.digestion.collect(target.food_id,{"risky":risky,"upwind":player.upwind})
	else:
		for pilot: RivalPilot in pilots:
			if pilot.gull == gull:
				pilot.carried_food_id = target.food_id
				pilot.took_food(target.food_value())
				effects.message(gull.position,"MINE!",Color("ffc65c"))

func _award(value: int, risky: bool, upwind: bool, mugged: bool) -> void:
	var earned: int = score.snatch(value,risky,upwind,mugged)
	var quip: String = "MUGGED!" if mugged else str(Config.quips.snatch[rng.randi_range(0,Config.quips.snatch.size()-1)])
	effects.message(player.position-Vector2(0,15),"+%d %s" % [earned,quip],Color("ffc65c"))
	effects.impact(player.position,false)
	Audio.play("snatch",1+score.tier*0.08)

func _stunned() -> void:
	training_clean_snatch = false
	score.points = maxi(0,score.points-5)
	var dropped: Dictionary = player.digestion.drop_current()
	if not dropped.is_empty():
		stash_raids.items.append({"owner":null,"source":"dropped","food_id":dropped.id,"snack":dropped,"position":player.beak(),"velocity":Vector2(-player.facing*35,-55),"grounded":false,"age":0.0})
	score.stunned()
	effects.message(player.position,"RUDE.",Color("ef725c"))
	effects.impact(player.position,true)
	Audio.play("stun")

func _crashed() -> void:
	training_clean_snatch = false
	score.points = 0
	score.stunned()
	effects.message(player.position-Vector2(0,20),"TRY AGAIN - LESSON SAVED" if training else "CRASH! POINTS LOST",Color("ef725c"))
	effects.impact(player.position,true)
	Audio.play("stun")

func _scrap_collected(at: Vector2, food_id: String) -> void:
	player.digestion.collect(food_id,{"scrap":true})
	if training and lesson == 1 and player.state == BeachGull.State.GROUNDED:
		_training_advance()

func _swallowed(snack: Dictionary) -> void:
	var value: int = int(snack.get("value",Config.foods[snack.id].points))
	if snack.get("scrap",false):
		score.points += value
		effects.message(player.position,"+%d" % value,Color("ffc65c"))
		Audio.play("snatch")
	else:
		_award(value,snack.get("risky",false),snack.get("upwind",false),snack.get("mugged",false))
		if not pending_rivals.is_empty():
			_release_rivals()
			effects.message(player.position-Vector2(0,22),"GARY JOINS THE LUNCH RUSH!",BeachUI.GOLD)

func _cry(source: BeachTarget) -> void:
	if is_instance_valid(source.family_parent):
		source.family_parent.alert = 1

func _whistle(source: BeachTarget) -> void:
	for target: BeachTarget in spawner.targets:
		if target.position.distance_to(source.position) <= float(Config.tuning.world.whistle_radius):
			target.alert = 1
	effects.message(source.position-Vector2(0,38),"HEY!",Color("ef725c"))
	Audio.play("gust")

func _gust() -> void:
	effects.message(player.position-Vector2(0,20),"WIND TURNING!" if wind.flip else "GUST INCOMING!",Color("fff4da"))
	Audio.play("gust")

func _mugging() -> void:
	if player.state != BeachGull.State.STRIKE:
		return
	for pilot: RivalPilot in pilots:
		if pilot.carry_window > 0 and player.can_collect_food(pilot.carried_food_id) and BeachCollisions.segment_hits(player.previous_beak,player.sweep_beak,pilot.gull.position,Vector2(14,10)):
			var value: int = pilot.mug()
			if value > 0:
				player.digestion.collect(pilot.carried_food_id,{"value":value,"upwind":player.upwind,"mugged":true})
				return

func _near_misses() -> void:
	if not Config.tuning.juice.near_miss or elapsed-last_near < 1 or player.state != BeachGull.State.STRIKE:
		return
	for target: BeachTarget in spawner.targets:
		var distance: float = player.position.distance_to(target.food_position())
		if target.defense > 0 and int(target.info.danger) > 0 and distance > float(target.info.danger) and distance < float(target.info.danger)+float(Config.tuning.juice.near_distance):
			effects.slow = Config.tuning.juice.slow_time
			effects.message(player.position,"CLOSE!")
			last_near = elapsed

func finish() -> void:
	if not running:
		return
	running = false
	input.enabled = false
	input.clear_touch()
	var result: Dictionary = score.result(level,casual,elapsed)
	if training:
		if lesson < 5:
			running = true
			input.enabled = true
			return
		GameState.complete_training()
		result.training = true
		result.success = true
		result.stars = 0
		result.casual = false
	else:
		GameState.record(level.id,result.score,result.stars,elapsed if casual else -1.0)
	level_finished.emit(result)

func _training_snatch(_target: BeachTarget) -> void:
	if lesson in [2,4]:
		training_clean_snatch = true

func _training_advance() -> void:
	lesson += 1
	training_clean_snatch = false
	GameState.save_training_step(lesson)
	effects.message(player.position-Vector2(0,24),"LESSON COMPLETE",BeachUI.GOLD)
	if lesson >= 5:
		finish()

func _training_tick(delta: float) -> void:
	if lesson == 0 and player.climb and player.position.y < 110 and player.position.x > 100:
		_training_advance()
	elif lesson in [2,4] and training_clean_snatch and player.position.y < 100 and player.velocity.y <= 0 and player.state in [BeachGull.State.GLIDE,BeachGull.State.STRIKE]:
		_training_advance()
	# Lessons cannot run out of food. Restore only after all loose food clears,
	# so a missed peck never duplicates an item still lying on the beach.
	training_reset_clock += delta
	if training_reset_clock < 5.0:
		return
	training_reset_clock = 0.0
	for target: BeachTarget in spawner.targets:
		if target.kind == "sunbather" and target.stash_remaining == 0:
			var loose: bool = false
			for item: Dictionary in stash_raids.items:
				if item.get("owner") == target:
					loose = true
			if not loose:
				target.stash_remaining = int(Config.tuning.world.sunbather_stash_size)
		if target.kind == "kiosk_customer":
			if target.dropped_pending:
				# Reset abandoned practice food in place for another timed peck.
				if not target.dropped_item.is_empty():
					target.dropped_item.recovered = true
				target.dropped_pending = false
				target.dropped_item = {}
				target.drop_retrieve = false
			target.respawn = 0
			target.food = true
			target.food_sprite.show()

func training_text() -> String:
	var flap: String = "A" if input.gamepad else "SPACE / LEFT CLICK"
	var dive_key: String = "B" if input.gamepad else "SHIFT / RIGHT CLICK"
	var peck_key: String = "X" if input.gamepad else "E"
	if input.touch_visible:
		flap = "FLAP"
		dive_key = "DIVE"
		peck_key = "PECK"
	if player.crash_warning():
		return "PULL UP! AIM UP TO AVOID A CRASH\nHOLD %s TO RECOVER" % flap
	match lesson:
		0: return "HOLD %s TO FLY\nSTEER RIGHT: %s" % [flap,"DRAG" if input.touch_visible else ("LEFT STICK" if input.gamepad else "MOUSE / WASD")]
		1: return "RELEASE FLAP. AIM DOWN TO LAND\nWALK OVER A GOLDEN CRUMB"
		2:
			return "SNACK TAKEN! AIM UP AND CLIMB" if training_clean_snatch else "DIVE: %s\nTAP %s AT THE SNACK. THEN AIM UP" % [dive_key,peck_key]
		3: return "LAND BESIDE THE PICNIC BAG\nTAP %s THREE TIMES. COLLECT FOOD" % peck_key
		4: return "ONE MORE CLEAN SWOOP THEN ESCAPE\nCHOOSE A HELD SNACK YOURSELF"
	return "TRAINING COMPLETE!"

func training_target() -> Vector2:
	if lesson == 0:
		return Vector2(245,75)
	if lesson == 1:
		var nearest: Vector2 = Vector2(60,156)
		var distance: float = INF
		for crumb: Dictionary in scraps.crumbs:
			if float(crumb.wait) <= 0 and absf(float(crumb.x)-player.position.x) < distance:
				nearest = Vector2(float(crumb.x),156)
				distance = absf(nearest.x-player.position.x)
		return nearest
	if lesson in [2,3]:
		for target: BeachTarget in spawner.targets:
			if lesson == 2 and target.kind == "kiosk_customer":
				return target.food_position()
			if lesson == 3 and target.kind == "sunbather":
				return target.stash_position()
	return Vector2(-1000,-1000)
