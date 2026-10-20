extends Node
## Run with tests/loading_checks.tscn; append -- --capture for rendered review stills.
var checks: int = 0
var failures: int = 0
var capture: bool = false

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func _ready() -> void:
	capture = OS.get_cmdline_user_args().has("--capture")
	run.call_deferred()

func snapshot(label: String) -> void:
	if capture:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://test-output/" + label + ".png")

func run() -> void:
	var loader: StartupLoading = load("res://scenes/loading.tscn").instantiate()
	loader.preview_only = true
	add_child(loader)
	await get_tree().process_frame
	check(loader.size == get_viewport().get_visible_rect().size, "loading artwork fills the viewport")
	check(loader.gull.is_playing() and loader.gull.animation == &"fly", "startup gull plays wingbeats")
	var start_frame: int = loader.gull.frame
	var start_position: Vector2 = loader.flight.position
	await get_tree().create_timer(0.13).timeout
	check(loader.gull.frame != start_frame, "wing pose changes over time")
	check(loader.flight.position.x > start_position.x, "gull flies forward across the sky")
	for pose: int in [1, 2, 3]:
		while loader.gull.frame != pose:
			await loader.gull.frame_changed
		await snapshot("loading-wings-" + ["up", "mid", "down", "up"][pose])
	var entry: Dictionary = Config.sprites.player_gull
	var largest_width: float = 0.0
	for index: int in entry.animations.fly.frames:
		largest_width = maxf(largest_width, float(entry.frame_bounds[index][2]) * loader.gull.scale.x)
	check(largest_width <= 42.0, "animated gull is under 56% of the old 76-pixel-wide splash gull")
	loader.set_process(false)
	for time: float in [0.0, 2.0, 4.0, 6.0, 9.0, 12.0]:
		loader.clock = time
		loader._process(0.0)
		check(loader.flight.position.y < loader.size.y * 0.40, "flight remains clear of loading lettering")
	loader.queue_free()
	await get_tree().process_frame
	# Keep this runner alive while exercising the real application entry point.
	get_tree().current_scene = null
	check(get_tree().change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene")) == OK, "application opens the loading scene")
	await get_tree().process_frame
	await get_tree().process_frame
	check(get_tree().current_scene is StartupLoading, "startup displays loading before the title")
	var deadline: int = Time.get_ticks_msec() + 15000
	while get_tree().current_scene is StartupLoading and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	var main: Node = get_tree().current_scene
	check(main != null and main.scene_file_path == "res://scenes/main.tscn", "loading completes at the main scene")
	if main != null and main.scene_file_path == "res://scenes/main.tscn":
		check(main.screen == "title" and main.menus.visible, "title menu is ready after loading")
		await snapshot("loading-complete-title")
	if main != null:
		main.queue_free()
	print("Startup loading: %d checks, %d failures" % [checks, failures])
	Audio.stop_all()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.1).timeout
	get_tree().quit(0 if failures == 0 else 1)
