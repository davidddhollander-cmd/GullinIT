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
	var sleeper := BeachTarget.new()
	root.add_child(sleeper)
	sleeper.setup("sunbather",300.0,RandomNumberGenerator.new(),1.0,{})
	sleeper.register_bag_peck()
	check.call(sleeper.shoo_left == 0.0,"first bag peck does not trigger a shoo")
	sleeper.register_bag_peck()
	check.call(sleeper.shoo_left > 0.0 and sleeper.sleep_state == BeachTarget.SleepState.SLEEPING,"second bag peck makes the sleeper shoo while lying down")
	sleeper.tick(0.8,[])
	check.call(sleeper.shoo_left == 0.0 and sleeper.sleep_state == BeachTarget.SleepState.SLEEPING,"shoo ends back at rest")
	sleeper.free()
	Config.tuning.world.sunbather_shoo_time = shoo_base
