extends Node2D
## Reproducible gameplay-scale captures for peck, snatch and tumbling litter.

var game: BeachGame

func _ready() -> void:
	Audio.music.stop()
	game = BeachGame.new()
	add_child(game)
	game.setup(Config.levels[1].duplicate(true),false)
	game.set_physics_process(false)
	game.running = true
	game.intro = 0.0
	game.overlay.hide()
	call_deferred("_capture")

func _focus(world_x: float) -> void:
	game.camera_x = clampf(world_x,160.0,float(Config.tuning.world.width)-160.0)
	game.camera.position.x = game.camera_x
	game.beach.camera_x = game.camera_x
	game.beach.queue_redraw()
	game.stash_raids.queue_redraw()
	game.effects.queue_redraw()

func _save(label: String) -> void:
	for frame: int in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png("res://assets/previews/vfx-polish-%s-v1.png" % label) == OK)

func _clear_feedback() -> void:
	game.effects.particles.clear()
	game.effects.texts.clear()
	game.effects.freeze = 0.0
	game.effects.shake = 0.0

func _capture() -> void:
	var gull: BeachGull = game.player
	var bag_owner: BeachTarget
	var snack_owner: BeachTarget
	for target: BeachTarget in game.spawner.targets:
		if target.kind == "sunbather" and bag_owner == null:
			bag_owner = target
		elif target.kind == "kiosk_customer" and snack_owner == null:
			snack_owner = target
	assert(bag_owner != null and snack_owner != null)

	# Real accepted bag peck and its dedicated gull pose.
	_focus(bag_owner.stash_position().x)
	gull.position = Vector2(bag_owner.stash_position().x-11.0,gull.ground_y())
	gull.facing = 1.0
	gull.land()
	assert(game.stash_raids.peck())
	gull.show_ground_peck()
	game.effects.tick(0.035)
	await _save("bag-peck")

	# Final bin hit: source burst and airborne wrapper are both mid-motion.
	_clear_feedback()
	for target: BeachTarget in game.spawner.targets:
		target.hide()
	var bin: Dictionary = game.stash_raids.bins[0]
	_focus(float(bin.x))
	gull.position = Vector2(float(bin.x)-22.0,gull.ground_y())
	gull.facing = 1.0
	gull.land()
	for tap: int in int(Config.tuning.world.bin_pecks):
		game.stash_raids.peck_cooldown = 0.0
		assert(game.stash_raids.peck())
		gull.show_ground_peck()
		if tap < int(Config.tuning.world.bin_pecks)-1:
			game.effects.tick(0.24)
			game.stash_raids.tick(0.24)
			_clear_feedback()
	game.effects.texts.clear()
	game.effects.tick(0.055)
	game.stash_raids.tick(0.055)
	await _save("bin-tumble")
	game.effects.tick(0.055)
	game.stash_raids.tick(0.055)
	await _save("bin-tumble-late")

	# Actual target theft signal: the contact VFX appears before digestion awards it.
	_clear_feedback()
	snack_owner.show()
	_focus(snack_owner.position.x)
	snack_owner.food = true
	snack_owner.food_sprite.show()
	snack_owner.respawn = 0.0
	gull.state = BeachGull.State.STRIKE
	gull.sweep_state = BeachGull.State.STRIKE
	gull.direction = Vector2(0.93,0.36)
	gull.velocity = gull.direction*190.0
	gull.position = snack_owner.food_position()-gull.direction*10.0
	gull.peck_used = true
	gull.peck_time = float(Config.tuning.dive.peck_window)
	assert(snack_owner.take(gull))
	gull.tick(0.0,0,0.0)
	game.effects.tick(0.035)
	await _save("snatch")

	for audio_player: Node in Audio.get_children():
		if audio_player is AudioStreamPlayer:
			audio_player.stop()
	await get_tree().create_timer(0.05).timeout
	get_tree().quit()
