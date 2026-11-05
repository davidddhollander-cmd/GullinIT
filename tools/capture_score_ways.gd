extends Node2D
## Stages the HOW TO SCORE stills with the real game sprites: godot --path . res://tools/capture_score_ways.tscn -- --way=snatch
## The moment just before contact is set up in the running game, frozen, and one native-resolution frame is
## cropped to assets/sprites/score-ways/<way>.png. No popups, HUD, tags or scenery: nothing is drawn in code.

const OUTPUT_DIR: String = "res://assets/sprites/score-ways/"
const SETTLE_LIMIT: int = 60 * 90

var way: String = "snatch"
var game: BeachGame
var focus: BeachTarget
var ok: bool = false
var center: Vector2

func _ready() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--way="):
			way = argument.trim_prefix("--way=")
	_run.call_deferred()

func _level(index: int) -> Dictionary:
	var level: Dictionary = Config.levels[index].duplicate(true)
	level.seed = 7352
	level.time_limit = 999
	level.erase("random_quest")
	level.quests = []
	level.crabs = {"enabled": false}
	level.player_species = "herring"
	return level

func _prepare(level: Dictionary) -> void:
	seed(7352)
	GameState.save_path = "user://score_ways_capture.json"
	Analytics.config.enabled = false
	GameState.options.merge({"stats": false, "touch": false, "shake": false, "tips": ["teen", "squall", "dogs"], "control_mode": "normal"}, true)
	GullInput.register_actions()
	BeachGame.trainer_cards = false
	get_window().size = Vector2i(1280, 720) # the game's own window: canvas_items stretch draws sprites at 4x, which is why the stills are sharp
	get_window().content_scale_size = Vector2i(320, 180)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	game = BeachGame.new()
	add_child(game)
	game.setup(level, false)
	game.set_physics_process(false)
	game.set_process_unhandled_input(false)
	game.running = true
	game.intro = 0.0
	game.intro_dismissed_elapsed = 0.0
	game.overlay.hide()
	game.input.set_process_input(false)
	game.input.enabled = false
	game.input.touch_visible = false
	game.input.touch_active = true
	game.input.gamepad = false
	Audio.music.stop()
	for dog: OffLeadDog in game.dogs:
		dog.position.x = -2000.0

## Everyone but the shot's subject leaves, so nothing overlaps in the frame.
func _clear_except(keep: Array) -> void:
	for target: BeachTarget in game.spawner.targets:
		if target not in keep:
			target.position.x = -2000.0
			target.leaving = true

const SCALE: int = 4 ## window pixels per logical pixel
const STILL_SIZE: Vector2i = Vector2i(74, 42) * SCALE ## the same 74x42 framing, captured at 4x
const GAP: float = 9.0 ## px between the beak and its food: just before contact

func _step(count: int) -> void:
	for index: int in count:
		game._physics_process(1.0 / 60.0)
		_suppress()

## Popups, tip text and burst sprites are dropped; the whole HUD layer (tags, rings, brackets) is hidden.
func _suppress() -> void:
	var fx: BeachEffects = game.effects
	fx.texts.clear()
	fx.particles.clear()
	fx.shake = 0.0
	for child: Node in fx.get_children():
		child.queue_free()
	for child: Node in game.get_children():
		if child is CanvasLayer:
			(child as CanvasLayer).visible = false

## Scenery props leave the frame (the stall under the counter shot stays); the backdrop sky, sea and sand remain.
func _clear_scenery(keep_x: float = -1.0) -> void:
	var beach: BeachBackdrop = game.get_child(0) as BeachBackdrop
	beach.props = []
	beach.wind_flags = []
	beach.zones = [{"name": "", "from": -5000, "to": -4900}] # no signposts (an empty list falls back to the defaults) or flagpoles
	beach.queue_redraw()
	for child: Node in beach.get_children():
		if child is AnimatedSprite2D and not is_equal_approx((child as AnimatedSprite2D).position.x, keep_x):
			child.hide()
	game.scraps.crumbs.clear()

## Name badges and the gold target corners are the game's own markers; hide them for the still.
func _strip_marks() -> void:
	for gull: BeachGull in game.gulls:
		gull.set_process(false)
		for marker: CanvasItem in [gull.rival_badge, gull.rival_label, gull.carry_marker]:
			if is_instance_valid(marker):
				marker.hide()
	for portion: BeachTarget in game.stalls.portions:
		if portion is StallPortion:
			RenderingServer.canvas_item_clear(portion.get_canvas_item())

func _run() -> void:
	match way:
		"ground": _ground()
		"snatch": _snatch()
		"counter": _counter()
		"mug": _mug()
	await get_tree().process_frame
	await get_tree().process_frame
	_strip_marks()
	await RenderingServer.frame_post_draw
	var screen: Image = get_viewport().get_texture().get_image()
	screen.convert(Image.FORMAT_RGBA8)
	if OS.get_cmdline_user_args().has("--full"):
		screen.save_png(ProjectSettings.globalize_path("res://test-output/score-ways/full-" + way + ".png"))
	var corner := Vector2i(roundi((center.x - game.camera.position.x + 160.0) * SCALE) - STILL_SIZE.x / 2, roundi(center.y * SCALE) - STILL_SIZE.y / 2)
	corner = corner.clamp(Vector2i.ZERO, screen.get_size() - STILL_SIZE)
	var still: Image = screen.get_region(Rect2i(corner, STILL_SIZE))
	var path: String = ProjectSettings.globalize_path(OUTPUT_DIR + way + ".png")
	var error: Error = still.save_png(path)
	print("SCORE WAY ", way, " ok=", ok, " save=", error, " -> ", path)
	get_tree().quit(0 if ok and error == OK else 1)

