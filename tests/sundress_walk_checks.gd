extends RefCounted

static func run(check: Callable) -> void:
	var current: Dictionary = Config.sprites.shopper_sundress
	var previous: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/reference/sundress-walk-v2/previous-entry.json"))
	check.call(current.file=="res://assets/sprites/shopper-sundress-walk-v2.png","sundress selects the new generated walk atlas")
	var expected: Dictionary = previous.duplicate(true)
	expected.file = current.file
	expected.food_anchors.walk = current.food_anchors.walk
	check.call(current==expected,"only sundress atlas and walking food anchors change")
	var frames := Config.frames("shopper_sundress")
	check.call(frames.get_frame_count(&"walk")==6 and is_equal_approx(frames.get_animation_speed(&"walk"),8.0),"sundress retains approved six-frame walking timing")
	var before := Image.load_from_file(ProjectSettings.globalize_path(previous.file))
	var after := Image.load_from_file(ProjectSettings.globalize_path(current.file))
	before.convert(Image.FORMAT_RGBA8)
	after.convert(Image.FORMAT_RGBA8)
	check.call(before.get_size()==after.get_size(),"sundress atlas retains its existing canvas")
	for index: int in 32:
		var region := Rect2i(index%8*128,index/8*128,128,128)
		var old_cell := before.get_region(region)
		var new_cell := after.get_region(region)
		if index in [1,2,3,4,5,6]:
			var lower := Rect2i(20,94,88,22)
			check.call(old_cell.get_region(lower).get_data()!=new_cell.get_region(lower).get_data(),"sundress walk %d replaces the lower-leg drawing" % index)
			check.call(new_cell.get_used_rect().end.y==116,"new sundress walk preserves the sole baseline")
		else:
			check.call(old_cell.get_data()==new_cell.get_data(),"sundress atlas cell %d outside walking is pixel-identical" % index)
