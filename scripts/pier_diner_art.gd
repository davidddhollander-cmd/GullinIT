class_name PierDinerArt
extends RefCounted
## The same warning and hit timers that drive gameplay select readable poses.

static func frames() -> SpriteFrames:
	var combined: SpriteFrames = SpriteFrames.new()
	combined.remove_animation(&"default")
	for id: String in ["pier_diner", "pier_diner_motion"]:
		var source: SpriteFrames = Config.frames(id)
		for name: StringName in source.get_animation_names():
			combined.add_animation(name)
			combined.set_animation_speed(name, source.get_animation_speed(name))
			combined.set_animation_loop(name, source.get_animation_loop(name))
			for index: int in source.get_frame_count(name):
				combined.add_frame(name, source.get_frame_texture(name, index))
	return combined

static func update(target: BeachTarget, moving: bool = false) -> void:
	var pose: StringName = &"idle"
	if target.action_pose_time > 0:
		pose = &"swat"
	elif target.reaction.swat_timer >= 0:
		pose = &"windup"
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
	target.sprite.play(pose)
	align_food(target)

static func align_food(target: BeachTarget) -> void:
	var animation: String = String(target.sprite.animation)
	var id: String = "pier_diner_motion" if animation in ["walk", "run", "eat"] else "pier_diner"
	var anchors: Dictionary = Config.sprites[id].food_anchors
	var sequence: Array = anchors.get(String(target.sprite.animation), [[14, -22]])
	var anchor: Array = sequence[mini(target.sprite.frame, sequence.size() - 1)]
	target.food_sprite.position = Vector2(float(anchor[0]) * target.facing, float(anchor[1]))
