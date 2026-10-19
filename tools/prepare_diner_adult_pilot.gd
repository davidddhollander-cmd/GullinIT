extends SceneTree
## Offline pilot preparation. Does not modify the production adult atlases.
const SOURCE := "res://assets/reference/adult-diner-pilot-v1/"
const OUTPUT := "res://assets/pilots/adult-diner-v1/"
const CELL := 128
const HEIGHT := 80
const SOLE := 116

func _initialize() -> void:
	call_deferred("_prepare")

func _prepare() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	var manifest := {"cell":CELL, "figure_height":HEIGHT, "sole":SOLE, "display_scale":0.5, "frames":[]}
	for spec: Dictionary in [
		{"id":"mum-idle", "file":"mum-three-poses-source.png", "column":0, "columns":3},
		{"id":"mum-walk", "file":"mum-three-poses-source.png", "column":1, "columns":3},
		{"id":"mum-swat", "file":"mum-three-poses-source.png", "column":2, "columns":3},
		{"id":"male-idle", "file":"male-idle-source.png", "column":0, "columns":1},
		{"id":"female-idle", "file":"female-idle-source.png", "column":0, "columns":1}
	]:
		var source := Image.load_from_file(ProjectSettings.globalize_path(SOURCE + spec.file))
		assert(source != null, "Missing pilot source")
		source.convert(Image.FORMAT_RGBA8)
		var x0 := roundi(float(spec.column) * source.get_width() / spec.columns)
		var x1 := roundi(float(spec.column + 1) * source.get_width() / spec.columns)
		var part := source.get_region(Rect2i(x0, 0, x1 - x0, source.get_height()))
		for y: int in part.get_height():
			for x: int in part.get_width():
				var color := part.get_pixel(x, y)
				if color.a < 0.75:
					part.set_pixel(x, y, Color.TRANSPARENT)
				else:
					color.a = 1.0
					part.set_pixel(x, y, color)
		var bounds := part.get_used_rect()
		assert(bounds.has_area(), "Empty pilot pose")
		part = part.get_region(bounds)
		var width := roundi(float(part.get_width()) * HEIGHT / part.get_height())
		assert(width <= CELL - 12, "Pilot pose exceeds safe cell width")
		part.resize(width, HEIGHT, Image.INTERPOLATE_NEAREST)
		var image := Image.create(CELL, CELL, false, Image.FORMAT_RGBA8)
		image.fill(Color.TRANSPARENT)
		image.blit_rect(part, Rect2i(0,0,width,HEIGHT), Vector2i((CELL-width)/2, SOLE-HEIGHT))
		var path: String = OUTPUT + spec.id + ".png"
		assert(image.save_png(path) == OK)
		var saved := Image.load_from_file(ProjectSettings.globalize_path(path))
		assert(saved.get_size() == Vector2i(CELL, CELL))
		assert(saved.get_used_rect().end.y == SOLE, "Foot baseline changed")
		var colours := {}
		for y: int in CELL:
			for x: int in CELL:
				var color := saved.get_pixel(x, y)
				assert(color.a == 0.0 or color.a == 1.0, "Pilot alpha must be binary")
				if color.a == 1.0:
					colours[color.to_rgba32()] = true
		manifest.frames.append({"id":spec.id,"source":spec.file,"source_size":[source.get_width(),source.get_height()],"source_region":[x0+bounds.position.x,bounds.position.y,bounds.size.x,bounds.size.y],"used_width":width,"colours":colours.size()})
		print("PILOT %s: %dx%d, figure %dx%d, %d colours, hard alpha" % [spec.id,CELL,CELL,width,HEIGHT,colours.size()])
	var file := FileAccess.open(OUTPUT + "manifest.json", FileAccess.WRITE)
	assert(file != null)
	file.store_string(JSON.stringify(manifest, "  ") + "\n")
	file.close()
	quit()
