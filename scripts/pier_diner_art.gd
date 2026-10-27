class_name PierDinerArt
extends RefCounted
## The same warning and hit timers that drive gameplay select readable poses.

const APPEARANCES: Array[String] = ["pier_diner", "pier_diner_b"]

static func normalize_appearance(appearance: String) -> String:
	return appearance if appearance in APPEARANCES else APPEARANCES[0]

static func frames(appearance: String = "pier_diner") -> SpriteFrames:
	var base_id: String = normalize_appearance(appearance)
	var combined: SpriteFrames = SpriteFrames.new()
	combined.remove_animation(&"default")
	for id: String in [base_id, base_id + "_motion", base_id + "_reactions"]:
		var source: SpriteFrames = Config.frames(id)
		for name: StringName in source.get_animation_names():
			combined.add_animation(name)
			combined.set_animation_speed(name, source.get_animation_speed(name))
			combined.set_animation_loop(name, source.get_animation_loop(name))
			for index: int in source.get_frame_count(name):
				combined.add_frame(name, source.get_frame_texture(name, index))
	return combined

static func update(target: BeachTarget, moving: bool = false) -> void:
	if CrowdPanic.present(target):
		align_food(target)
		return
	var pose: StringName = &"idle"
	if target.action_pose_time > 0:
		pose = &"swat"
	elif target.reaction.swat_timer >= 0:
		pose = &"windup"
	elif target.reaction.mode == "surprise":
		pose = &"surprise"
	elif target.reaction.mode == "give_up" and target.reaction.committed:
		pose = &"fist_shake"
	elif target.reaction.mode == "warning" or target.defense > 0:
		pose = &"brace"
	elif target.reaction.mode in ["follow","give_up"] or (not target.food and target.recover > 0 and not moving):
		pose = &"angry"
	elif target.reaction.mode == "chase" and moving:
		pose = &"run"
	elif moving:
		pose = &"walk"
	elif target.alert >= 0.9:
		pose = &"alert"
	elif target.alert >= 0.5:
		pose = &"watch"
	elif target.alert >= 0.1:
		pose = &"notice"
	elif target.food and fmod(target.art_time, 5.0) >= 3.0 and fmod(target.art_time, 5.0) < 4.2:
		pose = &"eat"
	target.sprite.flip_h = target.facing < 0
	# The leaving state moves three times faster than the promenade. Match its
	# cadence without replacing the separately approved pursuit run.
	var playback_scale := 3.0 if pose == &"walk" and target.leaving else 1.0
	if pose == &"walk" and not target.leaving and target.diner_meal != BeachTarget.DinerMeal.DINING:
		playback_scale = float(Config.tuning.world.diner_trip_speed)/float(Config.tuning.world.walk_speed)
	target.sprite.play(pose, playback_scale)
	if pose == &"surprise":
		_timed_pose(target,AdultReaction.THEFT_SURPRISE_TIME)
	elif pose == &"fist_shake":
		_timed_pose(target,AdultReaction.FAILED_CHASE_ANGER_TIME)
	align_food(target)

static func _timed_pose(target: BeachTarget,duration: float) -> void:
	# The reaction timer is the only clock, so pausing freezes both state and art.
	target.sprite.pause()
	var count: int = target.sprite.sprite_frames.get_frame_count(target.sprite.animation)
	var progress: float = clampf(1.0-target.reaction.timer/duration,0.0,0.999)
	target.sprite.set_frame_and_progress(clampi(floori(progress*count),0,count-1),0.0)

static func align_food(target: BeachTarget) -> void:
	var animation: String = String(target.sprite.animation)
	var base_id: String = normalize_appearance(target.diner_appearance)
	var id: String = base_id + ("_reactions" if animation in ["surprise", "fist_shake"] else ("_motion" if animation in ["walk", "run", "eat"] else ""))
	var anchors: Dictionary = Config.sprites[id].food_anchors
	var sequence: Array = anchors.get(String(target.sprite.animation), [[14, -22]])
	var anchor: Array = sequence[mini(target.sprite.frame, sequence.size() - 1)]
	target.food_sprite.position = Vector2(float(anchor[0]) * target.facing, float(anchor[1]))
