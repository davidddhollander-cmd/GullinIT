extends SceneTree
## Crop generated poses into the existing adult canvas; source sheets stay intact.
const Source = preload("res://tools/diner_adult_atlas_source.gd")
var source := Source.new()

func _palm(frame: Image,clip: String) -> Array:
	var right: int = -1
	var ys: Array[int] = []
	# Raised gestures may move the visible hand above the usual snack band.
	var top: int = 48 if clip in ["swat","warning","alert"] else 74
	for y: int in range(top,100):
		for x: int in range(72,124):
			if not Source.skin(frame.get_pixel(x,y)):
				continue
			if x > right:
				right = x
				ys.clear()
			if x == right:
				ys.append(y)
	if ys.is_empty():
		return [12,-22]
	ys.sort()
	return [(right-66)*0.5,(ys[ys.size()/2]-121)*0.5]

func _build(id: String) -> Dictionary:
	var path: String = "res://assets/reference/shopper-variants-v1/%s-source.png" % id
	var walk: Array[Image] = source._row(path,0,4)
	var run: Array[Image] = source._row(path,1,4)
	var utility: Array[Image] = source._row(path,2,4)
	var swat: Array[Image] = source._row(path,3,4)
	var groups: Dictionary = {
		"idle":[utility[0]],"walk":walk,"run":run,
		"alert":[utility[1]],"warning":[utility[2]],
		"angry":[utility[3],utility[4],utility[5]],
		"windup":[swat[0],swat[1]],"swat":swat
	}
	var count: int = 0
	for frames: Array in groups.values():
		count += frames.size()
	var atlas := Image.create(8*128,ceili(count/8.0)*128,false,Image.FORMAT_RGBA8)
	var animations: Dictionary = {}
	var anchors: Dictionary = {}
	var index: int = 0
	for clip: String in groups:
		var indices: Array[int] = []
		anchors[clip] = []
		for frame: Image in groups[clip]:
			source.extractor._isolate_actor(frame)
			assert(frame.get_used_rect().end.y==116,"Shopper feet must share adult baseline")
			atlas.blit_rect(frame,Rect2i(0,0,128,128),Vector2i(index%8*128,index/8*128))
			indices.append(index)
			anchors[clip].append(_palm(frame,clip))
			index += 1
		animations[clip] = {"frames":indices,"fps":10 if clip in ["run","swat"] else (8 if clip=="walk" else 4),"loop":clip not in ["swat","angry"]}
	var output: String = "res://assets/sprites/shopper-%s-diner-style.png" % id
	assert(atlas.save_png(output)==OK)
	var entry := {"file":output,"frame_w":128,"frame_h":128,"visual_scale":0.5,"art_height":40,"sprite_offset_y":-26,"animations":animations,"food_anchors":anchors}
	if id=="mullet":
		entry = preload("res://tools/mullet_walk_source.gd").new().apply(entry)
	elif id=="sundress":
		entry = preload("res://tools/sundress_walk_source.gd").new().apply(entry)
	return entry

func _initialize() -> void:
	var entries: Dictionary = {}
	for id: String in ["mullet","sundress"]:
		entries["shopper_"+id] = _build(id)
	FileAccess.open("res://data/shopper_variants_art.json",FileAccess.WRITE).store_string(JSON.stringify(entries,"  ",false)+"\n")
	quit()
