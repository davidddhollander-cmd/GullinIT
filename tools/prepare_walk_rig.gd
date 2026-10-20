extends SceneTree
const ROOT := "res://assets/pilots/shopper-walk-v1/"

func _initialize() -> void:
	var source := Image.load_from_file(ProjectSettings.globalize_path("res://assets/reference/shopper-walk-pilot-v1/leg-parts-flat.png"))
	source.convert(Image.FORMAT_RGBA8)
	var names := ["near-upper","near-lower","near-foot","far-upper","far-lower","far-foot"]
	var metadata := {"stride_pixels":28.0,"upper_length":7.0,"lower_length":7.0,"parts":{},"body":ROOT+"body.png","palm":[14.0,-22.0],"status":"cutout review pilot"}
	for i: int in 6:
		var x0 := roundi(float(i%3)*source.get_width()/3)
		var x1 := roundi(float(i%3+1)*source.get_width()/3)
		var y0 := roundi(float(i/3)*source.get_height()/2)
		var y1 := roundi(float(i/3+1)*source.get_height()/2)
		var part := source.get_region(Rect2i(x0,y0,x1-x0,y1-y0))
		for y: int in part.get_height():
			for x: int in part.get_width():
				var colour := part.get_pixel(x,y)
				colour.a = 1 if colour.a>=0.75 else 0
				part.set_pixel(x,y,colour)
		var bounds := part.get_used_rect()
		part = part.get_region(bounds)
		var detailed := part.duplicate()
		if i%3==2:
			part.resize(10,roundi(float(part.get_height())*10/part.get_width()),Image.INTERPOLATE_NEAREST)
		else:
			part.resize(roundi(float(part.get_width())*18/part.get_height()),18,Image.INTERPOLATE_NEAREST)
		var pivot := Vector2i(part.get_width()/2,2) if i%3!=2 else Vector2i(2,1)
		# Keep texture sampling dense during joint rotation; displayed dimensions stay fixed.
		detailed.resize(part.get_width()*4,part.get_height()*4,Image.INTERPOLATE_NEAREST)
		part = detailed
		pivot *= 4
		assert(part.save_png(ROOT+names[i]+".png")==OK)
		metadata.parts[names[i]] = {"file":ROOT+names[i]+".png","pivot":[pivot.x,pivot.y],"size":[part.get_width(),part.get_height()]}
	var body := Image.load_from_file(ProjectSettings.globalize_path(ROOT+"walk.png")).get_region(Rect2i(0,0,128,94))
	assert(body.save_png(ROOT+"body.png")==OK)
	metadata.ankle_height = float(metadata.parts["near-foot"].size[1]-4)*0.125
	FileAccess.open(ROOT+"rig.json",FileAccess.WRITE).store_string(JSON.stringify(metadata,"  ",false)+"\n")
	print("WALK RIG: prepared six generated limb pieces and cropped generated upper body")
	quit()
