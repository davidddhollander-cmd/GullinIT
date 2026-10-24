extends Node2D
## Approved ChatGPT roof-sign artwork; source cut-outs and lettering stay intact.
const HOT_DOGS = preload("res://assets/sprites/stand-sign-hot-dogs-runtime-v2.png")
const ICE_CREAM = preload("res://assets/sprites/stand-sign-ice-cream-runtime-v2.png")
const FISH_CHIPS = preload("res://assets/sprites/stand-sign-fish-chips-runtime-v1.png")
const WIDTH: float = 64.0
const BOTTOM: float = -30.0
var stall_type: String = "kiosk"

func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

static func texture_for(type: String) -> Texture2D:
	return {"hotdog_stand":HOT_DOGS,"fish_chips_stand":FISH_CHIPS}.get(type,ICE_CREAM)

static func local_bounds(type: String) -> Rect2:
	var texture: Texture2D = texture_for(type)
	var height: float = texture.get_height()*WIDTH/texture.get_width()
	return Rect2(-WIDTH*0.5,BOTTOM-height,WIDTH,height)

func _draw() -> void:
	draw_texture_rect(texture_for(stall_type),local_bounds(stall_type),false)
