class_name BeachTarget
extends Node2D
signal snatched(target: BeachTarget, gull: BeachGull, risky: bool)
signal cried(target: BeachTarget)
signal whistled(target: BeachTarget)
signal departed(target: BeachTarget)
signal food_knocked(target: BeachTarget, food_id: String, at: Vector2, impulse: Vector2)
var kind: String
var info: Dictionary
var alert: float = 0.0
var food: bool = true
var food_id: String = ""
var dropped_pending: bool = false
var dropped_item: Dictionary = {}
var drop_retrieve: bool = false
var drop_pickup_time: float = 0.0
var thefts: int = 0
var last_theft_direct: bool = false
var respawn: float = 0.0
var recover: float = 0.0
var defense: float = 0.0
var windup: float = -1.0
var overhead: float = 0.0
var leaving: bool = false
var facing: float = 1.0
var patrol_home: float
var patrol_radius: float = 35.0
var awareness_mult: float = 1.0
var encounter_awareness: float = 1.0
var speed_mult: float = 1.0
var reaction_delay: float = 1.0
var sprite: AnimatedSprite2D
var food_sprite: AnimatedSprite2D
var rng: RandomNumberGenerator
var art_time: float = 0.0
var family_id: String = ""
var family_parent: BeachTarget
var family_children: Array[BeachTarget] = []
var supply_crisps: int = 0
var supply_cookies: int = 0
var stash_remaining: int = 0
var stash_home_x: float = 0.0
var stash_active: bool = false
var stash_standing: bool = false
const BAG_SQUISH_TIME: float = 0.18
const BAG_PIVOT: Vector2 = Vector2(0, 8)
const BAG_TEXTURES: Array[Texture2D] = [
	preload("res://assets/sprites/retro-picnic-bag-coral-32bit.png"),
	preload("res://assets/sprites/retro-picnic-bag-teal-32bit.png"),
	preload("res://assets/sprites/retro-picnic-bag-woven-32bit.png"),
]
var bag_variant: int = 0
var bag_squish_time: float = 0.0
var bag_squish_duration: float = BAG_SQUISH_TIME
var bag_squish_strength: float = 0.12
var bag_release_bounce: bool = false
var sunbather_blue: bool = false
var sunbather_female: bool = false
var sunbather_run_time: float = 0.0
var seeking_parent: bool = false
var handover_timer: float = 0.0
var handover_x: float = NAN
enum FamilyTrip { IDLE, GATHER, TO_STAND, BUY, RETURN, RETREAT, COOLDOWN }
var family_trip: FamilyTrip = FamilyTrip.IDLE
var family_home: float = 0.0
var family_kiosk_x: float = 520.0
var family_trip_timer: float = 0.0
var family_trip_serial: int = 0
var purchased_on_trip: int = 0
var purchase_trip_serial: int = -1
var wants_ice_cream: bool = false
var family_slot: int = 0
var toddler_cry_timer: float = 0.0
var toddler_run_speed: float = 0.0
var toddler_cry_run_active: bool = false
var mum_swat_time: float = 0.0
var action_pose_time: float = 0.0
var reaction: AdultReaction = AdultReaction.new()

func art_height() -> float:
	if kind == "sunbather":
		return 40.0 if stash_standing else 20.0
	if kind == "picnic_family":
		return 40.0
	var entry: Dictionary = Config.sprites[info.sprite]
	return float(entry.frame_h) * float(entry.get("visual_scale",1.0))

func stash_position() -> Vector2:
	return Vector2(clampf(stash_home_x-30,16,float(Config.tuning.world.width)-16),float(Config.tuning.world.ground)-9)

func peck_bag(progress: float = 0.0, released: bool = false) -> void:
	bag_squish_duration = 0.30 if released else BAG_SQUISH_TIME
	bag_squish_time = bag_squish_duration
	bag_squish_strength = 0.13 + 0.08 * clampf(progress,0.0,1.0)
	bag_release_bounce = released
	queue_redraw()

