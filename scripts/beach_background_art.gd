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
## Darkens the sea toward blue under the peach dusk sky.
const SEA_DUSK: Color = Color(0.72, 0.62, 0.78)

var sky: Sprite2D
var sun: Sprite2D
var sea: AnimatedSprite2D
var birds: BackgroundBirds
var top_color: Color = SKY_COLOR

func _init(sunset: bool) -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	show_behind_parent = true
	sky = _sprite("sky-clouds-320x80.png", Vector2(0, SKY_Y))
	sun = _sprite("sun-34x34.png", Vector2(233, 26))
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
		sun.material = dusk
		top_color = Color8(236, 169, 132) # SKY_COLOR through the dusk tint
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
	birds.update(time)

func _draw() -> void:
	# The sky plate is 80 px tall; flat sky fills the strip above it.
	draw_rect(Rect2(0, 0, 320, SKY_Y), top_color)
