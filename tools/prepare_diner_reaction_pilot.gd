extends SceneTree
## Packs generated complete figures without drawing or reconstructing anatomy.

const FRAME := Vector2i(400,400)
const COLUMNS: int = 6
const BASELINE: int = 390
const TARGET_HEIGHT: float = 338.0

func _initialize() -> void:
	var surprise := _actors("res://assets/reference/diner-reaction-pilot-v1/diner-reactions-source-pass-1.png")
	var anger := _actors("res://assets/reference/diner-reaction-pilot-v1/diner-fist-shake-source.png")
	assert(surprise.size() >= 12,"The surprise source must contain twelve complete figures")
	assert(anger.size() >= 6,"The anger source must contain six complete figures")
	var surprise_row: Array[Dictionary] = _row(surprise,0,6)
	var anger_row: Array[Dictionary] = _row(anger,0,6)
	var output := Image.create(FRAME.x*COLUMNS,FRAME.y*2,false,Image.FORMAT_RGBA8)
	_pack_row(output,surprise_row,0)
	_pack_row(output,anger_row,1)
	assert(output.save_png("res://assets/sprites/pier-diner-reactions-v1.png") == OK)
	quit()

func _actors(path: String) -> Array[Dictionary]:
	var source := Image.load_from_file(path)
	var width := source.get_width()
	var height := source.get_height()
	var visited := PackedByteArray()
	visited.resize(width*height)
	var actors: Array[Dictionary] = []
	for start: int in width*height:
		if visited[start] or source.get_pixel(start%width,start/width).a < 0.1:
			continue
		var pixels := PackedInt32Array([start])
		visited[start] = 1
		var cursor := 0
		var bounds := Rect2i(start%width,start/width,1,1)
		while cursor < pixels.size():
			var index := pixels[cursor]
			cursor += 1
			var x := index%width
			var y := index/width
			bounds = bounds.expand(Vector2i(x,y))
			for next: int in [index-1,index+1,index-width,index+width]:
				if next < 0 or next >= visited.size() or absi(next%width-x) > 1:
					continue
				if not visited[next] and source.get_pixel(next%width,next/width).a >= 0.1:
					visited[next] = 1
					pixels.append(next)
		if pixels.size() > 1500:
			bounds.size += Vector2i.ONE
			actors.append({"source":source,"bounds":bounds,"pixels":pixels})
	actors.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		var ay: float = a.bounds.get_center().y
		var by: float = b.bounds.get_center().y
		return ay < by if absf(ay-by) > 80.0 else a.bounds.position.x < b.bounds.position.x)
	return actors

func _row(actors: Array[Dictionary],offset: int,count: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for index: int in count:
		result.append(actors[offset+index])
	result.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.bounds.position.x < b.bounds.position.x)
	return result

func _pack_row(output: Image,actors: Array[Dictionary],row: int) -> void:
	var average_height: float = 0.0
	for actor: Dictionary in actors:
		average_height += actor.bounds.size.y
	average_height /= actors.size()
	var scale_factor: float = TARGET_HEIGHT/average_height
	for column: int in actors.size():
		var actor: Dictionary = actors[column]
		# Copy only the connected complete figure. Very low-alpha generator specks
		# outside it are source noise, not character art or neighbouring anatomy.
		var crop := Image.create(actor.bounds.size.x,actor.bounds.size.y,false,Image.FORMAT_RGBA8)
		var source_width: int = actor.source.get_width()
		for index: int in actor.pixels:
			var point := Vector2i(index%source_width,index/source_width)
			crop.set_pixelv(point-actor.bounds.position,actor.source.get_pixelv(point))
		var size := Vector2i(roundi(crop.get_width()*scale_factor),roundi(crop.get_height()*scale_factor))
		crop.resize(size.x,size.y,Image.INTERPOLATE_NEAREST)
		var at := Vector2i(column*FRAME.x+(FRAME.x-size.x)/2,row*FRAME.y+BASELINE-size.y)
		output.blend_rect(crop,Rect2i(Vector2i.ZERO,size),at)
		print("diner reaction frame ",row*COLUMNS+column," bounds ",actor.bounds," packed ",size)
