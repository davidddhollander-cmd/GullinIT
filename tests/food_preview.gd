extends Control
## Render the actual atlas regions in-engine, including their gameplay sizes.
func _draw() -> void:
	draw_rect(Rect2(0,0,320,180),Color("20364d"))
	var font: Font = ThemeDB.fallback_font
	draw_string(font,Vector2(8,13),"SEASIDE BITES",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("fff1ca"))
	draw_string(font,Vector2(8,25),"Large preview / actual game size",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("bfd5db"))
	var index: int = 0
	for id: String in Config.foods:
		var definition: Dictionary = Config.foods[id]
		var origin: Vector2 = Vector2(8+(index%4)*79,33+(index/4)*48)
		var texture: Texture2D = Config.frames(definition.sprite).get_frame_texture(&"idle",0)
		var size: Vector2 = Vector2(definition.size[0],definition.size[1])
		var enlarged: Vector2 = size*minf(28/size.x,24/size.y)
		draw_texture_rect(texture,Rect2(origin+Vector2(18,12)-enlarged/2,enlarged),false)
		draw_texture_rect(texture,Rect2(origin+Vector2(57,14)-size/2,size),false)
		draw_string(font,origin+Vector2(0,30),str(definition.name).replace("Half-eaten", "1/2"),HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color.WHITE)
		draw_string(font,origin+Vector2(0,42),"%s / %d" % [definition.category,definition.points],HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("ffc65c"))
		index += 1
