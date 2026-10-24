extends RefCounted

static func run(check: Callable) -> void:
	var previous_file: String = ""
	var entries: Array[Dictionary] = [
		{"entry": VendorArt.entry(false), "label": "ice-cream vendor"},
		{"entry": VendorArt.entry(true), "label": "hotdog vendor"},
		{"entry": JSON.parse_string(FileAccess.get_file_as_string("res://data/vendor_art.json")).vendor_fish_chips, "label": "fish-and-chips vendor"}
	]
	for item: Dictionary in entries:
		var entry: Dictionary = item.entry
		var label: String = item.label
		var atlas := Image.load_from_file(ProjectSettings.globalize_path(str(entry.file)))
		check.call(FileAccess.file_exists(str(entry.source)),label+" preserves untouched generated full-body source")
		check.call(FileAccess.file_exists(str(entry.base_source)),label+" also preserves original approved full-body source")
		check.call(int(entry.frames)==12,label+" has eight approved poses plus four generated turning/working poses")
		var base := Image.load_from_file(ProjectSettings.globalize_path(str(entry.base_atlas)))
		check.call(atlas.get_region(Rect2i(0,0,1024,128)).get_data()==base.get_data(),label+" preserves the original eight poses pixel-for-pixel")
		check.call(str(entry.file)!=previous_file,label+" uses a distinct generated character atlas")
		previous_file = str(entry.file)
		var alpha_ok: bool = true
		var data: PackedByteArray = atlas.get_data()
		for index: int in range(3,data.size(),4):
			if data[index] not in [0,255]:
				alpha_ok = false
		check.call(alpha_ok,label+" has clean native transparency")
		var previous: PackedByteArray = PackedByteArray()
		for index: int in int(entry.frames):
			var frame := atlas.get_region(Rect2i(index*128,0,128,128))
			var bounds: Rect2i = frame.get_used_rect()
			check.call(bounds.end.y==116 and bounds.size.y>=72 and bounds.position.x>0 and bounds.end.x<128,label+" retains full character and anchored shoes in pose "+str(index))
			check.call(previous!=frame.get_data(),label+" supplies a distinct drawn pose "+str(index))
			previous = frame.get_data()
