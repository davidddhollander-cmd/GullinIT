extends SceneTree
## Import-only crops of approved ChatGPT artwork; full source assets stay intact.
func _initialize() -> void:
	for id: String in ["hot-dogs","ice-cream"]:
		var source: Image = Image.load_from_file(ProjectSettings.globalize_path("res://assets/sprites/stand-sign-%s-v2.png" % id))
		assert(source!=null)
		source.convert(Image.FORMAT_RGBA8)
		for y: int in source.get_height():
			for x: int in source.get_width():
				var pixel: Color = source.get_pixel(x,y)
				if pixel.a<0.75:
					pixel = Color.TRANSPARENT
				else:
					pixel.a = 1.0
				source.set_pixel(x,y,pixel)
		var image: Image = source.get_region(source.get_used_rect())
		var height: int = roundi(float(image.get_height())*256.0/image.get_width())
		image.resize(256,height,Image.INTERPOLATE_NEAREST)
		assert(image.save_png("res://assets/sprites/stand-sign-%s-runtime-v2.png" % id)==OK)
		print("Prepared roof sign ",id,": 256x",height)
	quit()
