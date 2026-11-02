class_name BeachStashRaids
extends Node2D
## Scattered items remain owned by their source until the gull or owner claims them.
signal collected(position: Vector2, food_id: String, scrap: bool)
signal bag_collected
signal bin_opened(bin_type: String)
signal bin_emptied(bin_type: String)
const BIN_SPILL_SPREAD: float = 90.0
var game: BeachGame
var items: Array[Dictionary] = []
var raids: Dictionary = {}
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var visual_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var peck_cooldown: float = 0.0
var bins: Array[Dictionary] = []
var shine_clock: float = 0.0
var actor: BeachGull ## set while a rival pecks, so the player's code path serves any gull

func _gull() -> BeachGull:
	return actor if actor != null else game.player

## A rival pecks with its own beak and cooldown; bins, bags and risks are the player's.
func peck_as(who: BeachGull) -> bool:
	var saved_cooldown: float = peck_cooldown
	actor = who
	peck_cooldown = 0.0
	var ok: bool = peck()
	actor = null
	peck_cooldown = saved_cooldown
	return ok

func setup(owner_game: BeachGame) -> void:
	game = owner_game
	rng.seed = int(game.level.seed) + 307
	# Cosmetic tumble must not advance the gameplay RNG that controls food trajectories.
	visual_rng.seed = int(game.level.seed) + 1307
	for prop: Dictionary in game.beach.props:
		var type: String = str(prop.type)
		if BeachBackdrop.is_bin_type(type):
			var capacity: int = int(Config.tuning.world.bin_stash_size)
			if type == BeachBackdrop.WHEELIE_BIN_TYPE:
				capacity *= int(Config.tuning.world.wheelie_bin_stash_multiplier)
			bins.append({"type":type,"x":float(prop.x),"content_y":BeachBackdrop.bin_content_y(prop),"requires_top_landing":type==BeachBackdrop.WHEELIE_BIN_TYPE,"capacity":capacity,"remaining":capacity,"pecks":0,"scatter_index":0})

func nearby_bin(include_empty: bool = false) -> Dictionary:
	if _gull().state != BeachGull.State.GROUNDED:
		return {}
	var nearest: Dictionary = {}
	var distance: float = float(Config.tuning.world.peck_reach)
	for bin: Dictionary in bins:
		if int(bin.remaining) <= 0 and not include_empty:
			continue
		if bool(bin.get("requires_top_landing",false)) and not _gull().is_supported_by(str(bin.type),float(bin.x)):
			continue
		var gap: float = absf(float(bin.x)-_gull().beak().x)
		if gap <= distance:
			distance = gap
			nearest = bin
	return nearest

func has_nearby_source() -> bool:
	return nearby_stash(true) != null or not nearby_bin(true).is_empty()

func nearby_toddler() -> BeachTarget:
	if _gull().state != BeachGull.State.GROUNDED:
		return null
	var beak: Vector2 = _gull().beak()
	var reach: float = float(Config.tuning.world.peck_reach)
	var vertical_tolerance: float = float(Config.tuning.world.toddler_peck_vertical_tolerance)
	var nearest: BeachTarget
	var distance: float = INF
	for target: BeachTarget in game.spawner.targets:
		if not is_instance_valid(target) or target.kind != "toddler" or not target.food or target.leaving or target.dropped_pending or not Config.foods.has(target.food_id):
			continue
		var food: Vector2 = target.food_position()
		var forward_gap: float = (food.x-beak.x)*_gull().facing
		if forward_gap < 0.0 or forward_gap > reach or absf(food.y-beak.y) > vertical_tolerance:
			continue
		if forward_gap < distance:
			distance = forward_gap
			nearest = target
	return nearest

func nearby_stash(include_empty: bool = false) -> BeachTarget:
	if _gull().state != BeachGull.State.GROUNDED:
		return null
	var nearest: BeachTarget
	var distance: float = float(Config.tuning.world.peck_reach)
	for target: BeachTarget in game.spawner.targets:
		if target.kind != "sunbather" or (target.stash_remaining <= 0 and not include_empty):
			continue
		var gap: float = absf(target.stash_position().x-_gull().beak().x)
		if gap <= distance:
			distance = gap
			nearest = target
	return nearest

