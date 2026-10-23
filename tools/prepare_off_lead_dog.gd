extends SceneTree
## Pack generated terrier poses without painting or synthesizing character pixels.
const SOURCE := "res://assets/reference/off-lead-dog-v1/dog-source.png"
const CELL := Vector2i(128,96)
const Extractor = preload("res://tools/adult_atlas_source.gd")

func _spans(part: Image,vertical: bool) -> Array[Vector2i]:
	var width := part.get_width()
	var height := part.get_height()
	var data := part.get_data()
	var length := height if vertical else width
	var across := width if vertical else height
	var spans: Array[Vector2i] = []
	var start := -1
	for i: int in range(length+1):
		var occupied := false
		if i < length:
			for j: int in across:
				var pixel := (i*width+j) if vertical else (j*width+i)
				if data[pixel*4+3] >= 192:
					occupied = true
					break
		if occupied and start < 0:
			start = i
		elif not occupied and start >= 0:
			if i-start > 20:
				spans.append(Vector2i(start,i))
			start = -1
	return spans

func _collar_x(image: Image) -> int:
	var xs: Array[int] = []
	for y: int in image.get_height():
		for x: int in image.get_width():
			var color := image.get_pixel(x,y)
			if color.a>0 and color.g>color.r*1.3 and color.b>color.r*1.2 and color.g>0.2:
				xs.append(x)
	assert(not xs.is_empty(),"Preserve the teal collar in every pose")
	xs.sort()
	return xs[xs.size()/2]

func _initialize() -> void:
	var source := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	source.convert(Image.FORMAT_RGBA8)
	var rows := _spans(source,true)
	assert(rows.size()==5,"Keep all five generated animation rows")
	var raw_frames: Array[Dictionary] = []
	for row: Vector2i in rows:
		var strip := source.get_region(Rect2i(0,row.x,source.get_width(),row.y-row.x))
		var columns := _spans(strip,false)
		assert(columns.size()==6,"Keep six complete dogs in every row")
		for column: Vector2i in columns:
			var part := strip.get_region(Rect2i(column.x,0,column.y-column.x,strip.get_height()))
			for y: int in part.get_height():
				for x: int in part.get_width():
					var color := part.get_pixel(x,y)
					color.a = 1.0 if color.a>=0.75 else 0.0
					part.set_pixel(x,y,color)
			var bounds := part.get_used_rect()
			raw_frames.append({"image":part.get_region(bounds),"lift":strip.get_height()-bounds.end.y})
	# One scale for all thirty frames: crouching/sniffing never enlarge the dog's head.
	var idle_heights: Array[int] = []
	for index: int in range(18,24):
		idle_heights.append(raw_frames[index].image.get_height())
	idle_heights.sort()
	var scale_factor := 32.0/idle_heights[3]
	var atlas := Image.create(CELL.x*6,CELL.y*5,false,Image.FORMAT_RGBA8)
	var extractor := Extractor.new()
	for index: int in raw_frames.size():
		var part: Image = raw_frames[index].image
		part.resize(roundi(part.get_width()*scale_factor),roundi(part.get_height()*scale_factor),Image.INTERPOLATE_NEAREST)
		extractor._isolate_actor(part)
		var bottom := 84-roundi(raw_frames[index].lift*scale_factor)
		var offset := Vector2i(76-_collar_x(part),bottom-part.get_height())
		assert(offset.x>=2 and offset.y>=2 and offset.x+part.get_width()<=CELL.x-2 and bottom<=84)
		atlas.blit_rect(part,Rect2i(Vector2i.ZERO,part.get_size()),Vector2i(index%6*CELL.x,index/6*CELL.y)+offset)
	var output := "res://assets/sprites/off-lead-dog-pixel-v1.png"
	assert(atlas.save_png(output)==OK)
	var entry := {
		"file":output,"frame_w":CELL.x,"frame_h":CELL.y,"visual_scale":0.5,"art_height":16,"sprite_offset_y":-18,
		"animations":{
			"run":{"frames":[0,1,2,3,4,5],"fps":12,"loop":true},
			"leap":{"frames":[6,7,8,9,10,11],"fps":10,"loop":false},
			"catch":{"frames":[12,13,14,15,16,17],"fps":12,"loop":false},
			"bite":{"frames":[12,13,14,15,16,17],"fps":12,"loop":false},
			"idle":{"frames":[18,19,20,21,22,23],"fps":4,"loop":true},
			"sniff":{"frames":[24,25,26,27,28,29],"fps":6,"loop":true}
		}
	}
	FileAccess.open("res://data/dog_art.json",FileAccess.WRITE).store_string(JSON.stringify({"off_lead_dog":entry},"  ",false)+"\n")
	var path := "res://data/sprites.json"
	var text := FileAccess.get_file_as_string(path)
	var replacement := '  "off_lead_dog": '+JSON.stringify(entry,"  ",false).replace("\n","\n  ")
	var pattern := RegEx.create_from_string('(?ms)^  "off_lead_dog": \\{.*?^  \\}(?=,?\\n)')
	if pattern.search(text) != null:
		text = pattern.sub(text,replacement)
	else:
		text = text.left(text.rfind("}")).strip_edges()+",\n"+replacement+"\n}\n"
	FileAccess.open(path,FileAccess.WRITE).store_string(text)
	print("Prepared 30 generated off-lead dog frames at one consistent scale")
	quit()
