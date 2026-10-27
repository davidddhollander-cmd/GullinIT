extends RefCounted

const IDS := ["kiosk_customer","shopper_mullet","shopper_sundress"]
const PREVIOUS := {
	"kiosk_customer":"res://assets/sprites/shopper-diner-style-v2-bite-v1.png",
	"shopper_mullet":"res://assets/sprites/shopper-mullet-walk-v2-bite-v1.png",
	"shopper_sundress":"res://assets/sprites/shopper-sundress-walk-v2-bite-v1.png"
}
const SOURCES := {
	"kiosk_customer":"res://assets/reference/shopper-panic-v1/kiosk-customer-panic-source.png",
	"shopper_mullet":"res://assets/reference/shopper-panic-v1/shopper-mullet-panic-source.png",
	"shopper_sundress":"res://assets/reference/shopper-panic-v1/shopper-sundress-panic-source.png"
}

static func run(check: Callable) -> void:
	for id: String in IDS:
		var entry: Dictionary = Config.sprites[id]
		check.call(FileAccess.file_exists(SOURCES[id]),id+" preserves its untouched generated panic source")
		check.call(FileAccess.file_exists(str(entry.file)),id+" registers its packed panic atlas")
		check.call(entry.animations.look_up.frames.size()==2 and is_equal_approx(float(entry.animations.look_up.fps),6.0) and not entry.animations.look_up.loop,id+" has a two-frame non-looping look-up at 6 fps")
		check.call(entry.animations.panic_run.frames.size()==6 and is_equal_approx(float(entry.animations.panic_run.fps),12.0) and entry.animations.panic_run.loop,id+" has a six-frame looping panic run at 12 fps")
		check.call(entry.food_anchors.look_up.size()==2 and entry.food_anchors.panic_run.size()==6,id+" supplies one food anchor per new frame")
		var frames := Config.frames(id)
		check.call(CrowdPanic.resolve(frames,CrowdPanic.LOOK_UP_CLIPS,1.0).clip==&"look_up",id+" gang warning selects the generated look-up clip")
		check.call(CrowdPanic.resolve(frames,CrowdPanic.PANIC_CLIPS,1.0).clip==&"panic_run",id+" gang hit selects the generated panic-run clip")
		var before := Image.load_from_file(ProjectSettings.globalize_path(PREVIOUS[id]))
		var after := Image.load_from_file(ProjectSettings.globalize_path(str(entry.file)))
		before.convert(Image.FORMAT_RGBA8)
		after.convert(Image.FORMAT_RGBA8)
		check.call(after.get_width()==before.get_width() and after.get_height()>=before.get_height(),id+" only extends the existing atlas")
		var legacy_unchanged := true
		for clip: String in entry.animations:
			if clip in ["look_up","panic_run"]:
				continue
			for frame: int in entry.animations[clip].frames:
				var region := Rect2i(frame%8*128,frame/8*128,128,128)
				legacy_unchanged = legacy_unchanged and _visible_pixels_equal(before.get_region(region),after.get_region(region))
		check.call(legacy_unchanged,id+" keeps every visible existing animation frame unchanged")
		for clip: String in ["look_up","panic_run"]:
			for frame: int in entry.animations[clip].frames:
				var cell := after.get_region(Rect2i(frame%8*128,frame/8*128,128,128))
				var bounds := cell.get_used_rect()
				check.call(bounds.has_area() and bounds.size.y==80,id+" "+clip+" frame "+str(frame)+" keeps approved adult pixel density")
				check.call(bounds.end.y==116,id+" "+clip+" frame "+str(frame)+" meets the shared sole baseline")
	check.call(FileAccess.file_exists("res://assets/reference/shopper-panic-v1/prompts.md"),"shopper panic prompts are preserved with the generated sources")
	check.call(FileAccess.file_exists("res://assets/previews/shopper-panic-v1.png"),"shopper panic review preview is present")

static func _visible_pixels_equal(before: Image,after: Image) -> bool:
	if before.get_size()!=after.get_size():
		return false
	for y: int in before.get_height():
		for x: int in before.get_width():
			var a := before.get_pixel(x,y)
			var b := after.get_pixel(x,y)
			if a.a==0.0 and b.a==0.0:
				continue
			if a!=b:
				return false
	return true
