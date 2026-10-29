class_name TrainerScript
extends RefCounted
## Looks up Screeches McCrumbs' copy in data/trainer.json for the player's input device and control mode.
## A copy value is a string or {default, realistic, casual}; {flap} {dive} {peck} {steer} {call} {n} are filled in.

static func device(input: GullInput) -> String:
	if input.touch_visible:
		return "touch"
	return "gamepad" if input.gamepad else "keyboard"

static func pick(value: Variant) -> String:
	if value is Dictionary:
		return str(value.get(GameState.control_mode(),value.get("default","")))
	return str(value)

static func fill(text: String, input: GullInput) -> String:
	var keys: Dictionary = Config.trainer.keys[device(input)]
	for key: String in keys:
		text = text.replace("{%s}" % key,str(keys[key]))
	return text.replace("{n}",str(int(Config.tuning.world.bin_pecks)))

static func line(value: Variant, input: GullInput) -> String:
	return fill(pick(value),input)
