extends RefCounted

static func run(root: Node, check: Callable) -> void:
	var game := BeachGame.new()
	root.add_child(game)
	game.setup(Config.levels[3],false)
	game.set_physics_process(false)
	game.running = true
	game.intro = 0.0
	var owner := game.spawner.create("sunbather",180.0)
	var other := game.spawner.create("sunbather",310.0)
	var gull: BeachGull = game.player
	var raids: BeachStashRaids = game.stash_raids
	gull.land()
	gull.position.x = owner.stash_position().x-10.0
	gull.facing = 1.0
	gull.previous_beak = gull.beak()
	gull.sweep_beak = gull.beak()
	var first_letters: Dictionary = owner.sleep_letters()
	owner.art_time += 0.8
	var next_letters: Dictionary = owner.sleep_letters()
	check.call(not first_letters.is_empty() and first_letters.alpha != next_letters.alpha and first_letters.position != next_letters.position,"sleep letters drift and fade with simulation time")
	for tap: int in 3:
		raids.peck_cooldown = 0.0
		check.call(raids.peck(),"sleeping bag accepts protected peck %d" % (tap+1))
		var counted: int = owner.sleep_pecks
		check.call(not raids.peck() and owner.sleep_pecks == counted,"rejected repeat cannot consume a protected hit")
		owner.reaction.theft(owner,gull)
		owner.tick(5.0,[gull])
		raids.tick(5.0)
		check.call(owner.sleep_state == BeachTarget.SleepState.SLEEPING and owner.reaction.mode.is_empty() and not owner.stash_standing and owner.sprite.animation == &"rest","time, proximity and theft cannot wake protected sleeper")
	check.call(owner.stash_remaining == 1,"first food burst still happens on third hit")
	check.call(not raids.items.is_empty(),"sleeping owner leaves scattered food for the gull")
	# Collect a real first-burst snack through the normal loose-food collision path.
	var item: Dictionary = raids.items[0]
	item.position = gull.beak()
	item.grounded = true
	item.age = 1.0
	raids.tick(0.0)
	check.call(not gull.digestion.snacks.is_empty() and owner.sleep_state == BeachTarget.SleepState.SLEEPING and owner.reaction.mode.is_empty(),"first-burst collection leaves sunbather sleeping")
	check.call(other.sleep_pecks == 0,"each sunbather owns an independent disturbance count")
	raids.peck_cooldown = 0.0
	check.call(raids.peck() and owner.sleep_pecks == 4 and owner.sleep_state == BeachTarget.SleepState.WAKING,"fourth protected hit starts waking after it resolves")
	check.call(owner.sleep_letters().is_empty() and gull.state != BeachGull.State.STUNNED,"sleep letters stop as waking begins without an immediate hit")
	owner.tick(0.3,[gull])
	raids.tick(0.3)
	check.call(owner.sleep_state == BeachTarget.SleepState.WAKING and owner.sprite.animation == &"rise" and owner.sprite.frame > 0,"waking plays visible intermediate rise frames")
	var remaining: float = owner.rise_remaining
	raids.peck_cooldown = 0.0
	check.call(raids.peck() and owner.rise_remaining == remaining,"fifth peck cannot restart or skip the waking animation")
	owner.tick(0.41,[])
	raids.tick(0.0)
	check.call(owner.sleep_state == BeachTarget.SleepState.AWAKE and owner.stash_standing,"owner becomes awake after the full rise")
	owner.reaction.theft(owner,gull)
	var notice: float = owner.reaction.timer
	owner.reaction.theft(owner,gull)
	check.call(owner.reaction.mode == "notice" and notice <= 0.25 and owner.reaction.timer == notice,"awake theft uses quick notice without repeated resets")
	owner.reaction = AdultReaction.new()
	raids.items.clear()
	owner.position.x = owner.stash_home_x
	gull.position = Vector2(400,60)
	gull.state = BeachGull.State.GLIDE
	gull.previous_beak = gull.beak()
	gull.sweep_beak = gull.beak()
	for frame: int in 100:
		owner.tick(0.02,[])
		raids.tick(0.02)
	check.call(not owner.stash_active and owner.sleep_state == BeachTarget.SleepState.AWAKE and owner.sleep_letters().is_empty(),"settling and raid deletion retain watchful rest without Zzz")
	var history: int = owner.sleep_pecks
	owner.stash_remaining = 0
	gull.land()
	gull.position.x = owner.stash_position().x-10.0
	raids.peck_cooldown = 0.0
	raids.peck()
	check.call(owner.sleep_pecks == history,"empty bag taps do not change wake history")
	# Real clean swept snatches commit to a visible pursuit, even during high escape.
	for kind: String in ["kiosk_customer","pier_diner"]:
		var victim := game.spawner.create(kind,850.0,{"food_id":"ice_cream"})
		victim.defense = 0.0
		gull.digestion.snacks.clear()
		gull.digestion.rest = 0.0
		gull.state = BeachGull.State.STRIKE
		gull.sweep_state = BeachGull.State.STRIKE
		gull.peck_sweep_active = true
		gull.grounded_sweep = false
		gull.direction = Vector2.RIGHT
		gull.velocity = Vector2(100,-60)
		gull.previous_beak = victim.food_position()-Vector2(15,0)
		gull.sweep_beak = victim.food_position()+Vector2(15,0)
		BeachCollisions.resolve(gull,[victim],[])
		check.call(not victim.food and victim.reaction.committed and victim.reaction.mode == "chase",kind+" clean swept snatch starts committed chase")
		gull.position = Vector2(1100,55)
		var before: float = victim.position.x
		victim.tick(0.2,[gull])
		check.call(victim.position.x > before and victim.sprite.animation == &"run",kind+" runs after high and distant escape instead of immediately quitting")
		for frame: int in 101:
			victim.tick(0.02,[gull])
		check.call(victim.reaction.mode == "give_up" and victim.sprite.animation == &"angry" and victim.position.x-before <= 120.0,kind+" gives up visibly after bounded short pursuit")
		victim.tick(0.7,[])
		check.call(victim.reaction.mode.is_empty() and victim.routine.enabled,kind+" resumes routine after give-up pause")
		victim.reaction = AdultReaction.new()
		victim.dropped_pending = true
		victim.dropped_item = {"position":victim.position,"recovered":false}
		victim.claim_dropped(gull)
		check.call(not victim.reaction.committed,kind+" loose-food recovery does not get the perfect-snatch chase")
	# Movement is wider, bounded, reproducible and alternates walks with pauses.
	for kind: String in ["kiosk_customer","pier_diner","dog_owner","lifeguard"]:
		var actor := game.spawner.create(kind,1000.0)
		var twin := game.spawner.create(kind,1000.0)
		check.call(actor.routine.destination == twin.routine.destination and actor.routine.pause == twin.routine.pause,kind+" seeded routine reproduces destinations and pauses")
		var farthest: float = 0.0
		var saw_walk: bool = false
		var saw_pause: bool = false
		for frame: int in 3000:
			actor.tick(0.05,[])
			farthest = maxf(farthest,absf(actor.position.x-actor.routine.anchor))
			saw_walk = saw_walk or actor.routine.phase == BeachRoutine.Phase.WALK
			saw_pause = saw_pause or actor.routine.phase == BeachRoutine.Phase.PAUSE
		check.call(farthest >= (75.0 if kind == "pier_diner" else 95.0) and saw_walk and saw_pause,kind+" takes wider walks with finite stops")
		check.call(actor.position.x >= actor.routine.bounds.x and actor.position.x <= actor.routine.bounds.y,kind+" routine stays on connected ground")
	var shopper := game.spawner.create("kiosk_customer",760.0)
	shopper.routine.purchased(shopper,760.0)
	check.call(absf(shopper.routine.destination-shopper.position.x)>=120.0 and shopper.routine.phase == BeachRoutine.Phase.WALK,"purchase sends buyer away from the counter")
	var training_actor := BeachTarget.new()
	root.add_child(training_actor)
	training_actor.setup("kiosk_customer",250,game.spawner.rng,1.0)
	training_actor.routine.setup(training_actor,Config.levels[0],{})
	check.call(not training_actor.routine.enabled,"tutorial target retains its authored short patrol")
	training_actor.free()
	game.free()