func update_art_pose(moving: bool = false) -> void:
	if kind == "pier_diner":
		PierDinerArt.update(self, moving)
		return
	if kind in ["kiosk_customer","dog_owner"]:
		BeachgoerArt.update(self,moving)
		return
	if kind == "picnic_family":
		MumArt.update(self,moving)
		return
	if kind != "toddler":
		return
	sprite.flip_h = facing < 0
	var anchor: Array = Config.sprites[info.sprite].get("food_anchor",[Config.tuning.world.food_offset_x,Config.tuning.world.food_offset_y])
	food_sprite.position = Vector2(float(anchor[0])*facing,anchor[1])
	var pose: StringName = &"walk" if moving else (&"eat" if food else &"idle")
	if not food and (seeking_parent or toddler_cry_run_active or recover > 0) and not leaving:
		pose = &"walk" if moving else &"cry"
	sprite.play(pose)

func setup(type: String, x: float, random: RandomNumberGenerator, mult: float, spawn: Dictionary = {}) -> void:
	kind = type
	info = Config.targets[kind]
	# Sunbathers and their bags belong on the sand, before the promenade begins.
	if kind == "sunbather":
		x = clampf(x,float(Config.tuning.world.beach_min_x),float(Config.tuning.world.beach_max_x))
	position = Vector2(x, Config.tuning.world.ground)
	patrol_home = x
	patrol_radius = float(spawn.get("patrol_radius",35.0))
	stash_home_x = x
	family_home = x
	rng = random
	encounter_awareness = float(spawn.get("awareness_mult",1.0))
	awareness_mult = mult * encounter_awareness
	speed_mult = float(spawn.get("speed_mult",1.0))
	reaction_delay = float(spawn.get("reaction_delay",1.0))
	family_id = str(spawn.get("family_id", ""))
	var choices: Array = info.foods
	food_id = str(choices[rng.randi_range(0,choices.size()-1)]) if not choices.is_empty() else ""
	if kind == "kiosk_customer" and Config.foods.has(str(spawn.get("food_id",""))):
		food_id = str(spawn.food_id)
	if kind == "picnic_family":
		food_id = "crisps_bag"
	food = not food_id.is_empty()
	if kind == "picnic_family":
		supply_crisps = int(Config.tuning.world.family_crisp_bags)
		supply_cookies = int(Config.tuning.world.family_cookie_reserve)
		# The snack already in mum's hand is part of, not additional to, her stock.
		if food and food_id == "crisps_bag":
			supply_crisps = maxi(0, supply_crisps - 1)
	elif kind == "sunbather":
		food_id = ""
		food = false
		stash_remaining = maxi(0,int(Config.tuning.world.sunbather_stash_size))
		sunbather_blue = int(x/100.0)%2 == 1
		var appearance: String = str(spawn.get("appearance",""))
		sunbather_female = appearance.begins_with("female")
		if not appearance.is_empty():
			sunbather_blue = appearance.ends_with("blue")
	sprite = AnimatedSprite2D.new()
	add_child(sprite)
	food_sprite = AnimatedSprite2D.new()
	add_child(food_sprite)
	refresh_art()
	if kind == "picnic_family":
		sprite.frame_changed.connect(func() -> void: MumArt.align_food(self))
	elif kind == "pier_diner":
		sprite.frame_changed.connect(func() -> void: PierDinerArt.align_food(self))
	elif kind in ["kiosk_customer","dog_owner"]:
		sprite.frame_changed.connect(func() -> void: BeachgoerArt.align_food(self))
	Config.reloaded.connect(refresh_art)

