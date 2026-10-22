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
	var frames: SpriteFrames = Config.frames("kiosk_customer")
	check(frames.get_frame_count(&"surprise")==6 and frames.get_frame_count(&"fist_shake")==6,"pilot exposes six complete frames for each new reaction")
	preload("res://tests/isolated_sprite_checks.gd").run(Callable(self,"check"),frames,"original shopper pilot")
	var idle_texture := frames.get_frame_texture(&"idle",0) as AtlasTexture
	var idle_height: int = idle_texture.atlas.get_image().get_region(Rect2i(idle_texture.region)).get_used_rect().size.y
	for clip: StringName in [&"surprise",&"fist_shake"]:
		for frame: int in frames.get_frame_count(clip):
			var texture := frames.get_frame_texture(clip,frame) as AtlasTexture
			var bounds: Rect2i = texture.atlas.get_image().get_region(Rect2i(texture.region)).get_used_rect()
			check(bounds.end.y==116,"%s frame %d keeps the approved adult foot baseline" % [clip,frame])
			check(absi(bounds.size.y-idle_height)<=2,"%s frame %d keeps the original shopper's body height" % [clip,frame])
	for direction: float in [-1.0,1.0]:
		gull.digestion.snacks.clear()
		gull.digestion.rest = 0.0
		gull.state = BeachGull.State.GLIDE
		gull.direction = Vector2(direction,0)
		gull.velocity = Vector2(direction*100.0,-60.0)
		var actor := game.spawner.create("kiosk_customer",500.0,{"appearance":"kiosk_customer","food_id":"ice_cream"})
		gull.position = Vector2(actor.position.x+direction*300.0,55.0)
		var planted_x: float = actor.position.x
		check(actor.take(gull),"successful direct theft starts the %s-facing pilot" % ("left" if direction<0 else "right"))
		check(actor.reaction.mode=="surprise" and actor.reaction.committed and actor.sprite.animation==&"surprise","successful theft triggers surprise exactly at theft completion")
		check(not actor.food and not actor.food_sprite.visible and actor.facing==direction and actor.sprite.flip_h==(direction<0),"surprise is empty-handed and supports both escape directions")
		actor.tick(0.15,[])
		check(actor.position.x==planted_x and actor.reaction.mode=="surprise" and actor.sprite.frame>=2,"surprise reads empty hand and recoil while planted")
		if direction > 0:
			var frozen_timer: float = actor.reaction.timer
			var frozen_frame: int = actor.sprite.frame
			game.set_paused(true)
			await get_tree().process_frame
			await get_tree().process_frame
			check(actor.reaction.timer==frozen_timer and actor.sprite.frame==frozen_frame and actor.sprite.speed_scale==0.0,"pause freezes surprise time and pose")
			game.set_paused(false)
			game.set_physics_process(false)
		actor.tick(0.18,[])
		check(actor.reaction.mode=="chase" and is_equal_approx(actor.reaction.timer,float(Config.tuning.world.snatch_chase_time)),"surprise hands off without consuming chase duration")
		actor.tick(0.01,[])
		check(actor.sprite.animation==&"run" and actor.position.x!=planted_x,"pilot reuses the existing running pursuit")
		var chase_start: float = actor.position.x
		actor.tick(float(Config.tuning.world.snatch_chase_time)-0.02,[])
		check(actor.reaction.mode=="chase" and absf(actor.position.x-chase_start)<=float(Config.tuning.world.snatch_chase_distance),"pursuit remains bounded for the full existing clock")
		actor.tick(0.02,[])
		var anger_x: float = actor.position.x
		check(actor.reaction.mode=="give_up" and is_equal_approx(actor.reaction.timer,AdultReaction.FAILED_CHASE_ANGER_TIME) and actor.sprite.animation==&"fist_shake","failed chase enters the 0.9 second planted fist shake")
		actor.tick(0.46,[])
		check(actor.position.x==anger_x and actor.facing==direction and actor.sprite.frame>=3,"anger stays planted, faces escape and reaches the second shake")
		check(actor.reaction.swat_timer<0 and actor.action_pose_time==0 and gull.state!=BeachGull.State.STUNNED,"fist shake cannot arm a swat or hit the gull")
		if direction > 0:
			var frozen_anger_timer: float = actor.reaction.timer
			var frozen_anger_frame: int = actor.sprite.frame
			game.set_paused(true)
			await get_tree().process_frame
			await get_tree().process_frame
			check(actor.reaction.timer==frozen_anger_timer and actor.sprite.frame==frozen_anger_frame,"pause freezes the planted fist-shake pose")
			game.set_paused(false)
			game.set_physics_process(false)
		actor.tick(0.45,[])
		check(actor.reaction.mode.is_empty() and actor.routine.enabled,"fist shake finishes cleanly and returns control to the routine")
	# Failed theft and ordinary proximity use their old paths, never the surprise clip.
	var failed := game.spawner.create("kiosk_customer",240.0,{"appearance":"kiosk_customer","food_id":"ice_cream"})
	failed.food = false
	failed.food_sprite.hide()
	check(not failed.take(gull) and failed.reaction.mode.is_empty(),"failed theft attempt does not trigger surprise")
	gull.position = failed.position+Vector2(10,-20)
	gull.state = BeachGull.State.GLIDE
	failed.reaction.tick(failed,0.01,[gull])
	check(failed.reaction.mode=="warning" and failed.sprite.animation!=&"surprise","ordinary proximity remains a warning")
	# The two non-pilot shopper appearances retain their existing immediate chase/anger.
	for appearance: String in ["shopper_mullet","shopper_sundress"]:
		gull.digestion.snacks.clear()
		gull.digestion.rest = 0.0
		gull.velocity = Vector2(100,-60)
		var other := game.spawner.create("kiosk_customer",700.0,{"appearance":appearance,"food_id":"ice_cream"})
		check(other.take(gull) and other.reaction.mode=="chase","%s remains outside the surprise pilot" % appearance)
		other.tick(float(Config.tuning.world.snatch_chase_time)+0.01,[])
		check(other.reaction.mode=="give_up" and other.sprite.animation==&"angry" and is_equal_approx(other.reaction.timer,float(Config.tuning.world.snatch_give_up_time)),"%s retains existing give-up art and timing" % appearance)
	print("SHOPPER REACTION PILOT: %d checks, %d failures" % [checks,failures])
	game.queue_free()
	await get_tree().process_frame
	get_tree().quit(1 if failures else 0)
