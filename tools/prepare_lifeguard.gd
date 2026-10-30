extends SceneTree
const Source = preload("res://tools/diner_adult_atlas_source.gd")
var source := Source.new()

func _row(path: String, top: int, bottom: int) -> Array[Image]:
	var image := source._read(path)
	var spans := source._actor_spans(image,top,bottom,4)
	var result: Array[Image] = []
	for span: Vector2i in spans:
		var frame := source._cut(image,Rect2i(span.x,top,span.y-span.x,bottom-top),80)
		source.extractor._isolate_actor(frame)
		result.append(frame)
	return result

func _initialize() -> void:
	var old := "res://assets/archive/previews/lifeguard-pixel-review-v1.png"
	var motion := "res://assets/archive/previews/lifeguard-motion-review-v1.png"
	var idle := _row(old,0,382)
	var reactions := _row(old,736,1088)
	var walk := _row(motion,0,444)
	var actions := _row(motion,444,887)
	var groups: Dictionary = {
		"idle":[idle[0],idle[1],idle[0],idle[0]],
		"lookout":[idle[2]],"alert":[idle[3]],
		"walk":walk,"whistle_prepare":[actions[0],actions[1]],
		"whistle":[reactions[0],actions[2],reactions[0],actions[0]],
		"point":[actions[3]],"angry":[reactions[3]]
	}
	var supplement := "res://assets/reference/shopper-lifeguard-v1/lifeguard-actions.png"
	if FileAccess.file_exists(supplement):
		groups.run = source._row("res://assets/reference/shopper-lifeguard-v1/lifeguard-run.png",0,1,[80,80,80,80,80,80])
		groups.swat = source._row(supplement,1,2,[80,80,80,80,80,80])
		groups.windup = [groups.swat[0],groups.swat[1]]
	var count := 0
	for frames: Array in groups.values():
		count += frames.size()
	var atlas := Image.create(8*128,ceili(count/8.0)*128,false,Image.FORMAT_RGBA8)
	var animations: Dictionary = {}
	var index := 0
	for clip: String in groups:
		var indices: Array[int] = []
		for frame: Image in groups[clip]:
			source.extractor._isolate_actor(frame)
			atlas.blit_rect(frame,Rect2i(0,0,128,128),Vector2i(index%8*128,index/8*128))
			indices.append(index)
			index += 1
		animations[clip] = {"frames":indices,"fps":10 if clip in ["run","swat"] else (8 if clip=="walk" else (5 if clip=="whistle" else 2)),"loop":clip not in ["swat","whistle"]}
	assert(atlas.save_png("res://assets/sprites/lifeguard-diner-style.png")==OK)
	var entry := {"file":"res://assets/sprites/lifeguard-diner-style.png","frame_w":128,"frame_h":128,"visual_scale":0.5,"art_height":40,"sprite_offset_y":-26,"animations":animations}
	FileAccess.open("res://data/lifeguard_art.json",FileAccess.WRITE).store_string(JSON.stringify({"lifeguard":entry},"  ",false)+"\n")
	quit()
