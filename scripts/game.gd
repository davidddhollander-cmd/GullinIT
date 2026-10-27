class_name BeachGame
extends Node2D
signal level_finished(result: Dictionary)
signal pause_requested
var level: Dictionary
var casual: bool = false
var elapsed: float = 0.0
var running: bool = false
var intro: float = 0.0
var intro_dismissed_elapsed: float = -1.0
var camera_x: float = 160.0
var debug: bool = false
var player: BeachGull
var gulls: Array[BeachGull] = []
var pilots: Array[RivalPilot] = []
var wind: BeachWind = BeachWind.new()
var score: BeachScore = BeachScore.new()
var spawner: BeachSpawner = BeachSpawner.new()
var stalls: StallService = StallService.new()
var crabs: CrabPopulation
var dog: OffLeadDog
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
var quests: BeachQuests = BeachQuests.new()
var feathers_earned: int = 0
var mugged_rivals: Dictionary = {}
const TRAINING_LESSONS: int = 7
const BIN_LESSON: int = 4
const WHEELIE_LESSON: int = 5
const FINAL_LESSON: int = 6
var training_took_off: bool = false
var training_clean_snatch: bool = false
var training_raid_started: bool = false
var training_reset_clock: float = 0.0
var pending_rivals: Array = []
var taunt_wait: float = -1.0
var taunt_rival: String = ""
var taunt_text: String = ""
var crashes: int = 0
# Dive outcomes for level_end analytics (player feedback F1: are dives overshooting?).
var dive_stats: Dictionary = {"dives":0,"dive_pecks":0,"dive_snatches":0,"dive_overshoots":0}
var dive_live: bool = false
var dive_hit: bool = false
var dive_target: BeachTarget = null
var dive_side: float = 0.0
var first_steal_sent: bool = false
var end_tracked: bool = false
var lesson_started: float = 0.0
var perk_id: String = ""
var bullet_meter: float = 0.0
var slowmo_end_msec: int = -1 ## real-clock end of bullet time (-1 = off); Engine.time_scale slows delta, so never count it
const SCREECH_HOLD_TIME: float = 0.24
var peck_hold_pending: bool = false
var peck_hold_elapsed: float = 0.0
var screech_audio: AudioStreamPlayer
var brash: BeachBrash = BeachBrash.new()
var peck_hold_touch: bool = false
# Level 2's first-play herring lesson: perch, screech, Gang Call, grab. The level clock is paused meanwhile.
var screech_lesson: bool = false
var screech_step: int = 0
var screech_clock: float = 0.0
var screech_snacks: int = 0
const SCREECH_STEPS: int = 4

