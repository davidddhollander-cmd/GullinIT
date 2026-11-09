extends RefCounted
## Task 064: the great black-back's Shakedown power and the shared power plumbing.

const BLACKBACK: String = "great-black-backed"

static func fixture(host: Node, species: String, extra: Array = []) -> BeachGame:
	var game := BeachGame.new()
	host.add_child(game)
	var definition: Dictionary = Config.levels[2].duplicate(true)
	definition.spawns = []
	definition.rivals = []
	definition.props = [{"type":"kiosk","x":180,"customer_x":228},{"type":"hotdog_stand","x":420,"customer_x":372}]+extra
	definition.player_species = species
	game.setup(definition,false)
	game.set_physics_process(false)
	game.running = true
	game.intro = 0
	game.player.position = Vector2(80,50)
	return game

## Same order as the game's physics step: gull first, then the power.
static func sim(game: BeachGame, seconds: float) -> void:
	var left: float = seconds
	while left > 0.00001:
		var delta: float = minf(0.02,left)
		left -= delta
		game.player.tick(delta,0,0.0)
		game.brash.tick(delta)

static func stall_ticks(game: BeachGame, seconds: float) -> void:
	var left: float = seconds
	while left > 0.00001:
		var delta: float = minf(0.01,left)
		left -= delta
		for buyer: BeachTarget in game.spawner.targets:
			buyer.tick(delta,[])
		game.stalls.tick(delta)

static func ground_gull(game: BeachGame, x: float) -> void:
	game.player.state = BeachGull.State.GROUNDED
	game.player.facing = 1
	game.player.position = Vector2(x,float(Config.tuning.world.ground)-float(Config.tuning.flight.feet_offset))
	game.player.velocity = Vector2.ZERO

static func vendor_hidden(stall: FoodStall) -> bool:
	var height: float = stall.vendor.sprite_frames.get_frame_texture(&"poses",0).get_height()*stall.vendor.scale.y
	return stall.vendor.position.y-height*0.5 >= stall.window.size.y

static func run(host: Node, check: Callable) -> void:
	var previous_audio: bool = bool(Config.tuning.juice.audio)
	Config.tuning.juice.audio = false
	_data_checks(check)
	_fire_checks(host,check)
	_untouchable_checks(host,check)
	_panic_and_shake_checks(host,check)
	_raid_checks(host,check)
	_toughness_checks(host,check)
	_punch_checks(host,check)
	_bounce_checks(host,check)
	_raid_feel_checks(host,check)
	await _end_checks(host,check)
	await _board_checks(host,check)
	Config.tuning.juice.audio = previous_audio

static func _data_checks(check: Callable) -> void:
	var power: Dictionary = Config.species.species["great-black-backed"].power
	check.call(power.id == "shakedown" and power.name == "SHAKEDOWN" and is_equal_approx(float(power.duration),8.0) and not str(power.ready_label).is_empty() and not str(power.sound).is_empty(),"black-back has a shakedown power block")
	check.call(is_equal_approx(float(power.fill.bump),1.5) and is_equal_approx(float(power.fill.mug),1.5),"black-back earns more meter from bumps and muggings")
	var herring: Dictionary = Config.species.species.herring.power
	check.call(herring.ready_label == "CALL!" and herring.sound == "gang_call" and not herring.has("fill"),"herring keeps CALL! and gang_call")
	var t: Dictionary = Config.tuning.shakedown
	check.call(is_equal_approx(float(t.panic_interval),1.0) and int(t.raid_cap) == 6 and float(t.shake_radius) > 0.0,"shakedown tunables live in tuning.json")
	var sizes: Array = t.raid_foods.map(func(id: String) -> String: return str(Config.foods[id].category))
	check.call(not t.raid_foods.is_empty() and not sizes.has("large"),"raid foods contain no large items")

