class_name OldManArt
extends RefCounted
## Generated old-man artwork prepared as the game's 128 px adult atlas cells.

const CELL := 128
const COLUMNS := 8
const DISPLAY_SCALE := 0.5
const ATLAS_PATH := "res://assets/sprites/retro-old-man-stick-32bit.png"
const CLIPS := {
	"rest": 4, "rise": 7, "idle": 4, "eat": 4,
	"walk": 6, "walk_left": 6, "alert": 4, "block": 4,
	"shield": 4, "swat": 6, "chase": 6, "chase_left": 6,
	"kick": 6, "kick_left": 6, "pickup": 5,
	"run": 7, "run_left": 7,
	"carry": 6, "carry_left": 6, "handover": 5,
	"stick_hit": 6, "stick_hit_left": 6
}
const HIT_FRAMES := {"stick_hit": 4, "stick_hit_left": 3}
const LOOPING := [
	"rest", "idle", "eat", "walk", "walk_left", "chase", "chase_left",
	"run", "run_left", "carry", "carry_left"
]

static func frames() -> SpriteFrames:
	var texture: Texture2D = load(ATLAS_PATH) as Texture2D
	var result := SpriteFrames.new()
	result.remove_animation(&"default")
	var index := 0
	for name: String in CLIPS:
		var animation := StringName(name)
		result.add_animation(animation)
		result.set_animation_loop_mode(animation, SpriteFrames.LOOP_LINEAR if name in LOOPING else SpriteFrames.LOOP_NONE)
		result.set_animation_speed(animation, _speed(name))
		for frame: int in int(CLIPS[name]):
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2((index % COLUMNS) * CELL, (index / COLUMNS) * CELL, CELL, CELL)
			atlas.filter_clip = true
			result.add_frame(animation, atlas)
			index += 1
	return result

static func hit_animation(facing: float) -> StringName:
	return &"stick_hit_left" if facing < 0.0 else &"stick_hit"

static func hit_frame(animation: StringName) -> int:
	return int(HIT_FRAMES.get(String(animation), -1))

static func _speed(name: String) -> float:
	if name in ["chase", "chase_left", "run", "run_left"]:
		return 12.0
	if name in ["walk", "walk_left", "carry", "carry_left", "stick_hit", "stick_hit_left"]:
		return 10.0
	if name == "rest":
		return 4.0
	if name == "idle":
		return 6.0
	return 8.0