func setup(definition: Dictionary, is_casual: bool, force_training: bool = false) -> void:
	level = definition
	Config.apply_level_world(level)
	training = bool(level.get("tutorial",false)) and (force_training or not bool(GameState.entry(1).get("training_complete",false)))
	lesson = 0 if force_training else clampi(int(GameState.entry(1).get("training_step",0)),0,TRAINING_LESSONS-1)
	casual = is_casual and not training
	if not training or (bool(level.get("quests_on_replay_only",false)) and bool(GameState.entry(1).get("training_complete",false))):
		var quest_rng: RandomNumberGenerator = RandomNumberGenerator.new()
		quest_rng.randomize()
		quests.setup(level,quest_rng)
	quests.quest_completed.connect(_quest_completed)
	rng.seed = int(level.seed) + 91
	wind.setup(level)
	wind.gust_warning.connect(_gust)
	beach = BeachBackdrop.new()
	beach.sunset = level.has("sunset")
	beach.wind_dir = wind.direction
	beach.strength = wind.strength
	add_child(beach)
	beach.setup(level.props,level.get("zones",[]),level.get("world",{}))
	if _twist() == "wind_intro":
		for flag_x: Variant in level.twist.get("flags",[]):
			beach.wind_flags.append(int(flag_x))
	scraps = BeachScraps.new()
	add_child(scraps)
	scraps.collected.connect(_scrap_collected)
	actors = Node2D.new()
	actors.y_sort_enabled = true
	add_child(actors)
	spawner.target_created.connect(_wire_target)
	spawner.setup(actors,level)
	if level.spawns.any(func(spawn: Dictionary) -> bool: return spawn.type == "off_lead_dog"):
		for spawn: Dictionary in level.spawns:
			if spawn.type == "off_lead_dog":
				dog = OffLeadDog.new()
				actors.add_child(dog)
				dog.setup(float(spawn.x),spawn.home,int(level.seed)+5)
				dog.barked.connect(func() -> void:
					effects.message(dog.position-Vector2(0,24),"WOOF!",BeachUI.GOLD)
					Audio.play("click")
				)
				dog.caught.connect(func() -> void:
					effects.message(dog.position-Vector2(0,24),"GOTCHA!",Color("ef725c"))
					_quest_event("dog_caught")
				)
				dog.rival_caught.connect(_dog_caught_rival)
				dog.outrun.connect(func() -> void:
					effects.message(player.position-Vector2(0,18),"OUTRUN!",BeachUI.GOLD)
					Audio.play("snatch")
					_quest_event("dog_outrun")
				)
				break
	stalls.setup(beach,spawner)
	stalls.portion_created.connect(_wire_target)
	crabs = CrabPopulation.new()
	add_child(crabs)
	crabs.setup(level,beach.props,spawner)
	crabs.crab_created.connect(_wire_target)
	player = BeachGull.new()
	player.species = str(level.get("player_species",GameState.chosen_gull()))
	player.apply_species_stats()
	player.digestion_enabled = true
	_apply_perk()
	player.digestion.swallowed.connect(_swallowed)
	player.name = "Player"
	# Flight and loose food stay in front of the stall's complete scenery layer.
	player.z_index = 4
	add_child(player)
	player.position = Vector2(Config.tuning.world.start_x,Config.tuning.world.start_y)
	brash.game = self
	add_child(brash)
	screech_lesson = level.has("screech_lesson") and not training and player.species == "herring" and not bool(GameState.entry(int(level.id)).get("screech_lesson_complete",false))
	player.setup_perches(level.props)
	player.add_sign_perches(beach.sign_layouts())
	_wire_sand(player)
	player.gull_stunned.connect(_stunned)
	player.ground_crashed.connect(_crashed)
	player.dive_started.connect(func() -> void:
		Audio.play("dive")
		_dive_began()
	)
	player.stun_ignored.connect(func() -> void:
		effects.message(player.position,"SKULL!",BeachUI.GOLD)
		Audio.play("click")
	)
	player.peck_started.connect(func() -> void:
		dive_stats.dive_pecks += 1
		effects.message(player.beak(),"PECK!",BeachUI.GOLD)
		Audio.play("click")
	)
	gulls.append(player)
	stash_raids = BeachStashRaids.new()
	stash_raids.z_index = 4
	add_child(stash_raids)
	stash_raids.setup(self)
	stash_raids.collected.connect(func(at: Vector2, food_id: String, scrap: bool) -> void:
		if scrap:
			_scrap_collected(at,food_id)
		else:
			effects.snatch_contact(at,player.velocity,false)
			Audio.play("snatch",1+score.tier*0.08)
			player.digestion.collect(food_id)
	)
	stash_raids.bag_collected.connect(func() -> void:
		if training and lesson == 3 and training_raid_started:
			_training_advance()
	)
	stash_raids.bin_emptied.connect(func(_bin_type: String) -> void: _quest_event("bin_emptied"))
	stash_raids.bin_opened.connect(func(bin_type: String) -> void:
		if not training:
			return
		if (lesson == BIN_LESSON and bin_type != BeachBackdrop.WHEELIE_BIN_TYPE) or (lesson == WHEELIE_LESSON and bin_type == BeachBackdrop.WHEELIE_BIN_TYPE):
			_training_advance()
	)
	pending_rivals = level.rivals.duplicate(true)
	var held: bool = bool(level.get("rivals_after_snatch",false))
	var later: Array = pending_rivals.filter(func(p: Dictionary) -> bool: return held or bool(p.get("after_snatch",false)))
	pending_rivals = pending_rivals.filter(func(p: Dictionary) -> bool: return p not in later)
	_release_rivals()
	pending_rivals = later
	effects = BeachEffects.new()
	effects.z_index = 5
	add_child(effects)
	input = GullInput.new()
	input.game = self
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
	intro_dismissed_elapsed = -1.0
	if training:
		player.position = Vector2(70,player.ground_y())
		player.state = BeachGull.State.GROUNDED
		if lesson >= 2:
			player.position = Vector2(180,70)
			player.state = BeachGull.State.GLIDE
	Config.reloaded.connect(_reload)

func _twist() -> String:
	return str(level.get("twist",{}).get("id",""))

# Level 2 teaches upwind scoring once per save, the first time the gull is airborne.
func _wind_tip() -> void:
	if _twist() != "wind_intro" or "upwind" in GameState.options.tips or player.state == BeachGull.State.GROUNDED:
		return
	GameState.options.tips.append("upwind")
	GameState.save_progress()
	# Fixed mid-screen band: clear of the top bar, hint and goal box.
	effects.message(Vector2(camera_x,84.0),"FLY INTO THE WIND = UPWIND +%d%%" % roundi(float(Config.tuning.score.upwind)*100.0),BeachUI.GOLD,float(Config.tuning.juice.tip_time),0.0)

# Shows a released rival's taunt after a delay, never while the score banner is up, below the rival so the tag stays clear.
func _rival_taunt(step: float) -> void:
	if taunt_wait < 0.0 or pilots.is_empty():
		return
	taunt_wait = maxf(0.0,taunt_wait-step)
	if taunt_wait > 0.0 or overlay.score_announcement.visible or effects.texts.any(func(t: Dictionary) -> bool: return t.has("fade_time")):
		return
	taunt_wait = -1.0
	var from: Vector2 = pilots[0].gull.position
	for pilot: RivalPilot in pilots:
		if pilot.gull.rival_name == taunt_rival:
			from = pilot.gull.position
	var half: float = taunt_text.length()*4.2
	var at: Vector2 = Vector2(clampf(from.x,camera_x-160.0+half,camera_x+160.0-half),from.y+22.0)
	effects.message(at,taunt_text,BeachUI.GOLD,float(Config.tuning.juice.taunt_time),0.0)

