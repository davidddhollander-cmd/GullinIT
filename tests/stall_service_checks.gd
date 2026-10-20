extends RefCounted

static func step(game: BeachGame, duration: float) -> void:
	var remaining: float = duration
	while remaining > 0.00001:
		var delta: float = minf(0.01,remaining)
		game.spawner.reset_spacing()
		for buyer: BeachTarget in game.spawner.targets:
			buyer.tick(delta,[])
		game.stalls.tick(delta)
		game.spawner.apply_spacing(delta)
		remaining -= delta

static func wait_for_food(game: BeachGame) -> StallPortion:
	for i: int in 500:
		step(game,0.01)
		for portion: BeachTarget in game.stalls.portions:
			if portion.food:
				return portion as StallPortion
	return null

static func run(host: Node, check: Callable) -> void:
	var previous_audio: bool = bool(Config.tuning.juice.audio)
	Config.tuning.juice.audio = false
	preload("res://tests/vendor_art_checks.gd").run(check)
	var game := BeachGame.new()
	host.add_child(game)
	var definition: Dictionary = Config.levels[2].duplicate(true)
	definition.spawns = []
	definition.rivals = []
	definition.props = [{"type":"kiosk","x":180,"customer_x":228},{"type":"hotdog_stand","x":420,"customer_x":372}]
	game.setup(definition,false)
	game.set_physics_process(false)
	game.running = true
	game.intro = 0
	game.player.position = Vector2(80,50)
	check.call(game.beach.stalls.size()==2,"each food stand has one vendor independent of target count")
	var shopper := game.spawner.create("kiosk_customer",227,{"food_id":"ice_cream"})
	shopper.food = false
	shopper.food_sprite.hide()
	shopper.respawn = 0
	step(game,0.1)
	check.call(shopper.service_locked and game.stalls.portions.is_empty(),"preparation plants buyer without granting an invisible snack")
	var portion: StallPortion = wait_for_food(game)
	check.call(portion != null,"vendor exposes a real serving item")
	if portion == null:
		game.queue_free()
		Config.tuning.juice.audio = previous_audio
		return
	check.call(portion.position.x>206 and portion.food_sprite.visible and not shopper.food,"serving item clears stall edge and buyer still has empty hand")
	var before: Vector2 = portion.food_position()
	step(game,0.65)
	check.call(portion.food and shopper.service_locked and portion.food_position().x>206,"handover remains exposed and snatchable for a readable window")
	check.call(before.is_equal_approx(portion.food_position()),"placed food stays stationary on the counter throughout bonus window")
	check.call(is_equal_approx(portion.position.y+game.beach.stalls[0].food_size.y*0.5,game.beach.stalls[0].position.y+FoodStall.COUNTER_TOP),"food base rests exactly on the shelf surface")
	for stand: FoodStall in game.beach.stalls:
		check.call(stand.window.clip_contents and stand.vendor.get_parent()==stand.window,"full-body vendor is masked by the stall window")
		check.call(stand.vendor.scale==Vector2(0.5,0.5) and stand.vendor.sprite_frames.get_frame_count(&"poses")==8,"generated vendor keeps adult scale and all eight complete poses")
	# Collision and scoring use the real dive/peck segment, not a bonus shortcut.
	var player: BeachGull = game.player
	player.state = BeachGull.State.STRIKE
	player.sweep_state = BeachGull.State.STRIKE
	player.grounded_sweep = false
	player.peck_sweep_active = true
	player.previous_beak = portion.food_position()-Vector2(16,-3)
	player.sweep_beak = portion.food_position()+Vector2(16,-3)
	BeachCollisions.resolve(player,game.stalls.portions,game.beach.props)
	check.call(not portion.food and player.digestion.snacks.size()==1 and player.digestion.snacks[0].handover,"mid-handover dive snatch marks only the caught snack for bonus")
	check.call(game.score.points==0,"handover points still wait for swallowing")
	player.digestion.tick(4,false)
	check.call(game.score.points==38 and game.score.bonuses.Handover==1,"handover adds 50 percent once through normal score rounding")
	step(game,1.0)
	check.call(not shopper.food and game.stalls.requests.is_empty(),"interception cancels receipt and cannot recreate food at animation end")
	check.call(game.score.items==1,"interception scores one item")
	# All three appearances and the reverse-facing hotdog stall receive normally.
	for appearance: String in ShopperArt.APPEARANCES:
		var buyer := game.spawner.create("kiosk_customer",373,{"food_id":"hotdog","appearance":appearance})
		buyer.food = false
		buyer.food_sprite.hide()
		buyer.respawn = 0
		var served: StallPortion = wait_for_food(game)
		check.call(served != null and served.food_position().x<394,"left-side vendor exposes food beyond its edge for "+appearance)
		step(game,1.1)
		check.call(buyer.food and buyer.food_id=="hotdog" and buyer.food_sprite.position.x>0,"buyer receives same food into mirrored hand: "+appearance)
		check.call(not buyer.service_locked,"completed purchase releases buyer: "+appearance)
		buyer.respawn = 100
	# Family purchase retains existing sibling food and counts held plus reserves.
	var mum := game.spawner.create("picnic_family",227,{"family_id":"test"})
	var child := game.spawner.create("toddler",220,{"family_id":"test"})
	var sibling := game.spawner.create("toddler",248,{"family_id":"test"})
	mum.family_children.assign([child,sibling])
	child.family_parent = mum
	sibling.family_parent = mum
	mum.food = false
	mum.food_sprite.hide()
	mum.supply_crisps = 0
	mum.supply_cookies = 0
	child.food = false
	child.food_sprite.hide()
	child.wants_ice_cream = true
	mum.family_trip = BeachTarget.FamilyTrip.BUY
	mum.family_trip_serial += 1
	var sibling_id: String = sibling.food_id
	check.call(game.stalls.request_family(mum),"family requests one order at kiosk")
	step(game,6.0)
	check.call(child.food and child.food_id=="ice_cream" and sibling.food and sibling.food_id==sibling_id,"visible family receipts fill missing hand and preserve existing sibling snack")
	check.call(mum.food and mum.supply_crisps==1 and mum.supply_cookies==0 and mum.purchased_on_trip==3,"family order conserves two crisps including held bag and no cookie refill")
	# A serving theft during BUY aborts outstanding grants, not just return trips.
	step(game,1.0)
	child.food = false
	child.food_sprite.hide()
	mum.family_trip = BeachTarget.FamilyTrip.BUY
	mum.family_trip_serial += 1
	check.call(game.stalls.request_family(mum),"new family visit can begin after previous service")
	var family_food: StallPortion = wait_for_food(game)
	if family_food != null:
		player.digestion.rest = 0
		player.state = BeachGull.State.STRIKE
		family_food.take(player)
	check.call(family_food != null and mum.family_trip==BeachTarget.FamilyTrip.RETREAT,"intercepting serving food triggers family retreat while buying")
	step(game,1.5)
	check.call(game.stalls.requests.is_empty() and not child.service_locked,"interrupted family purchase clears reservations")
	game.queue_free()
	await host.get_tree().process_frame
	await boundary_checks(host,check)
	Config.tuning.juice.audio = previous_audio

