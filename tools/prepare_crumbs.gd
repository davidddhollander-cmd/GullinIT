extends SceneTree
## Preserve complete generated sources; crop and sample onto the game pixel grid.
func _initialize() -> void:
	var atlas := Image.create(15,3,false,Image.FORMAT_RGBA8)
	var names: Array[String] = ["cluster","scatter","biscuit"]
	for index: int in names.size():
		var source := Image.load_from_file("res://assets/reference/crumbs-v2/%s-source.png" % names[index])
		for y: int in source.get_height():
			for x: int in source.get_width():
				var pixel: Color = source.get_pixel(x,y)
				pixel.a = 1.0 if pixel.a>=0.75 else 0.0
				source.set_pixel(x,y,pixel)
		var sprite: Image = source.get_region(source.get_used_rect())
		sprite.resize(5,3,Image.INTERPOLATE_NEAREST)
		atlas.blit_rect(sprite,Rect2i(0,0,5,3),Vector2i(index*5,0))
	assert(atlas.save_png("res://assets/sprites/food-crumbs-retro-v2.png")==OK)
	for y: int in 3:
		var row: String = ""
		for x: int in 15:
			row += "#" if atlas.get_pixel(x,y).a>0 else "."
		print(row)
	quit()