func _release_rivals() -> void:
	for profile: Dictionary in pending_rivals:
		var rival: BeachGull = BeachGull.new()
		rival.z_index = 4
		rival.rival = true
		add_child(rival)
		rival.position = Vector2(clampf(player.position.x+90,30,float(Config.tuning.world.width)-30),65)
		_wire_sand(rival)
		gulls.append(rival)
		var pilot: RivalPilot = RivalPilot.new()
		pilot.setup(rival,profile,rng)
		pilot.game = self
		rival.setup_perches(level.props)
		rival.perch_surfaces = rival.perch_surfaces.filter(func(surface: Dictionary) -> bool: return str(surface.prop_type) == BeachBackdrop.WHEELIE_BIN_TYPE)
		# Match each frame to distinct feathers within this round.
		var used_colours: Array[Color] = []
		for existing: RivalPilot in pilots:
			used_colours.append(existing.gull.rival_tint)
		if rival.rival_tint in used_colours:
			for colour: Color in RivalPilot.COLOURS:
				if colour not in used_colours:
					rival.rival_tint = colour
					break
			rival.refresh_art()
		pilots.append(pilot)
	pending_rivals.clear()
	if is_instance_valid(overlay):
		overlay.sync_rival_scores()

func _wire_sand(gull: BeachGull) -> void:
	gull.sand_landed.connect(func(at: Vector2) -> void: effects.sand_puff(at))
	gull.sand_departed.connect(func(at: Vector2) -> void: effects.sand_puff(at, true))
	gull.tumble_feathers.connect(func(at: Vector2, impulse: Vector2, amount: int) -> void: effects.feather_burst(at,impulse,amount))

func _wire_target(target: BeachTarget) -> void:
	if stalls.spawner != null:
		stalls.bind(target)
	target.snatched.connect(_snatched)
	target.cried.connect(_cry)
	target.whistled.connect(_whistle)
	target.food_knocked.connect(_food_knocked)

func _food_knocked(target: BeachTarget, food_id: String, at: Vector2, impulse: Vector2) -> void:
	stash_raids.add_knocked_food(target,food_id,at,impulse)
	effects.peck_contact(at,impulse,0.55,"glance")
	effects.food_crumble(at,impulse)
	effects.message(at-Vector2(0,18),"DROPPED!",Color("ef725c"))
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

func _exit_tree() -> void:
	end_slowmo()
	_stop_screech(false)

func perk_value(key: String, fallback: Variant) -> Variant:
	return Config.perks.perks.get(perk_id,{}).get(key,fallback)

func _apply_perk() -> void:
	perk_id = GameState.equipped_perk()
	player.digestion.capacity = int(perk_value("stomach",4))
	player.dive_mult *= float(perk_value("dive_mult",1.0))
	player.stun_shield = int(perk_value("ignore_stuns",0))
	stalls.handover_mult = float(perk_value("handover_window_mult",1.0))

## Keen eye: the most valuable food on offer that a dive could actually take.
func keen_target() -> BeachTarget:
	if perk_id != "keen_eye":
		return null
	var best: BeachTarget = null
	for target: BeachTarget in spawner.targets + stalls.portions:
		if not snatchable(target):
			continue
		if best == null or target.food_value() > best.food_value():
			best = target
	return best

func snatchable(target: BeachTarget) -> bool:
	return target.food and not target.leaving and target.kind != "sunbather" and not (target.info.twist == "shield" and target.defense > 0)

## Touch aim assist: the snatchable food nearest the aimed direction, within range and cone.
func assist_target(origin: Vector2, dir: Vector2, max_range: float, max_angle: float) -> BeachTarget:
	var best: BeachTarget = null
	var best_angle: float = max_angle
	for target: BeachTarget in spawner.targets + stalls.portions:
		if not snatchable(target):
			continue
		var offset: Vector2 = target.food_position() - origin
		if offset.length() > max_range:
			continue
		var angle: float = absf(dir.angle_to(offset))
		if angle <= best_angle:
			best = target
			best_angle = angle
	return best

func slowmo_ready() -> bool:
	return perk_id == "bullet_time" and slowmo_end_msec < 0 and bullet_meter >= 1.0

func slowmo_active() -> bool:
	return slowmo_end_msec >= 0

func start_slowmo() -> void:
	if running and perk_id != "bullet_time" and brash.fire():
		input.slowmo_ready = false
		return
	if not running or not slowmo_ready():
		return
	slowmo_end_msec = Time.get_ticks_msec() + roundi(float(perk_value("duration",2.5))*1000.0)
	Engine.time_scale = float(perk_value("time_scale",0.5))
	input.slowmo_ready = false

func end_slowmo() -> void:
	if slowmo_end_msec >= 0:
		slowmo_end_msec = -1
		bullet_meter = 0.0
	Engine.time_scale = 1.0

func _slowmo_tick() -> void:
	if slowmo_end_msec >= 0 and Time.get_ticks_msec() >= slowmo_end_msec:
		end_slowmo()
	input.slowmo_ready = slowmo_ready()