func peck() -> bool:
	if peck_cooldown > 0 or not game.running:
		return false
	var toddler: BeachTarget = nearby_toddler() if actor == null else null
	if toddler != null:
		return _peck_toddler(toddler)
	var owner: BeachTarget = nearby_stash()
	if owner == null:
		var bin: Dictionary = nearby_bin()
		if not bin.is_empty():
			return _peck_bin(bin)
		owner = nearby_stash(true)
		if owner != null:
			return _peck_empty(owner.stash_position()-Vector2(0,10))
		bin = nearby_bin(true)
		if not bin.is_empty():
			return _peck_empty(_bin_content_position(bin))
		return false
	var t: Dictionary = Config.tuning.world
	peck_cooldown = float(t.peck_cooldown)
	if not raids.has(owner):
		raids[owner] = {"pecks":0,"notice":float(t.sunbather_notice_delay)*owner.reaction_delay if owner.sleep_state == BeachTarget.SleepState.AWAKE else 0.0,"swat":0.0,"action":"","action_time":0.0,"pickup_item":{}}
	var raid: Dictionary = raids[owner]
	if str(raid.get("action","")) == "settle":
		raid.action = ""
		raid.action_time = 0.0
		raid.notice = float(t.sunbather_notice_delay)*owner.reaction_delay
	raid.raider = _gull()
	raid.pecks += 1
	owner.register_bag_peck()
	if owner.sleep_state == BeachTarget.SleepState.AWAKE:
		owner.alert = minf(1,owner.alert+float(t.peck_alert))
	owner.stash_active = true
	var final_hit: bool = int(raid.pecks) >= int(t.stash_pecks)
	var progress: float = clampf(float(raid.pecks)/float(maxi(1,int(t.stash_pecks))),0.0,1.0)
	game.effects.message(owner.stash_position()-Vector2(0,10),"PECK!",BeachUI.GOLD)
	owner.peck_bag(progress,final_hit)
	game.effects.peck_contact(owner.stash_position()-Vector2(0,4),Vector2(_gull().facing,-0.25),progress,"bag")
	Audio.play("bag_thump",0.88+0.22*progress)
	if final_hit:
		raid.pecks = 0
		var count: int = mini(owner.stash_remaining,int(t.stash_burst))
		if count > 0:
			game.effects.release_burst(owner.stash_position()-Vector2(0,4))
			Audio.play("stash_release")
			Audio.play("release_accent",1.0,-4.0)
		for i: int in count:
			owner.stash_remaining -= 1
			var choices: Array = t.stash_snacks
			var food_id: String = str(choices[rng.randi_range(0,choices.size()-1)])
			var direction: float = -1.0 if i%2 == 0 else 1.0
			items.append({"owner":owner,"food_id":food_id,"position":owner.stash_position(),"velocity":Vector2(direction*rng.randf_range(35,65),-rng.randf_range(65,95)),"grounded":false,"age":0.0})
	owner.queue_redraw()
	queue_redraw()
	return true

func _peck_toddler(toddler: BeachTarget) -> bool:
	if not toddler.knock_food(game.player):
		return false
	peck_cooldown = float(Config.tuning.world.peck_cooldown)
	game.effects.message(toddler.food_position()-Vector2(0,10),"PECK!",BeachUI.GOLD)
	Audio.play("click")
	queue_redraw()
	return true

