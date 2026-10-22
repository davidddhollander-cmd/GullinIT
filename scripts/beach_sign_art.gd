extends RefCounted
## Generated wood only; labels remain crisp native pixel text.
const RIGHT = preload("res://assets/sprites/beach-sign-arrow-v4.png")
const LEFT = preload("res://assets/sprites/beach-sign-arrow-left-v4.png")
const POST = preload("res://assets/sprites/beach-sign-post-v1.png")
const FONT = preload("res://assets/fonts/gull_hud.fnt")
const FONT_SIZE: int = 5
const BOARD_HEIGHT: int = 8
const ROW_STEP: int = 9
const LETTERING: Color = Color("817668")

static func draw_sign(canvas: Node2D, sign: Dictionary) -> void:
	var board: Rect2 = sign.rect
	canvas.draw_texture_rect(POST,Rect2(roundf(board.get_center().x)-1,board.position.y,3,134-board.position.y),false)
	for index: int in sign.arrows.size():
		var arrow: Dictionary = sign.arrows[index]
		var row := Rect2(board.position+Vector2(0,index*ROW_STEP),Vector2(board.size.x,BOARD_HEIGHT))
		canvas.draw_texture_rect(RIGHT if arrow.right else LEFT,row,false)
		var text_width: float = FONT.get_string_size(arrow.label,HORIZONTAL_ALIGNMENT_LEFT,-1,FONT_SIZE).x
		var center: float = row.get_center().x+(-1 if arrow.right else 1)
		canvas.draw_string(FONT,Vector2(roundf(center-text_width*0.5),row.position.y+7),arrow.label,HORIZONTAL_ALIGNMENT_LEFT,-1,FONT_SIZE,LETTERING)