func refresh_art() -> void:
	info = Config.targets[kind]
	if kind == "sunbather":
		sprite.sprite_frames = SunbatherArt.frames(sunbather_blue,sunbather_female)
	elif kind == "pier_diner":
		sprite.sprite_frames = PierDinerArt.frames()
	else:
		sprite.sprite_frames = Config.frames(info.sprite)
	sprite.scale = Vector2.ONE if kind in ["picnic_family", "sunbather"] else Vector2.ONE * float(Config.sprites[info.sprite].get("visual_scale",1.0))
	# The toddler is painted at high resolution, then shown small in the 320x180
	# world. Render it with smooth mipmapped sampling at the display resolution;
	# the rest of the pixel-art cast keeps the project-wide nearest filter.
	if kind in ["toddler","kiosk_customer","dog_owner"]:
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	elif kind in ["pier_diner", "picnic_family", "sunbather"]:
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position.y = -26.0 if kind in ["picnic_family", "sunbather"] else -art_height() * 0.5
	sprite.material = null
	if Config.sprites[info.sprite].has("visual_scale") and kind not in ["picnic_family", "sunbather"]:
		var cutout: ShaderMaterial = ShaderMaterial.new()
		cutout.shader = preload("res://assets/shaders/gull_cutout.gdshader")
		sprite.material = cutout
	sprite.play(sprite.sprite_frames.get_animation_names()[0])
	if not food_id.is_empty():
		var definition: Dictionary = Config.foods[food_id]
		food_sprite.sprite_frames = Config.frames(definition.sprite)
		food_sprite.play(&"idle")
		var texture: Texture2D = food_sprite.sprite_frames.get_frame_texture(&"idle",0)
		food_sprite.scale = Vector2(definition.size[0],definition.size[1]) / texture.get_size()
	food_sprite.position = Vector2(Config.tuning.world.food_offset_x, Config.tuning.world.food_offset_y)
	food_sprite.visible = food
	update_art_pose()
	if kind == "sunbather":
		SunbatherArt.pose(self,&"rest",0)

func food_position() -> Vector2:
	return position + food_sprite.position

func food_value() -> int:
	return int(Config.foods[food_id].points) if not food_id.is_empty() else 0

func food_radius() -> Vector2:
	var radius: Array = Config.foods[food_id].pickup_radius
	return Vector2(radius[0],radius[1])

func tick(delta: float, gulls: Array[BeachGull]) -> void:
	var t: Dictionary = Config.tuning.world
	art_time += delta
	bag_squish_time = maxf(0.0, bag_squish_time-delta)
	mum_swat_time = maxf(0,mum_swat_time-delta)
	action_pose_time = maxf(0, action_pose_time-delta)
	var moved: bool = false
	recover = maxf(0.0, recover - delta)
	defense = maxf(0.0, defense - delta)
	if reaction.tick(self,delta,gulls):
		return
	if kind == "toddler" and _tick_toddler_cry_run(delta):
		_tick_defense(delta,gulls)
		_update_defense_art()
		queue_redraw()
		return
	if leaving:
		position.x += facing * float(t.walk_speed) * 3.0 * delta
		update_art_pose(true)
		if position.x < -20 or position.x > float(t.width) + 20:
			departed.emit(self)
		return
	if kind == "picnic_family" and family_trip != FamilyTrip.IDLE:
		var before_trip_x: float = position.x
		_tick_family_trip(delta)
		_tick_defense(delta,gulls)
		_update_defense_art()
		update_art_pose(not is_equal_approx(position.x,before_trip_x))
		queue_redraw()
		return
	if kind == "toddler" and is_instance_valid(family_parent) and family_parent.family_trip != FamilyTrip.IDLE:
		_tick_family_follower(delta)
		_tick_defense(delta,gulls)
		_update_defense_art()
		queue_redraw()
		return
	if kind == "toddler" and seeking_parent:
		_tick_family_replacement(delta)
		queue_redraw()
		return
	if dropped_pending and drop_retrieve and not dropped_item.is_empty() and bool(dropped_item.get("grounded",false)):
		var destination: float = float(dropped_item.position.x)
		var gap: float = destination-position.x
		if absf(gap) > float(t.drop_retrieve_reach):
			facing = signf(gap)
			position.x += facing*minf(absf(gap),float(t.drop_retrieve_speed)*delta)
			update_art_pose(true)
		else:
			drop_pickup_time += delta
			update_art_pose(false)
			if drop_pickup_time >= float(t.drop_pickup_pause):
				recover_dropped()
		_tick_defense(delta,gulls)
		queue_redraw()
		return
	if not food and not dropped_pending and not food_id.is_empty() and kind not in ["toddler", "picnic_family", "sunbather"]:
		respawn -= delta
		if respawn <= 0:
			food = true
			food_sprite.show()
	# Brief eating stops and a planted crying pose make the new toddler frames readable.
	var toddler_pause: bool = kind == "toddler" and not seeking_parent and ((not food and recover > 0) or (food and fmod(art_time,6.0) < 1.2))
	# A short planted reaction makes the customer's empty-hand surprise readable.
	var customer_pause: bool = kind == "kiosk_customer" and not food and recover > float(t.recover_time)-0.5
	if info.twist in ["walk", "cry", "whistle"] and not toddler_pause and not customer_pause:
		position.x += facing * float(t.walk_speed) * speed_mult * delta
		moved = true
		if absf(position.x - patrol_home) > patrol_radius or position.x < 20 or position.x > float(t.width) - 20:
			facing *= -1
	_tick_defense(delta,gulls)
	_update_defense_art()
	update_art_pose(moved)
	queue_redraw()

