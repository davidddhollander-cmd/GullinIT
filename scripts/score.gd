class_name BeachScore
extends RefCounted
signal combo_changed(tier: int)
var points: int = 0
var items: int = 0
var tier: int = 0
var window: float = 0.0
var stuns: int = 0
var bonuses: Dictionary = {"Risky": 0, "Upwind": 0, "Mugged": 0}

func tick(delta: float) -> void:
	window = maxf(0.0, window - delta)
	if window <= 0:
		tier = 0

func snatch(value: int, risky: bool, upwind: bool, mugged: bool) -> int:
	var t: Dictionary = Config.tuning.score
	if window > 0:
		tier = mini(tier + 1, t.tiers.size() - 1)
		combo_changed.emit(tier)
	else:
		tier = 0
	var bonus: float = 1.0
	for pair: Array in [[risky,"Risky","risky"],[upwind,"Upwind","upwind"],[mugged,"Mugged","mugged"]]:
		if pair[0]:
			bonus += float(t[pair[2]])
			bonuses[pair[1]] += 1
	var earned: int = roundi(value * bonus * float(t.tiers[tier]))
	points += earned
	items += 1
	window = t.combo_window
	return earned

func stunned() -> void:
	stuns += 1
	tier = 0
	window = 0

func result(level: Dictionary, casual: bool, elapsed: float) -> Dictionary:
	var clean: int = roundi(points * float(Config.tuning.score.clean)) if stuns == 0 else 0
	var total: int = points + (0 if casual else clean)
	var stars: int = 0
	if not casual:
		for threshold: int in level.stars:
			if total >= threshold:
				stars += 1
	return {"score":total,"base":points,"clean":0 if casual else clean,"stars":stars,"items":items,"stuns":stuns,"bonuses":bonuses.duplicate(),"elapsed":elapsed,"casual":casual}
