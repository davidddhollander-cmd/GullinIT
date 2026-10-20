class_name BeachBackdrop
extends Node2D
var camera_x: float = 160.0
var time: float = 0.0
var wind_dir: int = 1
var strength: float = 0.3
var sunset: bool = false
var props: Array[Dictionary] = []
var zones: Array = []
var world: Dictionary = {}
var prop_sprites: Array[AnimatedSprite2D] = []
var stalls: Array[FoodStall] = []
var palm_materials: Array[ShaderMaterial] = []
const BIN_WOBBLE_TIME: float = 0.26
const BIN_WOBBLE_ANGLE: float = 0.095
const WHEELIE_BIN_TYPE: String = "wheelie_bin"
const WHEELIE_BIN_LID_INSET: float = 8.0
const WHEELIE_BIN_HALF_WIDTH: float = 12.0
const BIN_TYPES: Array[String] = ["bin", WHEELIE_BIN_TYPE]
const SIGN_TOP: int = 84
const SIGN_HEIGHT: int = 11
var bin_wobble: Array[float] = []
var bin_wobble_duration: Array[float] = []
var bin_wobble_strength: Array[float] = []
var bin_release_bounce: Array[bool] = []
var bin_full: Array[bool] = []
var bin_glints: Array[Sprite2D] = []
var font: Font = preload("res://assets/fonts/gull_pixel.fnt")

func setup(entries: Array, zone_entries: Array = [], world_settings: Dictionary = {}) -> void:
	zones = zone_entries.duplicate(true)
	world = world_settings.duplicate(true)
	for entry: Dictionary in entries:
		props.append(entry)
		bin_wobble.append(0.0)
		bin_wobble_duration.append(BIN_WOBBLE_TIME)
		bin_wobble_strength.append(BIN_WOBBLE_ANGLE)
		bin_release_bounce.append(false)
		bin_full.append(true)
		bin_glints.append(null)
		var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
		sprite.sprite_frames = Config.frames(entry.type)
		sprite.play(&"idle")
		sprite.position = Vector2(entry.x, 160 - float(Config.sprites[entry.type].frame_h) * 0.5)
		if entry.type == "umbrella":
			sprite.position.y = 125
		add_child(sprite)
		prop_sprites.append(sprite)
		_apply_prop_art(sprite,entry)
		if is_bin_type(str(entry.type)):
			# The glint is a child so it rotates and bounces with the wobbling bin.
			var glint: Sprite2D = Sprite2D.new()
			glint.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			glint.visible = false
			sprite.add_child(glint)
			bin_glints[bin_glints.size()-1] = glint
		if entry.type in ["kiosk","hotdog_stand"]:
			var stall := FoodStall.new()
			add_child(stall)
			stall.setup(entry,props.size()-1)
			stalls.append(stall)
			var sign_node: Node2D = preload("res://scripts/stand_sign.gd").new()
			sign_node.hotdog = entry.type == "hotdog_stand"
			sign_node.z_index = FoodStall.DRAW_DEPTH
			sign_node.position = Vector2(entry.x,float(entry.get("y",160))-11)
			add_child(sign_node)
	_update_palm_wind()
	Config.reloaded.connect(_refresh)

func _apply_prop_art(sprite: AnimatedSprite2D, entry: Dictionary) -> void:
	if entry.type in ["kiosk","hotdog_stand"]:
		sprite.z_index = FoodStall.DRAW_DEPTH
	var definition: Dictionary = Config.sprites[entry.type]
	var scale_factor: float = float(definition.get("visual_scale",1.0))
	sprite.scale = Vector2.ONE * scale_factor
	sprite.position = Vector2(entry.x,float(entry.get("y",160))-float(definition.frame_h)*scale_factor*0.5)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.material = null
	if entry.type == "beach_palm":
		var leaves := ShaderMaterial.new()
		leaves.shader = preload("res://assets/shaders/palm_leaf_sway.gdshader")
		# The palm frame covers its entire 44 x 62 texture, so the shader can
		# sample its transparent border directly, just like the approved pilot.
		leaves.set_shader_parameter("phase",fposmod(float(entry.x)*0.037,TAU))
		sprite.material = leaves
		palm_materials.append(leaves)
	if entry.type == WHEELIE_BIN_TYPE:
		var sharpen := ShaderMaterial.new()
		sharpen.shader = preload("res://assets/shaders/bin_pixel_sharpen.gdshader")
		sprite.material = sharpen
	if entry.type == "umbrella":
		sprite.position.y = 125

func _refresh() -> void:
	palm_materials.clear()
	for i: int in props.size():
		prop_sprites[i].sprite_frames = Config.frames(props[i].type)
		prop_sprites[i].play(&"idle")
		_apply_prop_art(prop_sprites[i],props[i])
	_update_palm_wind()

func _update_palm_wind() -> void:
	# Gameplay already smooths this wind through the gull's actual wind force.
	# Feeding the beach clock also freezes the leaves during pause and results.
	for leaves: ShaderMaterial in palm_materials:
		leaves.set_shader_parameter("wind_strength",strength)
		leaves.set_shader_parameter("wind_direction",float(wind_dir))
		leaves.set_shader_parameter("preview_time",time)

