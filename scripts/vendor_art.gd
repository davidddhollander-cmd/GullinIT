class_name VendorArt
extends RefCounted
## Cached full-body sheets; FoodStall clips them only at display time.
static var metadata: Dictionary = {}
static var cache: Dictionary = {}

static func entry(hotdog: bool) -> Dictionary:
	if metadata.is_empty():
		metadata = JSON.parse_string(FileAccess.get_file_as_string("res://data/vendor_art.json"))
	return metadata["hotdog" if hotdog else "ice_cream"]

static func frames(hotdog: bool) -> SpriteFrames:
	var key: String = "hotdog" if hotdog else "ice_cream"
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
