extends Node2D
var checks: int = 0
var failures: int = 0

func check(condition: bool,message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: "+message)

func _ready() -> void:
	Audio.music.stop()
	var definition: Dictionary = Config.levels[2].duplicate(true)
	definition.spawns = []
	definition.props = []
	var spawner := BeachSpawner.new()
	spawner.setup(self,definition)
	for id: String in ShopperArt.APPEARANCES:
		var actor := spawner.create("kiosk_customer",500)
		check(actor.shopper_appearance==id and actor.info.sprite==id,"new customers cycle through all three appearances")
	for id: String in ["shopper_mullet","shopper_sundress"]:
		var actor := spawner.create("kiosk_customer",650,{"appearance":id,"food_id":"ice_cream"})
		check(actor.art_height()==40 and actor.sprite.scale==Vector2(0.5,0.5),id+" matches adult height")
		check(Config.targets.kiosk_customer.sprite=="kiosk_customer",id+" leaves shared target data intact")
		actor.refresh_art()
		check(actor.info.sprite==id,id+" survives art refresh")
		for facing: float in [-1.0,1.0]:
			actor.facing = facing
			actor.reaction.mode = ""
			actor.update_art_pose(true)
			check(actor.sprite.animation==&"walk" and actor.sprite.flip_h==(facing<0),id+" walks in both directions")
			for frame: int in actor.sprite.sprite_frames.get_frame_count(&"walk"):
				actor.sprite.frame = frame
				check(signf(actor.food_sprite.position.x)==facing,id+" snack follows the visible facing hand")
		actor.reaction.mode = "chase"
		actor.update_art_pose(true)
		check(actor.sprite.animation==&"run",id+" uses chase artwork")
		actor.reaction.swat_timer = 0.35
		actor.update_art_pose(false)
		check(actor.sprite.animation==&"windup" and actor.sprite.frame==0,id+" anticipates the shared swat timer")
		actor.action_pose_time = 0.28
		actor.update_art_pose(false)
		check(actor.sprite.animation==&"swat" and actor.sprite.frame==2,id+" contact starts on the hit frame")
		actor.action_pose_time = 0
		actor.reaction.mode = ""
		actor.reaction.swat_timer = -1
		actor.facing = -1
		actor.update_art_pose(false)
		var gull := BeachGull.new()
		add_child(gull)
		gull.state = BeachGull.State.STRIKE
		gull.sweep_state = BeachGull.State.STRIKE
		gull.peck_sweep_active = true
		gull.direction = Vector2.RIGHT
		gull.previous_beak = actor.food_position()-Vector2(15,0)
		gull.sweep_beak = actor.food_position()+Vector2(15,0)
		BeachCollisions.resolve(gull,[actor],[])
		check(not actor.food and not actor.food_sprite.visible,id+" food is stealable at the mirrored drawn hand")
		gull.queue_free()
	check(Config.reload_data(),"config reload succeeds with new sprite registry entries")
	for actor: BeachTarget in spawner.targets:
		check(actor.info.sprite==actor.shopper_appearance,"config reload preserves each shopper's identity")
	print("SHOPPER VARIANTS: %d checks, %d failures" % [checks,failures])
	# Let the audio thread release the autoload's stopped music playback.
	await get_tree().create_timer(0.1).timeout
	get_tree().quit(1 if failures else 0)
