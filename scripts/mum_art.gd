class_name MumArt
extends RefCounted

# Generated per-frame palm anchors in logical gameplay coordinates.
static var _food_anchors: Dictionary = {}

static func update(target: BeachTarget, moving: bool) -> void:
	if CrowdPanic.present(target):
		align_food(target)
		return
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
	var clip := String(target.sprite.animation)
	var anchor := food_anchor(clip,target.sprite.frame)
	if not clip.ends_with("_left"):
		anchor.x *= target.facing
	target.food_sprite.position = anchor

static func food_anchor(clip: String, frame: int) -> Vector2:
	if _food_anchors.is_empty():
		var metadata: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/adult_art.json"))
		assert(metadata is Dictionary and metadata.has("mum_food_anchors"),"Missing adult palm metadata")
		_food_anchors = metadata.mum_food_anchors
	var anchors: Array = _food_anchors.get(clip,_food_anchors.idle)
	var point: Array = anchors[clampi(frame,0,anchors.size()-1)]
	return Vector2(float(point[0]),float(point[1]))
