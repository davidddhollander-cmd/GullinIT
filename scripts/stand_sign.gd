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
	# Roof emblems already live in the supplied booth shell. Repeating them
	# below this raised sign would cover the vendor's face and serving opening.
