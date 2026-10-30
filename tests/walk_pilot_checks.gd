extends SceneTree
const Motion = preload("res://tools/walk_pilot_motion.gd")
const Rig = preload("res://tools/walk_pilot_rig.gd")
var checks: int = 0
var failures: int = 0

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(label)

func _initialize() -> void:
	var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/archive/pilots/shopper-walk-v1/walk.json"))
	var atlas := Image.load_from_file(ProjectSettings.globalize_path(metadata.file))
	atlas.convert(Image.FORMAT_RGBA8)
	check(atlas.get_size()==Vector2i(512,256),"Eight full 128-pixel review cells")
	var unique: Dictionary = {}
	for index: int in 8:
		var cell := atlas.get_region(Rect2i(index%4*128,index/4*128,128,128))
		var bounds := cell.get_used_rect()
		check(bounds.end.y==116 and bounds.position.x>=2 and bounds.end.x<=126,"Unclipped full-body frame with grounded support sole")
		check(bounds.size.y>=77 and bounds.size.y<=83,"Stable adult size")
		var bytes := cell.get_data()
		var hard_alpha := true
		for alpha: int in range(3,bytes.size(),4):
			if bytes[alpha]!=0 and bytes[alpha]!=255:
				hard_alpha = false
		check(hard_alpha,"Crisp transparent/opaque edges")
		unique[bytes.hex_encode().sha256_text()] = true
		var palm: Array = metadata.frames[index].palm
		var pixel := Vector2i(roundi(float(palm[0])*2+64),roundi((float(palm[1])+26)*2+64))
		check(cell.get_pixelv(pixel).a>0.99,"Carrying anchor touches drawn hand")
	check(unique.size()==8,"Eight distinct generated pose images")
	var reference_phase: float = -1
	for hz: int in [30,60,120]:
		var motion := Motion.new()
		motion.stride = float(metadata.stride_pixels)
		for frame: int in hz*2:
			motion.advance_distance(20.0/hz)
		if reference_phase<0:
			reference_phase = motion.phase
		check(is_equal_approx(motion.phase,reference_phase),"Travel-based gait is stable across frame rates")
		var reverse := Motion.new()
		reverse.stride = motion.stride
		reverse.advance_distance(-40)
		check(is_equal_approx(reverse.phase,motion.phase),"Leftward travel preserves the same cadence")
		var held: float = motion.phase
		motion.advance_distance(0)
		check(is_equal_approx(motion.phase,held),"Paused movement cannot advance gait")
		check(motion.plant() in [0,4],"Stopping uses a contact pose")
	var rig: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/archive/pilots/shopper-walk-v1/rig.json"))
	check(rig.parts.size()==6,"Six complete generated leg pieces")
	for speed: float in [9.0,20.0]:
		for hz: int in [30,60,120]:
			for frame: int in int(14.0/speed*hz):
				var distance: float = speed*frame/hz
				var foot: Vector2 = Rig.foot_position(distance/28,float(rig.ankle_height))
				check(absf(distance+foot.x-7)<0.001,"Planted supporting foot stays fixed in world space")
				check(is_equal_approx(foot.y,-float(rig.ankle_height)),"Supporting foot stays on its ground plane")
	for frame: int in 120:
		var phase: float = float(frame)/120
		var hip := Vector2(2,-13.5+cos(phase*TAU*2)*0.5)
		var ankle: Vector2 = Rig.foot_position(phase,float(rig.ankle_height))
		var knee: Vector2 = Rig.knee_position(hip,ankle)
		check(absf(hip.distance_to(knee)-7)<0.001 and absf(knee.distance_to(ankle)-7)<0.001,"Generated thigh/calf keep constant bone lengths")
	check(Rig.foot_position(0,4).x>0 and Rig.foot_position(0.5,4).x<0,"The same near leg exchanges front and rear contacts")
	check(Rig.foot_position(0.75,4).y<=-8,"Swing foot visibly lifts during passing")
	print("WALK PILOT: ",checks," checks, ",failures," failures")
	quit(1 if failures>0 else 0)
