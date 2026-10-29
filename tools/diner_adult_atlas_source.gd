extends RefCounted
## Approved 2x-detail source preparation. All dimensions below are source pixels.
const CELL := 128
const SOLE := 116
const SOURCE := "res://assets/reference/adult-diner-production-v1/"
const OLD_SOURCE := "res://assets/reference/adult-replacement-v3/"
const PILOT := "res://assets/pilots/adult-diner-v1/"
const Extractor = preload("res://tools/adult_atlas_source.gd")
var extractor := Extractor.new()
var groups: Dictionary = {}
var food_anchors: Dictionary = {}
var cells: Dictionary = {}
## Sunbather sources carry 2-3 px outlines at atlas scale; peel them to the 1 px ring touching the fill.
var thin_outline := false
const OUTLINE_PEEL := 2

func _read(path: String) -> Image:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	assert(image != null, "Missing adult source: " + path)
	image.convert(Image.FORMAT_RGBA8)
	return image

func _cut(source: Image, region: Rect2i, height: int = 80) -> Image:
	var part := source.get_region(region)
	for y: int in part.get_height():
		for x: int in part.get_width():
			var c := part.get_pixel(x,y)
			if c.a < 0.75:
				part.set_pixel(x,y,Color.TRANSPARENT)
			else:
				c.a = 1.0
				part.set_pixel(x,y,c)
	extractor._isolate_actor(part)
	var bounds := part.get_used_rect()
	assert(bounds.has_area(), "Empty adult source crop")
	part = part.get_region(bounds)
	var width := roundi(float(part.get_width()) * height / part.get_height())
	if width > 116:
		height = roundi(float(height) * 116 / width)
		width = 116
	part.resize(width,height,Image.INTERPOLATE_NEAREST)
	var result := Image.create(CELL,CELL,false,Image.FORMAT_RGBA8)
	result.fill(Color.TRANSPARENT)
	if thin_outline:
		_peel_outline(part)
		# Keep the thinned soles on the shared baseline.
		var used := part.get_used_rect()
		result.blit_rect(part,used,Vector2i((CELL-width)/2+used.position.x,SOLE-used.size.y))
	else:
		result.blit_rect(part,Rect2i(0,0,width,height),Vector2i((CELL-width)/2,SOLE-height))
	return result

static func _dark(c: Color) -> bool:
	return c.a > 0.0 and maxf(c.r,maxf(c.g,c.b)) < 0.3

func _peel_outline(part: Image) -> void:
	var w := part.get_width()
	var h := part.get_height()
	for _pass: int in OUTLINE_PEEL:
		var drop: Array[Vector2i] = []
		for y: int in h:
			for x: int in w:
				if not _dark(part.get_pixel(x,y)):
					continue
				var exposed := false
				var touches_fill := false
				for d: Vector2i in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
					var n := Vector2i(x,y)+d
					if n.x < 0 or n.y < 0 or n.x >= w or n.y >= h or part.get_pixelv(n).a == 0.0:
						exposed = true
					elif not _dark(part.get_pixelv(n)):
						touches_fill = true
				if exposed and not touches_fill:
					drop.append(Vector2i(x,y))
		for p: Vector2i in drop:
			part.set_pixelv(p,Color.TRANSPARENT)

