extends Node

var checks := 0
var failures := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	Audio.music.stop()
	var entry: Dictionary = Config.sprites.pier_diner_motion
	check(entry.file == "res://assets/sprites/pier-diner-motion-v2.png", "diner selects the versioned walk atlas")
	var authoring: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/pier_diner_art.json"))
	check(authoring.pier_diner_motion == entry, "authoring and runtime diner motion metadata stay synchronized")
	var frames := Config.frames("pier_diner_motion")
	check(frames.get_frame_count(&"walk") == 6 and is_equal_approx(frames.get_animation_speed(&"walk"), 7.0), "diner has a six-phase seven-fps walk")
	check(frames.get_frame_count(&"run") == 4 and frames.get_frame_count(&"eat") == 4, "approved run and eat clip lengths remain unchanged")
	preload("res://tests/isolated_sprite_checks.gd").run(Callable(self, "check"), frames, "diner walk v2")
	var min_height := 1000
	var max_height := 0
	for frame: int in frames.get_frame_count(&"walk"):
		var texture := frames.get_frame_texture(&"walk", frame) as AtlasTexture
		var bounds := texture.atlas.get_image().get_region(Rect2i(texture.region)).get_used_rect()
		check(bounds.end.y == 398, "diner walk frame %d keeps the shared sole baseline" % frame)
		min_height = mini(min_height, bounds.size.y)
		max_height = maxi(max_height, bounds.size.y)
	check(max_height - min_height <= 2, "diner walk keeps stable adult height across all phases")
	var old_atlas := Image.load_from_file("res://assets/sprites/pier-diner-motion-clean.png")
	var new_atlas := Image.load_from_file("res://assets/sprites/pier-diner-motion-v2.png")
	for old_index: int in range(4, 12):
		var new_index := old_index + 2
		var old_cell := old_atlas.get_region(Rect2i(old_index % 4 * 400, old_index / 4 * 400, 400, 400))
		var new_cell := new_atlas.get_region(Rect2i(new_index % 4 * 400, new_index / 4 * 400, 400, 400))
		check(old_cell.get_data() == new_cell.get_data(), "approved diner motion cell %d remains pixel-identical" % old_index)
	var definition: Dictionary = Config.levels[2].duplicate(true)
	definition.spawns = []
	definition.rivals = []
	definition.props = []
	var game := BeachGame.new()
	add_child(game)
	game.setup(definition, false)
	game.set_physics_process(false)
	game.running = true
	game.intro = 0.0
	var diner := game.spawner.create("pier_diner", 420.0, {"food_id":"fish_chips"})
	diner.facing = 1.0
	diner.leaving = false
	diner.update_art_pose(true)
	check(diner.sprite.animation == &"walk" and is_equal_approx(diner.sprite.get_playing_speed(), 1.0), "normal promenade uses the new walk at its authored cadence")
	check(diner.food_sprite.visible and diner.food_sprite.position == Vector2(10, -22), "food remains separate and steady on the serving palm")
	diner.facing = -1.0
	diner.update_art_pose(true)
	check(diner.sprite.flip_h and diner.food_sprite.position == Vector2(-10, -22), "walk and food anchor mirror together when facing left")
	diner.leaving = true
	diner.update_art_pose(true)
	check(diner.sprite.animation == &"walk" and is_equal_approx(diner.sprite.get_playing_speed(), 3.0), "fast departure scales walk cadence with its three-times movement speed")
	var frozen_frame := diner.sprite.frame
	game.set_paused(true)
	await get_tree().process_frame
	await get_tree().process_frame
	check(diner.sprite.speed_scale == 0.0 and diner.sprite.frame == frozen_frame, "pause freezes the diner walk")
	game.set_paused(false)
	game.set_physics_process(false)
	diner.leaving = false
	diner.reaction.mode = "chase"
	diner.update_art_pose(true)
	check(diner.sprite.animation == &"run" and is_equal_approx(diner.sprite.get_playing_speed(), 1.0), "pursuit still uses the existing run unchanged")
	print("DINER WALK V2: %d checks, %d failures" % [checks, failures])
	game.queue_free()
	await get_tree().process_frame
	get_tree().quit(1 if failures else 0)
