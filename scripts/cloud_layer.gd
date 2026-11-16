class_name CloudLayer
extends Node2D
## Separate drifting clouds over the generated sky. Layouts live in data/levels/*.json ("clouds"), tuning in data/tuning.json ("clouds").
## Pinned to the screen by its parent. Drift follows the beach clock so pause and step freeze it.
const SHEET_DIR: String = "res://assets/sprites/background-v2/"
const SCREEN_W: float = 320.0

var clouds: Array[Dictionary] = [] ## {sprite, x, y, width, depth}
var tuning: Dictionary = {}
var last_time: float = -1.0

func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

## layout: [{id, x, y, scale}]. dusk recolours the clouds against the sunset sky bands.
func setup(layout: Array, dusk: bool) -> void:
	for cloud: Dictionary in clouds:
		(cloud.sprite as Sprite2D).free()
	clouds.clear()
	last_time = -1.0
	tuning = Config.tuning.clouds
	# Cloud ids are unique across sheets (pearl bubbly set, plate cut-outs), so layouts can mix them.
	var regions: Dictionary = {}
	for sheet_name: String in tuning.sheets:
		var texture: Texture2D = load(SHEET_DIR + sheet_name + ".png")
		for entry: Dictionary in Config.read_json(SHEET_DIR + sheet_name + ".json").clouds:
			regions[entry.id] = {"entry": entry, "texture": texture}
	var tint: ShaderMaterial = null
	if dusk:
		tint = ShaderMaterial.new()
		tint.shader = preload("res://assets/shaders/cloud_dusk.gdshader")
	for placed: Dictionary in layout:
		var source: Dictionary = regions[placed.id].entry
		var r: Array = source.region
		var scale_factor: float = float(placed.scale)
		var sprite: Sprite2D = Sprite2D.new()
		sprite.texture = regions[placed.id].texture
		sprite.region_enabled = true
		sprite.region_rect = Rect2(r[0], r[1], r[2], r[3])
		sprite.centered = false
		sprite.scale = Vector2.ONE * scale_factor
		sprite.material = tint
		add_child(sprite)
		var width: float = float(r[2]) * scale_factor
		# Bigger clouds read as nearer, so they drift faster.
		var depth: float = float(placed.get("depth", tuning.depth_by_size.get(str(source.size), 1.0))) # clusters set one depth so they drift together
		clouds.append({"sprite": sprite, "x": float(placed.x), "y": float(placed.y), "width": width, "depth": depth})
	_place()

## Calm (no wind) means no drift: speed scales with the wind strength alone.
func update(time: float, wind_dir: int, wind_strength: float) -> void:
	var delta: float = 0.0 if last_time < 0.0 else maxf(time - last_time, 0.0)
	last_time = time
	var heading: float = float(signi(wind_dir))
	var speed: float = wind_strength * float(tuning.wind_speed)
	for cloud: Dictionary in clouds:
		var x: float = cloud.x + heading * speed * cloud.depth * delta
		var span: float = SCREEN_W + cloud.width
		# Leaves one edge, re-enters from the other: x stays within [-width, SCREEN_W].
		cloud.x = fposmod(x + cloud.width, span) - cloud.width
	_place()

func _place() -> void:
	for cloud: Dictionary in clouds:
		(cloud.sprite as Sprite2D).position = Vector2(cloud.x, cloud.y) # fractional on purpose: the game renders at window resolution, so slow drift moves in sub-pixel steps