static func boundary_checks(host: Node, check: Callable) -> void:
	for scenario: String in ["full","no_peck","after","ground","rival","pause","busy","large_step","reserve"]:
		var game := BeachGame.new()
		host.add_child(game)
		var definition: Dictionary = Config.levels[2].duplicate(true)
		definition.spawns = []
		definition.rivals = []
		definition.props = [{"type":"kiosk","x":180,"customer_x":228}]
		game.setup(definition,false)
		game.set_physics_process(false)
		game.running = true
		game.intro = 0
		var buyer := game.spawner.create("picnic_family" if scenario=="reserve" else "kiosk_customer",227,{"food_id":"ice_cream"})
		if scenario=="reserve":
			buyer.supply_crisps = 0
			buyer.family_trip = BeachTarget.FamilyTrip.BUY
			game.stalls.request_family(buyer)
		else:
			buyer.food = false
			buyer.food_sprite.hide()
			buyer.respawn = 0
		var portion: StallPortion = wait_for_food(game)
		check.call(portion != null,"boundary fixture exposes serving food: "+scenario)
		if portion == null:
			game.queue_free()
			await host.get_tree().process_frame
			continue
		var player: BeachGull = game.player
		player.state = BeachGull.State.STRIKE
		player.sweep_state = BeachGull.State.STRIKE
		player.grounded_sweep = false
		player.peck_sweep_active = true
		player.previous_beak = portion.food_position()-Vector2(18,0)
		player.sweep_beak = portion.food_position()+Vector2(18,0)
		match scenario:
			"reserve":
				step(game,0.65)
				check.call(buyer.food and portion.food_position().distance_to(buyer.food_position())>10,"reserve handover stays separate from mum's existing held snack")
				player.previous_beak = portion.food_position()-Vector2(2,0)
				player.sweep_beak = portion.food_position()+Vector2(2,0)
				var available: Array[BeachTarget] = game.stalls.portions.duplicate()
				available.append_array(game.spawner.targets)
				BeachCollisions.resolve(player,available,game.beach.props)
				check.call(buyer.food and buyer.supply_crisps==0 and not portion.food and player.digestion.snacks[0].handover,"reserve interception earns bonus while preserving mum's earlier held bag")
			"full":
				player.digestion.collect("fried_fish")
				BeachCollisions.resolve(player,game.stalls.portions,game.beach.props)
				check.call(portion.food and player.digestion.snacks.size()==1 and game.score.bonuses.Handover==0,"full stomach cannot consume serving food or award a bonus")
			"no_peck":
				player.peck_sweep_active = false
				BeachCollisions.resolve(player,game.stalls.portions,game.beach.props)
				check.call(portion.food and player.digestion.snacks.is_empty(),"dive without timed peck cannot steal a handover")
			"after":
				step(game,1.1)
				player.previous_beak = buyer.food_position()-Vector2(18,0)
				player.sweep_beak = buyer.food_position()+Vector2(18,0)
				BeachCollisions.resolve(player,[buyer],game.beach.props)
				check.call(not buyer.food and player.digestion.snacks.size()==1 and not player.digestion.snacks[0].handover,"theft after receipt earns ordinary snack points")
				player.digestion.tick(4,false)
				check.call(game.score.points==25 and game.score.bonuses.Handover==0,"handover modifier expires exactly with the exposed item")
			"ground":
				portion.knock_food(player)
				check.call(portion.dropped_pending and buyer.dropped_pending and game.stalls.requests.is_empty(),"knockdown cancels receipt and links normal dropped-food recovery")
				player.state = BeachGull.State.GROUNDED
				player.position = Vector2(220,150)
				portion.dropped_item.position = player.beak()
				portion.dropped_item.grounded = true
				portion.dropped_item.age = 1.0
				player.previous_beak = player.beak()
				player.sweep_beak = player.beak()
				game.stash_raids.tick(0.01)
				check.call(player.digestion.snacks.size()==1 and not player.digestion.snacks[0].handover and not buyer.dropped_pending,"ground recovery cannot inherit the dive-handover bonus or leave buyer pending")
			"rival":
				var rival := BeachGull.new()
				rival.rival = true
				game.add_child(rival)
				rival.state = BeachGull.State.STRIKE
				portion.take(rival)
				check.call(not portion.food and not buyer.food and player.digestion.snacks.is_empty() and game.score.bonuses.Handover==0,"rival interception removes the same item without awarding player bonus")
			"pause":
				var clock: float = game.beach.stalls[0].clock
				game.set_paused(true)
				await host.get_tree().process_frame
				await host.get_tree().process_frame
				check.call(game.beach.stalls[0].clock==clock and portion.food,"pause freezes vendor motion and exposed food window")
				game.effects.freeze = 1.0
				game._physics_process(0.1)
				check.call(game.beach.stalls[0].clock==clock and portion.food,"hit freeze cannot deliver food behind a frozen animation")
				game.effects.freeze = 0.0
				game.running = false
				game._physics_process(0.1)
				check.call(game.beach.stalls[0].clock==clock and portion.food,"intro or results cannot advance a pending purchase")
			"busy":
				var second := game.spawner.create("kiosk_customer",227,{"food_id":"ice_cream"})
				second.food = false
				second.food_sprite.hide()
				second.respawn = 100
				check.call(not game.stalls.request_shopper(second) and game.stalls.portions.size()==1,"busy stall cannot create simultaneous servings")
				step(game,1.1)
				check.call(game.stalls.requests.is_empty(),"busy stall releases its reservation for next buyer")
				second.respawn = 0.0
				step(game,3.0)
				check.call(second.food and buyer.food,"both buyers eventually receive one snack")
			"large_step":
				game.stalls.tick(10.0)
				game.stalls.tick(10.0)
				check.call(buyer.food and game.stalls.requests.is_empty() and game.stalls.portions.is_empty(),"large simulation steps deliver one item and clear the transaction")
		game.queue_free()
		await host.get_tree().process_frame
