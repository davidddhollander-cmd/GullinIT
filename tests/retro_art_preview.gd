extends Node2D
## Visual QA only: captures the actual backdrop and native adult sprites.
var backdrop: BeachBackdrop
var camera: Camera2D

func _ready() -> void:
	backdrop = BeachBackdrop.new()
	add_child(backdrop)
	backdrop.setup(Config.levels[0].props)
	var rng := RandomNumberGenerator.new()
	rng.seed = 40
	for specification: Dictionary in [
		{"kind": "sunbather", "x": 105.0, "appearance": "male_red"},
		{"kind": "sunbather", "x": 255.0, "appearance": "female_blue"},
		{"kind": "picnic_family", "x": 435.0, "appearance": ""},
		{"kind": "picnic_family", "x": 585.0, "appearance": ""}
	]:
		var target := BeachTarget.new()
		add_child(target)
		target.setup(specification.kind, specification.x, rng, 1.0, {"appearance": specification.appearance})
		if specification.kind == "sunbather" and specification.x > 200.0:
			target.stash_standing = true
			SunbatherArt.pose(target, &"rise", 6)
		elif specification.kind == "picnic_family":
			target.update_art_pose(false)
	camera = Camera2D.new()
	add_child(camera)
	camera.enabled = true
	call_deferred("_capture")

func _capture() -> void:
	for scene: Dictionary in [
		{"x": 160.0, "name": "beach"},
		{"x": 480.0, "name": "families"},
		{"x": 800.0, "name": "stands"},
		{"x": 1120.0, "name": "pier"}
	]:
		camera.position = Vector2(scene.x, 90)
		backdrop.camera_x = scene.x
		backdrop.queue_redraw()
		for i: int in 3:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var image: Image = get_viewport().get_texture().get_image()
		image.save_png("res://assets/previews/retro-game-%s-v1.png" % scene.name)
	get_tree().quit()
