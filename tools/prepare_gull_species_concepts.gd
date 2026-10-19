extends SceneTree
## Prepare the concept silhouettes at a shared proposed game pixel scale.
const ROOT := "res://assets/reference/gull-species-v1/"
const OUT := "res://assets/pilots/gull-species-v1/"
var source = preload("res://tools/diner_adult_atlas_source.gd").new()

func _initialize() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT+"concepts.json"))
	var settings := {"herring":[44,76],"kittiwake":[34,60],"great-black-backed":[56,96]}
	for item: Dictionary in manifest.concepts:
		var image := source._read(ROOT+item.id+"-source.png")
		var spans: Array[Vector2i] = source._actor_spans(image,0,image.get_height(),2)
		for pose: int in 2:
			var span := spans[pose]
			var rect := Rect2i(span.x,0,span.y-span.x,image.get_height())
			var part := image.get_region(rect)
			for y: int in part.get_height():
				for x: int in part.get_width():
					if part.get_pixel(x,y).a < 0.75:
						part.set_pixel(x,y,Color(0,0,0,0))
			source.extractor._isolate_actor(part)
			var bounds := part.get_used_rect()
			assert(bounds.has_area(),"Empty gull concept")
			var detail := part.get_region(bounds)
			assert(detail.save_png(OUT+item.id+("-stand-detail.png" if pose==0 else "-fly-detail.png"))==OK)
			var height: int = settings[item.species][0] if pose==0 else roundi(float(settings[item.species][1])*bounds.size.y/bounds.size.x)
			var frame := source._cut(image,rect,height)
			source.extractor._isolate_actor(frame)
			frame = frame.get_region(frame.get_used_rect())
			for y: int in frame.get_height():
				for x: int in frame.get_width():
					if frame.get_pixel(x,y).a==0:
						frame.set_pixel(x,y,Color(0,0,0,0))
			assert(frame.save_png(OUT+item.id+("-stand.png" if pose==0 else "-fly.png"))==OK)
			print(item.id," ",pose," ",frame.get_size())
	quit()
