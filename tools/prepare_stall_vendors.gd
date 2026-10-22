extends SceneTree
## Import preparation only: crops/resizes ImageGen artwork, never paints actors.
const CELL := 128
const SOLE := 116
const SOURCE := "res://assets/reference/stall-vendors-v3/"

func _initialize() -> void:
	var entries: Dictionary = {}
	for id: String in ["ice_cream","hotdog"]:
		var stem: String = id.replace("_","-")
		var source_path: String = SOURCE+stem+"-turn-source.png"
		var sheet := Image.load_from_file(ProjectSettings.globalize_path(source_path))
		assert(sheet != null,"Missing generated vendor source: "+source_path)
		sheet.convert(Image.FORMAT_RGBA8)
		var frames: Array[Image] = []
		var cell_size := Vector2i(sheet.get_width()/2,sheet.get_height()/2)
		for index: int in 4:
			var part := sheet.get_region(Rect2i(Vector2i(index%2,index/2)*cell_size,cell_size))
			for y: int in part.get_height():
				for x: int in part.get_width():
					var color: Color = part.get_pixel(x,y)
					if color.a>=0.75:
						color.a = 1.0
					else:
						color = Color.TRANSPARENT
					part.set_pixel(x,y,color)
			frames.append(part)
		var base_path: String = "res://assets/sprites/vendor-%s-full-body-v2.png" % stem
		var base := Image.load_from_file(ProjectSettings.globalize_path(base_path))
		assert(base != null,"Missing original vendor atlas")
		var atlas := Image.create(12*CELL,CELL,false,Image.FORMAT_RGBA8)
		# Preserve all eight approved poses pixel-for-pixel; append new generated poses.
		atlas.blit_rect(base,Rect2i(0,0,8*CELL,CELL),Vector2i.ZERO)
		for index: int in frames.size():
			var frame: Image = frames[index]
			var bounds: Rect2i = frame.get_used_rect()
			assert(bounds.has_area(),"Empty vendor cell")
			var scale_factor: float = 80.0/float(bounds.size.y)
			var foot_left: int = frame.get_width()
			var foot_right: int = 0
			for y: int in range(bounds.end.y-maxi(1,roundi(bounds.size.y*0.09)),bounds.end.y):
				for x: int in range(bounds.position.x,bounds.end.x):
					if frame.get_pixel(x,y).a>0.5:
						foot_left = mini(foot_left,x)
						foot_right = maxi(foot_right,x)
			var shoe_centre: float = (foot_left+foot_right)*0.5
			var cropped := frame.get_region(bounds)
			var size := Vector2i(roundi(bounds.size.x*scale_factor),roundi(bounds.size.y*scale_factor))
			cropped.resize(size.x,size.y,Image.INTERPOLATE_NEAREST)
			var offset := Vector2i(64-roundi((shoe_centre-bounds.position.x)*scale_factor),SOLE-size.y)
			assert(Rect2i(0,0,CELL,CELL).encloses(Rect2i(offset,size)),"Vendor does not fit source cell")
			atlas.blit_rect(cropped,Rect2i(Vector2i.ZERO,size),Vector2i((index+8)*CELL,0)+offset)
		var target_path: String = "res://assets/sprites/vendor-%s-full-body-v3.png" % stem
		assert(atlas.save_png(target_path)==OK)
		entries[id] = {"file":target_path,"source":source_path,"base_source":"res://assets/reference/stall-vendors-v2/"+stem+"-full-body-source.png","base_atlas":base_path,"frame_w":CELL,"frame_h":CELL,"frames":12,"visual_scale":0.5,"art_height":40,"sole":SOLE,"sprite_offset_y":-26,"poses":{"turn_away":8,"work_a":9,"work_b":10,"turn_back":11}}
	FileAccess.open("res://data/vendor_art.json",FileAccess.WRITE).store_string(JSON.stringify(entries,"  ",false)+"\n")
	print("Prepared two 12-pose full-body vendor atlases from ChatGPT artwork")
	quit()