func _update_defense_art() -> void:
	food_sprite.modulate = Color("ef725c") if defense > 0 and info.twist == "shield" else Color.WHITE
	var animation: String = ""
	if defense > 0:
		animation = "windup" if windup > 0 else ("shield" if info.twist == "shield" else "swat")
	elif recover > 0:
		animation = "cry" if info.twist == "cry" else "angry"
	if kind not in ["toddler", "sunbather", "picnic_family", "kiosk_customer", "dog_owner", "pier_diner"]:
		if sprite.sprite_frames.has_animation(animation):
			sprite.play(animation)
		else:
			sprite.play(sprite.sprite_frames.get_animation_names()[0])

func _tick_defense(delta: float, gulls: Array[BeachGull]) -> void:
	var t: Dictionary = Config.tuning.world
	var seen: bool = false
	for gull: BeachGull in gulls:
		var offset: Vector2 = gull.position - position
		if offset.length() < float(info.awareness) * awareness_mult and gull.position.y > float(info.altitude):
			seen = true
			alert = minf(1.0,alert+float(info.rise)*awareness_mult*(float(t.front_multiplier) if signf(offset.x)==facing else 1.0)*delta)
		if info.twist == "whistle" and gull.state == BeachGull.State.STRIKE and offset.length() < float(t.whistle_trigger) and recover <= 0:
			whistled.emit(self)
			recover = t.recover_time
		if info.twist == "dog" and absf(offset.x) < float(t.dog_overhead):
			overhead += delta
			if overhead >= float(t.dog_delay):
				alert = 1.0
		if alert >= 1.0 and defense <= 0 and recover <= 0:
			defense = t.shield_time
			recover = float(t.shield_time)+float(t.recover_time)
			if info.twist == "broom":
				windup = info.windup
		var can_attack: bool = defense > 0 and int(info.danger) > 0
		if info.twist == "dog":
			can_attack = alert >= 1.0 and gull.position.y > float(t.dog_altitude)
		if info.twist == "broom":
			can_attack = defense > 0 and windup <= 0
		if can_attack and kind == "toddler" and gull.position.distance_to(food_position()) < float(info.danger):
			if kind == "picnic_family" and gull.state != BeachGull.State.STUNNED and gull.invulnerable <= 0:
				mum_swat_time = 0.25
			gull.stun()
	if windup >= 0:
		windup -= delta
	if not seen:
		alert = maxf(0.0,alert-float(t.alert_decay)*delta)
		overhead = maxf(0.0,overhead-delta)

func _tick_family_replacement(delta: float) -> void:
	if not is_instance_valid(family_parent):
		seeking_parent = false
		patrol_home = position.x
		return
	if not family_parent.reaction.mode.is_empty():
		handover_x = NAN
	if is_nan(handover_x):
		var approach_side: float = signf(position.x - family_parent.position.x)
		if is_zero_approx(approach_side):
			approach_side = -family_parent.facing
		handover_x = family_parent.position.x + approach_side * float(Config.tuning.world.family_handover_distance)
	var distance: float = absf(handover_x - position.x)
	if distance > 0.25:
		facing = signf(handover_x - position.x)
		toddler_run_speed = move_toward(toddler_run_speed,float(Config.tuning.world.toddler_run_speed),float(Config.tuning.world.toddler_run_acceleration)*delta)
		position.x += facing * minf(distance,toddler_run_speed * delta)
		if (handover_x - position.x) * facing < 0:
			position.x = handover_x
		update_art_pose(true)
		return
	position.x = handover_x
	toddler_run_speed = 0.0
	facing = signf(family_parent.position.x - position.x)
	family_parent.facing = -facing
	if not family_parent.reaction.mode.is_empty():
		update_art_pose(false)
		return
	handover_timer -= delta
	family_parent.handover_timer = maxf(family_parent.handover_timer, handover_timer)
	if handover_timer > 0:
		update_art_pose(false)
		family_parent.queue_redraw()
		return
	var replacement: String = family_parent.take_family_snack()
	seeking_parent = false
	handover_x = NAN
	patrol_home = position.x
	family_parent.handover_timer = 0.0
	if replacement.is_empty():
		family_parent.request_family_help(self)
		update_art_pose(false)
		return
	food_id = replacement
	food = true
	recover = 0.0
	refresh_art()

