extends RefCounted
## Task 086: the kittiwake's Lightning Strike (rough playtest build).

const Shake := preload("res://tests/shakedown_checks.gd")
const KITTI: String = "kittiwake"

static func fixture(host: Node) -> BeachGame:
	var game: BeachGame = Shake.fixture(host,KITTI)
	game.player.position = Vector2(170,90)
	game.camera_x = 160.0
	game.camera_y = 90.0
	return game

static func fire(game: BeachGame) -> void:
	game.brash.meter = 1.0
	game.effects.freeze = 0.0
	game.start_slowmo() # the Q path

static func food(game: BeachGame, x: float, id: String = "hotdog") -> BeachTarget:
	var person: BeachTarget = game.spawner.create("kiosk_customer",x,{"food_id":id,"appearance":"kiosk_customer"})
	person.respawn = 100.0
	person.food = true
	person.food_sprite.show()
	return person

## Ticks the gull then the power; returns game seconds until `until` is true (or the cap).
static func run_until(game: BeachGame, until: Callable, cap: float = 6.0) -> float:
	var t: float = 0.0
	while t < cap and not until.call():
		Shake.sim(game,0.02)
		t += 0.02
	return t

## Aims at a food from a fixed spot (the gull would otherwise drift) for one tick.
static func aim_tick(game: BeachGame, at: BeachTarget) -> void:
	game.player.position = Vector2(170,90)
	game.player.velocity = Vector2.ZERO
	game.player.aim = at.food_position()
	Shake.sim(game,0.02)

static func dashing(game: BeachGame) -> bool:
	return game.brash.lightning.phase == BeachLightning.Phase.DASH

static func landed(game: BeachGame) -> bool:
	return game.brash.lightning.phase != BeachLightning.Phase.DASH and game.brash.lightning.phase != BeachLightning.Phase.WINDUP

static func clean(game: BeachGame) -> bool:
	return is_equal_approx(Engine.time_scale,1.0) and game.player.visible and not game.player.dashing and game.player.invulnerable == 0.0 and not game.player.steady_invulnerable and game.brash.lightning.marks.is_empty() and not game.brash.active()

static func run(host: Node, check: Callable) -> void:
	var previous_audio: bool = bool(Config.tuning.juice.audio)
	Config.tuning.juice.audio = false
	_data_and_fire_checks(host,check)
	_windup_checks(host,check)
	_casual_checks(host,check)
	_dash_checks(host,check)
	_counter_checks(host,check)
	_lost_mark_checks(host,check)
	_charge_checks(host,check)
	_landing_checks(host,check)
	_other_species_checks(host,check)
	await _end_checks(host,check)
	Engine.time_scale = 1.0
	Config.tuning.juice.audio = previous_audio

