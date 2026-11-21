extends Node
## Renders the horizon strip for review: godot --path . tests/horizon_capture.tscn (non-headless) -> test-output/horizon/
const OUT: String = "res://test-output/horizon/"
var main: Node

func shot(label: String) -> Image:
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	if img.get_size() != Vector2i(1280, 720):
		img.resize(1280, 720, Image.INTERPOLATE_NEAREST)
	var native: Image = img.duplicate()
	native.resize(320, 180, Image.INTERPOLATE_NEAREST)
	native.save_png(OUT + label + "_native.png")
	img.save_png(OUT + label + "_x4.png")
	return img

func at(level: int, cam: float, label: String, strip: bool = true) -> Image:
	main.start_level(level)
	var game: BeachGame = main.game
	game.set_physics_process(false)
	game.intro = 0
	game.camera_x = cam
	game.beach.camera_x = cam
	game.camera.position.x = cam
	game.beach.tick(0.0)
	if game.beach.background_art.horizon:
		game.beach.background_art.horizon.visible = strip
	return await shot(label)

func _ready() -> void:
	GullInput.register_actions()
	Audio.music.stop()
	GameState.save_path = "res://test-output/horizon-save.json"
	BeachGame.trainer_cards = false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	main = preload("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	var before: Image = await at(5, 160.0, "L5_before", false)
	var after: Image = await at(5, 160.0, "L5_x160")
	await at(5, 640.0, "L5_x640")
	await at(5, 1120.0, "L5_x1120")
	await at(8, 160.0, "L8_x160")
	var both: Image = Image.create(1280, 1440, false, Image.FORMAT_RGBA8)
	both.blit_rect(before, Rect2i(0, 0, 1280, 720), Vector2i(0, 0))
	both.blit_rect(after, Rect2i(0, 0, 1280, 720), Vector2i(0, 720))
	both.save_png(OUT + "L5_compare_x4.png")
	get_tree().quit()
