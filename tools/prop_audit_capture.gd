extends Node2D
## Unused-prop audit (docs/PROP_ART_AUDIT.md): candidates beside in-use props and adults, placed by
## the real BeachBackdrop. Saves 1280x720 game renders and 320x180 1x copies to test-output/prop_audit/.
## Run: .tools/Godot_v4.7.2-stable_win64_console.exe --path . --rendering-method gl_compatibility tools/prop_audit_capture.tscn
const OUT: String = "res://test-output/prop_audit/"
const BACKDROP_Y: int = 148
const LITTER_SCALE: float = 0.35 # StashRaids.LITTER_SCALE
const LITTER_IN_USE: Array[String] = ["apple_core","fishbone","paper_ball","can_red","can_blue","bottle_water","styrofoam","wrapper","cardboard"]
const LITTER_NEW: Array[String] = ["banana","bone","bottle_brown","bottle_green","crisps","cup_plain","cup_red","flipflop","sweet","tin"]
# [camera_x, file name, props {type, x, y?, tag}, adults {id, x}]
var panels: Array = [
	[160, "1-ground-props", [["beach_bench",30,160,"use"],["beach_chair_blue",80,160,"use"],["bin",116,160,"use"],
		["beach_chair",196,160,"new"],["beach_boards",236,160,"new"],["beach_sign",286,160,"new"]], [["kiosk_customer",154]]],
	[480, "2-tall-props", [["beach_hut",346,160,"use"],["beach_lamp",388,160,"use"],["beach_palm",424,148,"use"],
		["beach_tower",552,160,"new"],["pier",612,160,"new"]], [["kiosk_customer",470],["lifeguard",500]]],
	[800, "3-backdrop-toys", [["beach_castle",668,160,"use"],["beach_rocks",708,160,"use"],["umbrella",766,160,"use"],
		["beach_ball",805,148,"new"],["beach_bucket",828,148,"new"],["beach_shells",850,148,"new"],
		["beach_lifebuoy_flat",876,148,"new"],["beach_lifebuoy_hung",900,148,"new"],["beach_jet_ski",935,148,"new"]], [["kiosk_customer",742]]],
	[1120, "4-ground-strips", [["kiosk",1000,160,"use"]], [["kiosk_customer",1060],["kiosk_customer",1200]]],
	[1440, "5-litter", [["bin",1300,160,"use"]], [["kiosk_customer",1580]]],
]
var labels: Array = [] # [position, text, colour]
var font: Font = preload("res://assets/fonts/gull_pixel.fnt")

func _ready() -> void:
	Audio.music.stop()
	get_window().size = Vector2i(1280,720)
	var entries: Array = []
	for panel: Array in panels:
		for p: Array in panel[2]:
			var type: String = "tower" if p[0]=="beach_tower" else str(p[0])
			entries.append({"type":type,"x":p[1],"y":p[2]})
			labels.append([Vector2(p[1],24+(entries.size()%3)*9),type.trim_prefix("beach_")+(" *" if p[3]=="new" else ""),Color.YELLOW if p[3]=="new" else Color.WHITE])
	var beach := BeachBackdrop.new()
	add_child(beach)
	beach.setup(entries)
	for panel: Array in panels:
		for a: Array in panel[3]:
			_adult(str(a[0]),float(a[1]))
	_strip("res://assets/sprites/beach-ground-v1/pier-320x22.png",Vector2(960,158),Vector2i(160,22),"pier strip *")
	_strip("res://assets/sprites/beach-ground-v1/promenade-320x14.png",Vector2(1120,160),Vector2i(160,14),"promenade strip *")
	for i: int in LITTER_IN_USE.size():
		_litter(LITTER_IN_USE[i],Vector2(1330+i*14,164))
	for i: int in LITTER_NEW.size():
		_litter(LITTER_NEW[i],Vector2(1330+i*14,175))
	labels.append([Vector2(1390,150),"litter: in use / new *",Color.WHITE])
	var text := Node2D.new()
	text.z_index = 20
	add_child(text)
	text.draw.connect(_draw_labels.bind(text))
	var camera := Camera2D.new()
	add_child(camera)
	camera.make_current()
	call_deferred("capture",beach,camera)

func _adult(id: String, x: float) -> void:
	var e: Dictionary = Config.sprites[id]
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = Config.frames(id)
	sprite.play(&"idle")
	sprite.stop()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE*float(e.get("visual_scale",1.0))
	var height: float = float(e.get("art_height",float(e.frame_h)*float(e.get("visual_scale",1.0))))
	sprite.position = Vector2(x,160.0+float(e.get("sprite_offset_y",-height*0.5)))
	sprite.z_index = 3
	add_child(sprite)
	labels.append([Vector2(x,52),id.trim_prefix("kiosk_").replace("customer","adult"),Color.LIGHT_GREEN])

func _strip(path: String, pos: Vector2, size: Vector2i, text: String) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = load(path)
	sprite.centered = false
	sprite.region_enabled = true
	sprite.region_rect = Rect2(Vector2.ZERO,size)
	sprite.position = pos
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = 1
	add_child(sprite)
	labels.append([pos+Vector2(size.x*0.5,-62),text,Color.YELLOW])

func _litter(kind: String, pos: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/sprites/retro-trash-%s.png" % kind)
	sprite.scale = Vector2.ONE*LITTER_SCALE
	sprite.position = pos
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = 4
	add_child(sprite)

func _draw_labels(canvas: Node2D) -> void:
	for l: Array in labels:
		var w: float = font.get_string_size(l[1],HORIZONTAL_ALIGNMENT_LEFT,-1,8).x
		canvas.draw_string(font,(l[0] as Vector2)-Vector2(w*0.5,0),l[1],HORIZONTAL_ALIGNMENT_LEFT,-1,8,l[2])

func capture(beach: BeachBackdrop, camera: Camera2D) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var sheet := Image.create(640,540,false,Image.FORMAT_RGBA8)
	for i: int in panels.size():
		var cx: float = panels[i][0]
		camera.position = Vector2(cx,90)
		beach.camera_x = cx
		beach.tick(0.0)
		beach.queue_redraw()
		for frame: int in 4:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var image: Image = get_viewport().get_texture().get_image()
		image.save_png(OUT+"%s-1280.png" % panels[i][1])
		image.resize(320,180,Image.INTERPOLATE_NEAREST)
		image.save_png(OUT+"%s-1x.png" % panels[i][1])
		sheet.blit_rect(image,Rect2i(0,0,320,180),Vector2i((i%2)*320,(i/2)*180))
	sheet.resize(1280,1080,Image.INTERPOLATE_NEAREST)
	sheet.save_png(OUT+"overview-1x-at-2x.png")
	print("Prop audit captures saved to ",ProjectSettings.globalize_path(OUT))
	get_tree().quit()
