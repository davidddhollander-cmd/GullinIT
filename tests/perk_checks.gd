extends RefCounted
## Perk effects in play (task 016). Sets wallet.owned / options.perk directly.

static func begin(host: Node, perk: String) -> BeachGame:
	GameState.wallet.owned = [perk] if not perk.is_empty() else []
	GameState.options.perk = perk
	host.main.start_level(1)
	var game: BeachGame = host.main.game
	game.set_physics_process(false)
	game.intro = 0
	game.running = true
	game.input.enabled = true
	return game

static func clean_swallow(game: BeachGame, extra: Dictionary = {}) -> void:
	var snack: Dictionary = {"id": "cookie"}
	snack.merge(extra)
	game._swallowed(snack)

static func run(host: Node, check: Callable) -> void:
	var species_dive: float = float(Config.species.species[GameState.chosen_gull()].get("dive", 1.0))
	# No perk: unchanged.
	var game: BeachGame = begin(host, "")
	check.call(game.perk_id == "" and game.player.digestion.capacity == 4 and is_equal_approx(game.player.dive_mult, species_dive) and game.player.stun_shield == 0 and is_equal_approx(game.stalls.handover_mult, 1.0), "no perk leaves capacity, dive, stuns and counter window unchanged")
	clean_swallow(game)
	check.call(game.bullet_meter == 0.0 and game.keen_target() == null and not game.slowmo_ready() and not game.input.slowmo_ready, "no perk has no bullet meter or keen marker")
	game.player.stun()
	check.call(game.player.state == BeachGull.State.STUNNED, "no perk: a swat stuns")
	# Bigger stomach.
	game = begin(host, "bigger_stomach")
	var belly: GullDigestion = game.player.digestion
	check.call(belly.capacity == int(Config.perks.perks.bigger_stomach.stomach) and belly.collect("hotdog") and belly.collect("ice_cream") and not belly.can_collect("cookie"), "bigger stomach carries 6 units")
	# Dive speed.
	game = begin(host, "dive_speed")
	check.call(is_equal_approx(game.player.dive_mult, species_dive * float(Config.perks.perks.dive_speed.dive_mult)), "dive speed stacks with the species stat")
	# Strong skull.
	game = begin(host, "strong_skull")
	game.score.points = 20
	var skull_hits: Array[int] = [0]
	game.player.stun_ignored.connect(func() -> void: skull_hits[0] += 1)
	game.player.digestion.collect("cookie")
	game.player.stun()
	check.call(game.player.state != BeachGull.State.STUNNED and game.score.points == 20 and game.player.digestion.snacks.size() == 1 and skull_hits[0] == 1 and game.player.stun_shield == 0, "strong skull ignores the first swat: no stun, points or food lost")
	game.player.stun()
	check.call(game.player.state == BeachGull.State.STUNNED and game.score.points == 15, "second swat lands normally")
	game = begin(host, "strong_skull")
	game.player.begin_tumble()
	check.call(game.player.state == BeachGull.State.STUNNED and game.player.stun_shield == 1, "ground crashes still count")
	# Keen eye.
	game = begin(host, "keen_eye")
	check.call(is_equal_approx(game.stalls.handover_mult, float(Config.perks.perks.keen_eye.handover_window_mult)), "keen eye lengthens the counter window")
	var best: BeachTarget
	for target: BeachTarget in game.spawner.targets:
		if target.kind != "sunbather" and not target.leaving and best == null:
			best = target
	check.call(best != null, "keen eye fixture target exists")
	for target: BeachTarget in game.spawner.targets:
		target.food = false
	best.food = true
	best.food_id = "hotdog"
	best.defense = 0.0
	check.call(game.keen_target() == best, "keen eye marks the best held snack")
	var cheap: BeachTarget = null
	for target: BeachTarget in game.spawner.targets:
		if target != best and target.kind != "sunbather" and not target.leaving and cheap == null:
			cheap = target
	if cheap != null:
		cheap.food = true
		cheap.food_id = "cookie"
		check.call(game.keen_target() == best, "keen eye prefers the higher value")
		cheap.food = false
	best.info = best.info.duplicate()
	var old_twist: Variant = best.info.get("twist", "")
	best.info.twist = "shield"
	best.defense = 1.0
	check.call(game.keen_target() == null, "keen eye skips shielded food")
	best.info.twist = old_twist
	best.defense = 0.0
	game.player.position = best.position
	game.camera_x = clampf(best.position.x, 160, float(Config.tuning.world.width) - 160)
	game.camera.position = Vector2(roundf(game.camera_x), 90)
	game.overlay.queue_redraw()
	await host.snapshot("perk-keen-eye-marker")
	# Bullet time.
	game = begin(host, "bullet_time")
	var fill: float = float(Config.perks.perks.bullet_time.fill_per_clean_snatch)
	game.start_slowmo()
	check.call(Engine.time_scale == 1.0 and not game.slowmo_active(), "bullet time cannot start with an empty meter")
	clean_swallow(game, {"scrap": true})
	clean_swallow(game, {"mugged": true})
	check.call(game.bullet_meter == 0.0, "scraps and mugged food do not fill the meter")
	clean_swallow(game)
	check.call(is_equal_approx(game.bullet_meter, fill), "a clean snatch fills the meter")
	game.overlay.queue_redraw()
	await host.snapshot("perk-bullet-meter-partial")
	game.start_slowmo()
	check.call(Engine.time_scale == 1.0, "bullet time still locked below full")
	clean_swallow(game)
	clean_swallow(game)
	game._slowmo_tick()
	check.call(game.bullet_meter == 1.0 and game.slowmo_ready() and game.input.slowmo_ready, "meter caps at full and arms the button")
	game.overlay.queue_redraw()
	await host.snapshot("perk-bullet-meter-full")
	game.start_slowmo()
	check.call(is_equal_approx(Engine.time_scale, float(Config.perks.perks.bullet_time.time_scale)) and game.slowmo_active(), "full meter slows time")
	game.slowmo_end_msec = Time.get_ticks_msec() + 5000
	game._slowmo_tick()
	check.call(Engine.time_scale < 1.0, "slow-mo lasts until its real-time end")
	game.slowmo_end_msec = Time.get_ticks_msec() - 1
	game._slowmo_tick()
	check.call(Engine.time_scale == 1.0 and game.bullet_meter == 0.0 and not game.slowmo_active(), "slow-mo ends: time restored, meter emptied")
	game.bullet_meter = 1.0
	game.start_slowmo()
	game.set_paused(true)
	check.call(Engine.time_scale == 1.0 and not game.slowmo_active(), "pausing during slow-mo restores time")
	game.set_paused(false)
	game.bullet_meter = 1.0
	game.start_slowmo()
	host.main.clear_game()
	check.call(Engine.time_scale == 1.0, "leaving the level restores time")
	# Input map and touch button.
	check.call(InputMap.has_action("slowmo"), "slowmo action exists")
	var has_key: bool = false
	var has_pad: bool = false
	for event: InputEvent in InputMap.action_get_events("slowmo"):
		has_key = has_key or event is InputEventKey
		has_pad = has_pad or (event is InputEventJoypadButton and event.button_index == JOY_BUTTON_RIGHT_SHOULDER)
	check.call(has_key and has_pad, "slowmo has keyboard and gamepad bindings")
	game = begin(host, "bullet_time")
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = GullInput.SLOWMO_BUTTON.get_center()
	game.input._input(touch)
	check.call(not game.input.touch_slowmo, "slowmo touch button is inert while the meter is not full")
	game.input.touch_visible = true
	game.bullet_meter = 1.0
	game._slowmo_tick()
	game.input._input(touch)
	check.call(game.input.touch_slowmo, "slowmo touch button works when full")
	var screen := Rect2(0, 0, 320, 180)
	check.call(screen.encloses(GullInput.SLOWMO_BUTTON) and screen.encloses(BeachOverlay.METER_RECT) and not GullInput.SLOWMO_BUTTON.intersects(GullInput.TOUCH_BUTTONS.peck) and not GullInput.SLOWMO_BUTTON.intersects(GullInput.TOUCH_BUTTONS.dive), "slowmo button and meter fit the 320x180 layout without overlapping touch buttons")
	game.overlay.queue_redraw()
	await host.snapshot("perk-bullet-touch-button")
	host.main.clear_game()
	GameState.wallet.owned = []
	GameState.options.perk = ""
	Engine.time_scale = 1.0
