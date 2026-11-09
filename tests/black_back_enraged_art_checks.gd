extends RefCounted
## Tasks 069/075: every enraged clip reuses the normal indices/contact anchors.
const FULL_CLIPS := ["fly","climb","glide","dive_windup","dive","pullup","snatch","peck","landing","stunned","screech"]
static func beak(image: Image) -> Vector2i:
	var right := -1
	var total := 0
	var count := 0
	# Match the packer's integer channel cutoffs exactly; normalized floats can
	# put a byte value on the other side of a threshold through rounding.
	var pixels := image.get_data()
	var width := image.get_width()
	for y: int in image.get_height():
		for x: int in width:
			var offset := (y*width+x)*4
			if pixels[offset+3] < 128 or pixels[offset] <= 160 or pixels[offset+1] <= 100 or pixels[offset+2] >= 130 or pixels[offset] <= pixels[offset+1]:
				continue
			if x > right:
				right = x
				total = 0
				count = 0
			if x == right:
				total += y
				count += 1
	return Vector2i(right,roundi(float(total)/maxi(1,count)))

static func run(check: Callable) -> void:
	var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/gull_art.json"))
	var entry: Dictionary = Config.sprites.gull_great_black_backed
	var frames := Config.frames("gull_great_black_backed")
	var normal := Image.load_from_file(ProjectSettings.globalize_path(entry.file))
	var baseline: int = normal.get_region(Rect2i(0,0,256,256)).get_used_rect().end.y
	for clip: String in ["idle_enraged","walk_enraged"]:
		check.call(entry.animations.has(clip),"black-back registers "+clip)
		if not entry.animations.has(clip):
			continue
		var details: Dictionary = entry.animations[clip]
		var expected := PackedInt32Array([0] if clip == "idle_enraged" else [1,2,3,4,5,6,7,0])
		check.call(details == metadata.gull_great_black_backed.animations[clip],clip+" matches both registries")
		check.call(PackedInt32Array(details.frames) == expected and details.fps == (1 if clip == "idle_enraged" else 8) and details.loop and not details.source_left,clip+" preserves production pose order, timing and direction")
		check.call(frames.get_frame_count(clip) == expected.size() and frames.get_animation_loop(clip) and frames.get_animation_speed(clip) == details.fps,clip+" loads through normal SpriteFrames")
	var seen: Dictionary = {}
	for i: int in 8:
		var clip := "idle_enraged" if i == 0 else "walk_enraged"
		if not frames.has_animation(clip):
			return
		var texture := frames.get_frame_texture(clip,0 if i == 0 else i-1) as AtlasTexture
		check.call(texture.atlas.resource_path == "res://assets/sprites/gull-great-black-backed-enraged-v1.png" and texture.atlas.get_size() == Vector2(1024,1280) and texture.region == Rect2((i%4)*256,(i/4)*256,256,256),"enraged cell %d retains its production index" % i)
		var image := texture.atlas.get_image().get_region(Rect2i(texture.region))
		var reference := normal.get_region(Rect2i((i%4)*256,(i/4)*256,256,256))
		check.call(image.get_used_rect().end.y == baseline,"enraged cell %d feet match normal idle" % i)
		var tip := beak(image)
		var target := beak(reference)
		check.call(tip.x >= 0 and target.x >= 0 and Vector2(tip).distance_to(Vector2(target)) <= 2,"enraged cell %d bill stays within two source pixels" % i)
		seen[hash(image.get_data())] = true
	check.call(seen.size() == 8,"enraged pilot has eight distinct generated poses")
	for path: String in ["assets/reference/gull-great-black-backed-enraged-v1/source.png","assets/reference/gull-great-black-backed-enraged-v1/prompt.txt","assets/previews/gull-great-black-backed-enraged-v1.png","assets/previews/gull-great-black-backed-enraged-v1-walk.gif"]:
		check.call(FileAccess.file_exists("res://"+path),"enraged pilot preserves "+path)
	_check_full(check,metadata,entry,frames,normal)

static func _image(path: String) -> Image:
	return Image.load_from_file(ProjectSettings.globalize_path(path))

static func _cell(image: Image, index: int, columns: int) -> Image:
	return image.get_region(Rect2i((index%columns)*256,(index/columns)*256,256,256))

static func _alignment(check: Callable, actual: Image, normal: Image, grounded: bool, label: String) -> void:
	var tip := beak(actual)
	var target := beak(normal)
	check.call(tip.x >= 0 and target.x >= 0 and Vector2(tip).distance_to(Vector2(target)) <= 2,label+" bill matches normal within two source pixels")
	if grounded:
		check.call(actual.get_used_rect().end.y == normal.get_used_rect().end.y,label+" feet match the normal baseline")

