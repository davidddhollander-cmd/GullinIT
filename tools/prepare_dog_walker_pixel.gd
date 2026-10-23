extends SceneTree
## Offline cropping/alignment only. Generated bodies and full sources stay intact.
const ROOT := "res://assets/reference/dog-walker-pixel-v1/"
const CELL := Vector2i(192,128)
const Source = preload("res://tools/diner_adult_atlas_source.gd")

func _row(path: String,row: int,rows: int) -> Array[Image]:
	var source := Image.load_from_file(ProjectSettings.globalize_path(path))
	source.convert(Image.FORMAT_RGBA8)
	var top := roundi(float(row)*source.get_height()/rows)
	var bottom := roundi(float(row+1)*source.get_height()/rows)
	var part := source.get_region(Rect2i(0,top,source.get_width(),bottom-top))
	var pixels := part.get_data()
	var spans: Array[Vector2i] = []
	var start := -1
	for x: int in range(part.get_width()+1):
		var occupied := false
		if x < part.get_width():
			for y: int in part.get_height():
				if pixels[(y*part.get_width()+x)*4+3] >= 192:
					occupied = true
					break
		if occupied and start < 0:
			start = x
		elif not occupied and start >= 0:
			if x-start > 20:
				spans.append(Vector2i(start,x))
			start = -1
	assert(spans.size()==4,"Expected four complete woman/dog pairs")
	var frames: Array[Image] = []
	for span: Vector2i in spans:
		var crop := part.get_region(Rect2i(span.x,0,span.y-span.x,part.get_height()))
		for y: int in crop.get_height():
			for x: int in crop.get_width():
				var color := crop.get_pixel(x,y)
				color.a = 1.0 if color.a >= 0.75 else 0.0
				crop.set_pixel(x,y,color)
		crop = crop.get_region(crop.get_used_rect())
		crop.resize(roundi(crop.get_width()*80.0/crop.get_height()),80,Image.INTERPOLATE_NEAREST)
		# Upper-face skin belongs to the owner, so the leash/dog never shift the pivot.
		var total_x := 0
		var count := 0
		for y: int in 25:
			for x: int in crop.get_width():
				if Source.skin(crop.get_pixel(x,y)):
					total_x += x
					count += 1
		assert(count > 0)
		var offset := Vector2i(102-roundi(float(total_x)/count),36)
		assert(offset.x>=2 and offset.x+crop.get_width()<=CELL.x-2,"Keep complete pair and gutters")
		var frame := Image.create(CELL.x,CELL.y,false,Image.FORMAT_RGBA8)
		frame.blit_rect(crop,Rect2i(Vector2i.ZERO,crop.get_size()),offset)
		frames.append(frame)
	return frames

func _palm(frame: Image) -> Array:
	var right := -1
	var ys: Array[int] = []
	# Human food hand only; the terrier's head is below this band.
	for y: int in range(52,74):
		for x: int in range(100,166):
			if not Source.skin(frame.get_pixel(x,y)):
				continue
			if x > right:
				right = x
				ys.clear()
			if x == right:
				ys.append(y)
	assert(not ys.is_empty())
	ys.sort()
	return [(right-99)*0.5,(ys[ys.size()/2]-122)*0.5]

func _initialize() -> void:
	var frames := _row(ROOT+"walk-source.png",0,1)
	frames.append_array(_row(ROOT+"paired-source.png",1,2))
	var atlas := Image.create(CELL.x*4,CELL.y*2,false,Image.FORMAT_RGBA8)
	var palms: Array = []
	for index: int in frames.size():
		atlas.blit_rect(frames[index],Rect2i(Vector2i.ZERO,CELL),Vector2i(index%4*CELL.x,index/4*CELL.y))
		palms.append(_palm(frames[index]))
	var output := "res://assets/sprites/dog-owner-pixel-v1.png"
	assert(atlas.save_png(output)==OK)
	var entry := {
		"file":output,"frame_w":CELL.x,"frame_h":CELL.y,"visual_scale":0.5,"art_height":40,"sprite_offset_y":-26,
		"animations":{
			"walk":{"frames":[0,1,2,3],"fps":7,"loop":true},
			"idle":{"frames":[4],"fps":1,"loop":true},
			"alert":{"frames":[5],"fps":1,"loop":true},
			"bark":{"frames":[5,6,6,5],"fps":6,"loop":true},
			"angry":{"frames":[7],"fps":1,"loop":true}
		},
		"food_anchors":{"walk":palms.slice(0,4),"idle":[palms[4]],"alert":[palms[5]],"bark":[palms[5],palms[6],palms[6],palms[5]],"angry":[palms[7]]}
	}
	FileAccess.open("res://data/dog_owner_art.json",FileAccess.WRITE).store_string(JSON.stringify({"dog":entry},"  ",false)+"\n")
	var path := "res://data/sprites.json"
	var text := FileAccess.get_file_as_string(path)
	var pattern := RegEx.create_from_string('(?ms)^  "dog": \\{.*?^  \\}(?=,?\\n)')
	assert(pattern.search(text) != null)
	text = pattern.sub(text,'  "dog": '+JSON.stringify(entry,"  ",false).replace("\n","\n  "))
	FileAccess.open(path,FileAccess.WRITE).store_string(text)
	quit()