static func _fire_checks(host: Node, check: Callable) -> void:
	var game: BeachGame = fixture(host,BLACKBACK)
	var brash: BeachBrash = game.brash
	var base: float = float(Config.tuning.brash.bump)
	brash.earn("bump")
	check.call(is_equal_approx(brash.meter,base*1.5),"black-back bump fills 1.5x the base")
	brash.meter = 0.0
	brash.earn("mug")
	check.call(is_equal_approx(brash.meter,float(Config.tuning.brash.mug)*1.5),"black-back mug fills 1.5x the base")
	brash.meter = 0.0
	brash.earn("snatch")
	check.call(is_equal_approx(brash.meter,float(Config.tuning.brash.snatch)),"snatch fills at the base rate for black-backs")
	brash.meter = 0.9
	check.call(not brash.fire() and is_equal_approx(brash.meter,0.9),"a part-full meter cannot fire")
	brash.meter = 1.0
	game.player.state = BeachGull.State.STUNNED
	check.call(not brash.fire() and brash.meter == 1.0 and not brash.active(),"cannot fire while stunned and the meter is kept")
	game.player.state = BeachGull.State.GLIDE
	game.start_slowmo() # the Q path
	check.call(brash.active_id == "shakedown" and is_equal_approx(brash.active_left,8.0) and brash.meter == 0.0 and brash.allies.is_empty(),"Q fires Shakedown on a full meter: no Gang Call gulls")
	check.call(brash.powers_fired == 1 and game.player.steady_invulnerable and game.player.invulnerable >= 8.0,"firing counts the power and starts immunity")
	brash.add(0.5)
	brash.earn("mug")
	check.call(brash.meter == 0.0,"the meter cannot fill while a power is active")
	brash.end_power()
	game.player.state = BeachGull.State.GROUNDED
	brash.meter = 1.0
	game.effects.freeze = 0.0 # the first fire left a hitstop
	game.input.touch_slowmo = true # the touch button path
	game._physics_process(0.02)
	check.call(brash.active_id == "shakedown" and brash.powers_fired == 2,"the touch button fires Shakedown too")
	var label: String = str(brash.power().ready_label)
	check.call(label == "SHAKE!" and brash.active_left < 8.0 and brash.active_left > 7.9,"overlay data: ready label and time left are available")
	game.overlay.queue_redraw()
	game.queue_free()
	var herring: BeachGame = fixture(host,"herring")
	herring.brash.meter = 1.0
	herring.start_slowmo()
	check.call(herring.brash.allies.size() == int(herring.player.species_stats().power.allies) and not herring.brash.active() and herring.brash.meter == 0.0,"herring still fires Gang Call, with no timed power")
	herring.brash.earn("bump")
	check.call(herring.brash.meter == 0.0,"herring meter stays blocked while the gang is out")
	herring.brash.clear()
	herring.brash.earn("bump")
	check.call(is_equal_approx(herring.brash.meter,float(Config.tuning.brash.bump)),"herring bump fill is unchanged")
	herring.queue_free()

static func _untouchable_checks(host: Node, check: Callable) -> void:
	var game: BeachGame = fixture(host,BLACKBACK)
	var player: BeachGull = game.player
	var brash: BeachBrash = game.brash
	player.stun_shield = 1
	var ignored: Array[int] = [0]
	player.stun_ignored.connect(func() -> void: ignored[0] += 1)
	brash.meter = 1.0
	brash.fire()
	ground_gull(game,80)
	sim(game,0.1)
	player.stun()
	check.call(player.state != BeachGull.State.STUNNED and player.stun_shield == 1 and ignored[0] == 1,"stuns are blocked, signalled, and Strong Skull is unspent")
	var flicker: bool = false
	var covered: bool = true
	for i: int in 30:
		sim(game,0.02)
		flicker = flicker or player.sprite.modulate.a < 1.0
		covered = covered and player.invulnerable >= brash.active_left
	check.call(not flicker and covered,"immunity never flickers and always covers the time left")
	# A sand crash still tumbles, and recovery cannot shorten the immunity.
	player.begin_tumble()
	check.call(player.state == BeachGull.State.STUNNED,"a crash still tumbles during the power")
	var still_covered: bool = true
	for i: int in 120:
		sim(game,0.02)
		still_covered = still_covered and player.invulnerable >= brash.active_left
		if player.state != BeachGull.State.STUNNED:
			break
	check.call(player.state != BeachGull.State.STUNNED and brash.active() and still_covered,"tumble recovery keeps immunity covering the power")
	sim(game,9.0)
	check.call(not brash.active() and player.invulnerable == 0.0 and not player.steady_invulnerable and is_equal_approx(player.sprite.modulate.a,1.0),"on expiry immunity is off and the sprite is opaque")
	ground_gull(game,80)
	player.stun()
	check.call(player.state != BeachGull.State.STUNNED and player.stun_shield == 0 and ignored[0] == 2,"after the power Strong Skull spends its charge as normal")
	player.stun()
	check.call(player.state == BeachGull.State.STUNNED,"after the power, stuns land again")
	game.queue_free()

