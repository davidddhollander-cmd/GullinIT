class_name SunbatherArt
extends RefCounted
## Native-sized male/female palette variants share frame timing and silhouette.
const PICKUP_PAUSE: float = 0.34
const SWAT_WINDUP: float = 0.42
const SWAT_FOLLOW: float = 0.14
const SETTLE_TIME: float = 0.42

static func scale_for(_female: bool) -> float:
	return 1.0

static func frames(blue: bool, female: bool = false) -> SpriteFrames:
	return AdultPixelArt.frames(false, female, blue)

static func pose(target: BeachTarget, name: StringName, frame: int) -> void:
	var directional_name: StringName = name
	if target.facing < 0 and name in [&"run", &"walk", &"chase", &"kick"]:
		directional_name = StringName(String(name) + "_left")
	target.sprite.visible = true
	target.sprite.stop()
	target.sprite.animation = directional_name
	target.sprite.frame = clampi(frame, 0, target.sprite.sprite_frames.get_frame_count(directional_name) - 1)
	target.sprite.flip_h = target.facing < 0 and directional_name == name and name not in [&"rest", &"rise", &"pickup"]
	target.sprite.position = Vector2(0, -26)
	target.sprite.rotation = 0.0

static func reaction_pose(target: BeachTarget, reaction: StringName, phase: float, run_frame: int = 0) -> void:
	match reaction:
		&"bend":
			pose(target, &"pickup", clampi(int(phase * 4.0), 0, 4))
		&"windup":
			pose(target, &"swat", clampi(int(phase * 5.0), 0, 5))
			target.sprite.position.x = target.facing * (2.0 if phase > 0.6 else -1.0)
		&"settle":
			pose(target, &"rise", clampi(6 - int(phase * 7.0), 0, 6))
		&"run":
			pose(target, &"run", run_frame)
		&"stand":
			pose(target, &"rise", 6)
		_:
			pose(target, &"rest", 0)
