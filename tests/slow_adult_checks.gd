class_name SlowAdultChecks
extends RefCounted

static func _make(root: Node, appearance: String) -> BeachTarget:
	var t := BeachTarget.new()
	root.add_child(t)
	t.setup("kiosk_customer",300.0,RandomNumberGenerator.new(),1.0,{"appearance":appearance})
	return t

static func run_checks(root: Node, check: Callable) -> void:
	var base: float = float(Config.tuning.world.reaction_mult)
	Config.tuning.world.reaction_mult = 1.3
	var regular := _make(root,"kiosk_customer")
	var old_man := _make(root,"old_man")
	var sundress := _make(root,"shopper_sundress")
	check.call(is_equal_approx(regular.speed_mult,1.0) and is_equal_approx(regular.reaction_delay,1.3) and is_equal_approx(regular.chase_speed_mult,1.0),"regular adult uses only the global reaction multiplier and 1.0 speed")
	for t: BeachTarget in [old_man,sundress]:
		check.call(t.speed_mult < regular.speed_mult and t.chase_speed_mult < 1.0,"%s walks slower than a regular adult" % t.shopper_appearance)
		check.call(t.reaction_delay > regular.reaction_delay,"%s reacts slower than a regular adult" % t.shopper_appearance)
	for t: BeachTarget in [regular,old_man,sundress]:
		t.free()
	Config.tuning.world.reaction_mult = base
	# Lying-down shoo: from the second bag peck, still asleep, then the rise.
	var shoo_base: float = float(Config.tuning.world.sunbather_shoo_time)
	Config.tuning.world.sunbather_shoo_time = 0.7
	# Sleep is protected from proximity; the second peck or a landing wakes with the sunglasses check, then the rise.
	Config.tuning.world.sunbather_shoo_time = 1.2
	var peck_base: int = int(Config.tuning.world.sunbather_sleep_pecks)
	Config.tuning.world.sunbather_sleep_pecks = 2
	var gull := BeachGull.new()
	root.add_child(gull)
	var pecked := BeachTarget.new()
	root.add_child(pecked)
	pecked.setup("sunbather",300.0,RandomNumberGenerator.new(),1.0,{})
	pecked.reaction_delay = 1.0
	gull.position = pecked.position + Vector2(8.0,-8.0)
	pecked.tick(5.0,[gull])
	check.call(pecked.sleep_state == BeachTarget.SleepState.SLEEPING and pecked.alert == 0.0 and pecked.sprite.animation == &"rest","a gull nearby (not landed) leaves the sleeper asleep")
	pecked.register_bag_peck()
	check.call(pecked.sleep_state == BeachTarget.SleepState.SLEEPING,"the first peck leaves the sleeper asleep")
	pecked.register_bag_peck()
	pecked.tick(0.1,[])
	check.call(pecked.sleep_state == BeachTarget.SleepState.WAKING and pecked.sprite.animation == &"lie_shoo" and not pecked.stash_standing,"the second peck wakes them lying down, looking through the sunglasses")
	pecked.tick(1.2,[])
	pecked.tick(0.3,[])
	check.call(pecked.sprite.animation == &"rise" and pecked.sleep_state == BeachTarget.SleepState.WAKING,"after the sunglasses check they begin to stand")
	pecked.tick(1.2,[])
	check.call(pecked.sleep_state == BeachTarget.SleepState.AWAKE and pecked.stash_standing,"then they are standing awake")
	var landed := BeachTarget.new()
	root.add_child(landed)
	landed.setup("sunbather",300.0,RandomNumberGenerator.new(),1.0,{})
	landed.reaction_delay = 1.0
	gull.land()
	gull.position = Vector2(landed.position.x+4.0,landed.position.y)
	landed.tick(0.1,[gull])
	check.call(landed.sleep_state == BeachTarget.SleepState.WAKING and landed.sprite.animation == &"lie_shoo","a gull landing on the sleeper wakes them with the sunglasses check")
	# Awake but lying back down: any new disturbance gets the sunglasses check before they stand.
	var settled := BeachTarget.new()
	root.add_child(settled)
	settled.setup("sunbather",300.0,RandomNumberGenerator.new(),1.0,{})
	settled.sleep_state = BeachTarget.SleepState.AWAKE
	settled.stash_standing = false
	check.call(settled.glance_gate() and settled.shoo_left > 0.0,"an awake sunbather lying down looks through the sunglasses first")
	settled.tick(0.5,[])
	check.call(settled.sprite.animation == &"lie_shoo" and not settled.stash_standing and settled.glance_gate(),"the look keeps going and holds the stand-up")
	settled.tick(1.0,[])
	check.call(not settled.glance_gate(),"once the look is over they may stand")
	settled.stash_standing = true
	settled.tick(0.1,[])
	settled.stash_standing = false
	check.call(settled.glance_gate(),"after standing and lying down again the first action is again the sunglasses check")
	for t: BeachTarget in [pecked,landed,settled]:
		t.free()
	gull.free()
	Config.tuning.world.sunbather_sleep_pecks = peck_base
	Config.tuning.world.sunbather_shoo_time = shoo_base