static func _data_and_fire_checks(host: Node, check: Callable) -> void:
	var p: Dictionary = Config.species.species.kittiwake.power
	var t: Dictionary = Config.tuning.lightning_strike
	check.call(p.id == "lightning_strike" and p.name == "LIGHTNING STRIKE" and p.ready_label == "STRIKE!" and p.sound == "gang_call" and is_equal_approx(float(p.pitch),1.3) and is_equal_approx(float(p.fill.snatch),1.0) and is_equal_approx(float(p.fill.handover),1.0) and int(p.charges) == 2,"kittiwake power block carries the agreed data")
	check.call(bool(Config.species.species.kittiwake.get("coming_soon",false)),"kittiwake stays coming_soon")
	check.call(is_equal_approx(float(t.windup_time),1.5) and is_equal_approx(float(t.windup_time_scale),0.35) and int(t.marks_per_charge) == 2 and is_equal_approx(float(t.mark_range),110.0) and is_equal_approx(float(t.mark_angle),15.0) and float(t.dash_speed) >= 600.0 and is_zero_approx(float(t.land_invulnerable)) and is_equal_approx(float(t.fizzle_pause),0.1),"lightning_strike tunables exist")
	var game: BeachGame = fixture(host)
	var brash: BeachBrash = game.brash
	brash.earn("snatch")
	check.call(is_equal_approx(brash.meter,float(Config.tuning.brash.snatch)),"kittiwake direct snatches fill 1.0x")
	brash.meter = 0.0
	brash.earn("handover")
	check.call(is_equal_approx(brash.meter,float(Config.tuning.brash.handover)),"kittiwake counter snatches fill 1.0x")
	brash.meter = 1.0
	game.player.state = BeachGull.State.STUNNED
	check.call(not brash.fire() and brash.meter == 1.0 and not brash.active(),"cannot fire while stunned")
	game.player.state = BeachGull.State.GLIDE
	var person: BeachTarget = food(game,160.0)
	game.player.aim = person.food_position()
	fire(game)
	check.call(brash.active_id == "lightning_strike" and brash.lightning.winding() and brash.meter == 0.0 and brash.allies.is_empty() and brash.powers_fired == 1,"Q fires Lightning Strike into the windup")
	check.call(is_equal_approx(Engine.time_scale,0.35) and not game.slowmo_active(),"the windup slows time without Bullet Time's own slowmo")
	check.call(str(brash.power().ready_label) == "STRIKE!","the meter shows STRIKE!")
	brash.add(0.5)
	brash.earn("snatch")
	check.call(brash.meter == 0.0,"the meter cannot fill while the power runs")
	# A second press with no marks refunds the meter and leaves no slow motion.
	game.start_slowmo()
	check.call(brash.meter == 1.0 and not brash.active() and is_equal_approx(Engine.time_scale,1.0) and brash.powers_fired == 0 and game.player.visible and not game.player.dashing,"firing with no marks refunds the meter and restores time")
	game.input.touch_slowmo = true # the touch button path
	game._physics_process(0.02)
	check.call(brash.active_id == "lightning_strike","the touch button fires it too")
	brash.end_power()
	game.queue_free()
	Engine.time_scale = 1.0

static func _windup_checks(host: Node, check: Callable) -> void:
	var game: BeachGame = fixture(host)
	var brash: BeachBrash = game.brash
	var player: BeachGull = game.player
	fire(game)
	var seconds: float = run_until(game,func() -> bool: return not brash.active())
	check.call(not brash.active() and brash.meter == 1.0 and is_equal_approx(Engine.time_scale,1.0),"an empty windup times out, refunds and restores time")
	check.call(is_equal_approx(seconds,1.5*0.35) or absf(seconds-0.525) < 0.06,"the windup lasts windup_time of real seconds (%.3f game s at 0.35x)" % seconds)
	var people: Array[BeachTarget] = [food(game,100.0),food(game,170.0),food(game,240.0)]
	fire(game)
	aim_tick(game,people[0])
	check.call(brash.lightning.marks == [people[0]],"sweeping the aim over a food marks it as number 1")
	aim_tick(game,people[0])
	check.call(brash.lightning.marks.size() == 1,"the same food is not marked twice")
	aim_tick(game,people[1])
	check.call(brash.lightning.marks.size() == 2 and dashing(game),"the second food becomes number 2 and, at the cap, the dash starts")
	check.call(brash.lightning.max_marks() == 2,"one charge allows 2 marks")
	check.call(dashing(game),"the dash starts")
	check.call(is_equal_approx(Engine.time_scale,1.0) and not player.visible and player.dashing,"the dash restores time, hides the gull and sets dashing")
	brash.end_power()
	check.call(clean(game),"ending mid-dash leaves a clean state")
	# Second press with marks starts the dash early.
	fire(game)
	aim_tick(game,people[0])
	game.start_slowmo()
	check.call(dashing(game) and brash.lightning.marks.size() == 1,"a second press ends the windup and dashes at the marks so far")
	brash.end_power()
	# The timeout also dashes with fewer marks than the cap.
	fire(game)
	aim_tick(game,people[0])
	run_until(game,func() -> bool:
		player.position = Vector2(170,90)
		player.aim = people[0].food_position()
		return dashing(game) or not brash.active())
	check.call(dashing(game) and brash.lightning.marks.size() == 1,"the timeout dashes with the marks it has")
	brash.end_power()
	game.queue_free()
	Engine.time_scale = 1.0

