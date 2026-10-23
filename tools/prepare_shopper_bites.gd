extends SceneTree
## Crop/align generated artwork only; keep every source and existing atlas cell intact.
const Source = preload("res://tools/diner_adult_atlas_source.gd")
const ROOT := "res://assets/reference/shopper-bite-v1/"
const ENTRIES := {
	"kiosk_customer": ["kiosk", "shopper_art", "shopper-diner-style-v2"],
	"shopper_mullet": ["mullet", "shopper_variants_art", "shopper-mullet-walk-v2"],
	"shopper_sundress": ["sundress", "shopper_variants_art", "shopper-sundress-walk-v2"]
}
var source := Source.new()

func _feet_center(frame: Image) -> int:
	var left := 128
	var right := 0
	for y: int in range(108,116):
		for x: int in 128:
			if frame.get_pixel(x,y).a > 0:
				left = mini(left,x)
				right = maxi(right,x)
	return (left+right)/2

func _initialize() -> void:
	var registries: Dictionary = {}
	var master_path := "res://data/sprites.json"
	var master_text := FileAccess.get_file_as_string(master_path)
	for id: String in ENTRIES:
		var spec: Array = ENTRIES[id]
		var registry_path: String = "res://data/%s.json" % spec[1]
		if not registries.has(registry_path):
			registries[registry_path] = JSON.parse_string(FileAccess.get_file_as_string(registry_path))
		var entry: Dictionary = registries[registry_path][id]
		for key: String in ["frame_w","frame_h","art_height","sprite_offset_y"]:
			entry[key] = int(entry[key])
		for clip: String in entry.animations:
			entry.animations[clip].fps = int(entry.animations[clip].fps)
			entry.animations[clip].frames = entry.animations[clip].frames.map(func(value: float) -> int: return int(value))
		var old := source._read("res://assets/sprites/%s.png" % spec[2])
		var idle_index: int = entry.animations.idle.frames[0]
		var idle := old.get_region(Rect2i(idle_index%8*128,idle_index/8*128,128,128))
		var poses: Array[Image] = source._row(ROOT+spec[0]+"-source.png",0,1,[80,80,80])
		var first: int = 0
		for clip: String in entry.animations:
			if clip == "bite":
				continue
			for index: int in entry.animations[clip].frames:
				first = maxi(first,index+1)
		var atlas := Image.create(1024,maxi(old.get_height(),ceili((first+3)/8.0)*128),false,Image.FORMAT_RGBA8)
		atlas.blit_rect(old,Rect2i(Vector2i.ZERO,old.get_size()),Vector2i.ZERO)
		for i: int in 3:
			var aligned := Image.create(128,128,false,Image.FORMAT_RGBA8)
			aligned.blit_rect(poses[i],Rect2i(0,0,128,128),Vector2i(_feet_center(idle)-_feet_center(poses[i]),0))
			source.extractor._isolate_actor(aligned)
			assert(aligned.get_used_rect().end.y == 116)
			atlas.blit_rect(aligned,Rect2i(0,0,128,128),Vector2i((first+i)%8*128,(first+i)/8*128))
		var output: String = "res://assets/sprites/%s-bite-v1.png" % spec[2]
		assert(atlas.save_png(output) == OK)
		entry.file = output
		entry.animations.bite = {"frames":[first,first+1,first+2],"fps":5,"loop":false}
		# Hand positions measured on the prepared 128px frames, in target coordinates.
		entry.food_anchors.bite = {
			"kiosk_customer":[[7.5,-27.0],[6.5,-27.0],[13.5,-21.0]],
			"shopper_mullet":[[13.5,-24.0],[8.0,-27.0],[14.0,-22.0]],
			"shopper_sundress":[[10.5,-27.0],[9.0,-27.0],[15.0,-22.0]]
		}[id]
		var pattern := RegEx.create_from_string('(?ms)^  "'+id+'": \\{.*?^  \\}(?=,?\\n)')
		assert(pattern.search(master_text) != null)
		var master_entry: Dictionary = JSON.parse_string(master_text)[id]
		master_entry.file = entry.file
		master_entry.animations.bite = entry.animations.bite
		master_entry.food_anchors.bite = entry.food_anchors.bite
		master_text = pattern.sub(master_text,'  "'+id+'": '+JSON.stringify(master_entry,"  ",false).replace("\n","\n  "))
	for path: String in registries:
		FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(registries[path],"  ",false)+"\n")
	FileAccess.open(master_path,FileAccess.WRITE).store_string(master_text)
	quit()
