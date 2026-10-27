extends Node
## Art Lab: current art next to proposed art on the real beach backdrop, moving the way it does in play.
## Dev-only (excluded from exports). Candidates live in data/art_lab.json and are registered in memory only;
## nothing here edits data/sprites.json or project settings.
const GROUND: float = 160.0
const MOTIONS: Array[String] = ["fly_across", "dive", "walk_across", "idle", "on_sand", "in_beak", "static"]
const LANE_HALF_GAP: Dictionary = {1: 80.0, 4: 22.0} ## pair spacing by zoom, so both sides fit on screen
const TRAVEL_MIN: float = 240.0
const TRAVEL_MAX: float = 1040.0
const REST_X: float = 640.0
const HOVER_Y: float = 52.0
const DIVE_EVERY: float = 2.4
const STEP: float = 1.0 / 60.0
const CAPTURE_DIR: String = "res://test-output/art_lab"
const FONT: Font = preload("res://assets/fonts/gull_pixel.fnt")
const GOLD: Color = Color("ffd76a")

var comparisons: Array = []
var candidate_ids: Array[String] = []
var index: int = 0
var motion: String = "static" ## effective motion of the selected comparison
var zoom: int = 1
var blind: bool = false
var swapped: bool = false
var smooth: bool = false
var integer_scale: bool = false
var paused: bool = false
var step_once: bool = false
var pair_x: float = REST_X
var dir: float = 1.0
var dive_timer: float = 0.0
var ground_timer: float = 0.0
var sides: Array[Dictionary] = [] ## [current, proposed]: {node, gull, item}
var backdrop: BeachBackdrop
var camera: Camera2D
var stage: Node2D
var title_label: Label
var desc_label: Label
var flags_label: Label
var side_labels: Array[Label] = []
var capturing: bool = false

func _ready() -> void:
	var data: Dictionary = Config.read_json("res://data/art_lab.json")
	comparisons = data.get("comparisons", [])
	if comparisons.is_empty():
		push_error("Art Lab: data/art_lab.json has no comparisons. %s" % Config.last_error)
		return
	for i: int in comparisons.size():
		candidate_ids.append(_register(i, comparisons[i]))
	backdrop = BeachBackdrop.new()
	add_child(backdrop)
	backdrop.setup([])
	stage = Node2D.new()
	stage.y_sort_enabled = true
	add_child(stage)
	camera = Camera2D.new()
	add_child(camera)
	_build_hud()
	_select(0)
	if OS.get_cmdline_user_args().has("--capture"):
		_capture_run()

## A candidate is an sprites.json-shaped entry; `clone` copies a live entry first so a self-test stays short.
func _register(i: int, entry: Dictionary) -> String:
	var candidate: Dictionary = (entry.candidate as Dictionary).duplicate(true)
	var def: Dictionary = {}
	if candidate.has("clone"):
		def = (Config.sprites[str(candidate.clone)] as Dictionary).duplicate(true)
	candidate.erase("clone")
	def.merge(candidate, true)
	var id: String = ("gull_lab_%d" if _is_gull(str(entry.current)) else "lab_%d") % i
	Config.sprites[id] = def
	Config.frames_cache.erase(id)
	return id

static func _is_gull(id: String) -> bool:
	var def: Dictionary = Config.sprites.get(id, {})
	return def.has("species") and id == "gull_" + str(def.species).replace("-", "_")

func _build_hud() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	var top: ColorRect = ColorRect.new()
	top.color = Color(0.05, 0.1, 0.14, 0.7)
	top.size = Vector2(320, 20)
	layer.add_child(top)
	var bottom: ColorRect = ColorRect.new()
	bottom.color = top.color
	bottom.position = Vector2(0, 160)
	bottom.size = Vector2(320, 20)
	layer.add_child(bottom)
	title_label = _label(layer, Vector2(2, 1), 316, HORIZONTAL_ALIGNMENT_LEFT)
	flags_label = _label(layer, Vector2(0, 1), 318, HORIZONTAL_ALIGNMENT_RIGHT)
	desc_label = _label(layer, Vector2(2, 11), 316, HORIZONTAL_ALIGNMENT_LEFT)
	for x: float in [0.0, 160.0]:
		side_labels.append(_label(layer, Vector2(x, 22), 160, HORIZONTAL_ALIGNMENT_CENTER))
	_label(layer, Vector2(2, 161), 316, HORIZONTAL_ALIGNMENT_LEFT).text = "1-9/ARROWS PICK  Z ZOOM  B BLIND  F FILTER"
	_label(layer, Vector2(2, 170), 316, HORIZONTAL_ALIGNMENT_LEFT).text = "I INT-SCALE  P PAUSE  . STEP  C CAPTURE  ESC QUIT"