static func _casual_checks(host: Node, check: Callable) -> void:
	var game: BeachGame = fixture(host)
	game.player.control_mode = "casual"
	var near: Array[BeachTarget] = [food(game,120.0),food(game,150.0),food(game,190.0)]
	var far: BeachTarget = food(game,260.0)
	game.player.aim = Vector2(0,0) # facing nothing: casual ignores aim
	fire(game)
	check.call(game.brash.lightning.marks.size() == 2 and not game.brash.lightning.marks.has(far) and game.brash.lightning.marks.all(func(m: BeachTarget) -> bool: return near.has(m)),"casual mode marks the nearest 2 foods (one charge) by itself")
	run_until(game,func() -> bool: return dashing(game))
	check.call(dashing(game),"casual mode dashes after a short beat")
	game.brash.end_power()
	game.queue_free()
	Engine.time_scale = 1.0
	var touch: BeachGame = fixture(host)
	touch.input.touch_active = true
	var two: Array[BeachTarget] = [food(touch,130.0),food(touch,200.0)]
	fire(touch)
	check.call(touch.brash.lightning.marks.size() == 2,"touch input auto-marks the foods in view")
	touch.brash.end_power()
	touch.queue_free()
	Engine.time_scale = 1.0

static func _dash_checks(host: Node, check: Callable) -> void:
	var game: BeachGame = fixture(host)
	var player: BeachGull = game.player
	var brash: BeachBrash = game.brash
	var people: Array[BeachTarget] = [food(game,40.0),food(game,300.0),food(game,60.0)]
	# A full stomach: the dash still scores every food at once and leaves the stomach as it was.
	player.digestion.snacks.append({"id":"hotdog"})
	player.digestion.snacks.append({"id":"crab"}) # 8 units: over any capacity
	var stomach: int = player.digestion.snacks.size()
	check.call(not player.can_collect_food("hotdog") and not player.dashing,"a full stomach refuses a normal snatch")
	fire(game)
	brash.lightning.marks.assign(people)
	brash.lightning.end_windup()
	var seconds: float = run_until(game,func() -> bool: return landed(game))
	check.call(seconds < 1.2,"three marks across the screen are done in under about a second (%.2f s)" % seconds)
	check.call(people.all(func(p: BeachTarget) -> bool: return not p.food),"every live mark is snatched in order")
	check.call(game.score.items == 3 and game.score.points > 0,"strike snatches score at once (%d pts)" % game.score.points)
	check.call(player.digestion.snacks.size() == stomach,"the stomach is left as it was")
	check.call(brash.meter == 0.0,"strike snatches do not refill the meter")
	check.call(brash.active_id == "lightning_strike","active_id stays set through the landing")
	# Empty stomach as well.
	player.digestion.snacks.clear()
	brash.end_power()
	var before: int = game.score.items
	var one: BeachTarget = food(game,120.0)
	fire(game)
	brash.lightning.marks.assign([one])
	brash.lightning.end_windup()
	run_until(game,func() -> bool: return landed(game))
	check.call(game.score.items == before+1 and player.digestion.snacks.is_empty(),"an empty stomach scores the same way and stays empty")
	brash.end_power()
	game.queue_free()
	Engine.time_scale = 1.0

