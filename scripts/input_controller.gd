class_name GullInput
extends Node
var game: BeachGame ## set by the game; supplies targets for touch aim assist
var stick_pos: Vector2 = FLY_STICK_CENTER ## current stick finger (logical px)
var touch_active: bool = false ## touch is the aim source until real mouse motion or a gamepad takes over
var touch_down: Dictionary = {} ## every finger currently on screen
var touch_last_msec: int = -1000000
var touch_climb: bool = false ## the FLY stick points up: climbing, same as holding FLAP
var flap_tap: bool = false ## a flap press latched in _input, handed to the gull by update_player
var touch_dive: bool = false
var touch_peck: bool = false
var peck_held: bool = false ## the PECK button is down; a hold screeches
const NO_FINGER: int = -(1 << 40) ## iOS touch indices are large negatives, so -1/0 cannot mean "no finger"
var peck_finger: int = NO_FINGER
var touch_slowmo: bool = false
var slowmo_ready: bool = false ## set by the game; the touch button only exists while true
var aim_finger: int = NO_FINGER
var dive_finger: int = NO_FINGER ## finger on the right-thumb dive stick
var dive_pos: Vector2 = DIVE_STICK_CENTER
var dive_down_msec: int = 0 ## when the dive finger landed, to tell a tap from a drag
var dive_held: bool = false ## the dive stick was pushed past its deadzone and owns the aim until released
var gamepad: bool = false ## last device used was a pad; prompts show pad buttons
var key_aim: bool = false ## WASD/arrows steer like a stick until the mouse or a touch takes over
const PAD_DEADZONE: float = 0.3 ## stick drift below this never claims the prompts
var touch_visible: bool = false
var enabled: bool = false
# Touch layout (logical 320x180 coordinates). Left thumb: the FLY ring rests bottom-left and any
# touch left of FLY_ZONE_MAX_X grabs it. Right thumb: the fixed DIVE circle bottom-right, PECK just
# above it, SLOW-MO left of PECK. The overlay draws these same rects and circles.
const FLY_STICK_CENTER: Vector2 = Vector2(38,140) ## ring radius is tuning touch.stick_radius, so it spans x 8-68, y 110-170
const FLY_ZONE_MAX_X: float = 150.0
const DIVE_STICK_CENTER: Vector2 = Vector2(296,152)
const TOUCH_BUTTONS: Dictionary = {
	"peck": Rect2(264,98,52,30),
}
const SLOWMO_BUTTON: Rect2 = Rect2(208,98,52,30)
const TOUCH_SLOP: float = 2.0

static func on_dive_stick(point: Vector2) -> bool:
	return point.distance_to(DIVE_STICK_CENTER) <= float(Config.tuning.touch.dive_stick_radius) + TOUCH_SLOP

static func in_fly_zone(point: Vector2) -> bool:
	return point.x < FLY_ZONE_MAX_X and point.y > 28.0

static func touch_button_at(point: Vector2) -> String:
	for kind: String in TOUCH_BUTTONS:
		if (TOUCH_BUTTONS[kind] as Rect2).grow(TOUCH_SLOP).has_point(point):
			return kind
	return ""

static func register_actions() -> void:
	var keys: Dictionary = {"climb":[KEY_SPACE],"dive":[KEY_SHIFT],"pause":[KEY_ESCAPE],"restart":[KEY_R],"slowmo":[KEY_Q],"fullscreen":[KEY_F11],"debug":[KEY_F1],"reload":[KEY_F2],"aim_left":[KEY_A,KEY_LEFT],"aim_right":[KEY_D,KEY_RIGHT],"aim_up":[KEY_W,KEY_UP],"aim_down":[KEY_S,KEY_DOWN]}
	for action: String in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action,0.2)
		for key: int in keys[action]:
			var event: InputEventKey = InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action,event)
	if not InputMap.has_action("peck"):
		InputMap.add_action("peck")
		var peck_key: InputEventKey = InputEventKey.new()
		peck_key.physical_keycode = KEY_E
		InputMap.action_add_event("peck",peck_key)
		var peck_button: InputEventJoypadButton = InputEventJoypadButton.new()
		peck_button.button_index = JOY_BUTTON_X
		InputMap.action_add_event("peck",peck_button)
	for pair: Array in [["climb",MOUSE_BUTTON_LEFT],["dive",MOUSE_BUTTON_RIGHT]]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.button_index = pair[1]
		InputMap.action_add_event(pair[0],event)
	for pair: Array in [["climb",JOY_BUTTON_A],["dive",JOY_BUTTON_B],["pause",JOY_BUTTON_START],["restart",JOY_BUTTON_BACK],["slowmo",JOY_BUTTON_RIGHT_SHOULDER]]:
		var event: InputEventJoypadButton = InputEventJoypadButton.new()
		event.button_index = pair[1]
		InputMap.action_add_event(pair[0],event)
	for pair: Array in [["aim_left",JOY_AXIS_LEFT_X,-1],["aim_right",JOY_AXIS_LEFT_X,1],["aim_up",JOY_AXIS_LEFT_Y,-1],["aim_down",JOY_AXIS_LEFT_Y,1]]:
		var event: InputEventJoypadMotion = InputEventJoypadMotion.new()
		event.axis = pair[1]
		event.axis_value = pair[2]
		InputMap.action_add_event(pair[0],event)

