class_name ShopperArt
extends RefCounted
const APPEARANCES: Array[String] = ["kiosk_customer","shopper_mullet","shopper_sundress","old_man"]

static func supports_bench(target: BeachTarget) -> bool:
	return target.sprite.sprite_frames.has_animation(&"seated_idle")

static func update(target: BeachTarget,moving: bool) -> void:
	if target.bench_visit.anchored():
		var visit: BenchVisit = target.bench_visit
		var clip: StringName = visit.pose()
		target.sprite.flip_h = visit.seat_facing < 0
		target.sprite.play(clip)
		target.sprite.pause()
		var count: int = target.sprite.sprite_frames.get_frame_count(clip)
		target.sprite.set_frame_and_progress(mini(count-1,int(visit.progress()*count)),0.0)
		BeachgoerArt.align_food(target)
		return
	if target.shopper_appearance == "old_man":
		_update_old_man(target,moving)
		return
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

# The old man has his own clip set; "_left" variants are drawn, so he is never mirrored.
static func _update_old_man(target: BeachTarget,moving: bool) -> void:
	var left: bool = target.facing < 0
	var pose: StringName = &"walk" if moving else &"idle"
	var hit_frame: int = -1
	if not target.leaving:
		if target.action_pose_time > 0:
			pose = &"stick_hit"
			hit_frame = clampi(int((0.28-target.action_pose_time)/0.28*6.0),0,5)
		elif target.reaction.swat_timer >= 0:
			pose = &"stick_hit"
			hit_frame = 0 if target.reaction.swat_timer > 0.2*target.reaction_delay else 1
		elif target.biting > 0.0 and not moving:
			pose = &"eat"
		elif target.reaction.mode == "chase" and moving:
			pose = &"run"
		elif target.reaction.mode in ["warning","follow","give_up"] or (not target.food and target.recover > 0 and not moving) or (not moving and target.alert >= float(Config.tuning.world.suspicious)):
			pose = &"alert"
	var clip: StringName = pose
	if left and pose in [&"walk",&"run",&"stick_hit"]:
		clip = StringName(String(pose)+"_left")
	target.sprite.flip_h = left and clip == pose
	target.sprite.play(clip)
	if hit_frame >= 0:
		target.sprite.pause()
		target.sprite.set_frame_and_progress(hit_frame,0.0)
	BeachgoerArt.align_food(target)