func _actor_spans(source: Image, y0: int, y1: int, count: int) -> Array[Vector2i]:
	var width := source.get_width()
	var height := y1-y0
	var pixels := source.get_region(Rect2i(0,y0,width,height)).get_data()
	var seen := PackedByteArray()
	seen.resize(width*height)
	var components: Array = []
	for first: int in width*height:
		if seen[first] or pixels[first*4+3] < 192:
			continue
		var queue := PackedInt32Array([first])
		seen[first] = 1
		var cursor := 0
		var left := width
		var right := 0
		while cursor < queue.size():
			var p := queue[cursor]
			cursor += 1
			var x := p%width
			var y := p/width
			left = mini(left,x)
			right = maxi(right,x)
			for next: int in [p-1 if x>0 else -1,p+1 if x<width-1 else -1,p-width if y>0 else -1,p+width if y<height-1 else -1]:
				if next >= 0 and not seen[next] and pixels[next*4+3] >= 192:
					seen[next] = 1
					queue.append(next)
		components.append({"size":queue.size(),"span":Vector2i(maxi(0,left-2),mini(width,right+3))})
	components.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.size>b.size)
	assert(components.size() >= count,"Missing complete source actors")
	var spans: Array[Vector2i] = []
	for i: int in count:
		spans.append(components[i].span)
	spans.sort_custom(func(a: Vector2i,b: Vector2i) -> bool: return a.x<b.x)
	return spans

func _row(path: String, row: int, rows: int, heights: Array = [80,80,80,80,80,80], edges: Array = []) -> Array[Image]:
	var source := _read(path)
	var result: Array[Image] = []
	var y0 := roundi(float(row)*source.get_height()/rows)
	var y1 := roundi(float(row+1)*source.get_height()/rows)
	var spans: Array[Vector2i] = []
	if edges.is_empty():
		# Limb and ponytail extents can overlap in x without actors touching.
		# Connected actor bounds retain those parts; nominal grid columns cannot.
		spans = _actor_spans(source,y0,y1,heights.size())
	for i: int in heights.size():
		var x0 := roundi(float(i)*source.get_width()/heights.size()) if edges.is_empty() else int(edges[i])
		var x1 := roundi(float(i+1)*source.get_width()/heights.size()) if edges.is_empty() else int(edges[i+1])
		if spans.size() == heights.size():
			x0 = spans[i].x
			x1 = spans[i].y
		result.append(_cut(source,Rect2i(x0,y0,x1-x0,y1-y0),int(heights[i])))
	return result

func _setup(mum: bool, female: bool) -> void:
	var id: String = "mum" if mum else ("female" if female else "male")
	thin_outline = not mum
	groups.idle = [_read(PILOT + id + "-idle.png")]
	for row: int in 4:
		groups[["walk","walk_left","chase","chase_left"][row]] = _row(SOURCE + id + "-locomotion.png",row,4)
	for row: int in 3:
		groups[["swat","kick","kick_left"][row]] = _row(SOURCE + id + "-actions.png",row,3)
	if mum:
		groups.carry = _row(SOURCE + "mum-utility.png",0,4)
		groups.carry_left = _row(SOURCE + "mum-utility.png",1,4)
		groups.handover = _row(SOURCE + "mum-utility.png",2,4,[80,74,64,58,74,80])
		groups.utility = _row(SOURCE + "mum-utility.png",3,4)
	else:
		var review := "res://assets/previews/sunbather-%s-retro-review-v1.png" % id
		# The female's lying feet reach x=448; the male's second pose starts at 442.
		groups.utility = _row(review,0,3,[36,58,80,80],[0,450 if female else 435,785,1110,1445])
		groups.block = _row(review,2,3,[80,80,80,80])
		if female:
			groups.rise = _row(OLD_SOURCE+"female-motion.png",2,4,[36,50,58,66,72,80],[0,348,610,842,1065,1328,1536])
			groups.pickup = _row(OLD_SOURCE+"female-motion.png",3,4,[80,72,64,58,72,80])
		else:
			groups.rise = _row(OLD_SOURCE+"male-transitions.png",0,2,[36,50,58,66,72,80],[0,500,900,1250,1600,1930,2172])
			groups.pickup = _row(OLD_SOURCE+"male-transitions.png",1,2,[80,72,64,58,72,80])

