extends RefCounted
## All species share the real flight/collision model and clean, anchored atlases.
const SPECIES := ["herring","kittiwake","great-black-backed"]

static func run(host: Node, check: Callable) -> void:
	var speeds: Array[float] = []
	for index: int in SPECIES.size():
		var species: String = SPECIES[index]
		var id: String = "gull_"+species.replace("-","_")
		var entry: Dictionary = Config.sprites[id]
		var frames := Config.frames(id)
		preload("res://tests/isolated_sprite_checks.gd").run(check,frames,species)
		var idle := frames.get_frame_texture(&"idle",0) as AtlasTexture
		var image := idle.atlas.get_image().get_region(Rect2i(idle.region))
		var bounds := image.get_used_rect()
		check.call(is_equal_approx(bounds.size.y*float(entry.visual_scale),[16.5,12.75,21.0][index]),species+" has the approved standing height")
		for role: bool in [false,true]:
			var gull := BeachGull.new()
			gull.species = species
			gull.rival = role
			host.add_child(gull)
			check.call(gull.art_id == id and gull.sprite.material == null,species+" keeps natural plumage for either role")
			gull.state = BeachGull.State.GROUNDED
			gull.position = Vector2(140,gull.ground_y())
			gull.aim = gull.position
			gull.tick(0,0,0)
			var sole_y: float = (bounds.end.y-128)*gull.sprite.scale.y+gull.sprite.position.y
			check.call(is_equal_approx(sole_y,float(Config.tuning.flight.feet_offset)),species+" rendered feet meet sand and perch height")
			check.call(gull.sprite.animation == &"idle" and gull.sprite.visible,species+" standing uses production art")
			check.call(is_equal_approx(gull.beak().y-gull.position.y,float(entry.ground_beak_y)),species+" standing interaction follows the visible bill")
			for facing: float in [1.0,-1.0]:
				gull.velocity.x = facing*20
				gull.aim.x = gull.position.x+facing*100
				gull.tick(0,0,0)
				check.call(gull.sprite.animation == &"walk" and gull.sprite.flip_h == (facing<0),species+" walking faces its movement direction")
			gull.state = BeachGull.State.GLIDE
			gull.position = Vector2(140,60)
			gull.velocity = Vector2.ZERO
			gull.aim = Vector2(600,60)
			gull.climb = true
			gull.tick(1.0/60,0,0)
			check.call(gull.sprite.animation == &"climb" and gull.sprite.scale == Vector2.ONE*float(entry.visual_scale),species+" wingbeats retain body scale")
			if role:
				var source_index: int = entry.animations.climb.frames[gull.sprite.frame]
				var wing_top: float = (float(entry.frame_bounds[source_index][1])-float(entry.frame_h)*.5)*float(entry.visual_scale)+gull.sprite.position.y
				check.call(gull.rival_badge.position.y+gull.rival_badge.size.y <= wing_top-1,species+" rival badge clears raised wings")
			gull.climb = false
			gull.state = BeachGull.State.STRIKE
			gull.direction = Vector2(1,1).normalized()
			gull.aim = gull.position+gull.direction*100
			gull.dive_speed = 120
			gull.tick(0,0,0)
			check.call(gull.sprite.animation == &"dive" and is_equal_approx(gull.sprite.rotation,PI/4),species+" dive rotates around its aligned bill")
			gull.attempt_peck()
			gull.tick(0,0,0)
			check.call(gull.sprite.animation == &"snatch",species+" peck has its own contact drawing")
			gull.pullup()
			gull.tick(0,0,0)
			check.call(gull.sprite.animation == &"pullup",species+" pull-up has its own braking drawing")
			gull.velocity.y = 20
			gull.land()
			gull.tick(0,0,0)
			check.call(gull.sprite.animation == &"landing" and is_zero_approx(gull.sprite.rotation),species+" landing plants its feet without dive rotation")
			gull.tick(.2,0,0)
			check.call(gull.sprite.animation in [&"idle",&"walk"],species+" landing returns to grounded animation")
			gull.show_ground_peck()
			gull.tick(0,0,0)
			check.call(gull.sprite.animation == &"peck",species+" ground peck is visible")
			gull.stun()
			gull.tick(0,0,0)
			gull.tick(0.1,0,0)
			check.call(gull.sprite.animation == &"idle" and absf(gull.sprite.rotation)>0.5 and gull.position.y<gull.tumble_floor(),species+" impact spins existing folded art clear of sand")
			gull.refresh_art()
			gull.state = BeachGull.State.GLIDE
			gull.position = Vector2(140,30)
			gull.velocity = Vector2.ZERO
			gull.coasting = false
			gull.aim = Vector2(600,30)
			for frame: int in 45:
				gull.tick(1.0/60,0,0)
			if not role:
				speeds.append(gull.velocity.x)
			gull.queue_free()
	check.call(speeds[1] > speeds[0]*1.15 and is_equal_approx(speeds[2],speeds[0]),"kittiwake flies faster; the larger gull keeps standard movement")
	await host.get_tree().process_frame
	# Exercise the authored rival assignments and capture their real game rendering.
	host.main.start_level(6)
	var game: BeachGame = host.main.game
	game.set_physics_process(false)
	game.intro = 0
	game.running = true
	game.overlay.intro_panel.hide()
	for target: BeachTarget in game.spawner.targets:
		target.hide()
	var xs := {"Gary":180.0,"Chip":265.0,"Bev":80.0}
	game.player.position = Vector2(70,game.player.ground_y())
	game.player.state = BeachGull.State.GROUNDED
	game.player.aim = game.player.position
	game.player.tick(0,0,0)
	for pilot: RivalPilot in game.pilots:
		var gull: BeachGull = pilot.gull
		var expected := {"Gary":"great-black-backed","Chip":"kittiwake","Bev":"great-black-backed"}
		check.call(gull.species == expected[pilot.gull.rival_name],"authored rival uses its chosen species")
		gull.position = Vector2(xs[gull.rival_name],gull.ground_y())
		gull.state = BeachGull.State.GROUNDED
		gull.aim = gull.position
		gull.tick(0,0,0)
		if gull.rival_name == "Bev":
			gull.hide()
	game.camera_x = 160
	game.camera.position = Vector2(160,90)
	game.beach.camera_x = 160
	await host.snapshot("gull-species-game-lineup")
	host.main.clear_game()
	await host.get_tree().process_frame
