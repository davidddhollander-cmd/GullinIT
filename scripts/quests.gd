class_name BeachQuests
extends RefCounted
## Per-run quest tracker built from level JSON. Events are fed by BeachGame.
signal quest_completed(quest: Dictionary)
var quests: Array[Dictionary] = []

func setup(level: Dictionary, rng: RandomNumberGenerator) -> void:
	quests.clear()
	for def: Dictionary in level.get("quests", []):
		var quest: Dictionary = def.duplicate(true)
		quest.progress = 0
		quest.done = false
		quests.append(quest)
	var random: Variant = level.get("random_quest")
	var foods: Array = level.get("random_foods", [])
	if random is Dictionary and not foods.is_empty():
		var food: String = str(foods[rng.randi_range(0, foods.size() - 1)])
		var range_: Array = random.count
		var count: int = rng.randi_range(int(range_[0]), int(range_[1]))
		quests.append({"id": "l%d_random" % int(level.get("id", 0)), "text": "EAT %d %s" % [count, str(Config.foods[food].name).to_upper()],
			"event": "swallowed", "filter": {"food": food}, "count": count, "bonus": int(random.bonus), "progress": 0, "done": false})

func record(event: String, data: Dictionary = {}) -> Array[Dictionary]:
	var completed: Array[Dictionary] = []
	for quest: Dictionary in quests:
		if quest.done or quest.event != event:
			continue
		var matches: bool = true
		for key: String in quest.filter:
			if not data.has(key) or data[key] != quest.filter[key]:
				matches = false
		if not matches:
			continue
		quest.progress += 1
		if quest.progress >= int(quest.count):
			quest.done = true
			completed.append(quest)
			quest_completed.emit(quest)
	return completed

func bonus_points() -> int:
	var total: int = 0
	for quest: Dictionary in quests:
		if quest.done:
			total += int(quest.bonus)
	return total
