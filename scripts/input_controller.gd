class_name GullInput
extends Node
var touch_aim: Vector2 = Vector2(210,140)
var touch_active: bool = false
var touch_climb: bool = false
var touch_dive: bool = false
var touch_peck: bool = false
var aim_finger: int = -1
var climb_fingers: Dictionary = {}
var gamepad: bool = false
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
const TOUCH_SLOP: float = 2.0

static func touch_button_at(point: Vector2) -> String:
	for kind: String in TOUCH_BUTTONS:
		if (TOUCH_BUTTONS[kind] as Rect2).grow(TOUCH_SLOP).has_point(point):
			return kind
	return ""

static func register_actions() -> void:
	var keys: Dictionary = {"climb":[KEY_SPACE],"dive":[KEY_SHIFT],"pause":[KEY_ESCAPE],"restart":[KEY_R],"fullscreen":[KEY_F11],"debug":[KEY_F1],"reload":[KEY_F2],"aim_left":[KEY_A,KEY_LEFT],"aim_right":[KEY_D,KEY_RIGHT],"aim_up":[KEY_W,KEY_UP],"aim_down":[KEY_S,KEY_DOWN]}
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
	for pair: Array in [["climb",JOY_BUTTON_A],["dive",JOY_BUTTON_B],["pause",JOY_BUTTON_START],["restart",JOY_BUTTON_BACK]]:
		var event: InputEventJoypadButton = InputEventJoypadButton.new()
		event.button_index = pair[1]
		InputMap.action_add_event(pair[0],event)
	for pair: Array in [["aim_left",JOY_AXIS_LEFT_X,-1],["aim_right",JOY_AXIS_LEFT_X,1],["aim_up",JOY_AXIS_LEFT_Y,-1],["aim_down",JOY_AXIS_LEFT_Y,1]]:
		var event: InputEventJoypadMotion = InputEventJoypadMotion.new()
		event.axis = pair[1]
		event.axis_value = pair[2]
		InputMap.action_add_event(pair[0],event)

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadMotion or event is InputEventJoypadButton:
		gamepad = true
	elif event is InputEventMouseMotion:
		gamepad = false
		touch_active = false
	if not enabled:
		return
	if event is InputEventScreenTouch:
		gamepad = false
		touch_visible = true
		if event.pressed:
			var button: String = touch_button_at(event.position)
			if button == "peck":
				touch_peck = true
			elif button == "flap":
				climb_fingers[event.index] = true
			elif button == "dive":
				touch_dive = true
			elif event.position.y > 28:
				aim_finger = event.index
				touch_aim = event.position
				touch_active = true
		else:
			climb_fingers.erase(event.index)
			if event.index == aim_finger:
				aim_finger = -1
		touch_climb = not climb_fingers.is_empty()
	elif event is InputEventScreenDrag and event.index == aim_finger:
		touch_aim = event.position

func update_player(gull: BeachGull, camera_x: float) -> void:
	var stick: Vector2 = Input.get_vector("aim_left","aim_right","aim_up","aim_down")
	if stick.length() > 0.15:
		gamepad = true
		gull.aim = gull.position + stick * float(Config.tuning.flight.cursor_radius)
	elif gamepad:
		if gull.state == BeachGull.State.GROUNDED:
			gull.aim = gull.position
		elif gull.state in [BeachGull.State.WINDUP,BeachGull.State.STRIKE]:
			gull.aim = gull.position + gull.direction * float(Config.tuning.flight.cursor_radius)
		else:
			var heading: Vector2 = gull.velocity.normalized() if gull.velocity.length() > 1 else Vector2(gull.facing,0)
			gull.aim = gull.position + heading * float(Config.tuning.flight.cursor_radius)
	elif touch_active:
		gull.aim = touch_aim + Vector2(camera_x-160,0)
	else:
		gull.aim = get_viewport().get_mouse_position() + Vector2(camera_x-160,0)
	gull.climb = Input.is_action_pressed("climb") or touch_climb

func clear_touch() -> void:
	touch_peck = false
	touch_climb = false
	touch_dive = false
	aim_finger = -1
	climb_fingers.clear()
