class_name FoodStall
extends Node2D
## Complete generated characters behind a local serving-window mask.
## Code draws scenery only; character poses come entirely from image assets.
enum Phase { IDLE, PREPARE, PLACE, COUNTER, RETRACT }
const WINDOW := Rect2(-19,-40,38,23)
const COUNTER_TOP: float = -17.0
const DRAW_DEPTH: int = 2 # Behind foreground buyers, in front of the rear walking lane.
var phase: Phase = Phase.IDLE
var clock: float = 0.0
var progress: float = 0.0
var side: float = 1.0
var hotdog: bool = false
var stall_type: String = "kiosk"
var stand_index: int = -1
var food_texture: Texture2D
var food_size: Vector2
var vendor: AnimatedSprite2D
var window: Control
var prepared_food: Sprite2D

func setup(entry: Dictionary, index: int) -> void:
	z_index = DRAW_DEPTH
	stand_index = index
	position = Vector2(float(entry.x),float(entry.get("y",160)))
	stall_type = str(entry.type)
	hotdog = stall_type=="hotdog_stand"
	side = -1.0 if float(entry.get("customer_x",position.x+48))-position.x<0 else 1.0
	clock = float(index)*1.71
	window = Control.new()
	window.name = "ServingWindow"
	window.position = WINDOW.position
	window.size = WINDOW.size
	window.clip_contents = true
	window.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(window)
	vendor = AnimatedSprite2D.new()
	vendor.name = "FullBodyVendor"
	vendor.sprite_frames = VendorArt.frames(stall_type)
	vendor.animation = &"poses"
	vendor.scale = Vector2.ONE*float(VendorArt.entry(stall_type).visual_scale)
	vendor.position = Vector2(0,float(VendorArt.entry(stall_type).sprite_offset_y))-WINDOW.position
	vendor.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	window.add_child(vendor)
	prepared_food = Sprite2D.new()
	prepared_food.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	prepared_food.hide()
	add_child(prepared_food)
	sync_pose()

func contact_x() -> float:
	return position.x+side*47.0

func counter_food_position() -> Vector2:
	return position+Vector2(side*31.0,COUNTER_TOP-food_size.y*0.5)

func show_food(id: String) -> void:
	food_texture = Config.frames(str(Config.foods[id].sprite)).get_frame_texture(&"idle",0)
	food_size = Vector2(float(Config.foods[id].size[0]),float(Config.foods[id].size[1]))
	prepared_food.texture = food_texture
	prepared_food.scale = food_size/food_texture.get_size()

func advance(delta: float) -> void:
	clock += delta

func sync_pose() -> void:
	var frame: int = 0
	match phase:
		Phase.IDLE:
			frame = 1 if fmod(clock,4.5)>4.3 else 0
		Phase.PREPARE:
			var poses: Dictionary = VendorArt.entry(stall_type).poses
			if progress<0.2:
				frame = int(poses.turn_away)
			elif progress<0.78:
				frame = int(poses.work_a) if int((progress-0.2)*10.0)%2==0 else int(poses.work_b)
			else:
				frame = int(poses.turn_back)
		Phase.PLACE:
			frame = 4 if progress<0.5 else 5
		Phase.COUNTER:
			frame = 6 if progress<0.25 else 7
		Phase.RETRACT:
			frame = 7
	vendor.frame = frame
	vendor.flip_h = side<0
	# Preparation happens behind the vendor; the snack appears only on returning to PLACE.
	prepared_food.visible = food_texture!=null and phase==Phase.PLACE
	if prepared_food.visible:
		var from := Vector2(side*11,-24)
		prepared_food.position = from.lerp(counter_food_position()-position,progress if phase==Phase.PLACE else 0.0)
	queue_redraw()

func _draw() -> void:
	# Environment only. The booth shell retains the complete lower front.
	draw_rect(Rect2(-21,-40,42,26),Color("183b4e"))
	draw_rect(WINDOW,Color("34515a"))
	draw_rect(Rect2(-23,-40,4,26),Color("d59a5e"))
	draw_rect(Rect2(19,-40,4,26),Color("d59a5e"))
	# A real shelf supports the stationary food outside the roof's footprint.
	var left: float = -39.0 if side<0 else -24.0
	draw_rect(Rect2(left,COUNTER_TOP,63,3),Color("a56942"))
	draw_rect(Rect2(left,COUNTER_TOP,63,1),Color("efc181"))