func _frame(mum: bool, clip: String, frame: int) -> Image:
	var action := clip.trim_suffix("_left")
	var idle: Image = groups.idle[0]
	if clip in ["walk","walk_left","chase","chase_left","carry","carry_left","swat","kick","kick_left"]:
		return groups[clip][frame]
	if action == "run":
		# The seven-frame runtime loop includes a distinct planted acceleration pose.
		return groups["walk_left" if clip.ends_with("_left") else "walk"][2] if frame == 0 else groups["chase_left" if clip.ends_with("_left") else "chase"][frame-1]
	match action:
		"handover": return groups.handover[[0,1,2,3,5][frame]]
		"eat":
			return groups.utility[[0,1,1,2][frame]] if mum else (groups.utility[2] if frame in [1,2] else idle)
		"alert": return idle if frame == 0 else groups.utility[3]
		"block", "shield":
			return groups.utility[[0,4,5,0][frame]] if mum else (groups.block[0] if frame in [1,2] else idle)
		"rest": return groups.utility[0]
		"rise": return idle if frame == 6 else groups.rise[frame]
		"pickup": return groups.pickup[frame]
	return idle

static func skin(c: Color) -> bool:
	return c.a > 0.99 and c.r > 0.65 and c.g > 0.28 and c.g < 0.84 and c.b < 0.65 and c.r > c.g*1.15 and c.g > c.b*1.15

func _palm(image: Image, left: bool) -> Array:
	var extreme := CELL if left else -1
	var ys: Array[int] = []
	for y: int in range(61,110):
		for x: int in (range(0,58) if left else range(72,CELL)):
			if not skin(image.get_pixel(x,y)):
				continue
			if (left and x < extreme) or (not left and x > extreme):
				extreme = x
				ys.clear()
			if x == extreme:
				ys.append(y)
	if ys.is_empty():
		return [-13 if left else 13,-21]
	ys.sort()
	return [(extreme-64+(2 if left else -2))*0.5,(ys[ys.size()/2]-SOLE-5)*0.5]

func build(mum: bool, female: bool, clips: Dictionary) -> Image:
	_setup(mum,female)
	var total := 0
	for count: int in clips.values():
		total += count
	var image := Image.create(8*CELL,ceili(float(total)/8)*CELL,false,Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var index := 0
	for clip: String in clips:
		food_anchors[clip] = []
		cells[clip] = []
		for frame: int in int(clips[clip]):
			var cell := _frame(mum,clip,frame)
			assert(cell.get_used_rect().has_area())
			image.blit_rect(cell,Rect2i(0,0,CELL,CELL),Vector2i(index%8*CELL,index/8*CELL))
			cells[clip].append(cell)
			if mum:
				food_anchors[clip].append(_palm(cell,clip.ends_with("_left")))
			index += 1
	return image

static func red_cloth(c: Color) -> bool:
	return c.a > 0.99 and c.r > 0.35 and c.r > c.g*1.65 and c.b > c.g*0.75 and (c.h < 0.035 or c.h > 0.93)

static func blue_variant(red: Image) -> Image:
	var result: Image = red.duplicate()
	var width := red.get_width()
	var height := red.get_height()
	var seen := PackedByteArray()
	seen.resize(width*height)
	# Recolour substantial connected garment regions. Tiny mouth/cheek marks stay red.
	for y: int in height:
		for x: int in width:
			var first := y*width+x
			if seen[first] or not red_cloth(red.get_pixel(x,y)):
				continue
			var queue := PackedInt32Array([first])
			seen[first] = 1
			var cursor := 0
			while cursor < queue.size():
				var p := queue[cursor]
				cursor += 1
				for d: Vector2i in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
					var nx := p%width+d.x
					var ny := p/width+d.y
					if nx < 0 or ny < 0 or nx >= width or ny >= height:
						continue
					var next := ny*width+nx
					if not seen[next] and red_cloth(red.get_pixel(nx,ny)):
						seen[next] = 1
						queue.append(next)
			if queue.size() < 8:
				continue
			for p: int in queue:
				var c := red.get_pixel(p%width,p/width)
				result.set_pixel(p%width,p/width,Color.from_hsv(0.59,c.s*0.78,c.v*0.83+0.04))
	return result