func _tick_toddler_cry_run(delta: float) -> bool:
	if not toddler_cry_run_active:
		return false
	toddler_cry_timer = 0
	if not is_instance_valid(family_parent) or food:
		toddler_cry_run_active = false
		toddler_run_speed = 0.0
		return false
	if family_parent.family_trip == FamilyTrip.IDLE:
		toddler_cry_run_active = false
		seeking_parent = true
		return false
	var distance: float = family_parent.position.x-position.x
	if absf(distance) <= 0.25:
		toddler_cry_run_active = false
		toddler_run_speed = 0.0
		return false
	facing = signf(distance)
	toddler_run_speed = move_toward(toddler_run_speed,float(Config.tuning.world.toddler_run_speed),float(Config.tuning.world.toddler_run_acceleration)*delta)
	position.x += facing * minf(absf(distance),toddler_run_speed*delta)
	update_art_pose(true)
	return true

func take_family_snack() -> String:
	if kind != "picnic_family":
		return ""
	# Transfer the visible held bag first. If the gull already stole it, food is
	# false and only the separately tracked reserve can be used.
	if food and food_id == "crisps_bag":
		food = false
		food_sprite.hide()
		queue_redraw()
		return "crisps_bag"
	if supply_crisps > 0:
		supply_crisps -= 1
		queue_redraw()
		return "crisps_bag"
	if supply_cookies > 0:
		supply_cookies -= 1
		queue_redraw()
		return "cookie"
	return ""

func request_family_help(child: BeachTarget) -> void:
	if kind != "picnic_family" or not is_instance_valid(child):
		return
	if family_trip != FamilyTrip.IDLE:
		return
	var has_backup: bool = food or supply_crisps > 0 or supply_cookies > 0
	var insist: bool = has_backup and rng.randf() < float(Config.tuning.world.family_ice_cream_chance)
	child.wants_ice_cream = insist
	if has_backup and not insist:
		return
	_start_family_trip()

func _start_family_trip() -> void:
	family_trip = FamilyTrip.GATHER
	family_trip_timer = float(Config.tuning.world.family_gather_pause)
	family_trip_serial += 1
	purchased_on_trip = 0
	family_home = patrol_home
	for i: int in family_children.size():
		var child: BeachTarget = family_children[i]
		if not is_instance_valid(child):
			continue
		child.family_slot = i
		child.seeking_parent = false
		child.handover_timer = 0.0
		child.handover_x = NAN

func _family_all_gathered() -> bool:
	for child: BeachTarget in family_children:
		if is_instance_valid(child) and absf(child.position.x-position.x) > float(Config.tuning.world.family_gather_distance):
			return false
	return true

func _move_family_toward(destination: float, delta: float) -> bool:
	var distance: float = destination-position.x
	if absf(distance) <= 0.25:
		position.x = destination
		return true
	facing = signf(distance)
	position.x += facing * minf(absf(distance),float(Config.tuning.world.family_trip_speed)*delta)
	return false

