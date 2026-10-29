class_name BeachBackgroundArt
extends Node2D
## Generated sky, sun and sea (assets/sprites/background-v2), pinned to the screen's left edge.
## BeachBackdrop owns the position and clock; sand, signs and props draw in front.

const ART: String = "res://assets/sprites/background-v2/"
const HORIZON_Y: float = 94.0
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
var top_color: Color = SKY_COLOR

func _init(sunset: bool) -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	show_behind_parent = true
	sky = _sprite("sky-clouds-320x80.png", Vector2(0, SKY_Y))
	sun = _sprite("sun-34x34.png", SUN_DAY_POS)
	var frames := SpriteFrames.new()
	for index: int in SEA_FRAMES:
		frames.add_frame(&"default", load(ART + "sea-frame-%02d.png" % (index + 1)))
	sea = AnimatedSprite2D.new()
	sea.sprite_frames = frames
	sea.centered = false
	sea.position = Vector2(0, HORIZON_Y)
	add_child(sea)
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

func _sprite(file: String, at: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(ART + file)
	sprite.centered = false
	sprite.position = at
	add_child(sprite)
	return sprite

## Follows the beach clock so the sea freezes with pause and results.
func update(camera_x: float, time: float) -> void:
	position.x = roundf(camera_x) - 160.0
	sea.frame = int(time / SEA_FRAME_TIME) % SEA_FRAMES

func _draw() -> void:
	# The sky plate is 80 px tall; flat sky fills the strip above it.
	draw_rect(Rect2(0, 0, 320, SKY_Y), top_color)

func _draw_glint(canvas: Node2D) -> void:
	var centre: float = SUN_DUSK_POS.x + sun.texture.get_width() / 2.0
	for dash: Vector3i in GLINT:
		canvas.draw_rect(Rect2(centre + dash.y - dash.z / 2.0, HORIZON_Y + dash.x, dash.z, 1), GLINT_COLOR)