static var touch_explained: bool = false ## the touch-controls card has been shown this app session
static var touch_blocked: bool = false ## the rotate-phone hint is up: ignore fingers

func _input(event: InputEvent) -> void:
	if touch_blocked and (event is InputEventScreenTouch or event is InputEventScreenDrag):
		return
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		touch_last_msec = Time.get_ticks_msec()
		if event is InputEventScreenDrag or event.pressed:
			touch_down[event.index] = true
		else:
			touch_down.erase(event.index)
		key_aim = false
	# The last device used wins: pad buttons or a real stick push, otherwise keys and mouse.
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > PAD_DEADZONE):
		gamepad = true
	elif event is InputEventKey or (event is InputEventMouseButton and not touch_recent()):
		gamepad = false
	elif event is InputEventMouseMotion and not touch_recent():
		gamepad = false
		key_aim = false
		touch_active = false
	if not enabled:
		return
	if event.is_action_pressed("climb") and not event.is_echo():
		flap_tap = true
	if event is InputEventScreenTouch:
		gamepad = false
		touch_visible = true
		if event.pressed:
			var button: String = touch_button_at(event.position)
			if slowmo_ready and SLOWMO_BUTTON.grow(TOUCH_SLOP).has_point(event.position):
				touch_slowmo = true
			elif button == "peck":
				touch_peck = true
				peck_held = true
				peck_finger = event.index
			elif on_dive_stick(event.position) and dive_finger == NO_FINGER:
				dive_finger = event.index
				dive_pos = event.position
				dive_down_msec = Time.get_ticks_msec()
				touch_active = true
			elif in_fly_zone(event.position) and aim_finger == NO_FINGER:
				_grab_fly_stick(event.index,event.position)
		else:
			if event.index == peck_finger:
				peck_held = false
				peck_finger = NO_FINGER
			if event.index == aim_finger:
				aim_finger = NO_FINGER
				stick_pos = FLY_STICK_CENTER
			if event.index == dive_finger:
				if not dive_held and Time.get_ticks_msec() - dive_down_msec <= int(float(Config.tuning.touch.dive_tap_time) * 1000.0):
					touch_dive = true ## a quick tap dives along the current heading; update_player adds the aim assist
				dive_finger = NO_FINGER
				dive_held = false
		_update_fly_flap()
	elif event is InputEventScreenDrag and event.index == dive_finger:
		dive_pos = event.position
	elif event is InputEventScreenDrag and event.index == aim_finger:
		stick_pos = event.position
		_update_fly_flap()
	elif event is InputEventScreenDrag and event.index != peck_finger and aim_finger == NO_FINGER and in_fly_zone(event.position):
		_grab_fly_stick(event.index,event.position) ## a finger that landed while input was off (a card closing) still steers once it moves

## Fixed stick: anywhere in the zone grabs it, deflection is always measured from FLY_STICK_CENTER.
func _grab_fly_stick(index: int, point: Vector2) -> void:
	aim_finger = index
	stick_pos = point
	touch_active = true
	_update_fly_flap()

## FLY pointed up past the threshold climbs like FLAP; entering the zone is a flap tap (realistic mode).
func _update_fly_flap() -> void:
	var up: bool = touch_stick().y < -float(Config.tuning.touch.flap_up_threshold)
	if up and not touch_climb:
		flap_tap = true
	touch_climb = up

## iOS Safari can send emulated mouse motion after a tap; ignore it around touches.
func touch_recent() -> bool:
	return not touch_down.is_empty() or Time.get_ticks_msec() - touch_last_msec < int(float(Config.tuning.touch.mouse_ignore_after_touch) * 1000.0)

## Fixed-stick deflection, up to 1 long; zero while released or inside the deadzone.
func touch_stick() -> Vector2:
	if aim_finger == NO_FINGER:
		return Vector2.ZERO
	var stick: Vector2 = ((stick_pos - FLY_STICK_CENTER) / float(Config.tuning.touch.stick_radius)).limit_length(1.0)
	return stick if stick.length() > float(Config.tuning.touch.stick_deadzone) else Vector2.ZERO

