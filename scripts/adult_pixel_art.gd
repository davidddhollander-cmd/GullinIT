class_name AdultPixelArt
extends RefCounted
## Approved diner-style atlases: 80-source-pixel adults shown at 40 logical pixels.
## tools/diner_adult_atlas_source.gd prepares the higher-detail artwork.

const CELL := 128
const DISPLAY_SCALE := 0.5
const COLUMNS := 8
const MUM_CLIPS := {
	"idle": 4, "eat": 4, "walk": 6, "walk_left": 6,
	"alert": 4, "block": 4, "shield": 4, "swat": 6,
	"chase": 6, "chase_left": 6, "kick": 6, "kick_left": 6,
	"carry": 6, "carry_left": 6, "handover": 5
}
const SUN_CLIPS := {
	"rest": 4, "rise": 7, "idle": 4, "eat": 4,
	"walk": 6, "walk_left": 6, "alert": 4, "block": 4,
	"swat": 6, "chase": 6, "chase_left": 6,
	"kick": 6, "kick_left": 6, "pickup": 5, "run": 7, "run_left": 7
}
static func clips(mum: bool) -> Dictionary:
	return MUM_CLIPS if mum else SUN_CLIPS

static func atlas_path(mum: bool, female: bool = false, blue: bool = false) -> String:
	if mum:
		return "res://assets/sprites/retro-mum-32bit.png"
	return "res://assets/sprites/retro-sunbather-%s-%s-32bit.png" % ["female" if female else "male", "blue" if blue else "red"]

static func frames(mum: bool, female: bool = false, blue: bool = false) -> SpriteFrames:
	var texture: Texture2D = load(atlas_path(mum, female, blue)) as Texture2D
	var result := SpriteFrames.new()
	result.remove_animation(&"default")
	var index := 0
	for name: String in clips(mum):
		var count: int = clips(mum)[name]
		var animation := StringName(name)
		result.add_animation(animation)
		result.set_animation_loop(animation, name in ["idle", "eat", "walk", "walk_left", "chase", "chase_left", "carry", "carry_left", "rest", "run", "run_left"])
		result.set_animation_speed(animation, 12.0 if name in ["chase", "chase_left", "run", "run_left"] else (10.0 if name in ["walk", "walk_left", "carry", "carry_left"] else (4.0 if name == "rest" else (6.0 if name == "idle" else 8.0))))
		for frame: int in count:
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2((index % COLUMNS) * CELL, (index / COLUMNS) * CELL, CELL, CELL)
			atlas.filter_clip = true
			result.add_frame(animation, atlas)
			index += 1
	return result
