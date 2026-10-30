extends SceneTree
## Crop the preserved ImageGen source into tiny palette-limited runtime VFX.

const SOURCE_PATH: String = "res://assets/reference/peck-snatch-vfx-v1/source.png"
const REVIEW_PATH: String = "res://assets/archive/previews/peck-snatch-vfx-v1.png"
const ALPHA_CUTOFF: float = 0.72
const PALETTE: Array[Color] = [
	Color("183b4e"), Color("fff4da"), Color("f3c443"),
	Color("ef725c"), Color("d4ad78"), Color("8bc6b4"),
]
const EFFECTS: Array[Dictionary] = [
	{"name":"peck-star", "cell":Vector2i(0,0), "size":Vector2i(12,12)},
	{"name":"snatch-slash", "cell":Vector2i(1,0), "size":Vector2i(16,10)},
	{"name":"impact-wedge", "cell":Vector2i(2,0), "size":Vector2i(12,10)},
	{"name":"crumb-flecks", "cell":Vector2i(0,1), "size":Vector2i(8,8)},
	{"name":"dust-puff", "cell":Vector2i(1,1), "size":Vector2i(10,8)},
	{"name":"speed-streak", "cell":Vector2i(2,1), "size":Vector2i(14,8)},
]

func _initialize() -> void:
	var source := Image.new()
	assert(source.load(SOURCE_PATH) == OK, "VFX source must load")
	assert(source.get_size() == Vector2i(1536,1024), "VFX source keeps its generated 3x2 canvas")
	var cell_size := Vector2i(source.get_width()/3,source.get_height()/2)
	var review := Image.create(72,40,false,Image.FORMAT_RGBA8)
	review.fill(Color.TRANSPARENT)
	for index: int in EFFECTS.size():
		var effect: Dictionary = EFFECTS[index]
		var cell: Vector2i = effect.cell
		var cell_image: Image = source.get_region(Rect2i(cell*cell_size,cell_size))
		var bounds: Rect2i = _solid_bounds(cell_image)
		assert(bounds.has_area(),"Generated cell must contain %s" % effect.name)
		var target_size: Vector2i = effect.size
		var factor: float = minf(float(target_size.x-2)/float(bounds.size.x),float(target_size.y-2)/float(bounds.size.y))
		var reduced_size := Vector2i(maxi(1,roundi(bounds.size.x*factor)),maxi(1,roundi(bounds.size.y*factor)))
		var reduced: Image = cell_image.get_region(bounds)
		reduced.resize(reduced_size.x,reduced_size.y,Image.INTERPOLATE_NEAREST)
		_quantize(reduced)
		var output := Image.create(target_size.x,target_size.y,false,Image.FORMAT_RGBA8)
		output.fill(Color.TRANSPARENT)
		var offset := Vector2i((target_size.x-reduced_size.x)/2,(target_size.y-reduced_size.y)/2)
		output.blit_rect(reduced,Rect2i(Vector2i.ZERO,reduced_size),offset)
		var path: String = "res://assets/sprites/vfx-%s-v1.png" % effect.name
		assert(output.save_png(path) == OK,"Could not save "+path)
		_validate(path,target_size)
		var review_cell := Vector2i(index%3*24,index/3*20)
		review.blit_rect(output,Rect2i(Vector2i.ZERO,target_size),review_cell+Vector2i((24-target_size.x)/2,(20-target_size.y)/2))
		print("%s: cell %s, source bounds %s, runtime %s" % [effect.name,cell,bounds,target_size])
	review.resize(576,320,Image.INTERPOLATE_NEAREST)
	assert(review.save_png(REVIEW_PATH) == OK,"Could not save VFX review")
	quit()

func _solid_bounds(image: Image) -> Rect2i:
	var low := Vector2i(image.get_width(),image.get_height())
	var high := Vector2i(-1,-1)
	for y: int in image.get_height():
		for x: int in image.get_width():
			if image.get_pixel(x,y).a >= ALPHA_CUTOFF:
				low = Vector2i(mini(low.x,x),mini(low.y,y))
				high = Vector2i(maxi(high.x,x),maxi(high.y,y))
	return Rect2i(low,high-low+Vector2i.ONE)

func _quantize(image: Image) -> void:
	for y: int in image.get_height():
		for x: int in image.get_width():
			var source: Color = image.get_pixel(x,y)
			if source.a < ALPHA_CUTOFF:
				image.set_pixel(x,y,Color.TRANSPARENT)
				continue
			var nearest: Color = PALETTE[0]
			var nearest_distance: float = INF
			for candidate: Color in PALETTE:
				var difference := Vector3(source.r-candidate.r,source.g-candidate.g,source.b-candidate.b)
				if difference.length_squared() < nearest_distance:
					nearest_distance = difference.length_squared()
					nearest = candidate
			image.set_pixel(x,y,nearest)

func _validate(path: String,target_size: Vector2i) -> void:
	var saved := Image.new()
	assert(saved.load(path) == OK,"Prepared VFX must reload")
	assert(saved.get_size() == target_size,"Prepared VFX keeps its target size")
	var opaque: int = 0
	var transparent: int = 0
	for y: int in target_size.y:
		for x: int in target_size.x:
			var pixel: Color = saved.get_pixel(x,y)
			assert(pixel.a == 0.0 or pixel.a == 1.0,"Prepared VFX alpha must be binary")
			if pixel.a == 0.0:
				transparent += 1
			else:
				opaque += 1
				assert(pixel in PALETTE,"Prepared VFX color must be in the approved palette")
	assert(opaque >= 3 and transparent > 0,"Prepared VFX needs an isolated readable silhouette")