func _physics_process(delta: float) -> void:
	_slowmo_tick()
	if intro > 0 and int(level.id) != 1:
		intro -= delta
		if intro <= 0:
			dismiss_intro()
	if intro_dismissed_elapsed >= 0.0 and running:
		intro_dismissed_elapsed += delta
	if not running:
		overlay.queue_redraw()
		return
	effects.tick(delta)
	if effects.freeze > 0:
		return
	var step: float = delta * (float(Config.tuning.juice.slow_scale) if effects.slow > 0 else 1.0)
	spawner.reset_spacing()
	if not screech_lesson:
		elapsed += step
	wind.tick(step)
	score.tick(step)
	input.update_player(player,camera_x)
	_advance_screech_hold(step)
	if input.touch_dive:
		input.touch_dive = false
		player.dive(wind.direction)
	if input.touch_peck:
		input.touch_peck = false
		peck_hold_touch = _peck_pressed()
	if peck_hold_touch and not input.peck_held:
		peck_hold_touch = false
		_peck_released()
	if input.touch_slowmo:
		input.touch_slowmo = false
		start_slowmo()
	player.tick(step,wind.direction,wind.strength)
	brash.tick(step)
	if perk_id != "bullet_time":
		input.slowmo_ready = brash.is_full()
	_dive_tick()
	_wind_tip()
	if dog != null:
		var rival_gulls: Array[BeachGull] = []
		for pilot: RivalPilot in pilots:
			rival_gulls.append(pilot.gull)
		dog.tick(step,player,rival_gulls)
	_rival_taunt(step)
	if player.state != BeachGull.State.STUNNED:
		player.digestion.tick(step,player.state == BeachGull.State.GROUNDED)
	scraps.tick(step,player)
	crabs.tick(step,camera_x,not training,gulls)
	var food_targets: Array[BeachTarget] = stalls.portions.duplicate()
	food_targets.append_array(spawner.targets)
	var claims: Dictionary = {}
	for pilot: RivalPilot in pilots:
		if is_instance_valid(pilot.target) and pilot.target.food:
			claims[pilot.target] = pilot
	var carriers: Array[BeachGull] = []
	for pilot: RivalPilot in pilots:
		if pilot.carry_window > 0.0 and pilot.carried > 0 and pilot.gull.state != BeachGull.State.STUNNED:
			carriers.append(pilot.gull)
	if not player.digestion.snacks.is_empty() and player.state != BeachGull.State.STUNNED and player.invulnerable <= 0.0:
		carriers.append(player)
	for pilot: RivalPilot in pilots:
		pilot.prey = carriers
		pilot.tick(step,food_targets,claims,wind,player.position)
	for target: BeachTarget in spawner.targets.duplicate():
		target.tick(step,gulls)
	stalls.tick(step)
	food_targets = stalls.portions.duplicate()
	food_targets.append_array(spawner.targets)
	stash_raids.tick(step)
	for gull: BeachGull in gulls:
		if gull.visible:
			var available: Array[BeachTarget] = food_targets
			if gull==player:
				available = food_targets.duplicate()
				available.append_array(crabs.targets)
			BeachCollisions.resolve(gull,available,beach.props)
	if level.has("boss"):
		BeachBoss.shove(self)
	BeachBoss.shove_player(self)
	_mugging()
	_rival_mugging()
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
	elif screech_lesson:
		_screech_lesson_tick(step)
	elif (casual and score.items >= int(Config.tuning.score.casual_items)) or (not casual and elapsed >= float(level.time_limit)):
		finish()

func mode_name() -> String:
	return "training" if training else ("practice" if casual else "arcade")

func track(event: String, props: Dictionary = {}) -> void:
	Analytics.input_kind = "touch" if input.touch_visible else ("gamepad" if input.gamepad else "keyboard_mouse")
	Analytics.track(event, props)

# Once per run; "quit" is reported by main when a started level is abandoned.
func track_end(outcome: String, result: Dictionary = {}) -> void:
	if end_tracked or intro_dismissed_elapsed < 0.0:
		return
	end_tracked = true
	track("level_end", {"level": int(level.id), "mode": mode_name(), "score": int(result.get("score", score.points)), "stars": int(result.get("stars", 0)), "seconds": snappedf(elapsed, 0.1), "crashes": crashes, "outcome": outcome}.merged(dive_stats))

func _dive_began() -> void:
	dive_stats.dives += 1
	dive_live = true
	dive_hit = false
	# ponytail: the intended snack is guessed as the nearest one along the dive line (the touch-assist cone); use real intent if an aim marker lands.
	var t: Dictionary = Config.tuning.touch
	dive_target = assist_target(player.position,player.direction,float(t.assist_range),deg_to_rad(float(t.assist_angle)))
	dive_side = signf(dive_target.food_position().x-player.position.x) if dive_target != null else 0.0

# A dive ends when the gull leaves WINDUP/STRIKE; ending past the lined-up snack without a snatch is an overshoot.
func _dive_tick() -> void:
	if not dive_live or player.state in [BeachGull.State.WINDUP,BeachGull.State.STRIKE]:
		return
	dive_live = false
	if not dive_hit and dive_side != 0.0 and is_instance_valid(dive_target) and dive_target.food and signf(dive_target.food_position().x-player.position.x) != dive_side:
		dive_stats.dive_overshoots += 1

func dismiss_intro() -> void:
	lesson_started = elapsed
	track("level_start", {"level": int(level.id), "mode": mode_name()})
	intro = 0.0
	intro_dismissed_elapsed = 0.0
	input.clear_touch()
	running = true
	input.enabled = true
	overlay.intro_panel.hide()

