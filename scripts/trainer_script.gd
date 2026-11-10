class_name TrainerScript
extends RefCounted
## Looks up Screeches McCrumbs' copy in data/trainer.json for the player's input device and control mode.
## A copy value is a string or {default, realistic, casual, touch, touch_casual}; {flap} {dive} {peck} {steer} {call} {n} are filled in.

static func device(input: GullInput) -> String:
	if input.touch_visible:
		return "touch"
	return "gamepad" if input.gamepad else "keyboard"

static func pick(value: Variant) -> String:
	if value is Dictionary:
		return str(value.get(GameState.control_mode(),value.get("default","")))
	return str(value)

## Display paths ask for marked names: each control name is wrapped in MARK_ON/MARK_OFF (bbcode() turns them into a pulsing highlight).
## Plain output (the default) is unchanged. `marking` lets a caller mark every line it asks for without threading a flag through.
const MARK_ON: String = "\u0001"
const MARK_OFF: String = "\u0002"
static var marking: bool = false

## Keycap chip: dark panel-colour text on a white chip that flips to gold (two solid colours, ~1.5 Hz) so the pixel font stays crisp.
static func phase() -> int:
	return (Time.get_ticks_msec() / 333) % 2

## Hug the glyphs: 1 px sideways, shaved top/bottom so the chip stays inside its own line.
static func snug_chips(label: RichTextLabel) -> void:
	label.add_theme_constant_override("text_highlight_h_padding",1)
	label.add_theme_constant_override("text_highlight_v_padding",CHIP_V_PAD)

const CHIP_V_PAD: int = 0

static func bbcode(text: String) -> String:
	var chip: String = "#ffc65c" if phase() == 1 else "#ffffff"
	return text.replace(MARK_ON,"[bgcolor=%s][color=#183b4d]" % chip).replace(MARK_OFF,"[/color][/bgcolor]")

static func fill(text: String, input: GullInput, mark: bool = false) -> String:
	mark = mark or marking
	var keys: Dictionary = Config.trainer.keys[device(input)]
	if mark and device(input) == "touch": # literal control names in touch copy ("Push FLY up", "Tap DIVE")
		var literal: RegEx = RegEx.create_from_string("\\b(FLY up|FLY|DIVE|PECK)\\b")
		text = literal.sub(text,MARK_ON + "$1" + MARK_OFF,true)
	for key: String in keys:
		text = text.replace("{%s}" % key,(MARK_ON + str(keys[key]) + MARK_OFF) if mark else str(keys[key]))
	return text.replace("{n}",str(int(Config.tuning.world.bin_pecks)))

static func line(value: Variant, input: GullInput, mark: bool = false) -> String:
	if value is Dictionary and device(input) == "touch":
		# Touch copy names the FLY stick and the DIVE circle: "touch_<mode>" first, then "touch".
		var mode: String = "touch_" + GameState.control_mode()
		if value.has(mode):
			return fill(str(value[mode]),input,mark)
		if value.has("touch"):
			return fill(str(value.touch),input,mark)
	return fill(pick(value),input,mark)