func _tick_family_trip(delta: float) -> void:
	var previous_x: float = position.x
	match family_trip:
		FamilyTrip.GATHER:
			family_trip_timer -= delta
			if _family_all_gathered() and family_trip_timer <= 0:
				family_trip = FamilyTrip.TO_STAND
		FamilyTrip.TO_STAND:
			if _move_family_toward(family_kiosk_x,delta) and _family_all_gathered():
				family_trip = FamilyTrip.BUY
				family_trip_timer = float(Config.tuning.world.family_purchase_pause)
		FamilyTrip.BUY:
			family_trip_timer -= delta
			if family_trip_timer <= 0:
				_complete_family_purchase()
				family_trip = FamilyTrip.RETURN
		FamilyTrip.RETURN:
			if _move_family_toward(family_home,delta) and _family_all_gathered():
				_offer_family_fallbacks()
				if _family_needs_purchase():
					family_trip = FamilyTrip.COOLDOWN
					family_trip_timer = float(Config.tuning.world.family_retry_wait)
				else:
					_finish_family_trip()
		FamilyTrip.RETREAT:
			if _move_family_toward(_family_retreat_x(),delta) and _family_all_gathered():
				_offer_family_fallbacks()
				family_trip = FamilyTrip.COOLDOWN
				family_trip_timer = float(Config.tuning.world.family_retry_wait)
		FamilyTrip.COOLDOWN:
			family_trip_timer -= delta
			if family_trip_timer <= 0:
				if _family_needs_purchase():
					_start_family_trip()
				else:
					_finish_family_trip()
		_:
			_finish_family_trip()
	update_art_pose(not is_equal_approx(position.x,previous_x))

func _tick_family_follower(delta: float) -> void:
	if not family_parent.reaction.mode.is_empty():
		update_art_pose(false)
		return
	var spacing: float = float(Config.tuning.world.family_follow_spacing)
	var side: float = -1.0 if family_slot % 2 == 0 else 1.0
	var row: float = float(family_slot / 2 + 1)
	var destination: float = family_parent.position.x + side * spacing * row
	var distance: float = destination-position.x
	if absf(distance) > 0.25:
		facing = signf(distance)
		position.x += facing * minf(absf(distance),maxf(float(Config.tuning.world.family_seek_speed),float(Config.tuning.world.family_trip_speed)+2.0)*delta)
		update_art_pose(true)
	else:
		position.x = destination
		facing = family_parent.facing
		update_art_pose(false)

func _complete_family_purchase() -> void:
	# Food is placed in visible hands at the stand, never in hidden cargo.
	for child: BeachTarget in family_children:
		if not is_instance_valid(child) or child.food or child.dropped_pending:
			continue
		child.food_id = "ice_cream" if child.wants_ice_cream else "crisps_bag"
		child.food = true
		child.purchase_trip_serial = family_trip_serial
		child.wants_ice_cream = false
		child.refresh_art()
		purchased_on_trip += 1
	var crisp_total_before: int = supply_crisps + (1 if food and food_id == "crisps_bag" else 0)
	var crisps_bought: int = maxi(0,int(Config.tuning.world.family_crisp_bags)-crisp_total_before)
	if not food and not dropped_pending and crisps_bought > 0:
		food_id = "crisps_bag"
		food = true
		purchase_trip_serial = family_trip_serial
		refresh_art()
		crisps_bought -= 1
	supply_crisps += crisps_bought
	food_sprite.visible = food
	purchased_on_trip += maxi(0,int(Config.tuning.world.family_crisp_bags)-crisp_total_before)

func _family_needs_purchase() -> bool:
	for child: BeachTarget in family_children:
		if is_instance_valid(child) and not child.food and not child.dropped_pending:
			return true
	return not food and not dropped_pending and supply_crisps <= 0 and supply_cookies <= 0

func _family_retreat_x() -> float:
	var direction: float = -1.0 if family_kiosk_x >= float(Config.tuning.world.width)*0.5 else 1.0
	return clampf(family_home + direction*float(Config.tuning.world.family_retreat_distance),20.0,float(Config.tuning.world.width)-20.0)

func _offer_family_fallbacks() -> void:
	for child: BeachTarget in family_children:
		if not is_instance_valid(child) or child.food or child.dropped_pending:
			continue
		var fallback: String = take_family_snack()
		if fallback.is_empty():
			continue
		child.food_id = fallback
		child.food = true
		child.purchase_trip_serial = -1
		child.refresh_art()

func family_purchase_stolen(serial: int) -> void:
	if family_trip != FamilyTrip.RETURN or serial != family_trip_serial:
		return
	family_trip = FamilyTrip.RETREAT
	for child: BeachTarget in family_children:
		if is_instance_valid(child):
			child.wants_ice_cream = false

