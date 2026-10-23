extends Node2D
var checks: int = 0
var failures: int = 0
var spawner := BeachSpawner.new()
var gull: BeachGull

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: "+message)

func actor(appearance: String = "kiosk_customer", x: float = 170.0) -> BeachTarget:
	var target := spawner.create("kiosk_customer",x,{"appearance":appearance,"food_id":"ice_cream"})
	target.routine.bounds = Vector2(20,600)
	return target

func step(target: BeachTarget, time: float, gulls: Array[BeachGull] = []) -> void:
	for i: int in ceili(time/0.02):
		target.tick(0.02,gulls)

func arrive(target: BeachTarget) -> void:
	check(target.bench_visit.consider(target,true),"eligible shopper reserves bench")
	for i: int in 2000:
		if target.bench_visit.phase == BenchVisit.Phase.REST:
			break
		target.tick(0.02,[])
	check(target.bench_visit.phase == BenchVisit.Phase.REST,"approach and sit complete (%s at %s, phase %s)" % [target.shopper_appearance,target.position,target.bench_visit.phase])

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	Audio.music.stop()
	for id: String in ShopperArt.APPEARANCES:
		var frames: SpriteFrames = Config.frames(id)
		preload("res://tests/isolated_sprite_checks.gd").run(check,frames,id)
		for clip: StringName in [&"sit_down",&"seated_idle",&"seated_eat",&"stand_up"]:
			for index: int in frames.get_frame_count(clip):
				var texture: AtlasTexture = frames.get_frame_texture(clip,index)
				var cell: Image = texture.atlas.get_image().get_region(Rect2i(texture.region))
				check(cell.get_used_rect().end.y == 116,"generated bench frame uses approved sole baseline")
	spawner.setup(self,{"id":3,"seed":571,"awareness_mult":1.0,"spawns":[],"props":[{"type":"beach_bench","x":200,"y":160}]})
	gull = BeachGull.new()
	add_child(gull)
	gull.position = Vector2(250,120)
	gull.direction = Vector2.RIGHT
	gull.velocity = Vector2(180,-40)
	for appearance: String in ShopperArt.APPEARANCES:
		for facing: float in [1.0,-1.0]:
			var target := actor(appearance,170 if facing > 0 else 230)
			arrive(target)
			check(is_equal_approx(target.position.x,200),"sitting anchors on bench")
			check(target.facing == facing,"approach facing preserved")
			check(target.food and target.food_sprite.visible,"rest retains real snack")
			var contender := actor(appearance)
			check(not contender.bench_visit.consider(contender,true),"second shopper cannot claim occupied bench")
			for clip: StringName in [&"sit_down",&"seated_idle",&"seated_eat",&"stand_up"]:
				var count: int = target.sprite.sprite_frames.get_frame_count(clip)
				for frame: int in count:
					target.sprite.animation = clip
					target.sprite.frame = frame
					BeachgoerArt.align_food(target)
					var entry: Dictionary = Config.sprites[target.info.sprite]
					var anchor: Array = entry.food_anchors[String(clip)][frame]
					check(target.food_position().is_equal_approx(target.position+Vector2(anchor[0]*facing,anchor[1])),"visible and collectible hand agree in both directions")
			# Full production theft; committed chase clocks remain untouched through standing.
			check(target.take(gull),"seated snack can be stolen")
			var reaction_time: float = target.reaction.timer
			check(not target.food and not target.food_sprite.visible,"theft clears visible food immediately")
			check(target.bench_visit.phase == BenchVisit.Phase.STAND,"theft queues one coherent stand")
			var x: float = target.position.x
			step(target,0.2)
			check(target.position.x == x and target.sprite.animation == &"stand_up","no seated chase sliding")
			check(is_equal_approx(target.reaction.timer,reaction_time),"full committed reaction time preserved")
			step(target,0.4)
			check(target.bench_visit.phase == BenchVisit.Phase.NONE,"standing releases reservation")
			check(target.reaction.mode in ["surprise","chase"],"existing reaction resumes after stand")
			check(spawner.benches.reserve(contender,contender.routine.bounds).size()>0,"released bench immediately available")
			spawner.benches.release(contender)
			spawner._departed(target)
			spawner._departed(contender)
			await get_tree().process_frame
	# Natural finish, cooling down, deletion and reset cleanup.
	var natural := actor()
	arrive(natural)
	step(natural,12.0)
	check(natural.bench_visit.phase == BenchVisit.Phase.NONE and natural.food,"normal rest ends without depletion or replenishment")
	check(not natural.bench_visit.consider(natural,true),"cooldown avoids immediate same-bench return")
	natural.bench_visit.cooldown = 0
	arrive(natural)
	spawner.targets.erase(natural)
	natural.queue_free()
	await get_tree().process_frame
	var successor := actor()
	check(successor.bench_visit.consider(successor,true),"deletion frees reservation")
	spawner.benches.setup([])
	step(successor,0.04)
	check(successor.bench_visit.phase == BenchVisit.Phase.NONE,"level registry reset cancels stale visit")
	spawner._departed(successor)
	spawner.benches.setup([{"type":"beach_bench","x":200,"y":160}])
	# Mid-sit drop reverses from current progress and never invents another food.
	var dropped := actor("kiosk_customer",200)
	check(dropped.bench_visit.consider(dropped,true),"mid-transition fixture claims seat")
	step(dropped,0.22)
	check(dropped.bench_visit.phase == BenchVisit.Phase.SIT,"fixture reaches partial sit")
	check(dropped.knock_food(gull),"food drops during sit")
	step(dropped,0.5)
	check(dropped.bench_visit.phase == BenchVisit.Phase.NONE and not dropped.food and dropped.dropped_pending,"drop stands and leaves existing retrieval state intact")
	spawner._departed(dropped)
	# Proximity warning must stand before its original warning/windup can hit.
	var warned := actor("kiosk_customer",200)
	arrive(warned)
	gull.position = Vector2(206,148)
	step(warned,0.1,[gull])
	check(warned.bench_visit.phase == BenchVisit.Phase.STAND and warned.reaction.mode == "warning","seated proximity warning stands first")
	check(gull.state != BeachGull.State.STUNNED,"no seated or untelegraphed hit")
	var warning_time: float = warned.reaction.timer
	step(warned,0.2,[gull])
	check(is_equal_approx(warned.reaction.timer,warning_time),"warning fairness clock preserved while standing")
	spawner._departed(warned)
	# Crowd placement must preserve the occupied bench while walkers step around it.
	var planted := actor("kiosk_customer",200)
	arrive(planted)
	var passer := actor("shopper_mullet",200)
	var seat_position: Vector2 = planted.position
	spawner.visual_offsets[planted] = Vector2(26,-14)
	spawner.apply_spacing(0.1)
	check(planted.position == seat_position and spawner.visual_offsets[planted] == Vector2.ZERO,"seated actor ignores old crowd offsets")
	check(passer.position.distance_to(planted.position) >= 14,"passing walker moves around occupied seat")
	spawner.reset_spacing()
	planted.service_locked = true
	step(planted,0.1)
	check(planted.bench_visit.phase == BenchVisit.Phase.STAND,"service request resolves a stand first")
	step(planted,0.6)
	check(planted.bench_visit.phase == BenchVisit.Phase.NONE and planted.service_locked,"service interruption releases seat without unlocking order")
	spawner._departed(planted)
	spawner._departed(passer)
	var approach := actor("kiosk_customer",160)
	check(approach.bench_visit.consider(approach,true),"approach cancellation fixture claims seat")
	approach.reaction.theft(approach,gull,true)
	step(approach,0.02)
	check(approach.bench_visit.phase == BenchVisit.Phase.NONE,"reaction cancels approaching seat immediately")
	spawner._departed(approach)
	var freed_focus := actor("kiosk_customer",200)
	arrive(freed_focus)
	var transient_gull := BeachGull.new()
	add_child(transient_gull)
	freed_focus.take(transient_gull)
	transient_gull.queue_free()
	await get_tree().process_frame
	step(freed_focus,1.0)
	check(freed_focus.bench_visit.phase == BenchVisit.Phase.NONE and freed_focus.reaction.mode in ["give_up","return",""],"freed theft focus safely resolves after standing")
	spawner._departed(freed_focus)
	# Exact pose and simulation time freeze during real game pause wiring.
	var paused := actor("kiosk_customer",200)
	check(paused.bench_visit.consider(paused,true),"pause fixture claims seat")
	var game := BeachGame.new()
	game.input = GullInput.new()
	game.spawner = spawner
	for phase: BenchVisit.Phase in [BenchVisit.Phase.APPROACH,BenchVisit.Phase.SIT,BenchVisit.Phase.REST,BenchVisit.Phase.STAND]:
		paused.bench_visit.phase = phase
		paused.bench_visit.timer = 0.3
		paused.bench_visit.bite = 0.4 if phase == BenchVisit.Phase.REST else 0.0
		if phase == BenchVisit.Phase.STAND:
			paused.reaction.theft(paused,gull,true)
		paused.update_art_pose(false)
		game.set_paused(true)
		var frame: int = paused.sprite.frame
		var timer: float = paused.bench_visit.timer
		await get_tree().create_timer(0.04).timeout
		check(paused.sprite.frame == frame and paused.bench_visit.timer == timer,"pause freezes exact visit frame and timer")
		game.set_paused(false)
		game.set_physics_process(false)
		paused.tick(0.02,[])
	check(paused.bench_visit.phase == BenchVisit.Phase.STAND,"pause resumes interrupted stand")
	game.input.free()
	game.free()
	spawner._departed(paused)
	spawner.benches.setup([{"type":"beach_bench","x":200,"y":153}])
	var raised := actor("kiosk_customer",170)
	arrive(raised)
	check(is_equal_approx(raised.position.y,153),"seat follows actual authored prop y")
	raised.bench_visit.interrupt(raised)
	step(raised,0.6)
	check(absf(raised.position.y-153) < 2.0,"standing avoids snapping back to original ground lane")
	step(raised,1.0)
	check(is_equal_approx(raised.position.y,160),"departing stroll gradually rejoins original lane")
	spawner._departed(raised)
	# Tutorial eligibility and unavailable-seat fallback.
	for lesson: int in [1,2]:
		var tutorial := BeachSpawner.new()
		tutorial.setup(self,{"id":lesson,"seed":31,"awareness_mult":1.0,"spawns":[],"props":[{"type":"beach_bench","x":200,"y":160}]})
		var shopper := tutorial.create("kiosk_customer",200)
		check(not shopper.bench_visit.consider(shopper,true),"tutorial bench behavior disabled")
		tutorial._departed(shopper)
	spawner.benches.setup([])
	var fallback := actor()
	check(not fallback.bench_visit.consider(fallback,true) and fallback.bench_visit.phase == BenchVisit.Phase.NONE,"no bench keeps ordinary routine")
	spawner._departed(fallback)
	print("BENCH SNACKS: %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)
