extends SceneTree
## Crop and downsample the intact ChatGPT-generated simplified arrow.
func _initialize() -> void:
	var source := Image.load_from_file("res://assets/reference/beach-signs-v4/arrow-source.png")
	for y: int in source.get_height():
		for x: int in source.get_width():
			var pixel: Color = source.get_pixel(x,y)
			pixel.a = 1.0 if pixel.a>=0.5 else 0.0
			source.set_pixel(x,y,pixel)
	var sprite: Image = source.get_region(source.get_used_rect())
	sprite.resize(80,20,Image.INTERPOLATE_NEAREST)
	assert(sprite.save_png("res://assets/sprites/beach-sign-arrow-v4.png")==OK)
	sprite.flip_x()
	assert(sprite.save_png("res://assets/sprites/beach-sign-arrow-left-v4.png")==OK)
	quit()