func _label(parent: Node, at: Vector2, width: float, align: HorizontalAlignment) -> Label:
	var label: Label = Label.new()
	label.position = at
	label.size = Vector2(width, 9)
	label.horizontal_alignment = align
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color("fff4da"))
	label.add_theme_color_override("font_shadow_color", Color("183b4e"))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _select(i: int) -> void:
	index = posmod(i, comparisons.size())
	for child: Node in stage.get_children():
		child.free()
	var entry: Dictionary = comparisons[index]
	motion = str(entry.get("motion", "static"))
	var gulls: bool = _is_gull(str(entry.current)) or motion == "in_beak"
	if not MOTIONS.has(motion) or (motion in ["fly_across", "dive"] and not gulls):
		push_error("Art Lab: motion '%s' needs a gull sprite (comparison %d); showing it static" % [motion, index])
		motion = "static"
	var species: Array[String] = ["herring", "herring"] # in_beak: the gull is always the herring, only the food changes
	if motion != "in_beak":
		species = [str(Config.sprites[str(entry.current)].get("species", "")), "lab_%d" % index]
	sides = [_make(str(entry.current), species[0], gulls, motion), _make(candidate_ids[index], species[1], gulls, motion)]
	var flies: bool = motion in ["fly_across", "dive", "in_beak"]
	pair_x = TRAVEL_MIN + 40.0 if flies else REST_X
	dir = 1.0
	dive_timer = 0.0
	ground_timer = 0.0
	_place_gulls()
	_apply_filter()
	_place()
	camera.position = Vector2(clampf(pair_x, 160.0, float(Config.tuning.world.width) - 160.0), 90.0)
	camera.zoom = Vector2.ONE * zoom
	_refresh_hud()

## Builds one side. Gull art is played by the real BeachGull; everything else by a plain AnimatedSprite2D.
func _make(id: String, species: String, gull_path: bool, motion: String) -> Dictionary:
	var side: Dictionary = {"gull": null, "node": null, "item": null}
	if gull_path:
		var gull: BeachGull = BeachGull.new()
		gull.species = species
		gull.position = Vector2(pair_x, HOVER_Y)
		side.gull = gull
		side.node = gull
		stage.add_child(gull)
	if motion == "in_beak" or not gull_path:
		var def: Dictionary = Config.sprites[id]
		var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
		sprite.sprite_frames = Config.frames(id)
		sprite.scale = Vector2.ONE * float(def.get("visual_scale", 1.0))
		var names: PackedStringArray = sprite.sprite_frames.get_animation_names()
		var wanted: String = "walk" if motion == "walk_across" else "idle"
		if motion == "static" or not sprite.sprite_frames.has_animation(wanted):
			sprite.animation = names[0]
			sprite.stop()
		else:
			sprite.play(wanted)
		sprite.set_meta(&"half_height", float(def.frame_h) * sprite.scale.y * 0.5)
		stage.add_child(sprite)
		if motion == "in_beak":
			sprite.z_index = 1
			side.item = sprite
		else:
			side.node = sprite
	return side

func _place_gulls() -> void:
	for side: Dictionary in sides:
		if side.gull != null:
			(side.gull as BeachGull).aim = (side.gull as BeachGull).position

func _lane(i: int) -> float:
	var left_slot: bool = (i == 0) != swapped
	return (-1.0 if left_slot else 1.0) * float(LANE_HALF_GAP[zoom])

func _advance(d: float) -> void:
	backdrop.tick(d)
	match motion:
		"fly_across", "dive", "in_beak":
			_fly(d, motion == "dive")
		"walk_across":
			pair_x += dir * 22.0 * d
			if (dir > 0.0 and pair_x > TRAVEL_MAX) or (dir < 0.0 and pair_x < TRAVEL_MIN):
				dir = -dir
			for side: Dictionary in sides:
				if side.node is AnimatedSprite2D:
					(side.node as AnimatedSprite2D).flip_h = dir < 0.0
	_place()

## Both sides get the same commands, so identical art stays frame-for-frame identical.
func _fly(d: float, diving: bool) -> void:
	var lead: BeachGull = sides[0].gull
	if (dir > 0.0 and pair_x > TRAVEL_MAX) or (dir < 0.0 and pair_x < TRAVEL_MIN):
		dir = -dir
	dive_timer += d
	var climb: bool = lead.position.y > HOVER_Y
	var aim_y: float = HOVER_Y
	var start_dive: bool = false
	match lead.state:
		BeachGull.State.GROUNDED:
			ground_timer += d
			climb = ground_timer > 0.7
		BeachGull.State.WINDUP, BeachGull.State.STRIKE:
			aim_y = GROUND - 4.0
			climb = lead.position.y > GROUND - 36.0
		_:
			ground_timer = 0.0
			start_dive = diving and dive_timer > DIVE_EVERY and lead.cooldown <= 0.0 and lead.position.y < HOVER_Y + 10.0
	for i: int in 2:
		var gull: BeachGull = sides[i].gull
		gull.position.x = pair_x + _lane(i)
		gull.climb = climb
		gull.aim = Vector2(gull.position.x + dir * (50.0 if aim_y > HOVER_Y or start_dive else 100.0), GROUND - 4.0 if start_dive else aim_y)
		if start_dive:
			gull.dive(0)
		gull.tick(d, 0, 0.0)
	if start_dive:
		dive_timer = 0.0
	pair_x = (sides[0].gull as BeachGull).position.x - _lane(0)