func _unhandled_input(event: InputEvent) -> void:
	if intro > 0:
		if int(level.id) != 1 and event.is_pressed() and not event is InputEventMouseMotion:
			dismiss_intro()
			get_viewport().set_input_as_handled()
		return
	if running and event.is_action_pressed("dive"):
		input.update_player(player,camera_x)
		player.dive(wind.direction)
	if event.is_action_pressed("slowmo") and not event.is_echo():
		start_slowmo()
	if running and event.is_action_pressed("peck") and not event.is_echo():
		if event is InputEventKey or event is InputEventJoypadButton:
			_peck_pressed()
		else:
			_peck()
	elif (event is InputEventKey or event is InputEventJoypadButton) and event.is_action_released("peck") and peck_hold_pending and not peck_hold_touch:
		_peck_released()
	if event.is_action_pressed("debug"):
		debug = not debug
	if event.is_action_pressed("reload"):
		if not Config.reload_data():
			effects.message(player.position,"RELOAD FAILED - CHECK JSON")

## A peck press that may become a screech hold; returns true when it is waiting to find out.
func _peck_pressed() -> bool:
	if _can_screech():
		peck_hold_pending = true
		peck_hold_elapsed = 0.0
		player.aim = player.position
		return true
	_peck()
	return false

func _peck_released() -> void:
	peck_hold_pending = false
	if player.screech_held:
		_stop_screech()
	elif running:
		_peck()

func _peck() -> void:
	if player.state == BeachGull.State.STRIKE:
		player.attempt_peck()
	elif player.state == BeachGull.State.GROUNDED:
		if crabs.peck(player) or crabs.peck_attempted:
			player.show_ground_peck()
			return
		if training and lesson == 3 and stash_raids.nearby_stash() != null:
			training_raid_started = true
		if stash_raids.peck():
			player.show_ground_peck()

func _can_screech() -> bool:
	return player != null and player.species == "herring" and player.detailed_art and player.state == BeachGull.State.GROUNDED and not player.climb and absf(player.velocity.x) <= 1.0 and Input.get_vector("aim_left","aim_right","aim_up","aim_down").length() <= 0.15 and (input == null or input.touch_stick().length() <= 0.15)

func _advance_screech_hold(delta: float) -> void:
	if not peck_hold_pending:
		return
	if not _can_screech():
		if player.screech_held:
			_stop_screech(false)
		else:
			_peck()
		peck_hold_pending = false
		return
	# Ground movement follows aim; pin it while E is held so mouse position
	# cannot make an otherwise stationary gull walk out of its call.
	player.aim = player.position
	if player.screech_held:
		brash.screech_tick(delta)
		if not is_instance_valid(screech_audio) or not screech_audio.playing:
			screech_audio = Audio.play("screech_long" if rng.randf() < 0.6 else "screech_short",rng.randf_range(0.94,1.06),-6.0)
		return
	peck_hold_elapsed += delta
	if peck_hold_elapsed >= SCREECH_HOLD_TIME and player.start_screech():
		screech_audio = Audio.play("screech_long",1.0,-6.0)
		brash.fire()

func _stop_screech(recover: bool = true) -> void:
	brash.screech_ended()
	if is_instance_valid(player):
		player.stop_screech(recover)
	if is_instance_valid(screech_audio):
		screech_audio.stop()
		screech_audio.queue_free()
	screech_audio = null

func set_paused(value: bool) -> void:
	if value:
		end_slowmo()
		peck_hold_pending = false
		peck_hold_touch = false
		_stop_screech(false)
	set_physics_process(not value)
	set_process_unhandled_input(not value)
	input.enabled = not value and running and intro <= 0
	input.clear_touch()
	for gull: BeachGull in gulls:
		gull.sprite.speed_scale = 0 if value else 1
	for target: BeachTarget in spawner.targets:
		target.sprite.speed_scale = 0 if value else 1
	if dog != null:
		dog.paused = value

func _snatched(target: BeachTarget, gull: BeachGull, risky: bool) -> void:
	if gull == player:
		var contact_at: Vector2 = target.food_position()
		if training and target.last_theft_direct and player.state == BeachGull.State.STRIKE:
			_training_snatch(target)
		var handover: bool = target.last_theft_handover and target.last_theft_direct and (player.state == BeachGull.State.STRIKE or player.sweep_state == BeachGull.State.STRIKE)
		if target.last_theft_biting and target.last_theft_direct and player.state == BeachGull.State.STRIKE:
			_quest_event("mid_air_bite")
		if dive_live and target.last_theft_direct and not dive_hit:
			dive_hit = true
			dive_stats.dive_snatches += 1
		player.digestion.collect(target.food_id,{"risky":risky,"upwind":player.upwind,"handover":handover})
		if target.last_theft_direct:
			brash.add(float(Config.tuning.brash.snatch)+(float(Config.tuning.brash.handover) if handover else 0.0))
		effects.snatch_contact(contact_at,gull.velocity,handover)
		Audio.play("snatch",1+score.tier*0.08)
		if handover:
			effects.message(target.food_position()-Vector2(0,12),"COUNTER +%d%%!" % roundi(float(Config.tuning.score.handover)*100),BeachUI.GOLD)
	else:
		for pilot: RivalPilot in pilots:
			if pilot.gull == gull:
				pilot.carried_food_id = target.food_id
				pilot.took_food(target.food_value())
				effects.message(gull.position,"MINE!",Color("ffc65c"))

