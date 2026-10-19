class_name ToddlerArt
extends RefCounted

static func align_food(target: BeachTarget) -> void:
	var entry: Dictionary = Config.sprites[target.info.sprite]
	var sequence: Array = entry.food_anchors.get(String(target.sprite.animation),[entry.food_anchor])
	var anchor: Array = sequence[mini(target.sprite.frame,sequence.size()-1)]
	target.food_sprite.position = Vector2(float(anchor[0])*target.facing,float(anchor[1]))
