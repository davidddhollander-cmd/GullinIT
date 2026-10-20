extends SceneTree
## Native-pixel preparation of the generated tall lamp; preserves its source.
const EnvironmentSource = preload("res://tools/prepare_retro_environment.gd")

func _initialize() -> void:
	var source := Image.load_from_file(ProjectSettings.globalize_path("res://assets/reference/tall-lamp-v1/source.png"))
	assert(source!=null)
	source.convert(Image.FORMAT_RGBA8)
	var bounds: Rect2i = EnvironmentSource._alpha_bounds(source,Rect2i(Vector2i.ZERO,source.get_size()))
	var foot_left: int = bounds.end.x
	var foot_right: int = bounds.position.x
	for y: int in range(bounds.end.y-roundi(bounds.size.y*0.04),bounds.end.y):
		for x: int in range(bounds.position.x,bounds.end.x):
			if source.get_pixel(x,y).a>=0.65:
				foot_left = mini(foot_left,x)
				foot_right = maxi(foot_right,x)
	var factor: float = 88.0/float(bounds.size.y)
	var part := source.get_region(bounds)
	part.resize(roundi(bounds.size.x*factor),88,Image.INTERPOLATE_NEAREST)
	EnvironmentSource._quantize(part)
	var output := Image.create(24,90,false,Image.FORMAT_RGBA8)
	var x_offset: int = 12-roundi(((foot_left+foot_right)*0.5-bounds.position.x)*factor)
	assert(x_offset>=0 and x_offset+part.get_width()<=24)
	output.blit_rect(part,Rect2i(Vector2i.ZERO,part.get_size()),Vector2i(x_offset,2))
	assert(output.save_png("res://assets/sprites/retro-beach-lamp-tall-v1.png")==OK)
	var registry: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/sprites.json"))
	registry.beach_lamp.file = "res://assets/sprites/retro-beach-lamp-tall-v1.png"
	registry.beach_lamp.frame_w = 24
	registry.beach_lamp.frame_h = 90
	var cap_x: Array[int] = []
	for y: int in range(2,5):
		for x: int in output.get_width():
			if output.get_pixel(x,y).a>0:
				cap_x.append(x)
	cap_x.sort()
	registry.beach_lamp.perch_offset_x = float(cap_x[cap_x.size()/2])-12.0
	registry.beach_lamp.perch_inset_y = 2
	FileAccess.open("res://data/sprites.json",FileAccess.WRITE).store_string(JSON.stringify(registry,"  ",false)+"\n")
	print("Prepared grounded 24 x 90 lamp and aligned its top perch")
	call_deferred("_finish")

func _finish() -> void:
	await process_frame
	var audio: Node = root.get_node_or_null("Audio")
	if audio != null:
		audio.get("music").stop()
	await create_timer(0.05).timeout
	quit()
