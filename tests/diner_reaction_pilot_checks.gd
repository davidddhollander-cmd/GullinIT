extends Node
var checks: int = 0
var failures: int = 0

func check(condition: bool,message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: "+message)

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	Audio.music.stop()
	var definition: Dictionary = Config.levels[2].duplicate(true)
	definition.spawns = []
	definition.rivals = []
	definition.props = []
	var game := BeachGame.new()
	add_child(game)
	game.setup(definition,false)
	game.set_physics_process(false)
	game.running = true
	game.intro = 0.0
	var gull: BeachGull = game.player
	var reaction_frames: SpriteFrames = Config.frames("pier_diner_reactions")
	check(reaction_frames.get_frame_count(&"surprise")==6 and reaction_frames.get_frame_count(&"fist_shake")==6,"diner pilot exposes six complete frames per reaction")
	preload("res://tests/isolated_sprite_checks.gd").run(Callable(self,"check"),reaction_frames,"diner reaction pilot")
	for clip: StringName in [&"surprise",&"fist_shake"]:
		var min_height: int = 1000
		var max_height: int = 0
		for frame: int in reaction_frames.get_frame_count(clip):
			var texture := reaction_frames.get_frame_texture(clip,frame) as AtlasTexture
			var bounds: Rect2i = texture.atlas.get_image().get_region(Rect2i(texture.region)).get_used_rect()
			check(bounds.end.y==390,"%s frame %d keeps the shared planted foot baseline" % [clip,frame])
			min_height = mini(min_height,bounds.size.y)
			max_height = maxi(max_height,bounds.size.y)
		check(max_height-min_height<=8,"%s keeps stable adult body scale" % clip)
	for direction: float in [-1.0,1.0]:
		gull.digestion.snacks.clear()
		gull.digestion.rest = 0.0
		gull.state = BeachGull.State.GLIDE
		gull.direction = Vector2(direction,0)
		gull.velocity = Vector2(direction*100.0,-60.0)
		var diner := game.spawner.create("pier_diner",500.0,{"food_id":"fish_chips"})
		gull.position = Vector2(diner.position.x+direction*300.0,55.0)
		var planted_x: float = diner.position.x
		check(diner.take(gull),"successful diner theft starts the %s-facing pilot" % ("left" if direction<0 else "right"))
		check(diner.reaction.mode=="surprise" and diner.reaction.committed and diner.sprite.animation==&"surprise","successful diner theft triggers surprise exactly once at completion")
		check(not diner.food and not diner.food_sprite.visible and diner.facing==direction and diner.sprite.flip_h==(direction<0),"diner surprise is empty-handed and supports both directions")
		diner.tick(0.15,[])
		check(diner.position.x==planted_x and diner.reaction.mode=="surprise" and diner.sprite.frame>=2,"diner looks at the empty hand and recoils while planted")
		if direction > 0:
			var frozen_timer: float = diner.reaction.timer
			var frozen_frame: int = diner.sprite.frame
			game.set_paused(true)
			await get_tree().process_frame
			await get_tree().process_frame
			check(diner.reaction.timer==frozen_timer and diner.sprite.frame==frozen_frame and diner.sprite.speed_scale==0.0,"pause freezes diner surprise time and pose")
			game.set_paused(false)
			game.set_physics_process(false)
		diner.tick(0.18,[])
		check(diner.reaction.mode=="chase" and is_equal_approx(diner.reaction.timer,float(Config.tuning.world.snatch_chase_time)),"diner surprise hands off to the full existing chase clock")
		diner.tick(0.01,[])
		check(diner.sprite.animation==&"run" and diner.position.x!=planted_x,"diner reuses the existing run for pursuit")
		var chase_start: float = diner.position.x
		diner.tick(float(Config.tuning.world.snatch_chase_time)-0.02,[])
		check(diner.reaction.mode=="chase" and absf(diner.position.x-chase_start)<=float(Config.tuning.world.snatch_chase_distance),"diner pursuit keeps its existing duration and distance bound")
		diner.tick(0.02,[])
		var anger_x: float = diner.position.x
		check(diner.reaction.mode=="give_up" and diner.sprite.animation==&"fist_shake" and is_equal_approx(diner.reaction.timer,AdultReaction.FAILED_CHASE_ANGER_TIME),"failed diner chase enters the 0.9 second planted fist shake")
		diner.tick(0.46,[])
		check(diner.position.x==anger_x and diner.facing==direction and diner.sprite.frame>=3,"diner anger stays planted, faces escape and reaches the second shake")
		check(diner.reaction.swat_timer<0 and diner.action_pose_time==0 and gull.state!=BeachGull.State.STUNNED,"diner fist shake cannot arm a swat or hit the gull")
		if direction > 0:
			var frozen_anger_timer: float = diner.reaction.timer
			var frozen_anger_frame: int = diner.sprite.frame
			game.set_paused(true)
			await get_tree().process_frame
			await get_tree().process_frame
			check(diner.reaction.timer==frozen_anger_timer and diner.sprite.frame==frozen_anger_frame,"pause freezes diner fist-shake time and pose")
			game.set_paused(false)
			game.set_physics_process(false)
		diner.tick(0.45,[])
		check(diner.reaction.mode.is_empty() and diner.routine.enabled,"diner fist shake finishes cleanly and resumes the routine")
	var failed := game.spawner.create("pier_diner",240.0,{"food_id":"fish_chips"})
	failed.food = false
	failed.food_sprite.hide()
	check(not failed.take(gull) and failed.reaction.mode.is_empty(),"failed diner theft does not trigger surprise")
	gull.position = failed.position+Vector2(10,-20)
	gull.state = BeachGull.State.GLIDE
	failed.reaction.tick(failed,0.01,[gull])
	check(failed.reaction.mode=="warning" and failed.sprite.animation!=&"surprise","ordinary diner proximity remains a warning")
	print("DINER REACTION PILOT: %d checks, %d failures" % [checks,failures])
	game.queue_free()
	await get_tree().process_frame
	get_tree().quit(1 if failures else 0)
