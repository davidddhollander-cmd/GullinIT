extends SceneTree
const Source = preload("res://tools/diner_adult_atlas_source.gd")
var source := Source.new()

func _palm(frame: Image) -> Array:
	# The carried-snack palm is at the waist; the swatting hand passes above it.
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
	if ys.is_empty():
		return [11,-22]
	ys.sort()
	return [(right-66)*0.5,(ys[ys.size()/2]-121)*0.5]

func _initialize() -> void:
	var root := "res://assets/reference/shopper-lifeguard-v1/"
	var idle := source._read(root+"shopper-pilot-0.png")
	var reaction := source._row(root+"shopper-actions.png",0,2,[80,80,80,80,80,80])
	var swat := source._row(root+"shopper-actions.png",1,2,[80,80,80,80,80,80])
	var groups: Dictionary = {
		"idle":[idle],"walk":source._row(root+"shopper-locomotion.png",0,2,[80,80,80,80,80,80]),
		"run":source._row(root+"shopper-locomotion.png",1,2,[80,80,80,80,80,80]),
		"alert":[reaction[1]],"warning":[reaction[1]],
		"angry":[reaction[3],reaction[4],reaction[4]],
		"windup":[swat[0],swat[1]],"swat":swat
	}
	var count := 0
	for frames: Array in groups.values():
		count += frames.size()
	var atlas := Image.create(8*128,ceili(count/8.0)*128,false,Image.FORMAT_RGBA8)
	var animations: Dictionary = {}
	var anchors: Dictionary = {}
	var index := 0
	for clip: String in groups:
		var indices: Array[int] = []
		anchors[clip] = []
		for frame: Image in groups[clip]:
			source.extractor._isolate_actor(frame)
			atlas.blit_rect(frame,Rect2i(0,0,128,128),Vector2i(index%8*128,index/8*128))
			indices.append(index)
			anchors[clip].append(_palm(frame))
			index += 1
		animations[clip] = {"frames":indices,"fps":10 if clip in ["run","swat"] else (8 if clip=="walk" else 4),"loop":clip not in ["swat","angry"]}
	assert(atlas.save_png("res://assets/archive/sprites/shopper-diner-style.png")==OK)
	var entry := {"file":"res://assets/archive/sprites/shopper-diner-style.png","frame_w":128,"frame_h":128,"visual_scale":0.5,"art_height":40,"sprite_offset_y":-26,"animations":animations,"food_anchors":anchors}
	FileAccess.open("res://data/shopper_art.json",FileAccess.WRITE).store_string(JSON.stringify({"kiosk_customer":entry},"  ",false)+"\n")
	quit()
