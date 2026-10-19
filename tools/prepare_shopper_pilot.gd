extends SceneTree
func _initialize() -> void:
	var source = preload("res://tools/diner_adult_atlas_source.gd").new()
	var frames: Array[Image] = source._row("res://assets/reference/shopper-lifeguard-v1/shopper-pilot.png",0,1,[80,80,80])
	for i: int in frames.size():
		source.extractor._isolate_actor(frames[i])
		assert(frames[i].save_png("res://assets/reference/shopper-lifeguard-v1/shopper-pilot-%d.png" % i)==OK)
	quit()