static func _panic_and_shake_checks(host: Node, check: Callable) -> void:
	var game: BeachGame = fixture(host,BLACKBACK)
	var player: BeachGull = game.player
	var brash: BeachBrash = game.brash
	var far: BeachTarget = game.spawner.create("kiosk_customer",700,{"food_id":"hotdog","appearance":"kiosk_customer"})
	var holder: BeachTarget = game.spawner.create("kiosk_customer",300,{"food_id":"hotdog","appearance":"kiosk_customer"})
	var bystander: BeachTarget = game.spawner.create("kiosk_customer",380,{"food_id":"hotdog","appearance":"kiosk_customer"})
	for person: BeachTarget in [far,holder,bystander]:
		person.respawn = 100.0
		person.food = true
	ground_gull(game,80)
	brash.meter = 1.0
	brash.fire()
	check.call(far.panic.state == CrowdPanic.State.NONE,"firing only warns people in range")
	player.position = Vector2(650,60)
	sim(game,1.05)
	check.call(far.panic.state == CrowdPanic.State.LOOK_UP and far.panic.stampede_pending and far.panic.direction == 1.0,"people flee around the gull's current position, not where it fired")
	check.call(holder.food and bystander.food,"food stays put when the gull is far away")
	# The shake: contact drops food, in flight.
	player.position = holder.food_position()+Vector2(4,-3)
	player.state = BeachGull.State.GLIDE
	sim(game,0.02)
	check.call(not holder.food and holder.dropped_pending and bystander.food,"touching a person makes their food drop, and only theirs")
	check.call(game.stash_raids.items.any(func(item: Dictionary) -> bool: return item.owner == holder and item.food_id == "hotdog"),"the dropped food is a loose ground item")
	# Rivals with food drop it too.
	game.pending_rivals = [{"name":"TESTER","speed":1.0}]
	game._release_rivals()
	var pilot: RivalPilot = game.pilots[0]
	pilot.carried = 20
	pilot.carry_window = 3.0
	pilot.carried_food_id = "crisps_bag"
	pilot.gull.position = player.position+Vector2(-60,0)
	sim(game,0.02)
	check.call(pilot.carried == 20,"a carrier out of reach keeps its food")
	pilot.gull.position = player.position+Vector2(8,0)
	sim(game,0.02)
	var loose: Array = game.stash_raids.items.filter(func(item: Dictionary) -> bool: return item.owner == null and item.food_id == "crisps_bag" and item.source == "dropped")
	check.call(pilot.carried == 0 and loose.size() == 1,"touching a food-carrying rival makes it drop the food to the sand")
	game.queue_free()