func _award(value: int, risky: bool, upwind: bool, mugged: bool, handover: bool = false) -> int:
	var earned: int = score.snatch(value,risky,upwind,mugged,handover)
	var quip: String = "COUNTER!" if handover else ("MUGGED!" if mugged else str(Config.quips.snatch[rng.randi_range(0,Config.quips.snatch.size()-1)]))
	effects.score_message(player.position-Vector2(0,15),"+%d %s" % [earned,quip],Color("ffc65c"))
	return earned

func _stunned() -> void:
	training_clean_snatch = false
	brash.add(float(Config.tuning.brash.stun))
	score.points = maxi(0,score.points-5)
	var dropped: Dictionary = player.digestion.drop_current()
	if not dropped.is_empty():
		stash_raids.items.append({"owner":null,"source":"dropped","food_id":dropped.id,"snack":dropped,"position":player.beak(),"velocity":Vector2(-player.facing*35,-55),"grounded":false,"age":0.0})
	score.stunned()
	effects.message(player.position,"RUDE.",Color("ef725c"))
	effects.impact(player.position,true)
	Audio.play("stun")

func _dog_caught_rival(rival: BeachGull) -> void:
	effects.message(dog.position-Vector2(0,24),"GOTCHA!",Color("ef725c"))
	for pilot: RivalPilot in pilots:
		if pilot.gull == rival:
			var food_id: String = pilot.carried_food_id
			if pilot.mug(dog.position) > 0:
				stash_raids.items.append({"owner":null,"source":"dropped","food_id":food_id,"position":rival.position-Vector2(0,10),"velocity":Vector2(-rival.facing*35,-55),"grounded":false,"age":0.0})

func _crashed() -> void:
	crashes += 1
	training_clean_snatch = false
	score.points = ceili(score.points * 0.5)
	score.stunned()
	effects.message(player.position-Vector2(0,20),"TRY AGAIN - LESSON SAVED" if training else "CRASH! POINTS LOST",Color("ef725c"))
	effects.impact(player.position,true)
	Audio.play("stun")

func _scrap_collected(at: Vector2, food_id: String) -> void:
	player.digestion.collect(food_id,{"scrap":true})
	if training and lesson == 1 and player.state == BeachGull.State.GROUNDED:
		_training_advance()

func _quest_event(event: String, data: Dictionary = {}) -> void:
	if running:
		quests.record(event,data)

func _quest_completed(quest: Dictionary) -> void:
	score.points += int(quest.bonus)
	effects.message(player.position-Vector2(0,22),"QUEST! +%d" % int(quest.bonus),BeachUI.GOLD)
	Audio.play("snatch")
	if GameState.complete_quest(int(level.id),str(quest.id)):
		feathers_earned += 1

func _swallowed(snack: Dictionary) -> void:
	_quest_event("swallowed",{"food":snack.id,"direct":not snack.get("scrap",false) and not snack.get("mugged",false),"mugged_from":snack.get("mugged_from",""),"handover":snack.get("handover",false)})
	var value: int = int(snack.get("value",Config.foods[snack.id].points))
	if snack.get("scrap",false):
		score.points += value
		effects.score_message(player.position,"+%d" % value,Color("ffc65c"))
		Audio.play("snatch")
		overlay.show_score_announcement(str(snack.id),value)
	else:
		if not first_steal_sent:
			first_steal_sent = true
			track("first_steal", {"level": int(level.id), "seconds": snappedf(elapsed, 0.1)})
		if perk_id == "bullet_time" and not snack.get("mugged",false) and not slowmo_active():
			bullet_meter = minf(1.0,bullet_meter+float(perk_value("fill_per_clean_snatch",0.34)))
		var earned: int = _award(value,snack.get("risky",false),snack.get("upwind",false),snack.get("mugged",false),snack.get("handover",false))
		overlay.show_score_announcement(str(snack.id),earned)
		if not pending_rivals.is_empty():
			var taunter: Dictionary = {}
			for profile: Dictionary in pending_rivals:
				if profile.has("taunt"):
					taunter = profile
			_release_rivals()
			if not taunter.is_empty():
				taunt_rival = str(taunter.name)
				taunt_text = str(taunter.taunt)
				taunt_wait = float(Config.tuning.juice.taunt_delay)
			else:
				effects.message(player.position-Vector2(0,22),"GARY JOINS THE LUNCH RUSH!",BeachUI.GOLD)

func _cry(source: BeachTarget) -> void:
	if source.kind == "toddler":
		_quest_event("toddler_cried")
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
			if BeachBoss.blocks_mug(self,pilot,player):
				return
			var value: int = pilot.mug(player.position)
			if value > 0:
				if not mugged_rivals.has(pilot.gull.rival_name):
					mugged_rivals[pilot.gull.rival_name] = true
					_quest_event("rival_mugged_distinct")
				effects.snatch_contact(pilot.gull.position,player.velocity,false)
				Audio.play("snatch",1+score.tier*0.08)
				player.digestion.collect(pilot.carried_food_id,{"value":value,"upwind":player.upwind,"mugged":true,"mugged_from":pilot.gull.rival_name})
				brash.add(float(Config.tuning.brash.mug))
				return