static func is_bin_type(type: String) -> bool:
	return type in BIN_TYPES

static func bin_content_y(prop: Dictionary) -> float:
	var base_y: float = float(prop.get("y",Config.tuning.world.ground))
	if str(prop.type) != WHEELIE_BIN_TYPE:
		return base_y-18.0
	var definition: Dictionary = Config.sprites[WHEELIE_BIN_TYPE]
	return base_y-(float(definition.frame_h)-WHEELIE_BIN_LID_INSET)*float(definition.get("visual_scale",1.0))

func wobble_bin(x: float, progress: float = 0.0, released: bool = false) -> void:
	for i: int in props.size():
		if is_bin_type(str(props[i].type)) and absf(float(props[i].x)-x) < 0.1:
			bin_wobble_duration[i] = 0.36 if released else BIN_WOBBLE_TIME
			bin_wobble[i] = bin_wobble_duration[i]
			bin_wobble_strength[i] = BIN_WOBBLE_ANGLE + 0.035 * clampf(progress,0.0,1.0)
			bin_release_bounce[i] = released
			return

func set_bin_full(x: float, full: bool) -> void:
	for i: int in props.size():
		if is_bin_type(str(props[i].type)) and absf(float(props[i].x)-x) < 0.1:
			bin_full[i] = full

func tick(delta: float) -> void:
	time += delta
	_update_palm_wind()
	for i: int in props.size():
		if is_instance_valid(bin_glints[i]):
			var glint: Texture2D = PickupShine.overlay(Config.frames(str(props[i].type)).get_frame_texture(&"idle",0),time,float(props[i].x)*0.37) if bin_full[i] else null
			bin_glints[i].texture = glint
			bin_glints[i].visible = glint != null
	for i: int in props.size():
		if not is_bin_type(str(props[i].type)) or bin_wobble[i] <= 0.0:
			continue
		bin_wobble[i] = maxf(0.0,bin_wobble[i]-delta)
		var progress: float = 1.0-bin_wobble[i]/bin_wobble_duration[i]
		var angle: float = sin(progress*TAU*2.0)*bin_wobble_strength[i]*(1.0-progress)
		var sprite: AnimatedSprite2D = prop_sprites[i]
		var definition: Dictionary = Config.sprites[str(props[i].type)]
		var scale_factor: float = float(definition.get("visual_scale",1.0))
		# The foot pivot is measured from the sprite center, so replacement art only changes this offset.
		var pivot: Vector2 = Vector2(0.0,float(props[i].get("wobble_pivot_y",float(definition.frame_h)*scale_factor*0.5-2.0)))
		var base: Vector2 = Vector2(float(props[i].x),float(props[i].get("y",160))-float(definition.frame_h)*scale_factor*0.5)
		sprite.rotation = angle
		var bounce_y: float = -3.0*sin(PI*progress) if bin_release_bounce[i] else 0.0
		sprite.position = base+pivot-pivot.rotated(angle)+Vector2(0,bounce_y)
	queue_redraw()

func _draw() -> void:
	var left: float = camera_x - 160
	draw_rect(Rect2(left-4,0,328,96), Color("edb98b") if sunset else Color("a9d7d2"))
	draw_rect(Rect2(left-4,65,328,31), Color("f4cf9f") if sunset else Color("c8e4ce"))
	draw_circle(Vector2(left+250,43), 18, Color("fff1bb"))
	for i: int in range(8):
		var cx: float = fposmod(i * 87.0 - camera_x * 0.1 + time * (1 + strength * 2) * wind_dir, 380) + left - 30
		draw_rect(Rect2(cx,25+(i%3)*12,29,5),Color("edf1d6"))
		draw_rect(Rect2(cx+7,21+(i%3)*12,16,5),Color("edf1d6"))
	draw_rect(Rect2(left-4,94,328,36),Color("408fa8"))
	draw_rect(Rect2(left-4,103,328,29),Color("56b7ae"))
	for i: int in range(35):
		var wx: float = fposmod(i * 31 - camera_x * 0.3 + time * 4, 360) + left - 20
		draw_rect(Rect2(wx,98+(i%5)*6,8+(i%3)*5,1),Color("b7dfce"))
	var width: float = float(world.get("width",Config.tuning.world.width))
	var promenade: float = float(world.get("promenade_start",Config.tuning.world.promenade_start))
	var pier: float = float(world.get("pier_start",Config.tuning.world.pier_start))
	draw_rect(Rect2(0,130,width,50),Color("e8c58e"))
	draw_rect(Rect2(0,130,width,3),Color("fff1cc"))
	draw_rect(Rect2(promenade,151,pier-promenade,14),Color("c18e68"))
	for x: int in range(int(promenade),int(pier),16):
		draw_line(Vector2(x,151),Vector2(x,165),Color("a57b5c"))
	draw_rect(Rect2(pier,158,width-pier,5),Color("9b6650"))
	draw_rect(Rect2(pier,157,width-pier,2),Color("efb984"))
	for i: int in range(int(width/6)):
		var x: float = fposmod(i*71.0,width)
		var y: float = 137+(i*13)%42
		draw_rect(Rect2(x,y,2,1),Color("d4ad78"))
	for sign: Dictionary in sign_layouts():
		var board: Rect2 = sign.rect
		if board.position.x < 0:
			continue
		var post_x: int = int(board.position.x) + int(board.size.x / 2) - 1
		draw_rect(Rect2(post_x,board.end.y,2,134-board.end.y),Color("9b6650"))
		draw_rect(board,Color("fff4da"))
		draw_rect(Rect2(board.position,Vector2(board.size.x,1)),Color("9b6650"))
		draw_string(font,board.position+Vector2(2,9),sign.name,HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("183b4e"))
	for entry: Dictionary in props:
		if entry.type in ["tower", "kiosk", "hotdog_stand"]:
			var top: int = 103 if entry.type == "tower" else 110
			_draw_flagpole(roundi(float(entry.x)) + 12, top, Color("ef725c") if entry.type != "kiosk" else Color("408fa8"))
	if strength > 0.5:
		for i: int in range(20):
			var x: float = left + fposmod(i * 37 + time * strength * wind_dir * 70,320)
			draw_line(Vector2(x,149+i%24),Vector2(x+wind_dir*4,149+i%24),Color("fff1cc"))

