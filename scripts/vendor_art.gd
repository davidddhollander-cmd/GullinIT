class_name VendorArt
extends RefCounted
## Cached full-body sheets; FoodStall clips them only at display time.
static var metadata: Dictionary = {}
static var cache: Dictionary = {}

## kind: a stand type string, or a bool (true = hotdog, false = ice cream).
static func key_for(kind: Variant) -> String:
	match kind:
		"hotdog_stand", true: return "hotdog"
		"fish_chips_stand": return "vendor_fish_chips"
	return "ice_cream"

static func entry(hotdog: Variant) -> Dictionary:
	if metadata.is_empty():
		metadata = JSON.parse_string(FileAccess.get_file_as_string("res://data/vendor_art.json"))
	return metadata[key_for(hotdog)]

static func frames(hotdog: Variant) -> SpriteFrames:
	var key: String = key_for(hotdog)
	if cache.has(key):
		return cache[key]
	var definition: Dictionary = entry(hotdog)
	var texture: Texture2D = load(str(definition.file))
	var result := SpriteFrames.new()
	result.rename_animation(&"default",&"poses")
	for index: int in int(definition.frames):
		var frame := AtlasTexture.new()
		frame.atlas = texture
		frame.region = Rect2(index*int(definition.frame_w),0,int(definition.frame_w),int(definition.frame_h))
		frame.filter_clip = true
		result.add_frame(&"poses",frame)
	cache[key] = result
	return result
