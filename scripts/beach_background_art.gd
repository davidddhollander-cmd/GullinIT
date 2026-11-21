class_name BeachBackgroundArt
extends Node2D
## Generated sky, sun and sea (assets/sprites/background-v2), pinned to the screen's left edge.
## BeachBackdrop owns the position and clock; sand, signs and props draw in front.

const ART: String = "res://assets/sprites/background-v2/"
const HORIZON_Y: float = 94.0
## Screen x where the horizon strip's left edge sits at the level start (camera_x 160).
const HORIZON_START_X: float = 90.0
const SKY_Y: float = HORIZON_Y - 80.0
const SKY_COLOR: Color = Color8(91, 199, 216)
const SEA_FRAME_TIME: float = 0.15
const SEA_FRAMES: int = 16
## Darkens the sea toward blue under the sunset sky.
const SEA_DUSK: Color = Color(0.66, 0.54, 0.82)
## Dusk: the top sky band (matches the first colour in dusk_tint.gdshader) and a deep-orange sun.
const SKY_DUSK_TOP: Color = Color8(88, 66, 128)
const SUN_DUSK: Color = Color(1.0, 0.5, 0.3)
## Dusk glint on the water under the sun: sparse flat dashes as [row below horizon, centre offset, width].
const GLINT_COLOR: Color = Color8(255, 196, 112)
const GLINT: Array[Vector3i] = [Vector3i(3, 0, 14), Vector3i(7, 2, 10), Vector3i(11, -2, 8), Vector3i(16, 1, 6), Vector3i(22, -1, 4)]
const SUN_DAY_POS: Vector2 = Vector2(233, 26)
## At dusk the sun sinks so its lower third is hidden by the sea.
const SUN_DUSK_POS: Vector2 = Vector2(233, 76)

var sky: Sprite2D
var sun: Sprite2D
var sea: AnimatedSprite2D
var birds: BackgroundBirds
var clouds: CloudLayer
var horizon: Sprite2D ## optional distant strip (assets/sprites/horizon-v1), null when the level has none
var top_color: Color = SKY_COLOR
static var flat_sky: Texture2D ## the plate's 320x80 strip in plain sky colour; the clouds are separate sprites

## layout: cloud placements from the level ({id, x, y, scale}); empty uses the default arrangement.
func _init(sunset: bool, layout: Array = [], horizon_id: String = "") -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	show_behind_parent = true
	sky = _sprite("sky-clouds-320x80.png", Vector2(0, SKY_Y))
	if flat_sky == null:
		var flat: Image = Image.create(320, 80, false, Image.FORMAT_RGBA8)
		flat.fill(SKY_COLOR)
		flat_sky = ImageTexture.create_from_image(flat)
	sky.texture = flat_sky
	sun = _sprite("sun-34x34.png", SUN_DAY_POS)
	clouds = CloudLayer.new() # after the sun, so clouds pass in front of it
	add_child(clouds)
	clouds.setup(layout if not layout.is_empty() else Config.tuning.clouds.default_layout, sunset)
	if horizon_id != "":
		horizon = Sprite2D.new() # bottom row on y 93, resting on the sea's top row; after the clouds, before the sea
		horizon.texture = load("res://assets/sprites/horizon-v1/%s-640x24.png" % horizon_id)
		horizon.centered = false
		horizon.region_enabled = true
		horizon.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		horizon.region_rect = Rect2(0, 0, 320, 24)
		horizon.position = Vector2(0, HORIZON_Y - 24.0)
		add_child(horizon)
	var frames := SpriteFrames.new()
	for index: int in SEA_FRAMES:
		frames.add_frame(&"default", load(ART + "sea-frame-%02d.png" % (index + 1)))
	sea = AnimatedSprite2D.new()
	sea.sprite_frames = frames
	sea.centered = false
	sea.position = Vector2(0, HORIZON_Y)
	add_child(sea)
	birds = BackgroundBirds.new(sunset)
	add_child(birds)
	if sunset:
		var dusk := ShaderMaterial.new()
		dusk.shader = preload("res://assets/shaders/dusk_tint.gdshader")
		sky.material = dusk
		sun.position = SUN_DUSK_POS
		sun.modulate = SUN_DUSK
		top_color = SKY_DUSK_TOP
		var glint := Node2D.new() # after the sea, so it draws over the water
		glint.draw.connect(_draw_glint.bind(glint))
		add_child(glint)
		sea.modulate = SEA_DUSK
		if horizon:
			horizon.modulate = SEA_DUSK

func _sprite(file: String, at: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(ART + file)
	sprite.centered = false
	sprite.position = at
	add_child(sprite)
	return sprite

## Follows the beach clock so the sea and clouds freeze with pause and results. Calm wind (the default) leaves clouds still.
func update(camera_x: float, time: float, wind_dir: int = 0, wind_strength: float = 0.0) -> void:
	position.x = roundf(camera_x) - 160.0
	if horizon: # 0.1x parallax in whole pixels, wrapping at the strip's 640 px
		horizon.region_rect.position.x = fposmod(roundf((camera_x - 160.0) * 0.1) - HORIZON_START_X, 640.0)
	sea.frame = int(time / SEA_FRAME_TIME) % SEA_FRAMES
	birds.update(time)
	clouds.update(time, wind_dir, wind_strength)

func _draw() -> void:
	# The sky strip is 80 px tall; flat sky fills the area above it.
	var extra: float = float(Config.tuning.world.sky_extra)
	draw_rect(Rect2(0, -extra, 320, SKY_Y + extra), top_color)

func _draw_glint(canvas: Node2D) -> void:
	var centre: float = SUN_DUSK_POS.x + sun.texture.get_width() / 2.0
	for dash: Vector3i in GLINT:
		canvas.draw_rect(Rect2(centre + dash.y - dash.z / 2.0, HORIZON_Y + dash.x, dash.z, 1), GLINT_COLOR)