## Puts the gull into the dive pose heading along `direction`, its beak GAP px short of `goal`, then lets one frame settle the sprite.
func _dive_to(goal: Vector2, direction: Vector2, gap: float = GAP) -> void:
	var player: BeachGull = game.player
	# Let the backdrop and camera settle on this spot first (the gull only glides: no contact yet).
	game.camera_x = clampf(goal.x + 12.0, 160.0, float(Config.tuning.world.width) - 160.0)
	player.state = BeachGull.State.GLIDE
	player.velocity = Vector2.ZERO
	_step(4)
	player.control_mode = "realistic"
	player.state = BeachGull.State.STRIKE
	player.direction = direction.normalized()
	player.facing = 1.0 if direction.x >= 0.0 else -1.0
	player.dive_speed = 40.0
	player.velocity = player.direction * player.dive_speed
	player.position += goal - player.direction * gap - player.beak()
	player.position += goal - player.direction * gap - player.beak()
	player.tick(0.001, 0, 0.0)
	_suppress()

func _ground() -> void:
	_prepare(_level(1))
	game.screech_lesson = false
	_clear_except([])
	var crumb: Dictionary = game.scraps.crumbs[0]
	for candidate: Dictionary in game.scraps.crumbs:
		if float(candidate.x) > 340.0 and float(candidate.x) < 500.0:
			crumb = candidate
			break
	var player: BeachGull = game.player
	player.state = BeachGull.State.GROUNDED
	player.position = Vector2(float(crumb.x) - 14.0, player.ground_y())
	_step(1)
	var keep: Array = [{"x": float(crumb.x), "wait": 0.0, "food_id": "crumbs"}] # fresh: the settle steps may already have eaten it
	player.show_ground_peck(5.0)
	player.position.x += float(crumb.x) - player.beak().x - 6.0
	player.tick(0.001, 0, 0.0) # the pose only: a game step here would eat the crumb
	_suppress()
	game.scraps.crumbs.clear()
	game.scraps.crumbs.append_array(keep)
	_clear_scenery()
	game.scraps.crumbs.append_array(keep)
	game.camera_x = clampf(player.position.x, 160.0, float(Config.tuning.world.width) - 160.0)
	game.camera.position.x = game.camera_x
	center = Vector2(player.position.x + 8.0, 153.0)
	ok = game.scraps.crumbs.size() == 1

func _snatch() -> void:
	_prepare(_level(2))
	for target: BeachTarget in game.spawner.targets:
		if target.kind == "kiosk_customer" and focus == null:
			focus = target
	_clear_except([focus])
	game.pilots.clear()
	focus.position.x = 330.0 # open sand between the parasol and the bin
	focus.food_id = "ice_cream"
	focus.food = true
	focus.leaving = false
	focus.patrol_radius = 0.0
	focus.alert = 0.0
	focus.defense = 0.0
	focus.refresh_art()
	_step(2)
	var food: Vector2 = focus.food_position()
	var side: float = -1.0 if food.x < focus.position.x else 1.0 ## he holds it out to one side: the gull comes in from that side
	game.player.position = food + Vector2(side * 34.0, -9.0)
	_dive_to(food, Vector2(-side * 34.0, 7.0))
	_clear_scenery()
	center = Vector2(food.x + side * 10.0, food.y - 1.0)
	ok = game.player.state == BeachGull.State.STRIKE

func _counter() -> void:
	_prepare(_level(2))
	game.pilots.clear()
	var serving: StallPortion
	for tick: int in SETTLE_LIMIT:
		game._physics_process(1.0 / 60.0)
		for portion: BeachTarget in game.stalls.portions:
			if portion is StallPortion and portion.food and is_instance_valid(portion.recipient):
				serving = portion
		if serving != null:
			break
	assert(serving != null, "no serving reached a counter")
	_clear_except([serving, serving.recipient])
	serving.recipient.position.x += 260.0 # the buyer waits out of frame; the serving stays on the counter
	serving.recipient.patrol_radius = 0.0
	var food: Vector2 = serving.food_position()
	game.player.position = food + Vector2(34.0, -14.0)
	_dive_to(food, Vector2(-34.0, 12.0))
	_clear_scenery(500.0)
	center = Vector2(food.x + 7.0, food.y + 3.0) # top edge just under the stall's sign
	ok = serving.food and game.player.state == BeachGull.State.STRIKE

func _mug() -> void:
	GameState.progress = {"1": {"training_step": BeachGame.MUG_LESSON}}
	_prepare(_level(0))
	game.lesson = BeachGame.TRAINING_LESSONS
	_clear_except([])
	var dummy: RivalPilot = game.training_dummy()
	dummy.dummy_hold = Vector2(300.0, 80.0)
	dummy.gull.position = dummy.dummy_hold
	_step(2)
	var player: BeachGull = game.player
	var goal: Vector2 = dummy.gull.beak()
	player.position = goal + Vector2(34.0, -14.0)
	_dive_to(goal, Vector2(-34.0, 12.0), 16.0)
	_clear_scenery()
	center = Vector2(goal.x + 6.0, goal.y - 4.0)
	ok = not dummy.dummy_food.is_empty()