## Fixed dive-stick deflection, up to 1 long; zero while released or inside the deadzone.
func dive_stick() -> Vector2:
	if dive_finger == NO_FINGER:
		return Vector2.ZERO
	var stick: Vector2 = ((dive_pos - DIVE_STICK_CENTER) / float(Config.tuning.touch.dive_stick_radius)).limit_length(1.0)
	return stick if stick.length() > float(Config.tuning.touch.dive_stick_deadzone) else Vector2.ZERO

func update_player(gull: BeachGull, camera_x: float) -> void:
	var stick: Vector2 = Input.get_vector("aim_left","aim_right","aim_up","aim_down")
	if dive_finger == NO_FINGER:
		dive_held = false ## a lost release must never leave the dive stick owning the aim
	if touch_active and (aim_finger != NO_FINGER or dive_finger != NO_FINGER):
		_aim_with_touch(gull) ## a thumb on a stick beats stray key, pad or mouse state
	elif stick.length() > 0.15:
		key_aim = not gamepad # keys share the aim actions with the pad stick
		_aim_with_stick(gull,stick)
	elif gamepad or key_aim:
		_aim_without_stick(gull)
	elif touch_active:
		_aim_with_touch(gull)
	else:
		gull.aim = get_viewport().get_mouse_position() + Vector2(camera_x-160,0)
	gull.climb = Input.is_action_pressed("climb") or touch_climb
	gull.flap_tap_pending = gull.flap_tap_pending or flap_tap
	flap_tap = false

func _aim_with_touch(gull: BeachGull) -> void:
	var dive_vec: Vector2 = dive_stick()
	if dive_vec != Vector2.ZERO and not dive_held:
		dive_held = true
		touch_dive = true ## pushing the dive stick starts the dive; the game consumes this after aiming below
	var touch_vec: Vector2 = dive_vec if dive_held else touch_stick()
	if dive_held and dive_vec == Vector2.ZERO:
		_aim_without_stick(gull) ## dive stick recentred: keep the heading, left stick stays ignored
	elif touch_vec == Vector2.ZERO:
		_aim_without_stick(gull)
		if touch_dive and not dive_held:
			_assist_aim(gull) ## a tap dive follows the current heading, bent toward a snack in the cone
	else:
		_aim_with_stick(gull,touch_vec)
		_assist_aim(gull)
		if not dive_held and gull.state == BeachGull.State.GLIDE and touch_vec.y > 0.0:
			_bend_toward_target(gull,float(Config.tuning.touch.approach_assist_strength)) ## approach assist while gliding down

# Shared by the gamepad stick and the touch stick.
func _aim_with_stick(gull: BeachGull, stick: Vector2) -> void:
	gull.aim = gull.position + stick * float(Config.tuning.flight.cursor_radius)

func _aim_without_stick(gull: BeachGull) -> void:
	if gull.state == BeachGull.State.GROUNDED:
		gull.aim = gull.position
	elif gull.state in [BeachGull.State.WINDUP,BeachGull.State.STRIKE]:
		gull.aim = gull.position + gull.direction * float(Config.tuning.flight.cursor_radius)
	else:
		var heading: Vector2 = gull.velocity.normalized() if gull.velocity.length() > 1 else Vector2(gull.facing,0)
		gull.aim = gull.position + heading * float(Config.tuning.flight.cursor_radius)

## Touch only: at dive start and through the swoop, bend the aim toward the snack
## nearest the aimed direction, if one lies inside the assist cone.
func _assist_aim(gull: BeachGull) -> void:
	if not (gull.state in [BeachGull.State.WINDUP,BeachGull.State.STRIKE] or (gull.state == BeachGull.State.GLIDE and touch_dive)):
		return
	_bend_toward_target(gull,float(Config.tuning.touch.assist_strength))

func _bend_toward_target(gull: BeachGull, strength: float) -> void:
	var t: Dictionary = Config.tuning.touch
	strength = clampf(strength,0.0,1.0)
	if game == null or strength <= 0.0 or gull.rival:
		return
	var dir: Vector2 = (gull.aim - gull.position).normalized()
	var target: BeachTarget = game.assist_target(gull.position,dir,float(t.assist_range),deg_to_rad(float(t.assist_angle)))
	if target == null:
		return
	var blended: Vector2 = dir.slerp((target.food_position() - gull.position).normalized(),strength)
	gull.aim = gull.position + blended * float(Config.tuning.flight.cursor_radius)

func clear_touch() -> void:
	touch_peck = false
	peck_held = false
	peck_finger = NO_FINGER
	touch_slowmo = false
	touch_climb = false
	flap_tap = false
	touch_dive = false
	aim_finger = NO_FINGER
	stick_pos = FLY_STICK_CENTER
	dive_finger = NO_FINGER
	dive_held = false
	touch_down.clear()
