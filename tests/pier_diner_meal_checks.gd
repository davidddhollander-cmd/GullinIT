extends RefCounted

static func fixture(host: Node, grill: bool = true) -> BeachGame:
	var game := BeachGame.new()
	host.add_child(game)
	var level: Dictionary = Config.levels[2].duplicate(true)
	level.spawns = [{"type":"pier_diner","x":1040}]
	level.rivals = []
	level.crabs = {"enabled":false}
	level.props = [{"type":"kiosk","x":800,"customer_x":847}]
	if grill:
		level.props.append({"type":"fish_chips_stand","x":900,"customer_x":947})
	game.setup(level,false)
	game.set_physics_process(false)
	game.set_process_unhandled_input(false)
	game.running = true
	game.intro = 0.0
	game.player.position = Vector2(100,50)
	return game

static func step(game: BeachGame, seconds: float) -> void:
	var remaining: float = seconds
	while remaining>0.00001:
		var delta: float = minf(0.02,remaining)
		for target: BeachTarget in game.spawner.targets:
			target.tick(delta,[])
		game.stalls.tick(delta)
		remaining -= delta

static func empty(diner: BeachTarget) -> void:
	diner.food = false
	diner.food_sprite.hide()
	diner.respawn = 0.0

static func wait_for_fish(game: BeachGame) -> StallPortion:
	for frame: int in 1200:
		step(game,0.02)
		for portion: BeachTarget in game.stalls.portions:
			if portion.food and portion.food_id=="fried_fish":
				return portion as StallPortion
	return null

