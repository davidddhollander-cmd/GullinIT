extends RefCounted

static func run(check: Callable) -> void:
	for rate: int in [30,60,120]:
		var belly := GullDigestion.new()
		var eaten: Array[String] = []
		belly.swallowed.connect(func(snack: Dictionary) -> void: eaten.append(snack.id))
		for i: int in 4:
			check.call(belly.collect("cookie"),"four small snacks fit")
		check.call(not belly.collect("single_chip") and not belly.collect("hotdog"),"full queue rejects fifth snack and large meal")
		for frame: int in rate*2:
			belly.tick(1.0/rate,false)
		check.call(eaten.size() == 4 and belly.snacks.is_empty(),"small snacks swallow consecutively at each frame rate")
		check.call(belly.collect("ice_cream") and belly.collect("crisps_bag") and not belly.collect("cookie"),"two medium snacks fill capacity")
		belly.tick(1.5,true)
		check.call(eaten.slice(4) == ["ice_cream","crisps_bag"],"grounded eating is twice as fast and preserves order")
		check.call(belly.collect("hotdog"),"large meal fits empty queue")
		belly.tick(2.9,false)
		check.call(eaten.size()==6 and not belly.can_collect("cookie"),"large snack blocks pickups before swallowing")
		belly.tick(0.1,false)
		check.call(eaten.size()==7 and belly.rest>1.99 and not belly.can_collect("cookie"),"large meal scores then locks digestion")
		belly.tick(0.5,true)
		check.call(is_equal_approx(belly.rest,1),"landing doubles digestion speed without resetting")
		belly.tick(1,false)
		check.call(belly.can_collect("cookie"),"digestion unlocks pickups")
		belly.collect("cookie",{"risky":true})
		belly.collect("single_chip")
		belly.tick(0.2,false)
		var dropped: Dictionary = belly.drop_current()
		check.call(dropped.id=="cookie" and dropped.risky and belly.progress==0 and belly.snacks.size()==1,"drop preserves metadata and only removes current snack")
		belly.tick(0.5,false)
		check.call(eaten.back()=="single_chip","remaining snack resumes normally")
