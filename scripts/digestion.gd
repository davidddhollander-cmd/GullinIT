class_name GullDigestion
extends RefCounted
signal swallowed(snack: Dictionary)
var snacks: Array[Dictionary] = []
var progress: float = 0.0
var rest: float = 0.0

func cost(id: String) -> int:
	return {"small":1,"medium":2,"large":4}[Config.foods[id].category]

func duration(id: String) -> float:
	return {"small":0.5,"medium":1.5,"large":3.0}[Config.foods[id].category]

func can_collect(id: String) -> bool:
	if not Config.foods.has(id) or rest > 0:
		return false
	var used: int = 0
	for snack: Dictionary in snacks:
		used += cost(snack.id)
	return used+cost(id) <= 4

func collect(id: String, details: Dictionary = {}) -> bool:
	if not can_collect(id):
		return false
	var snack: Dictionary = details.duplicate(true)
	snack.id = id
	snacks.append(snack)
	return true

func drop_current() -> Dictionary:
	if snacks.is_empty():
		return {}
	progress = 0
	return snacks.pop_front()

func tick(delta: float, grounded: bool) -> void:
	var budget: float = delta * (2.0 if grounded else 1.0)
	while budget > 0:
		if rest > 0:
			var used: float = minf(rest,budget)
			rest = maxf(0,rest-used)
			budget -= used
		elif not snacks.is_empty():
			var duration_seconds: float = duration(snacks[0].id)
			var used: float = minf(duration_seconds-progress,budget)
			progress += used
			budget -= used
			if progress >= duration_seconds-0.000001:
				var snack: Dictionary = snacks.pop_front()
				progress = 0
				if cost(snack.id) == 4:
					rest = 2
				swallowed.emit(snack)
		else:
			break
