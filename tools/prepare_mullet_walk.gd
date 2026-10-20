extends SceneTree
const WalkSource = preload("res://tools/mullet_walk_source.gd")

func _initialize() -> void:
	var entries: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/shopper_variants_art.json"))
	var result: Dictionary = WalkSource.new().apply(entries.shopper_mullet)
	FileAccess.open("res://data/mullet_walk_v2.json",FileAccess.WRITE).store_string(JSON.stringify({"shopper_mullet":result},"  ",false)+"\n")
	print("Prepared six full-body mullet walk poses; other atlas cells retained.")
	quit()
