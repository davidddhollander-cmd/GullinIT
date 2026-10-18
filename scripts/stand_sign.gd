extends Node2D
## Signs and striped awnings over the supplied wooden kiosk artwork.
var hotdog: bool = false
var font: Font = preload("res://assets/fonts/gull_pixel.fnt")

func _draw() -> void:
	var tint: Color = Color("dc5c43") if hotdog else Color("4bafc5")
	draw_rect(Rect2(-25,-43,50,13),Color("fff4da"))
	for i: int in range(10):
		if i % 2 == 0:
			draw_rect(Rect2(-25+i*5,-33,5,5),tint)
	var label: String = "HOT DOGS" if hotdog else "ICE CREAM"
	draw_string(font,Vector2(-23,-35),label,HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("183b4e"))
	# The small rooftop emblem is drawn on the same native pixel grid as the stand.
	if hotdog:
		draw_rect(Rect2(-8,-23,16,3),Color("183b4e"))
		draw_rect(Rect2(-7,-22,14,2),Color("d59a5e"))
		draw_rect(Rect2(-5,-25,10,3),Color("ef725c"))
		draw_rect(Rect2(-3,-25,6,1),Color("ffc65c"))
	else:
		draw_rect(Rect2(-3,-18,6,8),Color("183b4e"))
		draw_rect(Rect2(-2,-17,4,6),Color("d59a5e"))
		draw_rect(Rect2(-6,-23,12,7),Color("183b4e"))
		draw_rect(Rect2(-5,-22,10,5),Color("fff4da"))
		draw_rect(Rect2(0,-22,4,5),Color("ef725c"))
