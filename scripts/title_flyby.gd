class_name TitleFlyby
extends Node2D
## Title backdrop life: a player gull glides across; now and then a rival swoops at a sunbather.
const SWOOP_TIME: float = 3.2
var player: AnimatedSprite2D
var rival: AnimatedSprite2D
var clock: float = 0.0
var next_swoop: float = 6.0
var swoop: float = -1.0
var swoop_x: float = 270.0

func _ready() -> void:
	player = _gull("player_gull")
	rival = _gull("rival_gull")
	rival.visible = false

func _gull(id: String) -> AnimatedSprite2D:
	var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
	sprite.sprite_frames = Config.frames(id)
	sprite.scale = Vector2.ONE * float(Config.sprites[id].get("visual_scale",1.0))
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.play(&"glide")
	add_child(sprite)
	return sprite

func _process(delta: float) -> void:
	clock += delta
	player.position = Vector2(fposmod(clock * 22.0,380.0) - 30.0, 42.0 + sin(clock * 1.6) * 5.0)
	if swoop >= 0.0:
		swoop += delta / SWOOP_TIME
		if swoop >= 1.0:
			swoop = -1.0
			rival.visible = false
			next_swoop = clock + randf_range(8.0,12.0)
		else:
			rival.position = Vector2(swoop_x + 100.0 - 200.0 * swoop, 40.0 + 80.0 * sin(PI * swoop))
			rival.flip_h = true
	elif clock >= next_swoop:
		swoop = 0.0
		swoop_x = [255.0,285.0].pick_random()
		rival.visible = true
