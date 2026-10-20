extends SceneTree
## Technical extraction only: every character pixel comes from ImageGen artwork.
const Source = preload("res://tools/diner_adult_atlas_source.gd")
const ROOT := "res://assets/reference/shopper-walk-pilot-v1/"
const OUT := "res://assets/pilots/shopper-walk-v1/"
const CELL := 128
const SOLE := 116

func _read(path: String) -> Image:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	assert(image!=null,"Missing generated walk source")
	image.convert(Image.FORMAT_RGBA8)
	for y: int in image.get_height():
		for x: int in image.get_width():
			var colour := image.get_pixel(x,y)
			colour.a = 1 if colour.a>=0.75 else 0
			image.set_pixel(x,y,colour)
	return image

func _hip_x(part: Image, bounds: Rect2i) -> float:
	var xs: Array[int] = []
	for y: int in range(bounds.position.y+roundi(bounds.size.y*0.57),bounds.position.y+roundi(bounds.size.y*0.66)):
		for x: int in range(bounds.position.x,bounds.end.x):
			var c := part.get_pixel(x,y)
			if c.a>0.99 and c.b>c.r*1.3 and c.b>0.15 and c.r<0.4:
				xs.append(x)
	assert(not xs.is_empty(),"Missing shorts/hip alignment landmark")
	xs.sort()
	return float(xs[xs.size()/2])

func _palm(cell: Image) -> Vector2:
	var right := -1
	var ys: Array[int] = []
	for y: int in range(64,100):
		for x: int in range(74,124):
			if not Source.skin(cell.get_pixel(x,y)):
				continue
			if x>right:
				right = x
				ys.clear()
			if x==right:
				ys.append(y)
	assert(right>=0,"Missing generated carrying hand")
	ys.sort()
	return Vector2((right-64)*0.5,(ys[ys.size()/2]-64)*0.5-26)

func _initialize() -> void:
	var sheet := _read(ROOT+"source.png")
	var parts: Array[Image] = []
	var heights: Array[int] = []
	for i: int in 8:
		var x0 := roundi(float(i%4)*sheet.get_width()/4)
		var x1 := roundi(float(i%4+1)*sheet.get_width()/4)
		var y0 := roundi(float(i/4)*sheet.get_height()/2)
		var y1 := roundi(float(i/4+1)*sheet.get_height()/2)
		var part := sheet.get_region(Rect2i(x0,y0,x1-x0,y1-y0))
		parts.append(part)
		heights.append(part.get_used_rect().size.y)
	var sorted := heights.duplicate()
	sorted.sort()
	# One shared scale keeps the authored relative heights/bounce intact.
	var common_scale: float = 80.0/float(sorted[4])
	var atlas := Image.create(CELL*4,CELL*2,false,Image.FORMAT_RGBA8)
	var frames: Array[Dictionary] = []
	var audit: Array[Dictionary] = []
	for i: int in 8:
		var part: Image = parts[i]
		var scale: float = common_scale
		var source_file: String = "source.png"
		if i==4:
			# Separately generated opposing contact, aligned to the first contact's size.
			part = _read(ROOT+"opposite-contact.png")
			scale = float(heights[0])*common_scale/float(part.get_used_rect().size.y)
			source_file = "opposite-contact.png"
		var bounds := part.get_used_rect()
		var hip: float = _hip_x(part,bounds)
		var cropped := part.get_region(bounds)
		cropped.resize(roundi(bounds.size.x*scale),roundi(bounds.size.y*scale),Image.INTERPOLATE_NEAREST)
		var at := Vector2i(64-roundi((hip-bounds.position.x)*scale),SOLE-cropped.get_height())
		assert(at.x>=2 and at.x+cropped.get_width()<=126,"Clipped walking limb")
		var cell := Image.create(CELL,CELL,false,Image.FORMAT_RGBA8)
		cell.blit_rect(cropped,Rect2i(Vector2i.ZERO,cropped.get_size()),at)
		atlas.blit_rect(cell,Rect2i(0,0,CELL,CELL),Vector2i(i%4*CELL,i/4*CELL))
		var palm := _palm(cell)
		frames.append({"palm":[palm.x,palm.y]})
		audit.append({"frame":i,"source":source_file,"source_bounds":[bounds.position.x,bounds.position.y,bounds.size.x,bounds.size.y],"scale":scale,"hip_x":hip,"destination":[at.x,at.y]})
	assert(atlas.save_png(OUT+"walk.png")==OK)
	var metadata := {"file":OUT+"walk.png","frame_w":CELL,"frame_h":CELL,"columns":4,"count":8,"visual_scale":0.5,"sprite_offset_y":-26,"stride_pixels":36.0,"frames":frames,"source_preparation":audit,"status":"review pilot"}
	FileAccess.open(OUT+"walk.json",FileAccess.WRITE).store_string(JSON.stringify(metadata,"  ",false)+"\n")
	print("WALK PILOT: eight generated full-body frames, common scale, hip-aligned, separate palm anchors")
	quit()
