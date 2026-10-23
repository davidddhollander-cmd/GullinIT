class_name StallService
extends RefCounted
## One bounded service per stand; gameplay and presentation share the same clock.
signal portion_created(portion: BeachTarget)
const OrderBubble = preload("res://scripts/order_bubble.gd")
var stalls: Array[FoodStall] = []
var portions: Array[BeachTarget] = []
var requests: Dictionary = {}
var spawner: BeachSpawner

func setup(backdrop: BeachBackdrop, source: BeachSpawner) -> void:
	stalls = backdrop.stalls
	spawner = source
	for buyer: BeachTarget in spawner.targets:
		bind(buyer)

func bind(buyer: BeachTarget) -> void:
	buyer.stall_service = self
	if buyer.kind == "picnic_family":
		var stand: FoodStall = find_stall(buyer,"kiosk")
		if stand != null:
			buyer.family_kiosk_x = stand.contact_x()

func find_stall(buyer: BeachTarget, type: String = "") -> FoodStall:
	var best: FoodStall
	var gap: float = INF
	for stand: FoodStall in stalls:
		if not type.is_empty() and ("hotdog_stand" if stand.hotdog else "kiosk") != type:
			continue
		var distance: float = absf(stand.position.x-buyer.position.x)
		if distance < gap:
			gap = distance
			best = stand
	return best

func request_family(buyer: BeachTarget) -> bool:
	var stand: FoodStall = find_stall(buyer,"kiosk")
	if stand == null or requests.has(stand):
		return false
	var orders: Array[Dictionary] = []
	for child: BeachTarget in buyer.family_children:
		if is_instance_valid(child) and not child.food and not child.dropped_pending:
			orders.append({"buyer":child,"id":"ice_cream" if child.wants_ice_cream else "crisps_bag","reserve":false})
	var total: int = buyer.supply_crisps+(1 if buyer.food and buyer.food_id=="crisps_bag" else 0)
	# A dropped, still-owned bag is stock too; recovering it must not make three.
	if buyer.dropped_pending and buyer.food_id=="crisps_bag":
		total += 1
	for i: int in maxi(0,int(Config.tuning.world.family_crisp_bags)-total):
		orders.append({"buyer":buyer,"id":"crisps_bag","reserve":buyer.food or buyer.dropped_pending or i>0})
	if orders.is_empty():
		buyer.family_trip = BeachTarget.FamilyTrip.RETURN
		return true
	_begin(stand,buyer,orders,true)
	return true

func request_shopper(buyer: BeachTarget) -> bool:
	var type: String = buyer.purchase_stall_type()
	var stand: FoodStall = find_stall(buyer,type)
	if stand == null or requests.has(stand) or buyer.food or buyer.dropped_pending:
		return false
	if absf(buyer.position.x-stand.contact_x()) > 0.5:
		return false
	_begin(stand,buyer,[{"buyer":buyer,"id":buyer.food_id,"reserve":false}],false)
	return true

func _begin(stand: FoodStall, buyer: BeachTarget, orders: Array[Dictionary], family: bool) -> void:
	requests[stand] = {"owner":buyer,"orders":orders,"index":0,"time":0.0,"portion":null,"family":family,"serial":buyer.family_trip_serial}
	buyer.service_locked = true
	if family:
		for child: BeachTarget in buyer.family_children:
			child.service_locked = true
	_next(stand)
	var bubble := OrderBubble.new()
	buyer.add_child(bubble)
	bubble.position = Vector2(-8+buyer.facing*4,-buyer.art_height()-14).round()
	requests[stand].order_bubble = bubble

func _next(stand: FoodStall) -> void:
	var request: Dictionary = requests[stand]
	var order: Dictionary = request.orders[request.index]
	stand.phase = FoodStall.Phase.PREPARE
	stand.progress = 0.0
	stand.show_food(str(order.id))
	request.time = 0.0
	request.portion = null
	var buyer: BeachTarget = order.buyer
	if is_instance_valid(buyer):
		buyer.service_locked = true
		buyer.facing = stand.side if bool(order.reserve) and buyer.food else -stand.side
		buyer.update_art_pose(false)