## Rivals mug anyone holding food: other rivals in their grace window, or the player's unswallowed snack.
func _rival_mugging() -> void:
	for attacker: RivalPilot in pilots:
		var beak: BeachGull = attacker.gull
		if beak.state != BeachGull.State.STRIKE or attacker.leave > 0.0:
			continue
		for victim: RivalPilot in pilots:
			if victim != attacker and victim.carry_window > 0.0 and BeachCollisions.segment_hits(beak.previous_beak,beak.sweep_beak,victim.gull.position,Vector2(14,10)):
				if BeachBoss.blocks_mug(self,victim,beak):
					break
				var value: int = victim.mug(beak.position)
				if value > 0:
					attacker.carried_food_id = victim.carried_food_id
					attacker.took_food(value)
					attacker.mugs += 1
					effects.message(beak.position,"MUGGED!",Color("ffc65c"))
					break
		if attacker.leave > 0.0:
			continue
		if not player.digestion.snacks.is_empty() and player.state != BeachGull.State.STUNNED and player.invulnerable <= 0.0 and BeachCollisions.segment_hits(beak.previous_beak,beak.sweep_beak,player.position,Vector2(14,10)):
			# The food goes into the rival's beak, not onto the sand: take it before the stun can drop it.
			var taken: Dictionary = player.digestion.drop_current()
			attacker.carried_food_id = str(taken.id)
			attacker.took_food(int(taken.get("value",Config.foods[taken.id].points)))
			attacker.mugs += 1
			player.stun(Config.tuning.rival.mug_stun,beak.position)
			effects.message(player.position-Vector2(0,20),"MUGGED BY %s!" % attacker.gull.rival_name.to_upper(),Color("ef725c"))

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
	peck_hold_pending = false
	_stop_screech(false)
	var boss: bool = level.has("boss") and not casual
	if boss:
		BeachBoss.conclude(self)
	running = false
	end_slowmo()
	input.enabled = false
	input.clear_touch()
	var result: Dictionary = score.result(level,casual,elapsed)
	result.quests = quests.quests.map(func(quest: Dictionary) -> Dictionary: return {"text":quest.text,"done":quest.done,"progress":quest.progress,"count":quest.count,"bonus":quest.bonus})
	result.quest_bonus = quests.bonus_points()
	result.base = int(result.base) - int(result.quest_bonus)
	result.feathers_earned = feathers_earned
	if boss:
		BeachBoss.verdict(self,result)
	if training:
		if lesson < TRAINING_LESSONS:
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
	if lesson in [2,FINAL_LESSON]:
		training_clean_snatch = true

func _training_advance() -> void:
	lesson += 1
	training_clean_snatch = false
	if lesson in [BIN_LESSON,WHEELIE_LESSON]:
		# A bin explored earlier must still support a complete practice attempt.
		for bin: Dictionary in stash_raids.bins:
			bin.remaining = int(bin.get("capacity",Config.tuning.world.bin_stash_size))
			bin.pecks = 0
	track("lesson_complete", {"lesson": lesson, "seconds": snappedf(elapsed - lesson_started, 0.1)})
	lesson_started = elapsed
	GameState.save_training_step(lesson)
	effects.message(player.position-Vector2(0,24),"LESSON COMPLETE",BeachUI.GOLD)
	if lesson >= TRAINING_LESSONS:
		finish()

func _training_tick(delta: float) -> void:
	if lesson == 0:
		# Remember takeoff even when the player releases flap before steering.
		if player.state == BeachGull.State.GLIDE and player.position.y < 110:
			training_took_off = true
		if training_took_off and player.state == BeachGull.State.GLIDE and player.position.x > float(level.world.start_x) + 30:
			_training_advance()
	elif lesson in [2,FINAL_LESSON] and training_clean_snatch and player.position.y < 100 and player.velocity.y <= 0 and player.state in [BeachGull.State.GLIDE,BeachGull.State.STRIKE]:
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
		0:
			if training_took_off:
				return "STEER RIGHT: %s\nFLY TOWARD THE GOLDEN RING" % ("DRAG THUMB" if input.touch_visible else ("LEFT STICK" if input.gamepad else "MOUSE / WASD"))
			return "HOLD %s TO TAKE OFF\nTHEN STEER RIGHT TOWARD THE RING" % flap
		1: return "RELEASE FLAP. AIM DOWN TO LAND\nWALK OVER A GOLDEN CRUMB"
		2:
			if training_clean_snatch:
				return "SNACK TAKEN! AIM UP AND CLIMB"
			if player.state == BeachGull.State.STRIKE and not player.peck_used:
				return "NOW! TAP %s AT THE SNACK" % peck_key
			return "DIVE: %s\nTAP %s AT THE SNACK. THEN AIM UP" % [dive_key,peck_key]
		3: return "LAND BESIDE THE PICNIC BAG\nTAP %s THREE TIMES. COLLECT FOOD" % peck_key
		4: return "LAND BY THE BIN. TAP %s %d TIMES\nSCRAPS ARE FOOD. WRAPPERS ARE NOT" % [peck_key,int(Config.tuning.world.bin_pecks)]
		5:
			var wheelie: Dictionary = training_bin(true)
			if player.state == BeachGull.State.GROUNDED and not wheelie.is_empty() and player.support.is_empty() and absf(player.position.x-float(wheelie.x)) < 28.0:
				return "TOO LOW! FLY UP AND LAND\nON TOP OF THE LID"
			return "FLY UP AND LAND ON THE WHEELIE BIN\nTAP %s %d TIMES. POSH TRASH INSIDE!" % [peck_key,int(Config.tuning.world.bin_pecks)]
		6:
			if training_clean_snatch:
				return "GOT IT! NOW CLIMB BACK UP HIGH"
			if player.state == BeachGull.State.STRIKE and not player.peck_used:
				return "NOW! TAP %s AT THE SNACK" % peck_key
			return "DIVE AT ANYONE'S SNACK. PECK IT\nTHEN CLIMB BACK UP HIGH"
	return "TRAINING COMPLETE!"

