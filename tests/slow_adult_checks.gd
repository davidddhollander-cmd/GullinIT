class_name SlowAdultChecks
extends RefCounted

static func _make(root: Node, appearance: String) -> BeachTarget:
	var t := BeachTarget.new()
	root.add_child(t)
	t.setup("kiosk_customer",300.0,RandomNumberGenerator.new(),1.0,{"appearance":appearance})
	return t

static func run_checks(root: Node, check: Callable) -> void:
	var regular := _make(root,"kiosk_customer")
	var old_man := _make(root,"old_man")
	var sundress := _make(root,"shopper_sundress")
	check.call(is_equal_approx(regular.speed_mult,1.0) and is_equal_approx(regular.reaction_delay,1.0) and is_equal_approx(regular.chase_speed_mult,1.0),"regular adult keeps 1.0 speed and reaction multipliers")
	for t: BeachTarget in [old_man,sundress]:
		check.call(t.speed_mult < regular.speed_mult and t.chase_speed_mult < 1.0,"%s walks slower than a regular adult" % t.shopper_appearance)
		check.call(t.reaction_delay > regular.reaction_delay,"%s reacts slower than a regular adult" % t.shopper_appearance)
	for t: BeachTarget in [regular,old_man,sundress]:
		t.free()