func tick(delta: float) -> void:
	for stand: FoodStall in stalls:
		stand.advance(delta)
		if requests.has(stand):
			var request: Dictionary = requests[stand]
			if request.has("order_bubble"):
				var bubble: Control = request.order_bubble
				if not is_instance_valid(bubble):
					request.erase("order_bubble")
				elif bubble.advance(delta):
					bubble.queue_free()
					request.erase("order_bubble")
			_tick_request(stand,delta)
		stand.sync_pose()
	for portion: BeachTarget in portions.duplicate():
		if not portion.food and not portion.dropped_pending and not _is_active(portion):
			portions.erase(portion)
			portion.queue_free()
		elif portion.dropped_pending and bool(portion.dropped_item.get("recovered",false)):
			portion.dropped_pending = false

func _is_active(portion: BeachTarget) -> bool:
	for request: Dictionary in requests.values():
		if request.portion == portion:
			return true
	return false

func _tick_request(stand: FoodStall, delta: float) -> void:
	var request: Dictionary = requests[stand]
	var owner: BeachTarget = request.owner
	var order: Dictionary = request.orders[request.index]
	var buyer: BeachTarget = order.buyer
	if not is_instance_valid(owner) or not is_instance_valid(buyer) or owner.leaving or (bool(request.family) and owner.family_trip != BeachTarget.FamilyTrip.BUY):
		_finish(stand,false)
		return
	# Plant buyers beside the shelf; all food waits on the same counter surface.
	var destination: float = stand.position.x+stand.side*(40.0 if buyer.kind=="toddler" else 47.0)
	var moving: bool = absf(buyer.position.x-destination)>0.25
	buyer.position.x = move_toward(buyer.position.x,destination,float(Config.tuning.world.family_trip_speed)*delta)
	buyer.facing = stand.side if bool(order.reserve) and buyer.food else -stand.side
	buyer.update_art_pose(moving)
	if moving:
		return
	request.time = float(request.time)+delta
	var duration: float = float(Config.tuning.world.stall_prepare_time)
	match stand.phase:
		FoodStall.Phase.PREPARE:
			stand.progress = minf(1.0,float(request.time)/duration)
			if float(request.time)>=duration:
				stand.phase = FoodStall.Phase.PLACE
				stand.progress = 0.0
				request.time = 0.0
		FoodStall.Phase.PLACE:
			duration = float(Config.tuning.world.stall_extend_time)
			stand.progress = minf(1.0,float(request.time)/duration)
			if float(request.time)>=duration:
				if not bool(order.reserve) and (buyer.food or buyer.dropped_pending):
					_finish(stand,false)
					return
				var portion := StallPortion.new()
				spawner.parent.add_child(portion)
				portion.prepare(str(order.id),spawner.rng,buyer)
				portion.position = stand.counter_food_position()
				portion.intercepted.connect(func(gull: BeachGull) -> void: _intercept(stand,portion,gull))
				portion.food_knocked.connect(func(_target: BeachTarget,_id: String,_at: Vector2,_impulse: Vector2) -> void: _interrupt(stand,portion))
				portions.append(portion)
				request.portion = portion
				portion_created.emit(portion)
				stand.phase = FoodStall.Phase.COUNTER
				stand.progress = 0.0
				request.time = 0.0
		FoodStall.Phase.COUNTER:
			duration = float(Config.tuning.world.stall_handover_time)
			var portion: BeachTarget = request.portion
			if not portion.food:
				_finish(stand,false)
				return
			stand.progress = minf(1.0,float(request.time)/duration)
			# The placed snack stays still on the shelf until the buyer collects it.
			portion.position = stand.counter_food_position()
			if float(request.time)>=duration:
				_deliver(request,order)
				request.received_from = portion.position
				if not bool(order.reserve) and buyer.food:
					buyer.food_sprite.position = portion.position-buyer.position
				portion.food = false
				portion.hide()
				stand.phase = FoodStall.Phase.RETRACT
				request.time = 0.0
		FoodStall.Phase.RETRACT:
			duration = float(Config.tuning.world.stall_retract_time)
			stand.progress = minf(1.0,float(request.time)/duration)
			if not bool(order.reserve) and buyer.food:
				buyer.food_sprite.position = Vector2(request.received_from).lerp(buyer.food_position(),stand.progress)-buyer.position
			if float(request.time)>=duration:
				buyer.service_locked = false
				request.index = int(request.index)+1
				if int(request.index)>=request.orders.size():
					_finish(stand,true)
				else:
					_next(stand)