func _place() -> void:
	for i: int in 2:
		var side: Dictionary = sides[i]
		var x: float = pair_x + _lane(i)
		if side.gull == null:
			var node: AnimatedSprite2D = side.node
			node.position = Vector2(x, GROUND - float(node.get_meta(&"half_height", 8.0)))
		else:
			(side.gull as BeachGull).position.x = x
			if side.item != null:
				var item: AnimatedSprite2D = side.item
				item.position = (side.gull as BeachGull).beak() + Vector2(0.0, float(item.get_meta(&"half_height", 4.0)) * 0.4)
	var follow_y: float = 90.0
	if zoom > 1:
		var sum: float = 0.0
		for side: Dictionary in sides:
			sum += (side.node as Node2D).position.y
		follow_y = clampf(sum / 2.0, 90.0 / zoom, 180.0 - 90.0 / zoom)
	camera.position.x = clampf(pair_x, 160.0, float(Config.tuning.world.width) - 160.0)
	camera.position.y = lerpf(camera.position.y, follow_y, 0.15) if zoom > 1 else 90.0
	backdrop.camera_x = camera.position.x

func _process(_delta: float) -> void:
	if comparisons.is_empty():
		return
	if not paused or step_once:
		step_once = false
		_advance(STEP)
	_refresh_hud()

func _refresh_hud() -> void:
	var entry: Dictionary = comparisons[index]
	title_label.text = "%d/%d %s" % [index + 1, comparisons.size(), str(entry.title).to_upper()]
	desc_label.text = str(entry.get("description", "")).to_upper()
	var flags: PackedStringArray = ["%dX" % zoom, "SMOOTH" if smooth else "SHARP", "INT" if integer_scale else "FRAC"]
	if blind:
		flags.append("BLIND")
	if paused:
		flags.append("PAUSED")
	flags_label.text = " ".join(flags)
	flags_label.add_theme_color_override("font_color", GOLD if blind else Color("fff4da"))
	var names: Array[String] = ["CURRENT", "PROPOSED"]
	for slot: int in 2:
		# Slot 0 is the left half; unswapped it holds the current art.
		side_labels[slot].text = "" if blind else names[slot if not swapped else 1 - slot]

func _apply_filter() -> void:
	var mode: CanvasItem.TextureFilter = CanvasItem.TEXTURE_FILTER_LINEAR if smooth else CanvasItem.TEXTURE_FILTER_NEAREST
	for side: Dictionary in sides:
		for node: Variant in [side.node, side.item]:
			if node != null:
				_filter_tree(node, mode)

func _filter_tree(node: Node, mode: CanvasItem.TextureFilter) -> void:
	if node is CanvasItem:
		(node as CanvasItem).texture_filter = mode
	for child: Node in node.get_children():
		_filter_tree(child, mode)

func _unhandled_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo or capturing:
		return
	if key.keycode >= KEY_1 and key.keycode <= KEY_9:
		if key.keycode - KEY_1 < comparisons.size():
			_select(key.keycode - KEY_1)
		return
	match key.keycode:
		KEY_RIGHT, KEY_DOWN:
			_select(index + 1)
		KEY_LEFT, KEY_UP:
			_select(index - 1)
		KEY_Z:
			zoom = 4 if zoom == 1 else 1
			camera.zoom = Vector2.ONE * zoom
		KEY_B:
			blind = not blind
			if blind:
				swapped = randi() % 2 == 0 # revealing keeps the shuffled sides, now labelled
		KEY_F:
			smooth = not smooth
			_apply_filter()
		KEY_I:
			integer_scale = not integer_scale
			get_window().content_scale_stretch = Window.CONTENT_SCALE_STRETCH_INTEGER if integer_scale else Window.CONTENT_SCALE_STRETCH_FRACTIONAL
		KEY_P:
			paused = not paused
		KEY_PERIOD:
			paused = true
			step_once = true
		KEY_C:
			capture_all()
		KEY_ESCAPE:
			get_tree().quit()
	_refresh_hud()

## Saves the current screen at 1x and 4x to test-output/art_lab/<title>_<zoom>x<tag>.png.
func capture_all(tag: String = "") -> void:
	if capturing or DisplayServer.get_name() == "headless":
		return
	capturing = true
	var original: int = zoom
	var name: String = str(comparisons[index].title).to_lower().replace(" ", "-")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_DIR))
	for z: int in [1, 4]:
		zoom = z
		camera.zoom = Vector2.ONE * z
		if z > 1:
			camera.position.y = clampf((sides[0].node as Node2D).position.y, 90.0 / z, 180.0 - 90.0 / z)
		_place()
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var path: String = "%s/%s_%dx%s.png" % [ProjectSettings.globalize_path(CAPTURE_DIR), name, z, tag]
		get_viewport().get_texture().get_image().save_png(path)
		print("Art Lab capture: ", path)
	zoom = original
	camera.zoom = Vector2.ONE * zoom
	capturing = false

## `godot scenes/art_lab.tscn -- --capture`: saves a few moments of the first comparison, then exits.
func _capture_run() -> void:
	for tag: String in ["_a", "_b", "_c"]:
		await get_tree().create_timer(1.1).timeout
		await capture_all(tag)
	get_tree().quit()