static func _raid_checks(host: Node, check: Callable) -> void:
	var game: BeachGame = fixture(host,BLACKBACK)
	var player: BeachGull = game.player
	var brash: BeachBrash = game.brash
	var stall: FoodStall = game.beach.stalls[0]
	var raids: BeachStashRaids = game.stash_raids
	var shopper: BeachTarget = game.spawner.create("kiosk_customer",stall.contact_x(),{"food_id":"ice_cream","appearance":"kiosk_customer"})
	shopper.food = false
	shopper.food_sprite.hide()
	shopper.respawn = 0.0
	stall_ticks(game,0.1)
	check.call(game.stalls.requests.has(stall),"a normal order is running before the raid")
	ground_gull(game,stall.position.x)
	game._peck()
	check.call(raids.items.is_empty() and not stall.ducked,"without the power a peck at the stall raids nothing")
	raids.peck_cooldown = 0.0
	brash.meter = 1.0
	brash.fire()
	ground_gull(game,stall.position.x+float(FoodStall.COUNTER_REACH)+30.0)
	game._peck()
	check.call(raids.items.is_empty() and not stall.ducked,"a peck outside the counter's reach raids nothing")
	raids.peck_cooldown = 0.0
	ground_gull(game,stall.position.x+10.0)
	player.position.y -= 50.0 # on the roof
	game._peck()
	check.call(raids.items.size() == 1 and raids.items[0].source == "raid" and raids.peck_cooldown > 0.0,"a peck on the roof spits one food item and starts the cooldown")
	check.call(stall.ducked and not game.stalls.requests.has(stall) and shopper.service_locked == false,"the first raid peck ends the order and the vendor ducks")
	game._peck()
	check.call(raids.items.size() == 1,"the normal peck cooldown limits the raid")
	stall_ticks(game,0.2)
	check.call(vendor_hidden(stall),"the vendor sinks out of sight inside the mask")
	var walker: BeachTarget = game.spawner.create("kiosk_customer",stall.contact_x(),{"food_id":"ice_cream","appearance":"kiosk_customer"})
	walker.food = false
	walker.food_sprite.hide()
	walker.respawn = 0.0
	check.call(not game.stalls.request_shopper(walker) and not game.stalls.requests.has(stall),"no new order can start while the vendor hides")
	ground_gull(game,stall.position.x-12.0)
	for i: int in 12:
		raids.peck_cooldown = 0.0
		game._peck()
	var raid_items: Array = raids.items.filter(func(item: Dictionary) -> bool: return item.source == "raid")
	check.call(raid_items.size() == int(Config.tuning.shakedown.raid_cap),"raid food stops at the cap")
	check.call(raid_items.all(func(item: Dictionary) -> bool: return Config.foods[item.food_id].category != "large"),"raided food is never large")
	check.call(raids.peck_cooldown > 0.0,"pecks after the cap still spend the cooldown (empty tap)")
	# Other stall is its own raid.
	var other: FoodStall = game.beach.stalls[1]
	ground_gull(game,other.position.x)
	raids.peck_cooldown = 0.0
	game._peck()
	check.call(other.ducked and raids.items.filter(func(item: Dictionary) -> bool: return item.source == "raid").size() == raid_items.size()+1,"each stall has its own cap and vendor")
	# Release: the vendor returns and service resumes.
	sim(game,9.0)
	check.call(not brash.active() and not stall.ducked and not other.ducked,"the power's end releases the stalls")
	check.call(game.stalls.request_shopper(walker) and game.stalls.requests.has(stall),"normal service resumes after the power")
	stall_ticks(game,0.2)
	check.call(not vendor_hidden(stall) and is_equal_approx(stall.vendor.position.y,stall.vendor_home_y),"the vendor comes back up")
	game.queue_free()
	# A bin beside the stall: with the power the counter wins; without it the bin does.
	var busy: BeachGame = fixture(host,BLACKBACK,[{"type":"bin","x":190}])
	ground_gull(busy,185)
	busy._peck()
	check.call(int(busy.stash_raids.bins[0].pecks) == 1 and busy.stash_raids.items.is_empty(),"control: without the power the bin gets the peck")
	busy.stash_raids.peck_cooldown = 0.0
	busy.brash.meter = 1.0
	busy.brash.fire()
	busy._peck()
	check.call(int(busy.stash_raids.bins[0].pecks) == 1 and busy.stash_raids.items.size() == 1 and busy.stash_raids.items[0].source == "raid","the counter raid takes priority over a bin")
	busy.queue_free()

static func _end_checks(host: Node, check: Callable) -> void:
	var game: BeachGame = fixture(host,BLACKBACK)
	var player: BeachGull = game.player
	var brash: BeachBrash = game.brash
	var stall: FoodStall = game.beach.stalls[0]
	var results: Array[Dictionary] = []
	game.level_finished.connect(func(result: Dictionary) -> void: results.append(result))
	brash.meter = 1.0
	brash.fire()
	ground_gull(game,stall.position.x)
	game._peck()
	stall_ticks(game,0.2)
	game.set_paused(true)
	var left: float = brash.active_left
	var immune: float = player.invulnerable
	await host.get_tree().process_frame
	await host.get_tree().process_frame
	check.call(brash.active_id == "shakedown" and is_equal_approx(brash.active_left,left) and is_equal_approx(player.invulnerable,immune) and is_equal_approx(Engine.time_scale,1.0),"pause freezes the power and leaves it intact")
	game.set_paused(false)
	game.set_physics_process(false)
	check.call(brash.active_id == "shakedown" and player.steady_invulnerable and stall.ducked,"resume finds the power still running")
	game.finish()
	stall_ticks(game,0.0)
	check.call(not brash.active() and player.invulnerable == 0.0 and not player.steady_invulnerable and is_equal_approx(player.sprite.modulate.a,1.0),"level end during the power clears immunity and the sprite")
	check.call(not stall.ducked and is_equal_approx(stall.vendor.position.y,stall.vendor_home_y) and is_equal_approx(Engine.time_scale,1.0),"level end puts the vendor back up and restores the clock")
	check.call(results.size() == 1 and int(results[0].powers) == 1,"the result reports the power count")
	game.queue_free()

