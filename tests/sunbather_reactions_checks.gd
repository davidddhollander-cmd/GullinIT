class_name SunbatherReactionsChecks
extends RefCounted
## Parent integration runner can pass Callable(self, "check").
static func run_checks(check: Callable) -> void:
	var frames: SpriteFrames = SunbatherArt.frames(false,false)
	check.call(frames.get_frame_count(&"rise") == 7,"sunbather bend/stand uses all seven rise frames")
	check.call(frames.get_frame_count(&"run") == 7,"sunbather return uses all seven run frames")
	check.call(frames.get_frame_count(&"walk_left") == 6 and frames.get_frame_count(&"kick_left") == 6,"sunbather has separately drawn left-facing walk and kick poses")
	check.call(SunbatherArt.PICKUP_PAUSE > 0.0 and SunbatherArt.PICKUP_PAUSE < 0.5,"snack pickup has a short finite pause")
	check.call(SunbatherArt.SWAT_WINDUP >= 0.35,"swat gives the gull a readable reaction window")
	check.call(SunbatherArt.SWAT_FOLLOW > 0.0 and SunbatherArt.SETTLE_TIME > 0.0,"swat follow-through and return settling are timed")
	var target: BeachTarget = BeachTarget.new()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7919
	target.setup("sunbather",180.0,rng,1.0,{"appearance":"female-blue"})
	SunbatherArt.reaction_pose(target,&"bend",0.0)
	check.call(target.sprite.animation == &"pickup" and target.sprite.frame == 0,"pickup bend starts from upright pose")
	SunbatherArt.reaction_pose(target,&"bend",1.0)
	check.call(target.sprite.animation == &"pickup" and target.sprite.frame == 4,"pickup bend reaches a clear crouched snack pose")
	SunbatherArt.reaction_pose(target,&"windup",0.2)
	check.call(target.sprite.animation == &"swat" and target.sprite.frame == 1,"swat windup advances its raised-arm warning pose")
	SunbatherArt.reaction_pose(target,&"windup",0.9)
	check.call(target.sprite.animation == &"swat" and target.sprite.frame > 1 and target.sprite.position.x > 0,"swat has a distinct forward swing movement")
	target.facing = -1.0
	SunbatherArt.reaction_pose(target,&"run",0.0,3)
	check.call(target.sprite.animation == &"run_left" and target.sprite.frame == 3 and not target.sprite.flip_h,"return pose uses its drawn left-facing frames")
	SunbatherArt.reaction_pose(target,&"settle",1.0)
	check.call(target.sprite.animation == &"rise" and target.sprite.frame == 0,"return settlement ends at the reclined pose")
	target.free()
