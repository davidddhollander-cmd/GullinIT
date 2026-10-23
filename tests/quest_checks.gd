extends RefCounted
## Quest tracker, level quest data and the Feathers wallet save.

static func _level(id: int) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/levels/level_0%d.json" % id))

static func run(check: Callable) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 11
	var quests: BeachQuests = BeachQuests.new()
	var l2: Dictionary = _level(2)
	quests.setup(l2, rng)
	check.call(quests.quests.size() == 3, "level 2 has two fixed quests plus a random slot")
	var random: Dictionary = quests.quests[2]
	check.call(random.id == "l2_random" and random.filter.food in l2.random_foods and int(random.count) >= 3 and int(random.count) <= 5, "random quest picks a listed food and a 3-5 count")
	check.call(random.text == "EAT %d %s" % [random.count, str(Config.foods[random.filter.food].name).to_upper()], "random quest text names the food")
	for seed: int in 40:
		rng.seed = seed
		var roll: BeachQuests = BeachQuests.new()
		roll.setup(l2, rng)
		check.call(roll.quests[2].filter.food in l2.random_foods, "random food always from random_foods (seed %d)" % seed)
	# Every random food must be a real food, and levels 1 has no random slot.
	for id: int in [2, 3]:
		for food: String in _level(id).random_foods:
			check.call(Config.foods.has(food), "level %d random food exists: %s" % [id, food])
	var l1: BeachQuests = BeachQuests.new()
	l1.setup(_level(1), rng)
	check.call(l1.quests.size() == 2 and l1.quests[0].id == "l1_bin" and l1.quests[1].id == "l1_bite", "level 1 has two quests and no random slot")
	check.call(bool(_level(1).get("quests_on_replay_only", false)), "level 1 quests flagged replay-only")
	var l3: BeachQuests = BeachQuests.new()
	l3.setup(_level(3), rng)
	check.call(l3.quests.size() == 3 and l3.quests[0].id == "l3_mug_gary" and l3.quests[2].id == "l3_random", "level 3 has two quests plus random")

	var fired: Array[String] = []
	quests.quest_completed.connect(func(q: Dictionary) -> void: fired.append(q.id))
	check.call(quests.record("swallowed", {"food": "ice_cream", "direct": false}).is_empty(), "indirect ice cream does not count")
	check.call(quests.record("swallowed", {"food": "ice_cream"}).is_empty(), "missing filter key does not count")
	for i: int in 2:
		check.call(quests.record("swallowed", {"food": "ice_cream", "direct": true}).is_empty(), "clean ice cream %d is not yet complete" % (i + 1))
	var done: Array[Dictionary] = quests.record("swallowed", {"food": "ice_cream", "direct": true})
	check.call(done.size() == 1 and done[0].id == "l2_ice" and fired == ["l2_ice"], "third clean ice cream completes l2_ice once")
	check.call(quests.record("swallowed", {"food": "ice_cream", "direct": true}).is_empty(), "completed quest is not returned again")
	check.call(quests.bonus_points() == 50, "bonus_points sums done quests")

	var saved_path: String = GameState.save_path
	var saved_progress: Dictionary = GameState.progress
	var saved_wallet: Dictionary = GameState.wallet
	GameState.save_path = "res://test-output/quest-checks-save.json"
	GameState.progress = {}
	GameState.wallet = {"feathers": 0}
	var before: int = GameState.feathers()
	check.call(GameState.complete_quest(2, "l2_ice"), "first completion pays")
	check.call(not GameState.complete_quest(2, "l2_ice"), "replay completion does not pay")
	check.call(GameState.feathers() == before + 1, "exactly one Feather earned")
	check.call("l2_ice" in GameState.entry(2).quests, "completed id saved on the level entry")
	GameState.progress = {}
	GameState.wallet = {"feathers": 0}
	GameState.load_progress()
	check.call(GameState.feathers() == 1 and "l2_ice" in GameState.entry(2).quests, "wallet and quests survive a save round-trip")
	var old: FileAccess = FileAccess.open(GameState.save_path, FileAccess.WRITE)
	old.store_string(JSON.stringify({"version": 1, "progress": {"1": {"stars": 2, "best": 150, "training_step": 7}}, "options": {}}))
	old.close()
	GameState.progress = {}
	GameState.wallet = {"feathers": 0}
	GameState.load_progress()
	check.call(GameState.feathers() == 0 and int(GameState.entry(1).stars) == 2 and int(GameState.entry(1).best) == 150, "old save without wallet loads with 0 Feathers")
	GameState.save_path = saved_path
	GameState.progress = saved_progress
	GameState.wallet = saved_wallet