static func _board_checks(host: Node, check: Callable) -> void:
	GameState.progress = {"1": {"training_step": 7, "training_complete": true}, "2": {"screech_lesson_complete": true}}
	var texts: Array = []
	for setup: Array in [[5,true],[5,false],[2,true]]:
		Config.levels[int(setup[0])-1]["player_species"] = BLACKBACK
		host.main.start_level(int(setup[0]))
		Config.levels[int(setup[0])-1].erase("player_species")
		var game: BeachGame = host.main.game
		game.quests.quests = game.quests.quests.slice(0,2 if int(setup[0]) == 5 else 3)
		game.set_physics_process(false)
		game.intro = 0.0
		game.running = true
		if bool(setup[1]):
			game.brash.meter = 1.0
			game.brash.fire()
		game.finish()
		await host.settle()
		var board: ResultBoard = host.main.menus.get_child(0) as ResultBoard
		var quests: int = game.quests.quests.size()
		var shown: bool = board.captions.any(func(label: Label) -> bool: return label.text == "POWERS")
		texts.append([int(setup[0]),quests,bool(setup[1]),shown])
		if int(setup[0]) == 5 and bool(setup[1]):
			check.call(quests <= 2 and shown,"POWERS row shows on a board with room")
			board.finish_tally()
			var row: Label = board.rows.filter(func(label: Label) -> bool: return board.captions.any(func(c: Label) -> bool: return c.text == "POWERS" and c.position == label.position))[0]
			check.call(row.text == "1","POWERS row counts the powers")
		elif int(setup[0]) == 5:
			check.call(not shown,"POWERS row is hidden when no power was fired")
		else:
			check.call(quests >= 3 and not shown,"POWERS row is hidden when the board has no room (3 quests)")
		host.main.clear_game()
		await host.settle()
	GameState.progress = {"1": {"training_step": 7, "training_complete": true}, "2": {"screech_lesson_complete": true}}

## Task 066: toughness stats and the species-agnostic screech gate.
static func _toughness_checks(host: Node, check: Callable) -> void:
	var launch: float = float(Config.tuning.tumble.launch_speed)
	var up: float = float(Config.tuning.tumble.launch_up)
	var herring: BeachGame = fixture(host,"herring")
	var blackback: BeachGame = fixture(host,BLACKBACK)
	for game: BeachGame in [herring,blackback]:
		game.player.position = Vector2(200,60)
		game.player.begin_tumble(-1.0,Vector2(180,60))
	check.call(is_equal_approx(herring.player.velocity.x,launch) and is_equal_approx(herring.player.velocity.y,-up),"a herring's tumble launch is unchanged")
	check.call(is_equal_approx(blackback.player.velocity.x,launch*0.6) and is_equal_approx(blackback.player.velocity.y,-up*0.6) and blackback.player.velocity.x < herring.player.velocity.x,"a black-back tumbles shorter: both launch components scaled by knockback")
	for game: BeachGame in [herring,blackback]:
		game.brash.meter = 0.5
		game._stunned()
	check.call(is_equal_approx(herring.brash.meter,0.5+float(Config.tuning.brash.stun)),"a stun costs a herring the full meter loss")
	check.call(is_equal_approx(blackback.brash.meter,0.5+float(Config.tuning.brash.stun)*0.5),"a stun costs a black-back half as much meter")
	# Screech gate follows the clip, not the species.
	var player: BeachGull = herring.player
	ground_gull(herring,80)
	check.call(player.sprite.sprite_frames.has_animation(&"screech") and herring._can_screech(),"a herring with a screech clip can screech")
	var frames: SpriteFrames = player.sprite.sprite_frames
	var bare: SpriteFrames = frames.duplicate()
	bare.remove_animation(&"screech")
	player.sprite.sprite_frames = bare
	check.call(not herring._can_screech(),"without a screech clip a gull cannot screech")
	check.call(not herring._peck_pressed() and not herring.peck_hold_pending,"without the clip a peck press is a plain peck, not a pending hold")
	player.sprite.sprite_frames = frames
	check.call(herring._can_screech(),"restoring the clip re-enables the screech")
	var black_player: BeachGull = blackback.player
	ground_gull(blackback,80)
	check.call(blackback._can_screech() == black_player.sprite.sprite_frames.has_animation(&"screech"),"the black-back screeches exactly when its art has a screech clip")
	var fixture_frames: SpriteFrames = black_player.sprite.sprite_frames.duplicate()
	if not fixture_frames.has_animation(&"screech"):
		fixture_frames.add_animation(&"screech")
		fixture_frames.add_frame(&"screech",fixture_frames.get_frame_texture(fixture_frames.get_animation_names()[0],0))
	black_player.sprite.sprite_frames = fixture_frames
	check.call(blackback._can_screech() and is_equal_approx(blackback.screech_pitch(),0.8) and is_equal_approx(herring.screech_pitch(),1.0),"adding a clip lets a black-back screech, lower; herring pitch is unchanged")
	herring.queue_free()
	blackback.queue_free()

