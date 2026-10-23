extends SceneTree
## Finer generated crumb texture; keep the original on-screen size.
func _initialize() -> void:
	var atlas := Image.create(30,6,false,Image.FORMAT_RGBA8)
	var names: Array[String] = ["cluster","scatter","biscuit"]
	for index: int in names.size():
		var source := Image.load_from_file("res://assets/reference/crumbs-v3/%s-source.png" % names[index])
		for y: int in source.get_height():
			for x: int in source.get_width():
				var pixel: Color = source.get_pixel(x,y)
				pixel.a = 1.0 if pixel.a>=0.75 else 0.0
				source.set_pixel(x,y,pixel)
		var sprite: Image = source.get_region(source.get_used_rect())
		sprite.resize(10,6,Image.INTERPOLATE_NEAREST)
		atlas.blit_rect(sprite,Rect2i(0,0,10,6),Vector2i(index*10,0))
	assert(atlas.save_png("res://assets/sprites/food-crumbs-retro-v3.png")==OK)
	quit()