static func _check_full(check: Callable, metadata: Dictionary, entry: Dictionary, frames: SpriteFrames, normal: Image) -> void:
	var prefix := "res://assets/reference/gull-great-black-backed-enraged-v1/"
	var body := _image("res://assets/sprites/gull-great-black-backed-enraged-v1.png")
	var pilot := _image(prefix+"approved-pilot.png")
	check.call(body.get_size() == Vector2i(1024,1280),"full enraged body atlas has twenty production cells")
	check.call(pilot.get_size() == Vector2i(1024,512) and body.get_region(Rect2i(0,0,1024,512)).get_data() == pilot.get_data(),"approved pilot cells 0-7 remain pixel-identical")
	for base: String in FULL_CLIPS:
		var name := base+"_enraged"
		check.call(entry.animations.has(name) and frames.has_animation(name),name+" loads through normal SpriteFrames")
		if not frames.has_animation(name):
			continue
		var actual: Dictionary = entry.animations[name].duplicate(true)
		var expected: Dictionary = entry.animations[base].duplicate(true)
		var file: String = actual.file
		actual.erase("file")
		expected.erase("file")
		check.call(actual == expected and entry.animations[name] == metadata.gull_great_black_backed.animations[name],name+" preserves all normal clip values in both registries")
		check.call(frames.get_frame_count(name) == entry.animations[base].frames.size() and frames.get_animation_speed(name) == entry.animations[base].fps and frames.get_animation_loop(name) == entry.animations[base].loop,name+" preserves runtime count, speed and loop")
		for index: int in frames.get_frame_count(name):
			var texture := frames.get_frame_texture(name,index) as AtlasTexture
			var source: int = int(entry.animations[base].frames[index])
			var columns := 3 if base == "screech" else 4
			check.call(texture.atlas.resource_path == file and texture.region == Rect2((source%columns)*256,(source/columns)*256,256,256),name+" uses the registered generated atlas cell")
	for i: int in range(8,20):
		_alignment(check,_cell(body,i,4),_cell(normal,i,4),i>=17,"enraged body %d" % i)
	var screech := _image("res://assets/sprites/gull-great-black-backed-enraged-screech-v1.png")
	var normal_screech := _image(str(entry.animations.screech.file))
	check.call(screech.get_size() == Vector2i(768,512),"enraged screech packs six cells in the normal layout")
	var seen: Dictionary = {}
	for i: int in 6:
		var image := _cell(screech,i,3)
		_alignment(check,image,_cell(normal_screech,i,3),true,"enraged screech %d" % i)
		seen[hash(image.get_data())] = true
	check.call(seen.size() == 6,"enraged screech has six distinct poses including held peak and recovery")
	_check_carry(check,metadata.gull_great_black_backed)
	# Compare every old value, including normal carry and the approved pilot clips.
	for registry: String in ["gull_art","sprites"]:
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/"+registry+".json"))
		var old: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(prefix+"baseline-"+registry+"-entry.json"))
		var current: Dictionary = data.gull_great_black_backed.duplicate(true)
		for clip: String in FULL_CLIPS:
			current.animations.erase(clip+"_enraged")
		current.erase("carry_enraged")
		check.call(current == old,registry+" preserves every pre-existing black-back value")
	for path: String in ["body-full-source.png","body-full-source-prompt.txt","screech-source.png","screech-source-prompt.txt","carry-walk-source.png","carry-walk-source-prompt.txt","carry-flight-source.png","carry-flight-source-prompt.txt","full-set-packing.json"]:
		check.call(FileAccess.file_exists(prefix+path),"full enraged set preserves "+path)
	for path: String in ["full-body-v1.png","screech-v1.png","carry-v1.png","carry-layering-v1.png","fly-v1.gif","screech-v1.gif","carry-walk-v1.gif"]:
		check.call(FileAccess.file_exists("res://assets/previews/gull-great-black-backed-enraged-"+path),"full enraged preview exists: "+path)

static func _check_carry(check: Callable, entry: Dictionary) -> void:
	check.call(entry.has("carry_enraged"),"enraged carry metadata is registered")
	if not entry.has("carry_enraged"):
		return
	var carry: Dictionary = entry.carry_enraged
	var base: Dictionary = entry.carry.duplicate(true)
	var copy: Dictionary = carry.duplicate(true)
	for key: String in ["file","overlay_file","source"]:
		base.erase(key)
		copy.erase(key)
	check.call(copy == base,"enraged carry retains every normal anchor, sequence and scale")
	var sprites: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/sprites.json"))
	check.call(carry == sprites.gull_great_black_backed.carry_enraged,"both registries describe identical enraged carry layers")
	check.call(FileAccess.file_exists(str(carry.source)),"all thirteen generated carry source cells are preserved")
	var atlas := _image(str(carry.file))
	var upper := _image(str(carry.overlay_file))
	var normal := _image(str(entry.carry.file))
	var normal_upper := _image(str(entry.carry.overlay_file))
	check.call(atlas.get_size() == Vector2i(3328,256) and upper.get_size() == atlas.get_size(),"enraged carry body and upper-beak layers have thirteen aligned cells")
	var body_texture := load(str(carry.file)) as Texture2D
	var beak_texture := load(str(carry.overlay_file)) as Texture2D
	check.call(body_texture != null and beak_texture != null and body_texture.get_size() == Vector2(3328,256) and beak_texture.get_size() == body_texture.get_size(),"enraged carry layers load as production textures")
	var unique: Dictionary = {}
	for i: int in 13:
		var bird := _cell(atlas,i,13)
		var overlay := _cell(upper,i,13)
		_alignment(check,bird,_cell(normal,i,13),i<8,"enraged carry %d" % i)
		var allowed := _cell(normal_upper,i,13).get_used_rect()
		var bounds := overlay.get_used_rect()
		check.call(bounds.has_area() and allowed.encloses(bounds),"carry %d upper bill retains the normal food contact window" % i)
		var pixels := overlay.get_data()
		var body_pixels := bird.get_data()
		var copied := true
		var yellow := false
		for p: int in 256*256:
			var offset := p*4
			if pixels[offset+3] == 0:
				continue
			for channel: int in 4:
				if pixels[offset+channel] != body_pixels[offset+channel]:
					copied = false
			if pixels[offset] > 160 and pixels[offset+1] > 100 and pixels[offset+2] < 130:
				yellow = true
		check.call(copied and yellow,"carry %d upper-mandible pixels come unchanged from the generated bird" % i)
		unique[hash(bird.get_data())] = true
	check.call(unique.size() == 13,"enraged carry has thirteen distinct generated poses")