func _peck_bin(bin: Dictionary) -> bool:
	var t: Dictionary = Config.tuning.world
	var content_position: Vector2 = _bin_content_position(bin)
	peck_cooldown = float(t.peck_cooldown)
	bin.pecks = int(bin.pecks)+1
	var final_hit: bool = int(bin.pecks) >= int(t.bin_pecks)
	var progress: float = clampf(float(bin.pecks)/float(maxi(1,int(t.bin_pecks))),0.0,1.0)
	var wheelie: bool = str(bin.type) == BeachBackdrop.WHEELIE_BIN_TYPE
	game.effects.message(content_position,"POSH TRASH!" if wheelie and final_hit else "RATTLE!",BeachUI.GOLD)
	game.beach.wobble_bin(float(bin.x),progress,final_hit)
	game.effects.peck_contact(content_position,Vector2(_gull().facing,-0.35),progress,"bin")
	Audio.play("bin_rattle",0.90+0.20*progress)
	if final_hit:
		bin.pecks = 0
		var count: int = mini(int(bin.remaining),int(t.bin_burst))
		if count > 0:
			game.effects.release_burst(content_position,true)
			Audio.play("stash_release")
			Audio.play("release_accent",1.0,-4.0)
		for i: int in count:
			bin.remaining = int(bin.remaining)-1
			# Wheelie bins are harder to reach, so their scatter list is richer.
			var choices: Array = t.get("wheelie_bin_scatter",t.bin_scatter) if wheelie else t.bin_scatter
			var kind: String = str(choices[int(bin.scatter_index)%choices.size()])
			var look_alikes: Array[String] = Config.family_members(kind) # pizza leftovers vary: any slice, or the old half pizza
			if look_alikes.size() > 1:
				kind = look_alikes[visual_rng.randi_range(0,look_alikes.size()-1)]
			var is_food: bool = Config.foods.has(kind)
			bin.scatter_index = int(bin.scatter_index)+1
			var direction: float = -1.0 if i%2 == 0 else 1.0
			var item: Dictionary = {"owner":null,"source":"bin","bin_x":float(bin.x),"food_id":kind if is_food else "","garbage":not is_food,"garbage_kind":kind,"position":content_position+Vector2(0,6),"velocity":Vector2(direction*rng.randf_range(35,65),-rng.randf_range(65,95)),"grounded":false,"age":0.0}
			if not is_food:
				var rest_limit: float = 0.52 if kind == "wrapper" else 0.34
				item.rotation = visual_rng.randf_range(-0.18,0.18)
				item.angular_velocity = -direction*visual_rng.randf_range(float(Config.tuning.juice.trash_spin_min),float(Config.tuning.juice.trash_spin_max))
				item.rest_angle = visual_rng.randf_range(-rest_limit,rest_limit)
			items.append(item)
		if count > 0:
			bin_opened.emit(str(bin.type))
			if int(bin.remaining) <= 0:
				bin_emptied.emit(str(bin.type))
	queue_redraw()
	return true

func _bin_content_position(bin: Dictionary) -> Vector2:
	return Vector2(float(bin.x),float(bin.get("content_y",float(Config.tuning.world.ground)-18.0)))

func _peck_empty(at: Vector2) -> bool:
	peck_cooldown = float(Config.tuning.world.peck_cooldown)
	game.effects.empty_message(at)
	Audio.play("empty_tap",1.0,-8.0)
	queue_redraw()
	return true

func add_knocked_food(owner: BeachTarget, food_id: String, at: Vector2, impulse: Vector2) -> void:
	var item: Dictionary = {"owner":owner,"source":"near_miss","food_id":food_id,"position":at,"velocity":impulse,"grounded":false,"age":0.0,"recovered":false}
	items.append(item)
	owner.track_dropped(item)
	queue_redraw()