func _deliver(request: Dictionary, order: Dictionary) -> void:
	var buyer: BeachTarget = order.buyer
	if bool(order.reserve):
		buyer.supply_crisps += 1
	elif not buyer.food and not buyer.dropped_pending:
		buyer.food_id = str(order.id)
		buyer.food = true
		buyer.recover = 0.0
		buyer.wants_ice_cream = false
		buyer.toddler_cry_run_active = false
		buyer.seeking_parent = false
		buyer.refresh_art()
		if bool(request.family):
			buyer.purchase_trip_serial = int(request.serial)
	if bool(request.family):
		request.owner.purchased_on_trip += 1

func _intercept(stand: FoodStall, portion: StallPortion, gull: BeachGull) -> void:
	if is_instance_valid(portion.recipient):
		var buyer: BeachTarget = portion.recipient
		buyer.reaction.theft(buyer,gull,portion.last_theft_direct)
		buyer.recover = float(Config.tuning.world.recover_time)
		buyer.respawn = float(Config.tuning.world.stall_retry_wait)
		if buyer.kind == "pier_diner":
			buyer.diner_meal = BeachTarget.DinerMeal.DINING
		# Counter interception bypasses BeachTarget._finish_theft, so present the
		# recipient's successful-theft reaction immediately on this same frame.
		buyer.update_art_pose(false)
	_interrupt(stand,portion)

func _interrupt(stand: FoodStall, portion: StallPortion) -> void:
	if not requests.has(stand) or requests[stand].portion != portion:
		return
	var request: Dictionary = requests[stand]
	if bool(request.family):
		request.owner.family_purchase_stolen(int(request.serial))
	_finish(stand,false)

func _finish(stand: FoodStall, success: bool) -> void:
	var request: Dictionary = requests[stand]
	if request.has("order_bubble") and is_instance_valid(request.order_bubble):
		request.order_bubble.queue_free()
	for order: Dictionary in request.orders:
		if is_instance_valid(order.buyer):
			order.buyer.service_locked = false
	var owner: BeachTarget = request.owner
	if is_instance_valid(owner):
		owner.service_locked = false
		if bool(request.family):
			for child: BeachTarget in owner.family_children:
				if is_instance_valid(child):
					child.service_locked = false
		if bool(request.family) and success:
			owner.family_trip = BeachTarget.FamilyTrip.RETURN
		elif not bool(request.family):
			owner.respawn = float(Config.tuning.world.stall_retry_wait)
			if owner.kind == "pier_diner":
				owner.diner_meal = BeachTarget.DinerMeal.RETURN if success and owner.food else BeachTarget.DinerMeal.DINING
			elif success:
				owner.patrol_home = stand.contact_x()+stand.side*12.0
				owner.routine.purchased(owner,stand.contact_x())
	var portion: BeachTarget = request.portion
	if is_instance_valid(portion) and portion.food:
		portion.food = false
		portion.hide()
	requests.erase(stand)
	stand.phase = FoodStall.Phase.IDLE
	stand.progress = 0.0
	stand.food_texture = null