static func _counter_checks(host: Node, check: Callable) -> void:
	var game: BeachGame = fixture(host)
	var stall_checks: GDScript = preload("res://tests/stall_service_checks.gd")
	var shopper: BeachTarget = game.spawner.create("kiosk_customer",227,{"food_id":"ice_cream","appearance":"kiosk_customer"})
	shopper.food = false
	shopper.food_sprite.hide()
	shopper.respawn = 0
	var portion: StallPortion = stall_checks.wait_for_food(game)
	check.call(portion != null,"fixture serves a counter portion")
	if portion == null:
		game.queue_free()
		return
	fire(game)
	game.brash.lightning.marks.assign([portion])
	game.brash.lightning.end_windup()
	run_until(game,func() -> bool: return landed(game))
	check.call(not portion.food and game.score.bonuses.get("Handover",0) == 1,"a stall portion taken by the strike pays the counter bonus")
	game.brash.end_power()
	game.queue_free()
	Engine.time_scale = 1.0

static func _lost_mark_checks(host: Node, check: Callable) -> void:
	var game: BeachGame = fixture(host)
	var brash: BeachBrash = game.brash
	var people: Array[BeachTarget] = [food(game,120.0),food(game,200.0),food(game,260.0)]
	fire(game)
	brash.lightning.marks.assign(people)
	brash.lightning.end_windup()
	people[1].food = false # eaten or stolen before the bolt arrives
	var pauses: Array[int] = [0]
	var seconds: float = run_until(game,func() -> bool:
		pauses[0] += 1 if brash.lightning.pause_left > 0.0 else 0
		return landed(game))
	check.call(not people[0].food and not people[2].food and game.score.items == 2,"a lost mark is skipped and the dash carries on")
	check.call(pauses[0] > 0 and game.player.visible,"the lost mark pauses briefly (fizzle) before the next leg")
	check.call(seconds < 3.0,"the dash still finishes")
	brash.end_power()
	game.queue_free()
	Engine.time_scale = 1.0
	# Every mark lost: no crash, the gull still lands.
	var empty: BeachGame = fixture(host)
	var gone: BeachTarget = food(empty,150.0)
	fire(empty)
	empty.brash.lightning.marks.assign([gone])
	empty.brash.lightning.end_windup()
	gone.queue_free()
	run_until(empty,func() -> bool: return landed(empty))
	check.call(empty.player.visible and not empty.player.dashing,"a freed mark is survived")
	empty.brash.end_power()
	empty.queue_free()
	Engine.time_scale = 1.0

static func _landing_checks(host: Node, check: Callable) -> void:
	var game: BeachGame = fixture(host)
	var player: BeachGull = game.player
	var brash: BeachBrash = game.brash
	var low: BeachTarget = food(game,150.0)
	var sand: float = float(Config.tuning.world.ground)
	check.call(low.food_position().y > sand-40.0,"the fixture mark is low, near the sand")
	fire(game)
	brash.lightning.marks.assign([low])
	brash.lightning.end_windup()
	check.call(player.untargetable() and player.invulnerable > 10.0,"the dashing gull is ignored by rivals, people and dogs")
	player.stun()
	check.call(player.state != BeachGull.State.STUNNED,"a stun cannot land on the dashing gull")
	var states: Array[int] = []
	run_until(game,func() -> bool:
		states.append(player.state)
		return landed(game))
	check.call(states.all(func(s: int) -> bool: return s == BeachGull.State.GLIDE),"the dash never enters STRIKE or a sand crash")
	check.call(player.visible and not player.dashing and player.state == BeachGull.State.GLIDE,"the gull returns mid-air in GLIDE")
	check.call(is_zero_approx(player.invulnerable) and player.steady_invulnerable,"landing gives no extra immunity")
	var cap: float = float(Config.tuning.flight.max_speed)*player.species_speed()
	check.call(player.velocity.length() <= cap+0.01 and player.velocity.length() > 1.0,"the landing keeps the dash direction at normal flight speed")
	run_until(game,func() -> bool: return not brash.active())
	check.call(clean(game),"the power ends cleanly after the immunity")
	game.queue_free()
	Engine.time_scale = 1.0

