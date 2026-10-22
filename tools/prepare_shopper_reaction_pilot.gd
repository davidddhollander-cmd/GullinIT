extends SceneTree
## Append generated complete figures to a versioned atlas; preserve both old atlas and source.
const Source = preload("res://tools/diner_adult_atlas_source.gd")
const SOURCE_PATH := "res://assets/reference/shopper-reaction-pilot-v1/shopper-reactions-source.png"
const OLD_ATLAS_PATH := "res://assets/sprites/shopper-diner-style.png"
const OUTPUT_PATH := "res://assets/sprites/shopper-diner-style-v2.png"
const FIRST_NEW_FRAME := 26
var source := Source.new()

func _initialize() -> void:
	var old_atlas := Image.load_from_file(ProjectSettings.globalize_path(OLD_ATLAS_PATH))
	assert(old_atlas != null and old_atlas.get_width() == 1024 and old_atlas.get_height() == 512)
	old_atlas.convert(Image.FORMAT_RGBA8)
	var surprise: Array[Image] = source._row(SOURCE_PATH,0,2,[80,80,80,80,80,80])
	var fist_shake: Array[Image] = source._row(SOURCE_PATH,1,2,[80,80,80,80,80,80])
	var atlas := Image.create(1024,640,false,Image.FORMAT_RGBA8)
	atlas.fill(Color.TRANSPARENT)
	atlas.blit_rect(old_atlas,Rect2i(Vector2i.ZERO,old_atlas.get_size()),Vector2i.ZERO)
	var frames: Array[Image] = []
	frames.append_array(surprise)
	frames.append_array(fist_shake)
	for offset: int in frames.size():
		var frame: Image = frames[offset]
		assert(frame.get_used_rect().has_area(),"Reaction frame cannot be empty")
		assert(frame.get_used_rect().end.y == 116,"Reaction feet must share the adult baseline")
		var index: int = FIRST_NEW_FRAME+offset
		atlas.blit_rect(frame,Rect2i(0,0,128,128),Vector2i(index%8*128,index/8*128))
	assert(atlas.save_png(OUTPUT_PATH) == OK)
	quit()
