class_name SunbatherTowel
extends Node2D
## A separate ground layer, shared by gameplay and the title beach.
var blue: bool = false
var female: bool = false

func _draw() -> void:
	paint(self,Vector2.ZERO,blue,female)

static func paint(canvas: CanvasItem, at: Vector2, blue_variant: bool, female_variant: bool) -> void:
	var color := Color("f3c443") if blue_variant else (Color("ef725c") if female_variant else Color("408fa8"))
	canvas.draw_rect(Rect2(at+Vector2(-32,-3),Vector2(64,5)),Color("183b4e"))
	canvas.draw_rect(Rect2(at+Vector2(-31,-3),Vector2(62,4)),color)
	for stripe: int in 8:
		canvas.draw_rect(Rect2(at+Vector2(-29+stripe*8,-3),Vector2(3,4)),Color("fff4da"))
	for end: int in [-1,1]:
		for thread: int in 3:
			canvas.draw_rect(Rect2(at+Vector2(end*32-1,-3+thread*2),Vector2(3,1)),Color("fff4da"))