func tick(delta: float) -> void:
	shine_clock += delta
	for bin: Dictionary in bins:
		game.beach.set_bin_full(float(bin.x),int(bin.remaining) > 0)
	peck_cooldown = maxf(0,peck_cooldown-delta)
	var t: Dictionary = Config.tuning.world
	var gull: BeachGull = game.player
	# Resolve moving food against the moving beak in relative coordinates.
	for index: int in range(items.size()-1,-1,-1):
		var item: Dictionary = items[index]
		if bool(item.get("recovered",false)):
			items.remove_at(index)
			continue
		var previous: Vector2 = item.position
		# Missing ages are legacy/test fixtures that predate delayed pickup.
		var previous_age: float = float(item.get("age",float(t.stash_pickup_delay)))
		item.age = previous_age+delta
		var is_garbage: bool = bool(item.get("garbage",false))
		var definition: Dictionary = {} if is_garbage else Config.foods[item.food_id]
		if not item.grounded:
			if is_garbage:
				item.rotation = wrapf(float(item.get("rotation",0.0))+float(item.get("angular_velocity",0.0))*delta,-PI,PI)
			if item.get("source","") == "near_miss" and float(item.age)<0.7:
				item.crumb_trail = float(item.get("crumb_trail",0.0))+delta
				if float(item.crumb_trail)>=0.09:
					game.effects.food_crumble(item.position,item.velocity,3)
					item.crumb_trail = fmod(float(item.crumb_trail),0.09)
			item.velocity.y += float(t.stash_gravity)*delta
			item.position += item.velocity*delta
			if item.position.x < 12 or item.position.x > float(t.width)-12:
				item.position.x = clampf(item.position.x,12,float(t.width)-12)
				item.velocity.x *= -0.5
				if is_garbage:
					item.angular_velocity = -float(item.get("angular_velocity",0.0))*0.55
			var item_height: float = 5.0 if is_garbage else float(definition.size[1])
			var floor_y: float = float(t.ground)-item_height*0.5
			if item.position.y >= floor_y:
				item.position.y = floor_y
				item.velocity = Vector2.ZERO
				item.grounded = true
				if is_garbage:
					item.rotation = float(item.get("rest_angle",clampf(float(item.get("rotation",0.0)),-0.4,0.4)))
					item.angular_velocity = 0.0
		# Sand sources cannot throw food onto the paved promenade; bins already on the promenade or pier spill beside themselves.
		if item.get("source","") == "bin" and float(item.get("bin_x",0.0)) > float(t.beach_scatter_max_x):
			item.position.x = clampf(float(item.position.x),float(item.bin_x)-BIN_SPILL_SPREAD,float(item.bin_x)+BIN_SPILL_SPREAD)
		elif item.get("source","") == "bin" or (item.get("owner") is BeachTarget and item.owner.kind == "sunbather"):
			item.position.x = clampf(float(item.position.x),float(t.beach_min_x),float(t.beach_scatter_max_x))
		if is_garbage:
			continue
		var radius: Vector2 = Vector2(definition.pickup_radius[0],definition.pickup_radius[1])+Vector2(float(Config.tuning.dive.beak_w),float(Config.tuning.dive.beak_h))*0.5
		var pickup_delay: float = float(t.stash_pickup_delay)
		var taker: BeachGull
		var pilot: RivalPilot
		if _hit(gull,item,radius,previous,previous_age,delta,pickup_delay) and gull.can_collect_food(item.food_id):
			taker = gull
		else:
			for candidate: RivalPilot in game.pilots:
				if candidate.accepts_item(item) and _hit(candidate.gull,item,radius,previous,previous_age,delta,pickup_delay):
					pilot = candidate
					taker = candidate.gull
					break
		if taker != null:
			if item.get("source","") == "near_miss":
				if is_instance_valid(item.owner) and item.owner.claim_dropped(taker):
					items.remove_at(index)
				continue
			items.remove_at(index)
			if is_instance_valid(item.get("owner")):
				item.owner.reaction.theft(item.owner,taker)
			if pilot == null and taker.state == BeachGull.State.GROUNDED:
				taker.show_ground_peck(float(Config.tuning.world.pickup_pose_time)) # head-down pick-up for any floor item
			if pilot != null:
				pilot.ate_ground(str(item.food_id))
			elif item.has("snack"):
				game.effects.snatch_contact(item.position,taker.velocity,false)
				Audio.play("snatch",1+game.score.tier*0.08)
				game.player.digestion.collect(item.food_id,item.snack)
				if item.get("source","") == "abandoned":
					game._quest_event("abandoned_looted")
			else:
				collected.emit(item.position,item.food_id,item.get("source","") == "bin")
				if is_instance_valid(item.get("owner")) and item.owner.kind == "sunbather":
					bag_collected.emit()
	for owner: BeachTarget in raids.keys():
		if not is_instance_valid(owner):
			raids.erase(owner)
			continue
		var raid: Dictionary = raids[owner]
		var raider: BeachGull = raid.get("raider",gull) if is_instance_valid(raid.get("raider",gull)) else gull
		if owner.sleep_state != BeachTarget.SleepState.AWAKE:
			continue
		if not owner.reaction.mode.is_empty():
			continue
		if owner.panic.state != CrowdPanic.State.NONE:
			continue # running from a squall or a gang call: the bag can wait
		raid["action"] = str(raid.get("action",""))
		raid["action_time"] = float(raid.get("action_time",0.0))
		raid["pickup_item"] = raid.get("pickup_item",{})
		var notice: float = float(raid.get("notice",0.0))
		raid.notice = maxf(0.0,notice-delta)
		raid.swat = maxf(0,raid.swat-delta)
		if notice > 0.0:
			continue
		owner.stash_standing = true
		var action: String = str(raid.action)
		if action == "pickup":
			raid.action_time -= delta
			var held_item: Dictionary = raid.pickup_item
			if raid.action_time <= 0:
				var held_index: int = items.find(held_item)
				if held_index >= 0:
					items.remove_at(held_index)
					owner.stash_remaining += 1
				raid.pickup_item = {}
				raid.action = ""
		elif action == "swat_windup":
			raid.action_time -= delta
			if raid.action_time <= 0:
				if raider.state != BeachGull.State.STUNNED and raider.position.distance_to(owner.position-Vector2(0,12)) < float(t.stash_swat_reach):
					raider.stun(-1.0,owner.position)
				raid.swat = float(t.stash_swat_cooldown)
				raid.action = "swat_follow"
				raid.action_time = SunbatherArt.SWAT_FOLLOW
		elif action == "swat_follow":
			raid.action_time -= delta
			if raid.action_time <= 0:
				raid.action = ""
		elif action == "settle":
			raid.action_time -= delta
			if raid.action_time <= 0:
				owner.position.x = owner.stash_home_x
				owner.stash_active = false
				owner.stash_standing = false
				SunbatherArt.pose(owner,&"rest",0)
				owner.queue_redraw()
				raids.erase(owner)
				continue
		# Standing owner retrieves the closest grounded item from this bag.
		var nearest: int = -1
		var distance: float = INF
		var has_airborne: bool = false
		for i: int in items.size():
			if items[i].owner != owner:
				continue
			if float(items[i].get("age",float(t.stash_pickup_delay))) < float(t.stash_pickup_delay):
				# Protected food still keeps this raid alive until it can be retrieved.
				has_airborne = true
				continue
			if not items[i].grounded:
				has_airborne = true
				continue
			var gap: float = absf(float(items[i].position.x)-owner.position.x)
			if gap < distance:
				nearest = i
				distance = gap
		var destination: float = float(items[nearest].position.x) if nearest >= 0 else owner.stash_home_x
		var moving: bool = false
		# Start the telegraphed attack before choosing a return/settle action.
		if action == "" and raid.swat <= 0 and raider.state != BeachGull.State.STUNNED and raider.position.distance_to(owner.position-Vector2(0,12)) < float(t.stash_swat_reach):
			raid.action = "swat_windup"
			raid.action_time = SunbatherArt.SWAT_WINDUP
			action = "swat_windup"
			destination = raider.position.x
			owner.facing = signf(destination-owner.position.x) if absf(destination-owner.position.x)>1 else owner.facing
		if action == "":
			owner.facing = signf(destination-owner.position.x) if absf(destination-owner.position.x)>1 else owner.facing
			moving = absf(destination-owner.position.x)>1
			if moving:
				owner.sunbather_run_time += delta
			owner.position.x = move_toward(owner.position.x,destination,float(t.stash_retrieve_speed)*delta)
			if nearest >= 0 and absf(owner.position.x-destination) <= 3:
				raid.action = "pickup"
				raid.action_time = SunbatherArt.PICKUP_PAUSE
				raid.pickup_item = items[nearest]
				moving = false
			elif nearest < 0 and not has_airborne and absf(owner.position.x-owner.stash_home_x) < 1:
				owner.position.x = owner.stash_home_x
				raid.action = "settle"
				raid.action_time = SunbatherArt.SETTLE_TIME
				moving = false
		var phase_duration: float = SunbatherArt.SWAT_WINDUP
		if str(raid.action) == "pickup":
			phase_duration = SunbatherArt.PICKUP_PAUSE
		elif str(raid.action) == "settle":
			phase_duration = SunbatherArt.SETTLE_TIME
		var phase: float = 1.0-clampf(float(raid.action_time)/phase_duration,0.0,1.0)
		var reaction: StringName = StringName(str(raid.action))
		if reaction == &"pickup":
			reaction = &"bend"
		elif reaction == &"swat_windup":
			reaction = &"windup"
		if reaction == &"swat_follow":
			reaction = &"windup"
			phase = 0.76+0.24*phase
		elif reaction == &"":
			reaction = &"run" if moving else &"stand"
		SunbatherArt.reaction_pose(owner,reaction,phase,int(owner.sunbather_run_time*10)%7 if moving else 0)
		owner.queue_redraw()
	queue_redraw()