static func run(host: Node, check: Callable) -> void:
	var game: BeachGame = fixture(host)
	var diner: BeachTarget = game.spawner.targets[0]
	var home: float = diner.position.x
	var anchor: float = diner.routine.anchor
	empty(diner)
	step(game,0.1)
	check.call(not diner.food and not diner.food_sprite.visible,"empty diner cannot regenerate fish when its timer expires")
	check.call(diner.position.x<home and diner.sprite.animation==&"walk","empty diner visibly walks towards the grill")
	var portion: StallPortion = wait_for_fish(game)
	check.call(portion!=null,"diner orders a real fish portion from the compatible grill")
	if portion!=null:
		var stand: FoodStall = game.stalls.find_stall(diner,"fish_chips_stand")
		check.call(diner.service_locked and not diner.food and is_equal_approx(diner.position.x,stand.contact_x()),"diner waits empty-handed beside the serving counter")
		var at: Vector2 = portion.position
		step(game,0.65)
		check.call(portion.food and portion.position==at and not diner.food,"fish remains stationary for the readable counter-snatch window")
		var clock: float = stand.clock
		game.set_paused(true)
		await host.get_tree().process_frame
		check.call(stand.clock==clock and portion.position==at,"pause freezes diner counter service")
		game.effects.freeze = 1.0
		game._physics_process(0.1)
		check.call(stand.clock==clock and not diner.food,"hit freeze cannot deliver a replacement meal")
		game.effects.freeze = 0.0
		game.set_paused(false)
		game.set_physics_process(false)
		step(game,0.5)
		check.call(diner.food and not diner.service_locked and diner.food_id=="fried_fish" and not portion.food,"counter receipt transfers exactly one fish to the diner")
		check.call(diner.routine.anchor==anchor,"grill purchase does not move the dining anchor onto the promenade")
		step(game,6.0)
		check.call(diner.food and is_equal_approx(diner.position.x,home) and diner.routine.phase==BeachRoutine.Phase.PAUSE,"diner carries its meal home and takes a long dining stop")
		check.call(game.stalls.requests.is_empty() and game.stalls.portions.is_empty() and game.score.items==0,"ordinary purchase creates no extra portion or player score")
	game.queue_free()
	await host.get_tree().process_frame

	for source: String in ["missing_grill","missing_service"]:
		game = fixture(host,false)
		diner = game.spawner.targets[0]
		if source=="missing_service":
			diner.stall_service = null
		empty(diner)
		step(game,25.0)
		check.call(not diner.food and game.stalls.portions.is_empty(),"missing source leaves diner empty instead of granting invisible fish: "+source)
		game.queue_free()
		await host.get_tree().process_frame

	for scenario: String in ["theft","full","drop","busy","held_theft","return_interrupt"]:
		game = fixture(host)
		diner = game.spawner.targets[0]
		home = diner.position.x
		empty(diner)
		if scenario=="busy":
			diner.position.x = 947
			var shopper: BeachTarget = game.spawner.create("kiosk_customer",947,{"food_id":"fried_fish"})
			empty(shopper)
			check.call(game.stalls.request_shopper(shopper),"grill accepts its existing hotdog customer")
			step(game,0.1)
			check.call(not diner.food and not diner.service_locked and game.stalls.requests.size()==1,"busy grill cannot also serve invisible fish to a diner")
		portion = wait_for_fish(game)
		check.call(portion!=null,"fish order reaches counter: "+scenario)
		if portion==null:
			game.queue_free()
			await host.get_tree().process_frame
			continue
		var player: BeachGull = game.player
		player.upwind = false
		player.state = BeachGull.State.STRIKE
		player.direction = Vector2.RIGHT
		match scenario:
			"theft":
				player.sweep_state = BeachGull.State.STRIKE
				player.peck_sweep_active = true
				player.grounded_sweep = false
				player.previous_beak = portion.food_position()-Vector2(20,0)
				player.sweep_beak = portion.food_position()+Vector2(20,0)
				BeachCollisions.resolve(player,game.stalls.portions,game.beach.props)
				check.call(not portion.food and not diner.food and not diner.service_locked and diner.reaction.mode=="surprise" and diner.reaction.committed,"counter dive theft cancels receipt and preserves the diner's committed reaction")
				player.digestion.tick(3.1,false)
				check.call(game.score.points==roundi(55.0*(1.0+float(Config.tuning.score.handover))) and game.score.items==1,"stolen fish scores once on swallowing with the counter bonus")
				step(game,2.0)
				check.call(not diner.food and game.stalls.requests.is_empty(),"intercepted fish cannot later be delivered to the diner")
			"full":
				player.digestion.collect("hotdog")
				check.call(not portion.take(player) and portion.food and not diner.food,"full stomach preserves the counter fish for the diner")
				step(game,1.1)
				check.call(diner.food and game.score.points==0,"rejected catch still permits normal fish receipt")
			"drop":
				portion.knock_food(player)
				diner.drop_retrieve = false
				step(game,18.0)
				check.call(not diner.food and diner.dropped_pending and game.stash_raids.items.size()==1 and game.stalls.requests.is_empty(),"unrecovered knocked fish blocks replacement orders and cannot duplicate")
				diner.drop_retrieve = true
				for frame: int in 700:
					var delta: float = 0.02
					step(game,delta)
					game.stash_raids.tick(delta)
				check.call(diner.food and not diner.dropped_pending and is_equal_approx(diner.position.x,home),"recovering the fish resumes the trip back to the dining spot")
			"busy":
				step(game,14.0)
				check.call(diner.food and is_equal_approx(diner.position.x,home) and game.stalls.requests.is_empty(),"diner waits its turn then returns home with one fish")
			"held_theft":
				step(game,1.1)
				diner.take(player)
				diner.respawn = 0.0
				step(game,0.1)
				check.call(not diner.food and diner.reaction.mode=="surprise" and game.stalls.requests.is_empty(),"carried-fish theft reacts before starting another shopping trip")
			"return_interrupt":
				step(game,1.1)
				var before: float = diner.position.x
				diner.reaction.theft(diner,player,true)
				step(game,0.1)
				check.call(diner.position.x==before and diner.sprite.animation==&"surprise","reaction temporarily interrupts meal return")
				var returned: bool = false
				for frame: int in 900:
					step(game,0.02)
					if diner.reaction.mode.is_empty() and is_equal_approx(diner.position.x,home) and diner.routine.phase==BeachRoutine.Phase.PAUSE:
						returned = true
						break
				check.call(diner.food and returned and diner.routine.anchor==home,"interrupted return resumes towards the original dining home")
		game.queue_free()
		await host.get_tree().process_frame

	# Real levels: each pier diner buys fried fish at that level's fish & chips stand.
	for index: int in [2,4,5]:
		var real := BeachGame.new()
		host.add_child(real)
		var definition: Dictionary = Config.levels[index].duplicate(true)
		definition.rivals = []
		definition.crabs = {"enabled":false}
		real.setup(definition,false)
		real.set_physics_process(false)
		real.set_process_unhandled_input(false)
		real.running = true
		real.intro = 0.0
		real.player.position = Vector2(100,50)
		var fish_stand: FoodStall = real.stalls.find_stall(real.spawner.targets[0],"fish_chips_stand")
		check.call(fish_stand!=null,"level %d has a fish & chips stand"%(index+1))
		var buyer: BeachTarget
		for target: BeachTarget in real.spawner.targets:
			if target.kind=="pier_diner":
				empty(target)
				buyer = buyer if buyer!=null else target
		check.call(buyer!=null and buyer.purchase_stall_type()=="fish_chips_stand","level %d diners buy at the fish & chips stand"%(index+1))
		var served: bool = false
		for frame: int in 1500:
			step(real,0.02)
			if real.stalls.requests.has(fish_stand):
				served = true
				break
		check.call(served,"level %d fish & chips stand serves a diner"%(index+1))
		real.queue_free()
		await host.get_tree().process_frame
