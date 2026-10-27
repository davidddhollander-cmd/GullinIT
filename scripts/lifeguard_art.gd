class_name LifeguardArt
extends RefCounted

static func update(target: BeachTarget,moving: bool) -> void:
	if CrowdPanic.present(target):
		return
	var pose: StringName = &"walk" if moving else &"idle"
	if target.action_pose_time > 0:
		pose = &"swat"
	elif target.lifeguard_whistle_time > 0:
		pose = &"whistle"
	elif target.reaction.swat_timer >= 0:
		pose = &"windup"
	elif target.reaction.mode == "warning":
		pose = &"point"
	elif target.reaction.mode == "follow":
		pose = &"angry"
	elif target.reaction.mode == "chase" and moving:
		pose = &"run"
	elif not moving and target.alert >= 0.8:
		pose = &"whistle_prepare"
	elif not moving and target.alert >= 0.4:
		pose = &"lookout"
	# The base review sheets can be fitted before optional action sources arrive.
	if not target.sprite.sprite_frames.has_animation(pose):
		pose = &"walk" if moving else &"point"
	target.sprite.flip_h = target.facing < 0
	target.sprite.play(pose)
	if pose == &"swat":
		target.sprite.set_frame_and_progress(clampi(2+int((0.28-target.action_pose_time)*4.0/0.28),2,5),0)
	elif pose == &"windup":
		target.sprite.set_frame_and_progress(0 if target.reaction.swat_timer > 0.2*target.reaction_delay else 1,0)
