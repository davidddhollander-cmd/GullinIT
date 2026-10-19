extends Control

func _draw() -> void:
	draw_rect(Rect2(0,0,320,180),Color("20364d"))
	var font: Font = preload("res://assets/fonts/gull_pixel.fnt")
	draw_string(font,Vector2(8,12),"TODDLER / DINER STYLE / 22 PX",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("fff4da"))
	var groups: Array[StringName] = [&"eat",&"walk",&"cry",&"cry_run"]
	var frames: SpriteFrames = Config.frames("toddler")
	for column: int in 4:
		var animation: StringName = groups[column]
		draw_string(font,Vector2(8+column*80,27),str(animation).to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("ffc65c"))
		for row: int in 3:
			var frame: int = mini(row,frames.get_frame_count(animation)-1)
			var texture: Texture2D = frames.get_frame_texture(animation,frame)
			var size: Vector2 = Vector2(44,44)
			draw_texture_rect(texture,Rect2(Vector2(16+column*80,32+row*47),size),false)