static func _charge_checks(host: Node, check: Callable) -> void:
	var game: BeachGame = fixture(host)
	var brash: BeachBrash = game.brash
	brash.add(5.0)
	check.call(is_equal_approx(brash.meter,2.0) and brash.max_charges() == 2,"the kittiwake meter caps at 2 charges")
	brash.meter = 2.0
	game.start_slowmo()
	check.call(brash.lightning.max_marks() == 4 and is_zero_approx(brash.meter),"firing on 2 charges allows 4 marks and spends both")
	brash.end_power()
	brash.meter = 1.0
	game.start_slowmo()
	check.call(brash.lightning.max_marks() == 2 and is_zero_approx(brash.meter),"firing on 1 charge allows 2 marks")
	brash.end_power()
	brash.meter = 1.4
	game.start_slowmo()
	check.call(brash.lightning.max_marks() == 2 and is_equal_approx(brash.meter,0.4),"the fractional remainder survives firing")
	brash.lightning.end_windup() # no marks: refund
	check.call(is_equal_approx(brash.meter,1.4),"an empty windup refunds the spent charges")
	game.queue_free()
	Engine.time_scale = 1.0
	var herring: BeachGame = Shake.fixture(host,"herring")
	herring.brash.add(5.0)
	check.call(herring.brash.max_charges() == 2 and is_equal_approx(herring.brash.meter,2.0),"a two-charge power clamps at 2")
	herring.brash.fire()
	check.call(herring.brash.allies.size() == int(herring.player.species_stats().power.allies) * 2,"two banked charges double the Gang Call")
	herring.queue_free()

static func _other_species_checks(host: Node, check: Callable) -> void:
	var herring: BeachGame = Shake.fixture(host,"herring")
	herring.brash.meter = 1.0
	herring.start_slowmo()
	check.call(herring.brash.allies.size() == int(herring.player.species_stats().power.allies) and not herring.brash.active() and is_equal_approx(Engine.time_scale,1.0),"herring still fires Gang Call")
	herring.queue_free()
	var black: BeachGame = Shake.fixture(host,Shake.BLACKBACK)
	black.brash.meter = 1.0
	black.start_slowmo()
	check.call(black.brash.active_id == "shakedown" and not black.brash.lightning.winding(),"black-back still fires Shakedown")
	black.brash.end_power()
	black.queue_free()

static func _end_checks(host: Node, check: Callable) -> void:
	for dash: bool in [false,true]:
		var label: String = "mid-dash" if dash else "mid-windup"
		var game: BeachGame = fixture(host)
		var person: BeachTarget = food(game,200.0)
		var results: Array[Dictionary] = []
		game.level_finished.connect(func(result: Dictionary) -> void: results.append(result))
		fire(game)
		game.brash.lightning.marks.assign([person])
		if dash:
			game.brash.lightning.end_windup()
			Shake.sim(game,0.04)
		game.set_paused(true)
		var at: Vector2 = game.player.position
		var left: float = game.brash.lightning.wind_left
		await host.get_tree().process_frame
		await host.get_tree().process_frame
		check.call(is_equal_approx(Engine.time_scale,1.0) and game.player.position == at and is_equal_approx(game.brash.lightning.wind_left,left) and game.brash.active_id == "lightning_strike","pause "+label+" freezes the power and restores the clock")
		game.set_paused(false)
		game.set_physics_process(false)
		check.call(is_equal_approx(Engine.time_scale,1.0 if dash else 0.35) and game.brash.active_id == "lightning_strike","resume "+label+" carries on")
		game.finish()
		check.call(clean(game) and not game.brash.lightning.winding(),"level end "+label+" leaves no leftover state")
		check.call(results.size() == 1 and int(results[0].powers) == 1,"the results board counts the strike "+label)
		game.queue_free()
		Engine.time_scale = 1.0