func _finish_family_trip() -> void:
	family_trip = FamilyTrip.IDLE
	family_trip_timer = 0.0
	patrol_home = position.x
	purchase_trip_serial = -1
	for child: BeachTarget in family_children:
		if is_instance_valid(child):
			child.purchase_trip_serial = -1
			child.patrol_home = child.position.x

func take(gull: BeachGull) -> bool:
	if not gull.can_collect_food(food_id):
		return false
	if kind == "sunbather" or not food or leaving or (info.twist == "shield" and defense > 0):
		return false
	var risky: bool = alert >= 1.0 or defense > 0
	food = false
	food_sprite.hide()
	last_theft_direct = true
	_finish_theft(gull,risky)
	return true

func knock_food(gull: BeachGull) -> bool:
	if kind == "sunbather" or not food or leaving or (info.twist == "shield" and defense > 0):
		return false
	food = false
	food_sprite.hide()
	dropped_pending = true
	drop_retrieve = rng.randf() < float(Config.foods[food_id].get("reclaim_chance",0.0))
	drop_pickup_time = 0.0
	recover = float(Config.tuning.world.recover_time)
	alert = 1.0
	var impulse: Vector2 = gull.velocity.normalized()*float(Config.tuning.world.drop_impulse_side)+Vector2(0,-float(Config.tuning.world.drop_impulse_up))
	food_knocked.emit(self,food_id,food_position(),impulse)
	update_art_pose(false)
	return true

func track_dropped(item: Dictionary) -> void:
	dropped_item = item

func recover_dropped() -> void:
	if not dropped_pending or dropped_item.is_empty():
		return
	dropped_item.recovered = true
	dropped_item = {}
	dropped_pending = false
	drop_retrieve = false
	drop_pickup_time = 0.0
	food = true
	food_sprite.show()
	recover = 0.0
	update_art_pose(false)

func claim_dropped(gull: BeachGull) -> bool:
	if not dropped_pending or not gull.can_collect_food(food_id):
		return false
	dropped_pending = false
	dropped_item = {}
	drop_retrieve = false
	last_theft_direct = false
	_finish_theft(gull,alert >= 1.0 or defense > 0)
	return true

func _finish_theft(gull: BeachGull, risky: bool) -> void:
	thefts += 1
	respawn = rng.randf_range(Config.tuning.world.respawn_min, Config.tuning.world.respawn_max)
	recover = Config.tuning.world.recover_time
	alert = 1.0
	var stolen_purchase_serial: int = purchase_trip_serial
	purchase_trip_serial = -1
	if kind == "toddler" and is_instance_valid(family_parent) and stolen_purchase_serial >= 0:
		family_parent.family_purchase_stolen(stolen_purchase_serial)
	elif kind == "picnic_family" and stolen_purchase_serial >= 0:
		family_purchase_stolen(stolen_purchase_serial)
	# Repeated theft now leads to a bounded chase and return, not departure.
	snatched.emit(self, gull, risky)
	reaction.theft(self,gull)
	if info.twist == "cry":
		toddler_cry_timer = float(Config.tuning.world.toddler_cry_duration)
		toddler_run_speed = 0.0
		toddler_cry_run_active = true
		if is_instance_valid(family_parent):
			family_parent.request_family_help(self)
		seeking_parent = is_instance_valid(family_parent) and family_parent.family_trip == FamilyTrip.IDLE
		handover_timer = float(Config.tuning.world.family_handover_pause)
		handover_x = NAN
		cried.emit(self)
	update_art_pose(leaving)

