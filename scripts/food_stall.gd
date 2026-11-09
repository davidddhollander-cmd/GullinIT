class_name FoodStall
extends Node2D
## Complete generated characters behind a local serving-window mask.
## Code draws scenery only; character poses come entirely from image assets.
enum Phase { IDLE, PREPARE, PLACE, COUNTER, RETRACT }
const WINDOW := Rect2(-19,-40,38,23)
const COUNTER_TOP: float = -17.0
const COUNTER_FOOD_X: float = 28.0
const COUNTER_REACH: float = 32.0 ## shelf sticks out this far each side of the centre
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
var ducked: bool = false ## Shakedown raid: the vendor sinks out of sight inside the mask
var duck: float = 0.0 ## 0 up, 1 hidden
var vendor_home_y: float = 0.0
var home_x: float = 0.0
var shake_left: float = 0.0 ## Shakedown raid rattle
var marker_layer: Node2D
var marked: bool = false ## Shakedown: gold corners on the counter window while raids remain

func setup(entry: Dictionary, index: int) -> void:
	z_index = DRAW_DEPTH
	stand_index = index
	position = Vector2(float(entry.x),float(entry.get("y",160)))
	home_x = position.x
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
	vendor_home_y = vendor.position.y
	prepared_food = Sprite2D.new()
	prepared_food.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	prepared_food.hide()
	add_child(prepared_food)
	marker_layer = Node2D.new()
	marker_layer.draw.connect(_draw_marker)
	add_child(marker_layer)
	sync_pose()

## An idle stand serves whichever side the buyer arrives on; the vendor turns to match.
func face(buyer_x: float) -> void:
	if phase == Phase.IDLE and not is_zero_approx(buyer_x-position.x):
		side = signf(buyer_x-position.x)
		sync_pose()

func contact_x() -> float:
	return position.x+side*47.0

func counter_food_position() -> Vector2:
	return position+Vector2(side*COUNTER_FOOD_X,COUNTER_TOP-food_size.y*0.5)

func show_food(id: String) -> void:
	food_texture = Config.frames(str(Config.foods[id].sprite)).get_frame_texture(&"idle",0)
	food_size = Vector2(float(Config.foods[id].size[0]),float(Config.foods[id].size[1]))
	prepared_food.texture = food_texture
	prepared_food.scale = food_size/food_texture.get_size()

func advance(delta: float) -> void:
	clock += delta
	if shake_left > 0.0:
		var t: Dictionary = Config.tuning.shakedown
		shake_left = maxf(0.0,shake_left-delta)
		position.x = home_x+sin(clock*80.0)*float(t.raid_shake)*shake_left/float(t.raid_shake_time)
	if marked:
		marker_layer.queue_redraw() # the corners pulse
	var goal: float = 1.0 if ducked else 0.0
	if duck != goal:
		duck = move_toward(duck,goal,delta/float(Config.tuning.shakedown.duck_time))
		vendor.position.y = vendor_home_y+duck*float(Config.tuning.shakedown.duck_depth)

func set_marker(on: bool) -> void:
	if on != marked:
		marked = on
		marker_layer.queue_redraw()

func rattle() -> void:
	shake_left = float(Config.tuning.shakedown.raid_shake_time)

func snap_duck() -> void:
	shake_left = 0.0
	position.x = home_x
	duck = 1.0 if ducked else 0.0
	vendor.position.y = vendor_home_y+duck*float(Config.tuning.shakedown.duck_depth)

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
	draw_rect(Rect2(-COUNTER_REACH,COUNTER_TOP,COUNTER_REACH*2.0,3),Color("a56942"))
	draw_rect(Rect2(-COUNTER_REACH,COUNTER_TOP,COUNTER_REACH*2.0,1),Color("efc181"))

## Drawn on its own child so the corners sit in front of the vendor.
func _draw_marker() -> void:
	if marked:
		var radius: Array = Config.tuning.shakedown.marker_radius
		PickupShine.draw_target_corners(marker_layer,Vector2(0,-28),Vector2(float(radius[0]),float(radius[1])),true)
