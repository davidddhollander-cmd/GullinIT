class_name ShopperArt
extends RefCounted
const APPEARANCES: Array[String] = ["kiosk_customer","shopper_mullet","shopper_sundress"]

static func update(target: BeachTarget,moving: bool) -> void:
	var pose: StringName = &"walk" if moving else &"idle"
	var original_pilot: bool = target.shopper_appearance == "kiosk_customer"
	if not target.leaving:
		if target.action_pose_time > 0:
			pose = &"swat"
		elif target.reaction.swat_timer >= 0:
			pose = &"windup"
		elif original_pilot and target.reaction.mode == "surprise":
			pose = &"surprise"
		elif original_pilot and target.reaction.mode == "give_up" and target.reaction.committed:
			pose = &"fist_shake"
		elif target.biting > 0.0 and not moving:
			pose = &"bite"
		elif target.reaction.mode == "warning":
			pose = &"warning"
		elif target.reaction.mode in ["follow","give_up"] or (not target.food and target.recover > 0 and not moving):
			pose = &"angry"
		elif target.reaction.mode == "chase" and moving:
			pose = &"run"
		elif not moving and target.alert >= float(Config.tuning.world.suspicious):
			pose = &"alert"
	target.sprite.flip_h = target.facing < 0
	target.sprite.play(pose)
	if pose == &"surprise":
		_timed_pose(target,AdultReaction.THEFT_SURPRISE_TIME)
	elif pose == &"fist_shake":
		_timed_pose(target,AdultReaction.FAILED_CHASE_ANGER_TIME)
	elif pose == &"swat":
		# Contact artwork starts on the actual hit; anticipation belongs to windup.
		target.sprite.set_frame_and_progress(clampi(2+int((0.28-target.action_pose_time)*4.0/0.28),2,5),0)
	elif pose == &"windup":
		target.sprite.set_frame_and_progress(0 if target.reaction.swat_timer > 0.2*target.reaction_delay else 1,0)
	BeachgoerArt.align_food(target)

static func _timed_pose(target: BeachTarget,duration: float) -> void:
	# Reaction time is the single animation clock, so pause freezes the exact pose.
	target.sprite.pause()
	var count: int = target.sprite.sprite_frames.get_frame_count(target.sprite.animation)
	var progress: float = clampf(1.0-target.reaction.timer/duration,0.0,0.999)
	target.sprite.set_frame_and_progress(clampi(floori(progress*count),0,count-1),0.0)
