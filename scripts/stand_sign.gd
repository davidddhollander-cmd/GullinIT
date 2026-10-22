extends Node2D
## Approved ChatGPT roof-sign artwork; source cut-outs and lettering stay intact.
const HOT_DOGS = preload("res://assets/sprites/stand-sign-hot-dogs-runtime-v2.png")
const ICE_CREAM = preload("res://assets/sprites/stand-sign-ice-cream-runtime-v2.png")
const WIDTH: float = 64.0
const BOTTOM: float = -30.0
var hotdog: bool = false

func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

static func local_bounds(is_hotdog: bool) -> Rect2:
	var texture: Texture2D = HOT_DOGS if is_hotdog else ICE_CREAM
	var height: float = texture.get_height()*WIDTH/texture.get_width()
	return Rect2(-WIDTH*0.5,BOTTOM-height,WIDTH,height)

func _draw() -> void:
	draw_texture_rect(HOT_DOGS if hotdog else ICE_CREAM,local_bounds(hotdog),false)
