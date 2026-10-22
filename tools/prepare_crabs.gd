extends SceneTree
## Crop and align supplied artwork only; preserve the complete original sheet.
const SOURCE := "res://assets/sprites/crabs-transparent.png"

func _initialize() -> void:
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	assert(sheet!=null)
	sheet.convert(Image.FORMAT_RGBA8)
	for row: int in 2:
		var strip: Image = sheet.get_region(Rect2i(0,row*sheet.get_height()/2,sheet.get_width(),sheet.get_height()/2))
		for y: int in strip.get_height():
			for x: int in strip.get_width():
				var pixel: Color = strip.get_pixel(x,y)
				if pixel.a<0.75:
					pixel = Color.TRANSPARENT
				else:
					pixel.a = 1.0
				strip.set_pixel(x,y,pixel)
		# Find transparent gutters: oversized blue claws cross the nominal cell edge.
		var cuts: Array[int] = [0]
		for column: int in range(1,6):
			var nominal: int = column*sheet.get_width()/6
			var chosen: int = nominal
			var best: int = strip.get_height()+1
			for distance: int in 41:
				for direction: int in [-1,1]:
					var x: int = nominal+distance*direction
					var count: int = 0
					for y: int in strip.get_height():
						if strip.get_pixel(x,y).a>0:
							count += 1
					if count<best:
						best = count
						chosen = x
			assert(best==0,"Crab crop must use a transparent gutter; never cut a claw")
			cuts.append(chosen)
		cuts.append(sheet.get_width())
		# Double source detail, then display at 0.5 scale like the adult character art.
		var atlas := Image.create(48*6,40,false,Image.FORMAT_RGBA8)
		for column: int in 6:
			var part: Image = strip.get_region(Rect2i(cuts[column],0,cuts[column+1]-cuts[column],strip.get_height()))
			var bounds: Rect2i = part.get_used_rect()
			assert(bounds.has_area())
			var image: Image = part.get_region(bounds)
			var ratio: float = minf(40.0/bounds.size.x,32.0/bounds.size.y)
			var width: int = maxi(1,roundi(bounds.size.x*ratio))
			var height: int = maxi(1,roundi(bounds.size.y*ratio))
			image.resize(width,height,Image.INTERPOLATE_NEAREST)
			atlas.blit_rect(image,Rect2i(0,0,width,height),Vector2i(column*48+(48-width)/2,40-height))
		var path: String = "res://assets/sprites/crab-%s-v2.png" % ("red" if row==0 else "blue")
		assert(atlas.save_png(path)==OK)
		print("Prepared ",path)
	quit()