func _draw() -> void:
	if kind == "toddler" and not food and (seeking_parent or toddler_cry_run_active):
		for i: int in 2:
			var fall: float = fposmod(art_time*14+i*4,8)
			draw_circle(Vector2(facing*4,-15+fall),0.8,Color("72c9ef"))
	if Config.sprites[info.sprite].has("visual_scale"):
		draw_set_transform(Vector2(0,-1),0,Vector2(1,0.25))
		draw_circle(Vector2.ZERO,7,Color(0.09,0.18,0.22,0.20))
		draw_set_transform(Vector2.ZERO)
	var awareness_cue: String = ""
	var fill: float = alert
	var color: Color = Color("ffc65c")
	if reaction.mode in ["warning","wake"]:
		awareness_cue = "WATCH"
		fill = clampf(1.0-reaction.timer/((0.8 if kind == "sunbather" else 0.35)*reaction_delay),0.05,1.0)
	elif reaction.mode == "chase":
		awareness_cue = "CHASE"
		fill = clampf(reaction.timer/3.0,0.0,1.0)
		color = Color("ef725c")
	elif defense > 0:
		awareness_cue = "BLOCK"
		fill = clampf(defense/float(Config.tuning.world.shield_time),0.0,1.0)
		color = Color("ef725c")
	elif alert > 0.05:
		awareness_cue = "ALERT" if alert >= 0.95 else "SEEN"
		color = Color("ef725c") if alert >= 0.95 else Color("ffc65c")
	elif reaction.cooldown > 0:
		awareness_cue = "CALM"
		fill = clampf(reaction.cooldown,0.0,1.0)
		color = Color("80bcb8")
	if not awareness_cue.is_empty():
		var marker_y: float = -art_height()-20
		draw_rect(Rect2(-16,marker_y-9,32,9),Color("183b4e"))
		draw_string(preload("res://assets/fonts/gull_pixel.fnt"),Vector2(-14,marker_y-2),awareness_cue,HORIZONTAL_ALIGNMENT_LEFT,-1,8,color)
		draw_rect(Rect2(-16,marker_y,32,3),Color("397a85"))
		draw_rect(Rect2(-16,marker_y,32*clampf(fill,0.0,1.0),3),color)
	if kind == "sunbather":
		# Large zipped picnic duffle beside the feet. Food stays inside until pecked.
		var bag_anchor: Vector2 = stash_position()-position
		var phase: float = 1.0-bag_squish_time/bag_squish_duration if bag_squish_time > 0.0 else 0.0
		var squish: float = sin(PI * phase)
		var rebound: float = 0.17*sin(PI*(phase-0.55)/0.45) if bag_release_bounce and phase > 0.55 and bag_squish_time > 0.0 else 0.0
		var stretch: float = bag_squish_strength*squish-rebound
		draw_set_transform(bag_anchor+BAG_PIVOT, 0.0, Vector2(1.0+stretch*0.55,1.0-stretch))
		var bag: Vector2 = -BAG_PIVOT
		# The 32x24 sprite's bottom-centre sits on the old bag's base, so pecks squish it the same way.
		draw_texture(BAG_TEXTURES[bag_variant],bag+Vector2(-16,-15))
		if stash_remaining > 0:
			draw_rect(Rect2(bag+Vector2(-5,1),Vector2(stash_remaining*3+1,4)),Color("183b4e"))
		for i: int in stash_remaining:
			draw_rect(Rect2(bag+Vector2(-4+i*3,2),Vector2(2,2)),Color("ffc65c"))
		draw_set_transform(Vector2.ZERO)
		if stash_standing and (sprite.animation == &"run" or absf(position.x-stash_home_x)>1):
			var towel_x: float = stash_home_x-position.x-23
			var towel_color: Color = Color("f3c443") if sunbather_blue else (Color("ef725c") if sunbather_female else Color("408fa8"))
			draw_rect(Rect2(towel_x,-3,46,3),towel_color)
			for stripe: int in 7:
				draw_rect(Rect2(towel_x+stripe*6.6,-3,2.2,3),Color("fff4da"))
	if kind == "picnic_family":
		for i: int in supply_crisps:
			draw_rect(Rect2(-12+i*4,-7,3,4),Color("ef725c"),true)
		for i: int in supply_cookies:
			draw_circle(Vector2(-11+i*4,-11),1.5,Color("d8944f"))
		if handover_timer > 0:
			draw_line(Vector2(0,-18),Vector2(facing*10,-14),Color("ffc65c"),2)
		if family_trip != FamilyTrip.IDLE:
			var cue: String = ["","GATHER","KIOSK","BUY","HOME","RETREAT","WAIT"][int(family_trip)]
			draw_string(preload("res://assets/fonts/gull_pixel.fnt"),Vector2(-18,-art_height()-11),cue,HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("183b4e"))
