extends RefCounted

static func run(check: Callable) -> void:
	var current: Dictionary = Config.sprites.shopper_mullet
	var previous: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/reference/mullet-walk-v2/previous-entry.json"))
	check.call(current.file=="res://assets/sprites/shopper-mullet-bench-v1.png","mullet selects the atlas retaining generated walk and appended bench poses")
	var expected: Dictionary = previous.duplicate(true)
	expected.file = current.file
	expected.food_anchors.walk = current.food_anchors.walk
	for clip: String in ["sit_down","seated_idle","seated_eat","stand_up"]:
		expected.animations[clip] = current.animations[clip]
		expected.food_anchors[clip] = current.food_anchors[clip]
	check.call(current==expected,"mullet retains previous metadata with only walk anchors and bench additions")
	var frames := Config.frames("shopper_mullet")
	check.call(frames.get_frame_count(&"walk")==6 and is_equal_approx(frames.get_animation_speed(&"walk"),8.0),"mullet retains approved six-frame walking timing")
	var before := Image.load_from_file(ProjectSettings.globalize_path(previous.file))
	var after := Image.load_from_file(ProjectSettings.globalize_path(current.file))
	before.convert(Image.FORMAT_RGBA8)
	after.convert(Image.FORMAT_RGBA8)
	check.call(after.get_size()==before.get_size()+Vector2i(0,128),"mullet atlas appends one bench row without changing old cell coordinates")
	var approved := Image.load_from_file(ProjectSettings.globalize_path("res://assets/sprites/shopper-mullet-walk-v2.png"))
	approved.convert(Image.FORMAT_RGBA8)
	check.call(after.get_region(Rect2i(Vector2i.ZERO,approved.get_size())).get_data()==approved.get_data(),"mullet approved walk and reaction pixels remain exact")
	for index: int in 32:
		var region := Rect2i(index%8*128,index/8*128,128,128)
		var old_cell := before.get_region(region)
		var new_cell := after.get_region(region)
		if index in [1,2,3,4,5,6]:
			var lower := Rect2i(20,94,88,22)
			check.call(old_cell.get_region(lower).get_data()!=new_cell.get_region(lower).get_data(),"mullet walk %d replaces the lower-leg drawing" % index)
			check.call(new_cell.get_used_rect().end.y==116,"new mullet walk preserves the sole baseline")
		else:
			check.call(old_cell.get_data()==new_cell.get_data(),"mullet atlas cell %d outside walking is pixel-identical" % index)
