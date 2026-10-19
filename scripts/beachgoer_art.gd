class_name BeachgoerArt
extends RefCounted
## Customer/owner poses share the existing target movement and awareness state.
static func update(target: BeachTarget, moving: bool) -> void:
	if target.kind == "kiosk_customer":
		ShopperArt.update(target,moving)
		return
	var pose: StringName = &"walk" if moving else &"idle"
	if not target.leaving:
		if target.reaction.swat_timer >= 0 or target.reaction.mode in ["warning","follow"]:
			pose = &"bark" if target.kind == "dog_owner" else &"angry"
		elif not target.food and target.recover > 0 and not moving:
			pose = &"angry"
		elif target.kind == "dog_owner" and target.alert >= 0.95:
			pose = &"bark"
		elif not moving and target.alert >= float(Config.tuning.world.suspicious):
			pose = &"alert"
	target.sprite.flip_h = target.facing < 0
	target.sprite.play(pose)
	align_food(target)

static func align_food(target: BeachTarget) -> void:
	var entry: Dictionary = Config.sprites[target.info.sprite]
	var anchors: Dictionary = entry.get("food_anchors",{})
	var sequence: Array = anchors.get(String(target.sprite.animation),[[10,-22]])
	var anchor: Array = sequence[mini(target.sprite.frame,sequence.size()-1)]
	target.food_sprite.position = Vector2(float(anchor[0])*target.facing,float(anchor[1]))
