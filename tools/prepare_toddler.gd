extends SceneTree
## Match the adults' half-scale, crisp source pixels with a 22-pixel child.
const Extractor = preload("res://tools/adult_atlas_source.gd")

func _initialize() -> void:
	var source := Image.load_from_file("res://assets/reference/toddler-diner-v1/toddler-source.png")
	source.convert(Image.FORMAT_RGBA8)
	var extractor := Extractor.new()
	var sheet := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	var rows := [0, 306, 592, 864, source.get_height()]
	for row: int in 4:
		for column: int in 4:
			var x0 := roundi(float(column) * source.get_width() / 4)
			var x1 := roundi(float(column + 1) * source.get_width() / 4)
			var part := source.get_region(Rect2i(x0, rows[row], x1-x0, rows[row+1]-rows[row]))
			for y: int in part.get_height():
				for x: int in part.get_width():
					var colour := part.get_pixel(x,y)
					colour.a = 1.0 if colour.a >= 0.75 else 0.0
					part.set_pixel(x,y,colour)
			extractor._isolate_actor(part)
			part = part.get_region(part.get_used_rect())
			var height := 38 if row == 3 else 44
			var width := roundi(float(part.get_width()) * height / part.get_height())
			part.resize(width, height, Image.INTERPOLATE_NEAREST)
			extractor._isolate_actor(part)
			sheet.blit_rect(part, Rect2i(0,0,width,height), Vector2i(column*64+(64-width)/2, row*64+60-height))
	assert(sheet.save_png("res://assets/sprites/toddler-diner-style.png") == OK)
	var preview := sheet.duplicate() as Image
	preview.resize(1024,1024,Image.INTERPOLATE_NEAREST)
	assert(preview.save_png("res://assets/previews/toddler-diner-style-sheet-v1.png") == OK)
	quit()
