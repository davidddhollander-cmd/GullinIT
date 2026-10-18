class_name MumArt
extends RefCounted

static func update(target: BeachTarget, moving: bool) -> void:
	var pose: StringName = &"idle"
	if target.mum_swat_time > 0 or target.reaction.swat_timer >= 0:
		pose = &"swat"
	elif target.reaction.mode == "warning":
		pose = &"alert"
	elif moving and target.reaction.mode == "chase":
		pose = &"chase"
	elif moving and target.reaction.mode == "return":
		pose = &"carry" if target.food else &"walk"
	elif target.defense > 0:
		pose = &"shield"
	elif target.handover_timer > 0:
		pose = &"handover"
	elif moving:
		pose = &"carry" if target.food or target.family_trip == BeachTarget.FamilyTrip.RETURN else &"walk"
	elif target.alert >= float(Config.tuning.world.suspicious):
		pose = &"alert"
	elif target.food and target.family_trip == BeachTarget.FamilyTrip.IDLE and fmod(target.art_time, 5.0) < 0.9:
		pose = &"eat"
	if target.facing < 0 and pose in [&"walk", &"carry", &"chase"]:
		pose = StringName(String(pose) + "_left")
	target.sprite.flip_h = target.facing < 0 and pose not in [&"walk_left", &"carry_left", &"chase_left"]
	target.sprite.play(pose)
	align_food(target)

static func align_food(target: BeachTarget) -> void:
	var anchor := Vector2(11,-22)
	match target.sprite.animation:
		&"carry", &"carry_left": anchor = Vector2(13,-21)
		&"walk", &"walk_left", &"chase", &"chase_left": anchor = Vector2(9,-19)
		&"shield": anchor = Vector2(1,-25)
		&"eat": anchor = Vector2(6,-28) if target.sprite.frame in [1,2] else Vector2(11,-22)
		&"handover":
			var anchors: Array[Vector2] = [Vector2(11,-22),Vector2(12,-15),Vector2(16,-10),Vector2(16,-10),Vector2(12,-22)]
			anchor = anchors[mini(target.sprite.frame,4)]
	target.food_sprite.position = Vector2(anchor.x*target.facing,anchor.y)