# The bin used by the bin lessons: the ordinary sand bin, or the wheelie bin.
func training_bin(wheelie: bool) -> Dictionary:
	for bin: Dictionary in stash_raids.bins:
		if (str(bin.type) == BeachBackdrop.WHEELIE_BIN_TYPE) == wheelie:
			return bin
	return {}

func training_target() -> Vector2:
	if lesson in [BIN_LESSON,WHEELIE_LESSON]:
		var bin: Dictionary = training_bin(lesson == WHEELIE_LESSON)
		if not bin.is_empty():
			# The wheelie ring marks its lid, where the gull has to stand.
			return Vector2(float(bin.x),float(bin.content_y)-6.0 if lesson == WHEELIE_LESSON else float(Config.tuning.world.ground)-18)
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

# --- Level 2 screech lesson (first herring play) -------------------------------------------

func lesson_active() -> bool:
	return training or screech_lesson

func screech_settings() -> Dictionary:
	return level.get("screech_lesson",{})

## The ice-cream stand's roof-sign perch that step 1 asks for: the stand nearest the start.
func lesson_perch() -> Dictionary:
	var best: Dictionary = {}
	for surface: Dictionary in player.perch_surfaces:
		if str(surface.get("prop_type","")) == "kiosk" and (best.is_empty() or float(surface.x) < float(best.x)):
			best = surface
	return best

func _screech_advance() -> void:
	screech_step += 1
	screech_clock = 0.0
	screech_snacks = player.digestion.snacks.size()
	track("lesson_complete", {"lesson": 100+screech_step, "seconds": snappedf(elapsed, 0.1)})
	if screech_step == 1:
		brash.meter = maxf(brash.meter,float(screech_settings().get("start_meter",0.6)))
	if screech_step >= SCREECH_STEPS:
		end_screech_lesson(true)
	else:
		effects.message(player.position-Vector2(0,24),"NICE!",BeachUI.GOLD)

## Finish (or skip) the lesson: save it, empty the meter and let the level clock run.
func end_screech_lesson(completed: bool) -> void:
	if not screech_lesson:
		return
	screech_lesson = false
	brash.meter = 0.0
	GameState.complete_screech_lesson()
	if completed:
		effects.message(player.position-Vector2(0,24),"LESSON DONE",BeachUI.GOLD)

func _screech_lesson_tick(delta: float) -> void:
	screech_clock += delta
	# The shoppers by the stand keep their ice creams until the gang arrives.
	if screech_step < 3:
		for target: BeachTarget in spawner.targets:
			if target.kind == "kiosk_customer" and not target.food and not target.dropped_pending and not target.leaving:
				target.food = true
				target.food_sprite.show()
				target.respawn = 0.0
	match screech_step:
		0:
			var perch: Dictionary = lesson_perch()
			if not perch.is_empty() and player.is_supported_by("kiosk",float(perch.x)):
				_screech_advance()
		1:
			if brash.is_full():
				_screech_advance()
		2:
			if not brash.allies.is_empty():
				_screech_advance()
			elif not brash.is_full():
				screech_step = 1
		3:
			var snacks: int = player.digestion.snacks.size()
			if snacks > screech_snacks or screech_clock >= float(screech_settings().get("grab_timeout",8.0)):
				_screech_advance()
			screech_snacks = snacks

func screech_lesson_text() -> String:
	var peck_key: String = "X" if input.gamepad else "E"
	var call_key: String = "RB" if input.gamepad else "Q"
	if input.touch_visible:
		peck_key = "PECK"
		call_key = "CALL"
	match screech_step:
		0: return "LAND ON THE ICE CREAM SIGN\nHIGH PERCHES ARE LOUDER"
		1: return "HOLD %s TO SCREECH\nHIGH PERCHES FILL BRASH FASTER" % peck_key
		2: return "BRASH FULL! SCREECH AGAIN\nOR %s TO CALL THE GANG" % call_key
	return "GRAB THE DROPPED FOOD!\nTHEY'LL BE BACK SOON"

func screech_lesson_target() -> Vector2:
	if screech_step == 0:
		var perch: Dictionary = lesson_perch()
		if not perch.is_empty():
			return Vector2(float(perch.x),BeachGull.perch_y(perch,float(perch.x))-8.0)
	elif screech_step == 3:
		for item: Dictionary in stash_raids.items:
			if item.get("owner") != null and not bool(item.get("recovered",false)):
				return item.position
	return Vector2(-1000,-1000)