## Does this gull's beak reach the item this frame? Grounded items need a standing gull; moving ones use the swept beak.
func _hit(who: BeachGull, item: Dictionary, radius: Vector2, previous: Vector2, previous_age: float, delta: float, pickup_delay: float) -> bool:
	if item.age < pickup_delay or who.state == BeachGull.State.STUNNED:
		return false
	if item.grounded and who.state == BeachGull.State.GROUNDED:
		return absf(who.beak().x-float(item.position.x)) <= radius.x
	# If grace expires during this frame, ignore the protected part of both paths.
	var eligible_fraction: float = clampf((pickup_delay-previous_age)/delta,0,1) if delta > 0 else 0
	var eligible_food_start: Vector2 = previous.lerp(item.position,eligible_fraction)
	var eligible_beak_start: Vector2 = who.previous_beak.lerp(who.sweep_beak,eligible_fraction)
	return BeachCollisions.segment_hits(eligible_beak_start-eligible_food_start,who.sweep_beak-item.position,Vector2.ZERO,radius)

func _draw() -> void:
	for item: Dictionary in items:
		if bool(item.get("garbage",false)):
			var at := Vector2(roundf(float(item.position.x)),roundf(float(item.position.y)))
			draw_set_transform(at,float(item.get("rotation",0.0)))
			if item.get("garbage_kind","") == "wrapper":
				draw_colored_polygon(PackedVector2Array([Vector2(-4,-2),Vector2(3,-3),Vector2(4,2),Vector2(-3,3)]),Color("8bc6b4"))
				draw_line(Vector2(-3,0),Vector2(3,-1),Color("fff1cc"),1)
			else:
				draw_rect(Rect2(Vector2(-2,-3),Vector2(4,6)),Color("d7d9cf"))
				draw_line(Vector2(-2,-2),Vector2(2,2),Color("7993a3"),1)
			draw_set_transform(Vector2.ZERO)
		else:
			var definition: Dictionary = Config.foods[item.food_id]
			var display_size: Array = definition.get("display_size",definition.size)
			var size: Vector2 = Vector2(display_size[0],display_size[1])
			var texture: Texture2D = Config.frames(definition.sprite).get_frame_texture(&"idle",0)
			var rect: Rect2 = Rect2(item.position-size*0.5,size)
			if item.food_id == "crumbs":
				draw_texture_rect(texture,Rect2(rect.position+Vector2(0,1),size),false,Color("754a39"))
			draw_texture_rect(texture,rect,false)
			# Glint only once the item can be picked up and the gull has room for it.
			if float(item.get("age",1.0)) >= float(Config.tuning.world.stash_pickup_delay) and is_instance_valid(game) and game.player.can_collect_food(item.food_id):
				if not item.has("shine_seed"):
					item.shine_seed = fposmod(float(item.position.x)*0.37,3.0)
				var glint: Texture2D = PickupShine.overlay(texture,shine_clock,float(item.shine_seed))
				if glint != null:
					draw_texture_rect(glint,rect,false)
	for owner: BeachTarget in raids.keys():
		if not is_instance_valid(owner):
			continue
		var raid: Dictionary = raids[owner]
		if str(raid.get("action","")) == "swat_windup":
			var start: Vector2 = owner.position+Vector2(owner.facing*3,-25)
			var reach: Vector2 = start+Vector2(owner.facing*(8+8*clampf(float(raid.action_time)/SunbatherArt.SWAT_WINDUP,0,1)),-2)
			draw_line(start,reach,Color("fff1cc"),2)
			draw_circle(reach,2,Color("ffc65c"))
