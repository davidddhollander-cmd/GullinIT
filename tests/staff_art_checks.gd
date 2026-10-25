extends RefCounted

static func run(harness: Node,check: Callable) -> void:
	for id: String in ["lifeguard","kiosk_customer","shopper_mullet","shopper_sundress","seafood_vendor"]:
		var frames := Config.frames(id)
		preload("res://tests/isolated_sprite_checks.gd").run(check,frames,id)
		var atlas: Texture2D = frames.get_frame_texture(&"idle",0).atlas
		var image := atlas.get_image()
		var data := image.get_data()
		var hard_alpha := true
		for offset: int in range(3,data.size(),4):
			if data[offset] not in [0,255]:
				hard_alpha = false
		check.call(hard_alpha and image.get_mipmap_count()==0,id+" keeps clean hard alpha and native detail")
		for clip: StringName in frames.get_animation_names():
			for index: int in frames.get_frame_count(clip):
				var texture := frames.get_frame_texture(clip,index) as AtlasTexture
				check.call(texture.get_size()==Vector2(128,128),id+" uses adult source canvas")
				check.call(Rect2(Vector2.ZERO,texture.atlas.get_size()).encloses(texture.region),id+" crop stays inside atlas")
				var cell := texture.atlas.get_image().get_region(Rect2i(texture.region))
				check.call(cell.get_used_rect().end.y==116,id+" feet share adult baseline")
		for clip: StringName in [&"walk",&"run",&"swat"]:
			if not frames.has_animation(clip):
				continue
			var previous := PackedByteArray()
			for index: int in frames.get_frame_count(clip):
				var texture := frames.get_frame_texture(clip,index) as AtlasTexture
				var pixels := texture.atlas.get_image().get_region(Rect2i(texture.region)).get_data()
				check.call(previous!=pixels,id+" "+String(clip)+" advances drawn limbs")
				previous = pixels
	var seafood_entry: Dictionary = Config.sprites.seafood_vendor
	check.call(seafood_entry.file=="res://assets/sprites/seafood-vendor-generated-v1.png" and seafood_entry.frame_w==128 and seafood_entry.frame_h==128,"seafood guard replaces the 16x32 placeholder with generated adult art")
	check.call(seafood_entry.visual_scale==0.5 and seafood_entry.art_height==40 and seafood_entry.sprite_offset_y==-26,"seafood guard matches the approved adult display scale and foot offset")
	var seafood_expected := {"idle":4,"windup":2,"swat":2,"walk":6,"alert":2,"angry":2}
	var seafood_frames := Config.frames("seafood_vendor")
	for clip: String in seafood_expected:
		check.call(seafood_frames.has_animation(clip) and seafood_frames.get_frame_count(clip)==seafood_expected[clip],"seafood guard exposes the generated "+clip+" animation")
		for frame: int in seafood_frames.get_frame_count(clip):
			var texture := seafood_frames.get_frame_texture(clip,frame) as AtlasTexture
			var bounds := texture.atlas.get_image().get_region(Rect2i(texture.region)).get_used_rect()
			check.call(bounds.size.x>=35 and bounds.size.y>=45,"seafood guard keeps the full body and visible broom in "+clip+" frame")
	check.call(FileAccess.file_exists("res://assets/sprites/seafood_vendor.png"),"legacy seafood placeholder stays in the project but unused")
	check.call(FileAccess.file_exists("res://assets/previews/seafood-vendor-v1-comparison.png"),"seafood guard comparison preview is preserved")
	harness.main.start_level(4)
	var game: BeachGame = harness.main.game
	game.set_physics_process(false)
	game.intro = 0
	game.running = true
	for actor: BeachTarget in game.spawner.targets:
		actor.hide()
	var guard := game.spawner.create("lifeguard",550)
	var shopper := game.spawner.create("kiosk_customer",625,{"food_id":"ice_cream","appearance":"kiosk_customer"})
	game.camera_x = 590
	game.camera.position = Vector2(590,90)
	game.beach.camera_x = 590
	game.player.position = Vector2(450,80)
	for actor: BeachTarget in [guard,shopper]:
		check.call(actor.art_height()==40 and actor.sprite.scale==Vector2(0.5,0.5),actor.kind+" matches adult visible height")
		check.call(actor.sprite.texture_filter==CanvasItem.TEXTURE_FILTER_NEAREST and actor.sprite.material==null,actor.kind+" uses crisp transparent sprite rendering")
	guard.tick(0.1,[])
	check.call(guard.sprite.animation==&"walk" and not guard.food_sprite.visible,"lifeguard patrols without carrying food")
	await harness.snapshot("staff-patrol-and-shopper")
	var old_man := game.spawner.create("kiosk_customer",550,{"food_id":"ice_cream","appearance":"old_man"})
	old_man.update_art_pose(true)
	shopper.hide()
	guard.hide()
	await harness.snapshot("old-man-on-beach")
	shopper.show()
	guard.show()
	game.spawner.targets.erase(old_man)
	old_man.queue_free()
	var whistles := {"count":0,"visible":false}
	guard.whistled.connect(func(_owner: BeachTarget) -> void:
		whistles.count += 1
		whistles.visible = guard.sprite.animation==&"whistle" and guard.sprite.frame==0
	)
	game.player.state = BeachGull.State.STRIKE
	game.player.position = guard.position+Vector2(55,-16)
	var whistle_at := guard.position
	guard.tick(0.01,[game.player])
	check.call(whistles.count==1 and whistles.visible,"whistle event coincides with the drawn mouth whistle pose")
	check.call(shopper.alert==1,"lifeguard whistle still alerts nearby targets")
	check.call(guard.position==whistle_at,"lifeguard plants its feet for the whistle pose")
	guard.sprite.pause()
	guard.sprite.frame = 1
	guard.tick(0.01,[game.player])
	check.call(whistles.count==1 and guard.sprite.frame==1,"whistle cooldown and playback do not restart each tick")
	await harness.snapshot("staff-lifeguard-whistle")
	guard.tick(0.9,[])
	check.call(guard.sprite.animation==&"walk","lifeguard returns to patrol after whistle presentation")
	# A close strike must still whistle even when the shared warning logic runs.
	guard.recover = 0
	guard.lifeguard_whistle_time = 0
	guard.reaction.mode = ""
	guard.reaction.cooldown = 0
	guard.reaction.near.clear()
	guard.reaction.window = 0
	game.player.position = guard.position+Vector2(-20,-12)
	guard.tick(0.01,[game.player])
	check.call(whistles.count==2 and guard.sprite.animation==&"whistle" and guard.sprite.flip_h,"nearby strike shows left-facing whistle before shared reaction fallback")
	await harness.snapshot("staff-lifeguard-whistle-left")
	var close_whistle_at := guard.position
	guard.tick(0.1,[game.player])
	check.call(guard.position==close_whistle_at,"shared reactions do not slide the planted whistle pose")
	guard.recover = 0
	guard.action_pose_time = 0.2
	guard._tick_lifeguard_whistle([game.player])
	check.call(whistles.count==2,"a new whistle does not interrupt a swat contact")
	for actor: BeachTarget in [guard,shopper]:
		actor.lifeguard_whistle_time = 0
		actor.action_pose_time = 0
		actor.reaction.mode = "chase"
		actor.reaction.swat_timer = -1
		actor.facing = -1
		actor.update_art_pose(true)
		check.call(actor.sprite.animation==&"run" and actor.sprite.flip_h,actor.kind+" chases with dedicated mirrored run art")
	await harness.snapshot("staff-chase-left")
	for actor: BeachTarget in [guard,shopper]:
		actor.reaction.swat_timer = 0.35
		actor.update_art_pose(false)
		check.call(actor.sprite.animation==&"windup" and actor.sprite.frame==0,actor.kind+" anticipates actual shared swat timer")
	await harness.snapshot("staff-windup")
	for actor: BeachTarget in [guard,shopper]:
		actor.reaction.mode = "chase"
		actor.reaction.timer = 1
		actor.reaction.home = actor.position.x
		actor.reaction.focus = game.player
		actor.reaction.swat_timer = 0.01
		actor.recover = 3
		game.player.position = actor.position-Vector2(10,12)
		game.player.state = BeachGull.State.GLIDE
		game.player.invulnerable = 0
		actor.tick(0.02,[game.player])
		check.call(game.player.state==BeachGull.State.STUNNED and actor.sprite.animation==&"swat" and actor.sprite.frame==2,actor.kind+" contact art matches actual hit frame")
	await harness.snapshot("staff-swat-contact")
	shopper.action_pose_time = 0
	shopper.reaction.mode = ""
	shopper.reaction.swat_timer = -1
	shopper.recover = 0
	shopper.alert = 0
	shopper.facing = 1
	shopper.update_art_pose(true)
	for frame: int in shopper.sprite.sprite_frames.get_frame_count(&"walk"):
		shopper.sprite.frame = frame
		var anchor: Array = Config.sprites.kiosk_customer.food_anchors.walk[frame]
		check.call(shopper.food_sprite.position==Vector2(anchor[0],anchor[1]),"shopper snack follows each source palm")
	shopper.facing = -1
	shopper.update_art_pose(true)
	shopper.sprite.frame = 2
	check.call(shopper.food_position().x < shopper.position.x,"new shopper mirrors food with its drawn hand")
	var food_at := shopper.food_position()
	game.player.state = BeachGull.State.STRIKE
	game.player.sweep_state = BeachGull.State.STRIKE
	game.player.peck_sweep_active = true
	game.player.grounded_sweep = false
	game.player.direction = Vector2.RIGHT
	game.player.previous_beak = food_at-Vector2(15,0)
	game.player.sweep_beak = food_at+Vector2(15,0)
	BeachCollisions.resolve(game.player,[shopper],[])
	check.call(not shopper.food and not shopper.food_sprite.visible,"new shopper snack remains stealable at the visible mirrored hand")
	harness.main.clear_game()
	await harness.settle()
	harness.main.start_level(6)
	var boss: BeachGame = harness.main.game
	boss.set_physics_process(false)
	boss.intro = 0
	boss.running = true
	boss.overlay.hide()
	boss.camera_x = 1235
	boss.camera.position = Vector2(1235,90)
	boss.beach.camera_x = 1235
	boss.player.position = Vector2(900,50)
	var seafood_guard: BeachTarget
	for actor: BeachTarget in boss.spawner.targets:
		if actor.kind=="seafood_vendor":
			seafood_guard = actor
			break
	check.call(seafood_guard!=null,"level 6 pier end contains the seafood guard")
	if seafood_guard!=null:
		seafood_guard.sprite.play(&"idle")
		seafood_guard.sprite.pause()
		seafood_guard.sprite.frame = 0
		check.call(seafood_guard.art_height()==40 and seafood_guard.sprite.scale==Vector2(0.5,0.5),"level 6 seafood guard stands at the same adult scale as pier diners")
		await harness.snapshot("seafood-vendor-l6-pier-end")
		seafood_guard.alert = 1
		# Stay inside broom awareness but outside the shared 38 px proximity warning,
		# so the broom-specific telegraph can advance through windup to swat.
		boss.player.position = seafood_guard.position+Vector2(-55,-12)
		boss.player.state = BeachGull.State.GLIDE
		boss.player.invulnerable = 0
		seafood_guard.tick(0.01,boss.gulls)
		check.call(seafood_guard.sprite.animation==&"windup","level 6 broom warning plays the generated windup")
		seafood_guard.tick(0.7,boss.gulls)
		check.call(seafood_guard.sprite.animation==&"swat","level 6 broom defense advances to the generated swat")
	harness.main.clear_game()
	await harness.settle()