static func _person(game: BeachGame, x: float) -> BeachTarget:
	var person: BeachTarget = game.spawner.create("kiosk_customer",x,{"food_id":"hotdog","appearance":"kiosk_customer"})
	person.respawn = 100.0
	person.food = true
	return person

## Puts a person so their food sits `gap` pixels from the point.
static func _place(person: BeachTarget, at: Vector2, gap: float) -> void:
	var low: float = 0.0
	var high: float = 300.0
	for i: int in 24:
		var mid: float = (low+high)*0.5
		person.position.x = at.x+mid
		if at.distance_to(person.food_position()) < gap:
			low = mid
		else:
			high = mid

static func _punch_checks(host: Node, check: Callable) -> void:
	var game: BeachGame = fixture(host,BLACKBACK)
	var player: BeachGull = game.player
	var brash: BeachBrash = game.brash
	var t: Dictionary = Config.tuning.shakedown
	check.call(is_equal_approx(float(t.shake_radius),50.0) and is_equal_approx(float(t.slam_radius),70.0) and is_equal_approx(float(t.gorge_digest),3.0) and int(t.gorge_capacity) == 4 and is_equal_approx(float(t.bully_scale),1.25) and is_equal_approx(float(t.bounce_cooldown),2.0),"punch tunables live in the shakedown block")
	var inner: BeachTarget = _person(game,300)
	var middle: BeachTarget = _person(game,300)
	var outer: BeachTarget = _person(game,300)
	ground_gull(game,300)
	var at: Vector2 = player.position
	_place(inner,at,30.0)
	_place(middle,at,62.0)
	_place(outer,at,95.0)
	var knocks: Array[float] = []
	for person: BeachTarget in [inner,middle,outer]:
		person.food_knocked.connect(func(_who: BeachTarget, _id: String, _pos: Vector2, impulse: Vector2) -> void: knocks.append(impulse.y))
	player.digestion.capacity = 6 # a perk's stomach
	brash.meter = 1.0
	brash.fire()
	check.call(not inner.food and not middle.food and outer.food,"firing knocks food from everyone inside slam_radius at once, and no one outside")
	check.call(brash.hits == 1 and knocks.size() == 2,"the slam is one impact bundle")
	var lift: float = -float(Config.tuning.world.drop_impulse_up)*float(t.food_lift)
	check.call(knocks.all(func(y: float) -> bool: return is_equal_approx(y,lift)),"slam food flies with food_lift")
	check.call(not inner.drop_retrieve and not middle.drop_retrieve,"food knocked by the power cannot be reclaimed")
	# Shake hits: higher lift, no reclaim, capped impact rate.
	var reclaim: float = float(Config.foods.hotdog.reclaim_chance)
	Config.foods.hotdog.reclaim_chance = 1.0
	var control: BeachTarget = _person(game,700)
	control.knock_food(player)
	check.call(control.drop_retrieve,"control: an ordinary knock of this food is reclaimable")
	var shaken: Array[BeachTarget] = [_person(game,400),_person(game,400)]
	player.state = BeachGull.State.GLIDE
	player.position = Vector2(560,100)
	knocks.clear()
	for person: BeachTarget in shaken:
		_place(person,player.position,20.0)
		person.food_knocked.connect(func(_who: BeachTarget, _id: String, _pos: Vector2, impulse: Vector2) -> void: knocks.append(impulse.y))
	var before_hits: int = brash.hits
	sim(game,0.02)
	Config.foods.hotdog.reclaim_chance = reclaim
	check.call(shaken.all(func(p: BeachTarget) -> bool: return not p.food),"shake knocks the food from people in range")
	check.call(shaken.all(func(p: BeachTarget) -> bool: return not p.drop_retrieve),"shaken food cannot be reclaimed")
	check.call(knocks.size() == 2 and knocks.all(func(y: float) -> bool: return absf(y-lift) <= float(Config.tuning.world.drop_impulse_side)),"shake knocks use food_lift (the gull's own heading adds at most drop_impulse_side)")
	check.call(brash.hits == before_hits+1,"two simultaneous shake knocks make a single impact")
	var again: BeachTarget = _person(game,400)
	_place(again,player.position,20.0)
	sim(game,0.02)
	check.call(brash.hits == before_hits+1 and not again.food,"impact_gap stops chained hits stacking shake and freeze")
	sim(game,float(t.impact_gap)+0.05)
	var next: BeachTarget = _person(game,400)
	_place(next,player.position,20.0)
	sim(game,0.02)
	check.call(brash.hits == before_hits+2 and not next.food,"the next hit after the gap lands as a fresh impact")
	# Gorge.
	var stomach: GullDigestion = player.digestion
	check.call(stomach.capacity == 10 and is_equal_approx(stomach.speed,3.0),"capacity and digest speed rise during the power, on top of the perk")
	stomach.snacks.clear()
	stomach.collect("single_chip")
	stomach.tick(0.2,false)
	check.call(stomach.snacks.is_empty(),"digestion runs 3x during the power")
	# Bully size, tint, warning.
	var base: float = player.art_scale if player.detailed_art else 1.0
	player.squash_left = 0.0 # the swallow above bulges the body briefly; this check is about bully_scale alone
	sim(game,0.1)
	check.call(is_equal_approx(player.sprite.scale.x,base*1.25) and is_equal_approx(player.sprite.scale.y,base*1.25),"the gull is drawn at bully_scale during the power")
	ground_gull(game,420)
	sim(game,0.02)
	var scaled_beak: Vector2 = player.beak()-player.position
	var scaled_feet: Vector2 = player.position-Vector2(0,float(Config.tuning.flight.feet_offset))
	player.power_scale = 1.0
	sim(game,0.02)
	check.call(player.state == BeachGull.State.GROUNDED and (player.beak()-player.position).is_equal_approx(scaled_beak) and is_equal_approx(player.position.y,scaled_feet.y+float(Config.tuning.flight.feet_offset)),"scaling the sprite does not move the beak or feet")
	player.power_scale = float(t.bully_scale)
	var tinted: bool = false
	for i: int in 80:
		sim(game,0.02)
		tinted = tinted or player.sprite.modulate.g < 0.95
	check.call(tinted,"the tint pulses")
	var calm: float = game.brash.shakedown.pulse
	sim(game,0.2)
	var calm_step: float = game.brash.shakedown.pulse-calm
	brash.active_left = 1.0
	var warn: float = game.brash.shakedown.pulse
	sim(game,0.2)
	check.call(game.brash.shakedown.pulse-warn > calm_step*2.0,"the pulse speeds up in the last end_warning seconds")
	game.effects.shake = 0.0
	player.sand_landed.emit(Vector2(400,160))
	check.call(not bool(Config.tuning.juice.shake) or not GameState.options.shake or game.effects.shake >= float(t.land_shake),"landing during the power adds a shake")
	# Every end path restores size, capacity and speed.
	for path: String in ["expiry","end_power","clear","finish"]:
		if not brash.active():
			ground_gull(game,80)
			brash.meter = 1.0
			brash.fire()
		check.call(player.digestion.capacity == 10,"gorge applies for the %s path" % path)
		match path:
			"expiry":
				sim(game,9.0)
			"end_power":
				brash.end_power()
			"clear":
				brash.clear()
			"finish":
				game.finish()
		sim(game,0.02)
		check.call(not brash.active() and player.digestion.capacity == 6 and is_equal_approx(player.digestion.speed,1.0),"%s restores the perk's capacity and normal digestion" % path)
		check.call(is_equal_approx(player.power_scale,1.0) and is_equal_approx(player.sprite.scale.x,base) and player.sprite.modulate.is_equal_approx(Color.WHITE),"%s restores the sprite size and tint" % path)
	game.queue_free()

