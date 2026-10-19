class_name MumArt
extends RefCounted

# Snack centres sit three native pixels above the palms in the v3 atlas.
# Explicit left-walk/carry sources have different contours from the right poses.
const FOOD_ANCHORS := {
	"idle": [Vector2(13,-21)],
	"eat": [Vector2(13,-21),Vector2(11,-25),Vector2(11,-25),Vector2(13,-21)],
	"walk": [Vector2(12,-23),Vector2(9,-22),Vector2(12,-22),Vector2(10,-23),Vector2(10,-20),Vector2(12,-24)],
	"walk_left": [Vector2(-13,-24),Vector2(-12,-21),Vector2(-13,-24),Vector2(-12,-22),Vector2(-12,-19),Vector2(-13,-25)],
	"carry": [Vector2(14,-21),Vector2(13,-21),Vector2(14,-21),Vector2(14,-21),Vector2(12,-19),Vector2(14,-21)],
	"carry_left": [Vector2(-16,-22),Vector2(-14,-21),Vector2(-16,-21),Vector2(-16,-21),Vector2(-14,-20),Vector2(-16,-21)],
	"chase": [Vector2(12,-23),Vector2(9,-22),Vector2(16,-27),Vector2(10,-23),Vector2(10,-20),Vector2(12,-24)],
	"chase_left": [Vector2(-13,-24),Vector2(-12,-21),Vector2(-17,-27),Vector2(-12,-22),Vector2(-12,-19),Vector2(-13,-25)],
	"handover": [Vector2(13,-24),Vector2(10,-18),Vector2(11,-17),Vector2(11,-17),Vector2(13,-24)],
	"alert": [Vector2(13,-21),Vector2(11,-19),Vector2(11,-19),Vector2(11,-19)],
	"shield": [Vector2(13,-21),Vector2(14,-29),Vector2(14,-29),Vector2(13,-21)],
	"block": [Vector2(13,-21),Vector2(14,-29),Vector2(14,-29),Vector2(13,-21)],
	"swat": [Vector2(11,-19),Vector2(13,-18),Vector2(13,-18),Vector2(16,-29),Vector2(16,-29),Vector2(13,-21)]
}

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
	var clip := String(target.sprite.animation)
	var anchors: Array = FOOD_ANCHORS.get(clip, FOOD_ANCHORS.idle)
	var anchor: Vector2 = anchors[mini(target.sprite.frame, anchors.size() - 1)]
	if not clip.ends_with("_left"):
		anchor.x *= target.facing
	target.food_sprite.position = anchor
