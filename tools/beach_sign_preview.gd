extends Node2D
## Actual beach renders and focused checks for generated direction signs.
var game: BeachGame
var failures: int = 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _ready() -> void:
	Audio.music.stop()
	call_deferred("review")

func review() -> void:
	for level: Dictionary in Config.levels:
		var beach := BeachBackdrop.new()
		add_child(beach)
		Config.apply_level_world(level)
		beach.setup(level.props,level.get("zones",[]),level.get("world",{}))
		var signs: Array[Dictionary] = beach.sign_layouts()
		check(signs.size()==beach.sign_zones().size(),"Every level %s zone has a clear sign position" % level.id)
		for sign: Dictionary in signs:
			check(not beach._sign_hits_prop(int(sign.rect.position.x),int(sign.rect.size.x),beach.props,int(sign.rect.size.y)),"Generated sign clears props, including post")
			check(sign.rect.position.x>=float(sign.zone.from) and sign.rect.end.x<=float(sign.zone.to),"Sign fits zone")
			for arrow: Dictionary in sign.arrows:
				check(bool(arrow.right)==(float(arrow.target_x)>=sign.rect.get_center().x),"Arrow points toward destination after placement")
		print("SIGNS level ",level.id,": ",signs.size()," clear signs")
		beach.queue_free()
		await get_tree().process_frame
	if "--check-only" in OS.get_cmdline_user_args():
		print("Beach sign checks: ",failures," failures")
		get_tree().quit(1 if failures else 0)
		return
	game = BeachGame.new()
	add_child(game)
	game.setup(Config.levels[2].duplicate(true),false)
	game.set_physics_process(false)
	game.running = true
	game.intro = 0
	game.overlay.hide()
	var sheet := Image.create(640,360,false,Image.FORMAT_RGBA8)
	var signs: Array[Dictionary] = game.beach.sign_layouts()
	for index: int in signs.size():
		var sign: Dictionary = signs[index]
		var center: float = clampf(sign.rect.get_center().x,160,float(game.level.world.width)-160)
		game.camera_x = center
		game.camera.position.x = center
		game.beach.camera_x = center
		game.player.position = Vector2(center-66,65)
		game.beach.queue_redraw()
		for frame: int in 3:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var image: Image = get_viewport().get_texture().get_image()
		image.save_png("res://assets/previews/beach-signs-level3-%d-v7.png" % index)
		image.resize(320,180,Image.INTERPOLATE_NEAREST)
		if index<4:
			sheet.blit_rect(image,Rect2i(0,0,320,180),Vector2i((index%2)*320,(index/2)*180))
	# The authored boardwalk has three zones; the fourth panel shows a single arrow.
	game.queue_free()
	await get_tree().process_frame
	game = BeachGame.new()
	add_child(game)
	game.setup(Config.levels[0].duplicate(true),false)
	game.set_physics_process(false)
	game.overlay.hide()
	game.player.hide()
	var last_sign: Dictionary = game.beach.sign_layouts()[2]
	var center: float = last_sign.rect.get_center().x
	game.camera_x = center
	game.camera.position.x = center
	game.beach.camera_x = center
	game.beach.queue_redraw()
	for frame: int in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var single: Image = get_viewport().get_texture().get_image()
	single.save_png("res://assets/archive/previews/beach-signs-single-arrow-v7.png")
	single.resize(320,180,Image.INTERPOLATE_NEAREST)
	sheet.blit_rect(single,Rect2i(0,0,320,180),Vector2i(320,180))
	sheet.resize(1280,720,Image.INTERPOLATE_NEAREST)
	sheet.save_png("res://assets/archive/previews/beach-signs-review-v7.png")
	get_window().size = Vector2i(640,360)
	for frame: int in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://assets/archive/previews/beach-signs-phone-v7.png")
	var level_sheet := Image.create(960,360,false,Image.FORMAT_RGBA8)
	for number: int in 6:
		game.queue_free()
		await get_tree().process_frame
		game = BeachGame.new()
		add_child(game)
		game.setup(Config.levels[number].duplicate(true),false)
		game.set_physics_process(false)
		game.overlay.hide()
		game.player.hide()
		var layouts: Array[Dictionary] = game.beach.sign_layouts()
		var focus: Dictionary = layouts[mini(1,layouts.size()-1)]
		for layout: Dictionary in layouts:
			if str(layout.name)=="PROMENADE":
				focus = layout
		var camera: float = clampf(focus.rect.get_center().x,160,float(Config.tuning.world.width)-160)
		game.camera_x = camera
		game.camera.position.x = camera
		game.beach.camera_x = camera
		game.beach.queue_redraw()
		for display_size: int in [1280,640]:
			get_window().size = Vector2i(display_size,display_size*180/320)
			for frame: int in 3:
				await get_tree().process_frame
			await RenderingServer.frame_post_draw
			var capture: Image = get_viewport().get_texture().get_image()
			capture.save_png("res://assets/previews/beach-signs-level%d-%d-v7.png" % [number+1,display_size])
			if display_size==1280:
				capture.resize(320,180,Image.INTERPOLATE_NEAREST)
				level_sheet.blit_rect(capture,Rect2i(0,0,320,180),Vector2i((number%3)*320,(number/3)*180))
	level_sheet.resize(1920,720,Image.INTERPOLATE_NEAREST)
	level_sheet.save_png("res://assets/archive/previews/beach-signs-all-levels-v7.png")
	print("Beach sign checks: ",failures," failures")
	get_tree().quit(1 if failures else 0)