static func _bounce_checks(host: Node, check: Callable) -> void:
	var game: BeachGame = fixture(host,BLACKBACK)
	var player: BeachGull = game.player
	var brash: BeachBrash = game.brash
	var bounce: float = float(Config.tuning.shakedown.bounce_cooldown)
	var dog: OffLeadDog = OffLeadDog.new()
	game.add_child(dog)
	dog.setup(100,[0,600],1)
	ground_gull(game,100)
	player.invulnerable = 1.0
	check.call(player.untargetable() and not dog._can_chase(player),"a dog ignores a gull in ordinary post-hit invulnerability")
	player.invulnerable = 0.0
	check.call(not player.untargetable() and dog._can_chase(player),"a plain gull is targetable")
	brash.meter = 1.0
	brash.fire()
	var nopes: Array[int] = [0]
	player.stun_ignored.connect(func() -> void: nopes[0] += 1)
	check.call(not player.untargetable() and dog._can_chase(player),"the dog still goes for a gull with power immunity")
	var dog_x: float = dog.position.x
	player.position.x = dog.mouth().x
	dog._try_catch(player)
	check.call(player.state != BeachGull.State.STUNNED and nopes[0] == 1,"the dog's catch is blocked and signalled")
	check.call(dog.state == OffLeadDog.State.COOLDOWN and dog.timer >= bounce and not is_equal_approx(dog.position.x,dog_x),"the dog recoils and cannot bite again for bounce_cooldown")
	game.last_nope_ms = Time.get_ticks_msec()
	var first: int = game.last_nope_ms
	player.stun()
	check.call(game.last_nope_ms == first,"a second NOPE inside nope_gap is silent")
	game.last_nope_ms -= 5000
	player.stun()
	check.call(game.last_nope_ms >= first,"NOPE shows again after the gap")
	var sweeper: BeachSweeper = BeachSweeper.new()
	game.add_child(sweeper)
	sweeper.setup(game,100,1)
	sweeper.state = BeachSweeper.State.SWAT
	var hit_frame: int = int(BeachSweeper.art().swat_hit_frames[0])
	sweeper.clip_name = &"swat"
	sweeper.clip_clock = (float(hit_frame)+0.5)/6.0*float(Config.tuning.sweeper.swat_time)
	player.position = sweeper.broom_point()
	check.call(sweeper.can_mark(player),"the sweeper still marks a gull with power immunity")
	var sweeper_x: float = sweeper.position.x
	var before: int = nopes[0]
	sweeper._swing_check(player)
	check.call(sweeper.landed_hit and sweeper.bounced and player.state != BeachGull.State.STUNNED and nopes[0] == before+1,"the sweeper's swat is blocked and signalled")
	check.call(not is_equal_approx(sweeper.position.x,sweeper_x),"the sweeper recoils")
	sweeper._swing_fx_start()
	sweeper.timer = 0.01
	sweeper.tick(0.02,player)
	check.call(sweeper.state == BeachSweeper.State.FIST and sweeper.cooldown >= bounce-0.05,"the sweeper cannot swing again for bounce_cooldown")
	brash.end_power()
	player.invulnerable = 0.5
	check.call(not sweeper.can_mark(player),"after the power ordinary invulnerability is ignored by the sweeper again")
	player.invulnerable = 0.0
	sweeper.hit_done = false
	sweeper.clip_name = &"swat"
	sweeper.clip_clock = (float(hit_frame)+0.5)/6.0*float(Config.tuning.sweeper.swat_time)
	player.position = sweeper.broom_point()
	sweeper._swing_check(player)
	check.call(player.knockback < 1.0 and player.state == BeachGull.State.STUNNED and is_equal_approx(absf(player.velocity.x),float(Config.tuning.sweeper.knock_speed)*player.knockback),"a broom swat launches a black-back by its knockback")
	game.queue_free()

