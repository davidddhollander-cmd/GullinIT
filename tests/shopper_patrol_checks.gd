extends RefCounted

static func run(root: Node,check: Callable) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 123
	# A serving counter or chase can leave a shopper beyond her small patrol span.
	for appearance: String in ShopperArt.APPEARANCES:
		for side: float in [-1.0,1.0]:
			var actor := BeachTarget.new()
			root.add_child(actor)
			actor.setup("kiosk_customer",400,rng,1,{"appearance":appearance,"patrol_radius":12,"food_id":"ice_cream"})
			actor.position.x = actor.patrol_home+side*35
			actor.facing = -side
			var start := actor.position.x
			var reversals := 0
			for frame: int in 120:
				var before := actor.facing
				actor.tick(1.0/60.0,[])
				if actor.facing!=before:
					reversals += 1
			check.call(reversals==0,appearance+" keeps an inward heading outside patrol instead of flickering")
			check.call((actor.position.x-start)*side < -15,appearance+" makes steady progress back from counter or chase")
			check.call((actor.sprite.animation==(&"walk_left" if side>0 else &"walk") and not actor.sprite.flip_h if appearance=="old_man" else actor.sprite.animation==&"walk" and actor.sprite.flip_h==(side>0)),appearance+" walk and food use the stable return heading")
			actor.free()
	# Outward-facing actors already beyond the endpoint correct once, then return.
	for side: float in [-1.0,1.0]:
		var actor := BeachTarget.new()
		root.add_child(actor)
		actor.setup("kiosk_customer",400,rng,1,{"appearance":"shopper_sundress","patrol_radius":12,"food_id":"ice_cream"})
		actor.position.x += side*35
		actor.facing = side
		var turns := 0
		for frame: int in 120:
			var before := actor.facing
			actor.tick(1.0/60.0,[])
			if actor.facing!=before:
				turns += 1
		check.call(turns==1 and actor.facing==-side,"older woman corrects an outward heading once beyond endpoint")
		actor.free()
	# Normal endpoints still turn once, including clipped patrols at world edges.
	for at: float in [20.0,400.0,float(Config.tuning.world.width)-20.0]:
		for side: float in [-1.0,1.0]:
			var actor := BeachTarget.new()
			root.add_child(actor)
			actor.setup("kiosk_customer",at,rng,1,{"appearance":"shopper_sundress","patrol_radius":12,"food_id":"ice_cream"})
			actor.position.x = clampf(at+side*12,20,float(Config.tuning.world.width)-20)
			actor.facing = side
			var turns := 0
			for frame: int in 30:
				var before := actor.facing
				actor.tick(1.0/60.0,[])
				if actor.facing!=before:
					turns += 1
			check.call(turns==1,"shopper turns only once at patrol/world endpoint "+str(at)+" / "+str(side))
			actor.free()
