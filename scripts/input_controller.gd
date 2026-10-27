class_name GullInput
extends Node
var game: BeachGame ## set by the game; supplies targets for touch aim assist
var stick_anchor: Vector2 = Vector2.ZERO ## where the floating touch stick landed (logical px)
var stick_pos: Vector2 = Vector2.ZERO ## current stick finger (logical px)
var touch_active: bool = false ## touch is the aim source until real mouse motion or a gamepad takes over
var touch_down: Dictionary = {} ## every finger currently on screen
var touch_last_msec: int = -1000000
var touch_climb: bool = false
var touch_dive: bool = false
var touch_peck: bool = false
var peck_held: bool = false ## the PECK button is down; a hold screeches
var peck_finger: int = -1
var touch_slowmo: bool = false
var slowmo_ready: bool = false ## set by the game; the touch button only exists while true
var aim_finger: int = -1
var climb_fingers: Dictionary = {}
var gamepad: bool = false ## last device used was a pad; prompts show pad buttons
var key_aim: bool = false ## WASD/arrows steer like a stick until the mouse or a touch takes over
const PAD_DEADZONE: float = 0.3 ## stick drift below this never claims the prompts
var touch_visible: bool = false
var enabled: bool = false
# Compact right-thumb cluster (logical 320x180 coordinates). FLAP sits in the
# corner, DIVE above it and PECK beside it, so the right thumb can peck mid-dive
# while the left thumb keeps steering. The overlay draws these same rects.
const TOUCH_BUTTONS: Dictionary = {
	"peck": Rect2(226,149,42,22),
	"flap": Rect2(272,149,44,22),
	"dive": Rect2(272,124,44,21),
}
const SLOWMO_BUTTON: Rect2 = Rect2(226,124,42,21)
const TOUCH_SLOP: float = 2.0

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

func _input(event: InputEvent) -> void:
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
			elif button == "flap":
				climb_fingers[event.index] = true
			elif button == "dive":
				touch_dive = true
			elif event.position.y > 28 and aim_finger < 0:
				aim_finger = event.index
				stick_anchor = event.position
				stick_pos = event.position
				touch_active = true
		else:
			climb_fingers.erase(event.index)
			if event.index == peck_finger:
				peck_held = false
				peck_finger = -1
			if event.index == aim_finger:
				aim_finger = -1
		touch_climb = not climb_fingers.is_empty()
	elif event is InputEventScreenDrag and event.index == aim_finger:
		stick_pos = event.position
		var pull: Vector2 = stick_pos - stick_anchor
		var radius: float = float(Config.tuning.touch.stick_radius)
		if pull.length() > radius:
			stick_anchor = stick_pos - pull.normalized() * radius ## the anchor follows so the stick never stalls

## iOS Safari can send emulated mouse motion after a tap; ignore it around touches.
func touch_recent() -> bool:
	return not touch_down.is_empty() or Time.get_ticks_msec() - touch_last_msec < int(float(Config.tuning.touch.mouse_ignore_after_touch) * 1000.0)

## Floating-stick deflection, up to 1 long; zero while released or inside the deadzone.
func touch_stick() -> Vector2:
	if aim_finger < 0:
		return Vector2.ZERO
	var stick: Vector2 = ((stick_pos - stick_anchor) / float(Config.tuning.touch.stick_radius)).limit_length(1.0)
	return stick if stick.length() > float(Config.tuning.touch.stick_deadzone) else Vector2.ZERO

func update_player(gull: BeachGull, camera_x: float) -> void:
	var stick: Vector2 = Input.get_vector("aim_left","aim_right","aim_up","aim_down")
	if stick.length() > 0.15:
		key_aim = not gamepad # keys share the aim actions with the pad stick
		_aim_with_stick(gull,stick)
	elif gamepad or key_aim:
		_aim_without_stick(gull)
	elif touch_active:
		var touch_vec: Vector2 = touch_stick()
		if touch_vec == Vector2.ZERO:
			_aim_without_stick(gull)
		else:
			_aim_with_stick(gull,touch_vec)
			_assist_aim(gull)
	else:
		gull.aim = get_viewport().get_mouse_position() + Vector2(camera_x-160,0)
	gull.climb = Input.is_action_pressed("climb") or touch_climb

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
	var t: Dictionary = Config.tuning.touch
	var strength: float = clampf(float(t.assist_strength),0.0,1.0)
	if game == null or strength <= 0.0 or gull.rival:
		return
	if not (gull.state in [BeachGull.State.WINDUP,BeachGull.State.STRIKE] or (gull.state == BeachGull.State.GLIDE and touch_dive)):
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
	peck_finger = -1
	touch_slowmo = false
	touch_climb = false
	touch_dive = false
	aim_finger = -1
	climb_fingers.clear()
	touch_down.clear()
