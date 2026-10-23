extends SceneTree
## Only crops/scales whole generated figures. Never paints or assembles anatomy.
const Source = preload("res://tools/diner_adult_atlas_source.gd")
const ROOT := "res://assets/reference/bench-snack-v1/"
var source := Source.new()

func _initialize() -> void:
	var entries: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/sprites.json"))
	var metadata: String = FileAccess.get_file_as_string("res://data/sprites.json")
	var definitions: Dictionary = {
		"kiosk_customer":{"name":"yellow","old":"shopper-diner-style-v2.png","hips":[225,635,1065,1517,200,656,1095,1548],"palms":[[352,235],[759,250],[1200,288],[1622,324],[355,663],[742,618],[1163,620],[1661,733]]},
		"shopper_mullet":{"name":"mullet","old":"shopper-mullet-walk-v2.png","hips":[208,635,1078,1528,190,645,1095,1538],"palms":[[360,231],[802,252],[1245,285],[1660,322],[378,676],[774,620],[1201,620],[1669,714]]},
		"shopper_sundress":{"name":"sundress","old":"shopper-sundress-walk-v2.png","hips":[218,660,1095,1528,190,645,1080,1528],"palms":[[355,240],[800,254],[1258,294],[1650,330],[355,675],[750,627],[1168,627],[1650,733]]}
	}
	for id: String in definitions:
		var definition: Dictionary = definitions[id]
		var image := Image.load_from_file(ProjectSettings.globalize_path(ROOT+str(definition.name)+"-source.png"))
		image.convert(Image.FORMAT_RGBA8)
		var hips: Array = definition.hips
		var frames: Array[Image] = []
		var soles: Array[float] = []
		var sole_adjustments: Array[int] = []
		var scale_factor: float = 0.0
		for row: int in 2:
			var y0: int = roundi(float(row)*image.get_height()/2)
			var y1: int = roundi(float(row+1)*image.get_height()/2)
			var spans: Array[Vector2i] = source._actor_spans(image,y0,y1,4)
			for col: int in 4:
				var region := Rect2i(spans[col].x,y0,spans[col].y-spans[col].x,y1-y0)
				var part := image.get_region(region)
				source.extractor._isolate_actor(part)
				var used := part.get_used_rect()
				if scale_factor == 0:
					scale_factor = 80.0/float(used.size.y)
				soles.append(float(used.end.y+y0))
				part = part.get_region(used)
				part.resize(roundi(part.get_width()*scale_factor),roundi(part.get_height()*scale_factor),Image.INTERPOLATE_NEAREST)
				var canvas := Image.create(128,128,false,Image.FORMAT_RGBA8)
				canvas.fill(Color.TRANSPARENT)
				var hip_x: int = roundi((float(hips[row*4+col])-region.position.x-used.position.x)*scale_factor)
				canvas.blit_rect(part,Rect2i(Vector2i.ZERO,part.get_size()),Vector2i(64-hip_x,116-part.get_height()))
				# Match existing pixel imports: drop alpha fringes, retain opaque ink.
				for y: int in 128:
					for x: int in 128:
						var color: Color = canvas.get_pixel(x,y)
						color.a = 1.0 if color.a >= 0.75 else 0.0
						canvas.set_pixel(x,y,color)
				source.extractor._isolate_actor(canvas)
				var shift: int = 116-canvas.get_used_rect().end.y
				sole_adjustments.append(shift)
				if shift != 0:
					var aligned := Image.create(128,128,false,Image.FORMAT_RGBA8)
					aligned.fill(Color.TRANSPARENT)
					aligned.blit_rect(canvas,Rect2i(0,0,128,128),Vector2i(0,shift))
					canvas = aligned
				frames.append(canvas)
		var entry: Dictionary = entries[id]
		var clips: Dictionary = {"sit_down":[0,1,2,4],"seated_idle":[4],"seated_eat":[4,5,6,7,4],"stand_up":[4,2,1,0]}
		var old := Image.load_from_file(ProjectSettings.globalize_path("res://assets/sprites/"+str(definition.old)))
		old.convert(Image.FORMAT_RGBA8)
		var first: int = old.get_width()/128*old.get_height()/128
		var atlas := Image.create(old.get_width(),old.get_height()+128,false,Image.FORMAT_RGBA8)
		atlas.fill(Color.TRANSPARENT)
		atlas.blit_rect(old,Rect2i(Vector2i.ZERO,old.get_size()),Vector2i.ZERO)
		for i: int in frames.size():
			atlas.blit_rect(frames[i],Rect2i(0,0,128,128),Vector2i(i*128,old.get_height()))
		# Hand points measured on full source; stored in the same world units as existing anchors.
		var palms: Array = definition.palms
		var anchors: Array = []
		for i: int in 8:
			var sole: float = soles[i]
			anchors.append([(float(palms[i][0])-float(hips[i]))*scale_factor*0.5,(float(palms[i][1])-sole)*scale_factor*0.5+sole_adjustments[i]*0.5])
		for clip: String in clips:
			var indices: Array = []
			var hand: Array = []
			for i: int in clips[clip]:
				indices.append(first+i)
				hand.append(anchors[i])
			entry.animations[clip] = {"frames":indices,"fps":8,"loop":clip.begins_with("seated")}
			entry.food_anchors[clip] = hand
		entry.file = "res://assets/sprites/shopper-%s-bench-v1.png" % definition.name
		assert(atlas.save_png(entry.file)==OK)
		entries[id] = entry
		var prefix: String = "  \"%s\": " % id
		var start: int = metadata.find(prefix)+prefix.length()
		var end: int = metadata.find("\n  }",start)+4
		metadata = metadata.substr(0,start)+JSON.stringify(entry,"  ",false).replace("\n","\n  ")+metadata.substr(end)
	FileAccess.open("res://data/sprites.json",FileAccess.WRITE).store_string(metadata)
	print("Prepared full-body bench poses and source-measured hand anchors")
	quit()
