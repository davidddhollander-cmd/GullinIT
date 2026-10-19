class_name ShopperArt
extends RefCounted

static func update(target: BeachTarget,moving: bool) -> void:
	var pose: StringName = &"walk" if moving else &"idle"
	if not target.leaving:
		if target.action_pose_time > 0:
			pose = &"swat"
		elif target.reaction.swat_timer >= 0:
			pose = &"windup"
		elif target.reaction.mode == "warning":
			pose = &"warning"
		elif target.reaction.mode == "follow" or (not target.food and target.recover > 0 and not moving):
			pose = &"angry"
		elif target.reaction.mode == "chase" and moving:
			pose = &"run"
		elif not moving and target.alert >= float(Config.tuning.world.suspicious):
			pose = &"alert"
	target.sprite.flip_h = target.facing < 0
	target.sprite.play(pose)
	if pose == &"swat":
		# Contact artwork starts on the actual hit; anticipation belongs to windup.
		target.sprite.set_frame_and_progress(clampi(2+int((0.28-target.action_pose_time)*4.0/0.28),2,5),0)
	elif pose == &"windup":
		target.sprite.set_frame_and_progress(0 if target.reaction.swat_timer > 0.2*target.reaction_delay else 1,0)
	BeachgoerArt.align_food(target)
