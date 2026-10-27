extends SceneTree
## Crop, nearest-neighbour resize, align and pack generated artwork only.
## No character pixels are drawn here; untouched ImageGen sources stay in reference/.
const Source = preload("res://tools/diner_adult_atlas_source.gd")
const ROOT := "res://assets/reference/shopper-panic-v1/"
const CELLS := [Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1),Vector2i(2,1),Vector2i(0,2),Vector2i(1,2),Vector2i(2,2)]
const ENTRIES := {
	"kiosk_customer": {
		"source":"kiosk-customer-panic-source.png",
		"registry":"shopper_art",
		"base":"shopper-diner-style-v2-bite-v1.png",
		"output":"shopper-diner-style-v2-bite-panic-v1.png"
	},
	"shopper_mullet": {
		"source":"shopper-mullet-panic-source.png",
		"registry":"shopper_variants_art",
		"base":"shopper-mullet-walk-v2-bite-v1.png",
		"output":"shopper-mullet-walk-v2-bite-panic-v1.png"
	},
	"shopper_sundress": {
		"source":"shopper-sundress-panic-source.png",
		"registry":"shopper_variants_art",
		"base":"shopper-sundress-walk-v2-bite-v1.png",
		"output":"shopper-sundress-walk-v2-bite-panic-v1.png"
	}
}
var source := Source.new()

func _initialize() -> void:
	var registries: Dictionary = {}
	var master_path := "res://data/sprites.json"
	var master_text := FileAccess.get_file_as_string(master_path)
	for id: String in ENTRIES:
		var spec: Dictionary = ENTRIES[id]
		var registry_path: String = "res://data/%s.json" % spec.registry
		if not registries.has(registry_path):
			registries[registry_path] = JSON.parse_string(FileAccess.get_file_as_string(registry_path))
		var entry: Dictionary = registries[registry_path][id]
		_normalize(entry)
		var master_entry: Dictionary = JSON.parse_string(master_text)[id]
		var old := source._read("res://assets/sprites/" + str(spec.base))
		# Bench clips are composed into the master registry and may occupy cells
		# beyond the local art JSON's last frame. Allocate after both registries.
		var first := maxi(_next_frame(entry.animations),_next_frame(master_entry.animations))
		var generated := source._read(ROOT + str(spec.source))
		var atlas_height := maxi(old.get_height(), ceili((first + CELLS.size()) / 8.0) * 128)
		var atlas := Image.create(1024, atlas_height, false, Image.FORMAT_RGBA8)
		atlas.fill(Color.TRANSPARENT)
		atlas.blit_rect(old, Rect2i(Vector2i.ZERO, old.get_size()), Vector2i.ZERO)
		for index: int in CELLS.size():
			var cell: Vector2i = CELLS[index]
			var x0 := roundi(float(cell.x) * generated.get_width() / 3.0)
			var x1 := roundi(float(cell.x + 1) * generated.get_width() / 3.0)
			var y0 := roundi(float(cell.y) * generated.get_height() / 3.0)
			var y1 := roundi(float(cell.y + 1) * generated.get_height() / 3.0)
			var frame: Image = source._cut(generated, Rect2i(x0,y0,x1-x0,y1-y0), 80)
			assert(frame.get_used_rect().end.y == 116, "%s panic frame %d misses the sole baseline" % [id,index])
			var target := first + index
			atlas.blit_rect(frame, Rect2i(0,0,128,128), Vector2i(target % 8 * 128, target / 8 * 128))
		var output := "res://assets/sprites/" + str(spec.output)
		assert(atlas.save_png(output) == OK)
		entry.file = output
		entry.animations.look_up = {"frames":[first,first+1],"fps":6,"loop":false}
		entry.animations.panic_run = {"frames":range(first+2,first+8),"fps":12,"loop":true}
		entry.food_anchors.look_up = [entry.food_anchors.idle[0],entry.food_anchors.idle[0]]
		entry.food_anchors.panic_run = entry.food_anchors.run.duplicate(true)
		master_entry.file = entry.file
		master_entry.animations.look_up = entry.animations.look_up
		master_entry.animations.panic_run = entry.animations.panic_run
		master_entry.food_anchors.look_up = entry.food_anchors.look_up
		master_entry.food_anchors.panic_run = entry.food_anchors.panic_run
		var pattern := RegEx.create_from_string('(?ms)^  "'+id+'": \\{.*?^  \\}(?=,?\\n)')
		assert(pattern.search(master_text) != null)
		master_text = pattern.sub(master_text, '  "'+id+'": '+JSON.stringify(master_entry,"  ",false).replace("\n","\n  "))
	for path: String in registries:
		FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(registries[path],"  ",false)+"\n")
	FileAccess.open(master_path,FileAccess.WRITE).store_string(master_text)
	print("Prepared three generated shopper look-up and panic-run atlases")
	quit()

func _next_frame(animations: Dictionary) -> int:
	var first := 0
	for clip: String in animations:
		if clip in ["look_up","panic_run"]:
			continue
		for frame in animations[clip].frames:
			first = maxi(first, int(frame) + 1)
	return first

func _normalize(entry: Dictionary) -> void:
	for key: String in ["frame_w","frame_h","art_height","sprite_offset_y"]:
		entry[key] = int(entry[key])
	for clip: String in entry.animations:
		entry.animations[clip].fps = int(entry.animations[clip].fps)
		entry.animations[clip].frames = entry.animations[clip].frames.map(func(value: float) -> int: return int(value))
