extends SceneTree
## Derive native sprites from intact ChatGPT-generated sources; never paint art.
func _initialize() -> void:
	for item: String in ["arrow", "post"]:
		var source := Image.new()
		if source.load("res://assets/reference/beach-signs-v1/%s-source.png" % item) != OK:
			quit(1)
			return
		# Discard faint edge alpha before calculating the crop, preserving source files.
		for y: int in source.get_height():
			for x: int in source.get_width():
				var color: Color = source.get_pixel(x,y)
				color.a = 1.0 if color.a >= 0.5 else 0.0
				source.set_pixel(x,y,color)
		var native: Image = source.get_region(source.get_used_rect())
		native.resize(80 if item=="arrow" else 4,16 if item=="arrow" else 50,Image.INTERPOLATE_NEAREST)
		var path: String = "res://assets/sprites/beach-sign-%s-v1.png" % item
		if native.save_png(path) != OK:
			quit(1)
			return
		if item=="arrow":
			native.flip_x()
			native.save_png("res://assets/archive/sprites/beach-sign-arrow-left-v1.png")
		print("Prepared ",path)
	quit()