func sign_zones() -> Array:
	if not zones.is_empty():
		return zones
	var width: float = float(world.get("width",Config.tuning.world.width))
	var promenade: float = float(world.get("promenade_start",Config.tuning.world.promenade_start))
	var pier: float = float(world.get("pier_start",Config.tuning.world.pier_start))
	return [{"name":"SUNBATHERS","from":0,"to":320},{"name":"FAMILY BAY","from":320,"to":promenade},{"name":"PROMENADE","from":promenade,"to":pier},{"name":"THE PIER","from":pier,"to":width}]

func sign_layouts() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var width: int = roundi(float(world.get("width",Config.tuning.world.width)))
	for zone: Dictionary in sign_zones():
		var board_width: int = ceili(font.get_string_size(str(zone.name),HORIZONTAL_ALIGNMENT_LEFT,-1,8).x)+4
		var min_x: int = maxi(0,int(zone.from)+4)
		var max_x: int = mini(int(zone.to),width)-board_width-4
		var desired: int = clampi(int(zone.from)+28,min_x,maxi(min_x,max_x))
		var chosen: int = -1
		if max_x >= min_x:
			for x: int in range(desired,max_x+1):
				if not _sign_hits_prop(x,board_width,props):
					chosen = x
					break
			if chosen < 0:
				for x: int in range(desired-1,min_x-1,-1):
					if not _sign_hits_prop(x,board_width,props):
						chosen = x
						break
		result.append({"name":zone.name,"zone":zone,"rect":Rect2(chosen,SIGN_TOP,board_width,SIGN_HEIGHT),"shift":chosen-int(zone.from)-28})
	return result
func _sign_hits_prop(x: int,board_width: int,entries: Array) -> bool:
	# Compare the readable board against full scaled sprite bounds and decorative flags.
	var sign_rect: Rect2 = Rect2(x,SIGN_TOP,board_width,SIGN_HEIGHT)
	for entry: Dictionary in entries:
		if not Config.sprites.has(entry.type):
			continue
		var sprite: Dictionary = Config.sprites[entry.type]
		var scale_factor: float = float(sprite.get("visual_scale",1.0))
		var prop_y: float = float(entry.get("y",160))
		if entry.type == "umbrella":
			prop_y = 125.0 + float(sprite.frame_h)*scale_factor*0.5
		var prop_rect: Rect2 = Rect2(float(entry.x)-float(sprite.frame_w)*scale_factor*0.5,prop_y-float(sprite.frame_h)*scale_factor,float(sprite.frame_w)*scale_factor,float(sprite.frame_h)*scale_factor)
		if entry.type in ["tower","kiosk","hotdog_stand"]:
			var flag_top: int = 85 if entry.type == "tower" else 92
			if sign_rect.intersects(Rect2(float(entry.x)-5,flag_top,37,25)):
				return true
		if sign_rect.intersects(prop_rect):
			return true
	return false

func _draw_flagpole(x: int, top: int, accent: Color) -> void:
	# Three stepped flutter poses; all coordinates stay on the native pixel grid.
	draw_rect(Rect2(x - 1, top - 16, 4, 25), Color("183b4e"))
	draw_rect(Rect2(x, top - 15, 2, 22), Color("d59a5e"))
	draw_rect(Rect2(x - 2, top - 18, 5, 3), Color("fff4da"))
	var flutter: int = int(floor(time * 7.0)) % 3
	var reach: int = 7 + flutter * 2 + roundi(strength * 3.0)
	var start_x: int = x + 3 if wind_dir >= 0 else x - reach
	for row: int in 6:
		var width: int = reach - (row / 2) * 2
		var row_x: int = start_x + (row / 2 if wind_dir >= 0 else reach - width - row / 2)
		draw_rect(Rect2(row_x, top - 15 + row, width, 1), Color("183b4e") if row in [0, 5] else (accent if row < 3 else Color("fff4da")))