static func _raid_feel_checks(host: Node, check: Callable) -> void:
	var game: BeachGame = fixture(host,BLACKBACK)
	var player: BeachGull = game.player
	var stall: FoodStall = game.beach.stalls[0]
	var raids: BeachStashRaids = game.stash_raids
	game.brash.meter = 1.0
	game.brash.fire()
	var gravity: float = float(Config.tuning.world.stash_gravity)
	var floor_y: float = float(Config.tuning.world.ground)
	for roof: bool in [true,false]:
		raids.items.clear()
		raids.peck_cooldown = 0.0
		ground_gull(game,stall.position.x+(10.0 if roof else -14.0))
		if roof:
			player.position.y -= 50.0
		stall.shake_left = 0.0
		game._peck()
		var item: Dictionary = raids.items[0]
		var pos: Vector2 = item.position
		var vel: Vector2 = item.velocity
		for i: int in 600:
			vel.y += gravity*0.005
			pos += vel*0.005
			if pos.y >= floor_y-3.0:
				break
		var aim: float = player.position.x if roof else player.beak().x
		check.call(absf(pos.x-aim) <= float(Config.tuning.world.peck_reach),"the spit lands within pickup reach of the gull (%s)" % ("roof" if roof else "sand"))
		check.call(stall.shake_left > 0.0,"a raid peck rattles the stall")
		var rattled: bool = false
		for i: int in 40:
			stall.advance(0.01)
			rattled = rattled or not is_equal_approx(stall.position.x,stall.home_x)
		check.call(rattled and is_equal_approx(stall.position.x,stall.home_x),"the rattle moves the stall briefly and settles exactly home")
	game.queue_free()
