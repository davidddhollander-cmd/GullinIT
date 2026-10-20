extends RefCounted
## Technical cropping only: every complete pose comes from preserved ImageGen art.
const Source = preload("res://tools/diner_adult_atlas_source.gd")
const BASE := "res://assets/sprites/shopper-mullet-diner-style.png"
const OUTPUT := "res://assets/sprites/shopper-mullet-walk-v2.png"
const REFERENCES := "res://assets/reference/mullet-walk-v2/"

func _palm(frame: Image) -> Array:
	var right := -1
	var ys: Array[int] = []
	for y: int in range(74,100):
		for x: int in range(72,124):
			if not Source.skin(frame.get_pixel(x,y)):
				continue
			if x > right:
				right = x
				ys.clear()
			if x == right:
				ys.append(y)
	assert(not ys.is_empty(), "Walk pose needs an exposed carrying palm")
	ys.sort()
	return [(right-66)*0.5,(ys[ys.size()/2]-121)*0.5]

func apply(entry: Dictionary) -> Dictionary:
	var source := Source.new()
	var atlas: Image = source._read(BASE)
	var anchors: Array = []
	for i: int in 6:
		var raw: Image = source._read(REFERENCES+"walk-%d-source.png" % i)
		var frame: Image = source._cut(raw,Rect2i(Vector2i.ZERO,raw.get_size()))
		source.extractor._isolate_actor(frame)
		assert(frame.get_used_rect().end.y==116,"Walk soles must retain the adult baseline")
		var index := i+1
		atlas.blit_rect(frame,Rect2i(0,0,128,128),Vector2i(index%8*128,index/8*128))
		anchors.append(_palm(frame))
	assert(atlas.save_png(OUTPUT)==OK)
	var result: Dictionary = entry.duplicate(true)
	result.file = OUTPUT
	result.food_anchors.walk = anchors
	return result
