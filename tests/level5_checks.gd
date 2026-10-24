extends RefCounted
## Level 5 "Three's a Crowd": hand-built layout, Chip's delayed debut and taunt, rival-vs-rival sim.

static func _rect(game: BeachGame, item: Dictionary) -> Rect2:
	var width: float = game.effects.font.get_string_size(item.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	return Rect2(item.at - Vector2(width * 0.5 + 2.0, 8.0), Vector2(width + 4.0, 11.0))

static func run(host: Node, main: Node, check: Callable) -> void:
	var level: Dictionary = Config.levels[4]
	check.call(level.name == "Three's a Crowd" and int(level.map_version) >= 3 and level.has("world") and level.has("zones") and level.twist.id == "chip_intro", "level 5 is the hand-built Three's a Crowd")
	check.call(not level.has("rivals_after_snatch") and level.rivals.size() == 2 and not bool(level.rivals[0].get("after_snatch", false)) and bool(level.rivals[1].after_snatch) and level.rivals[1].name == "Chip" and float(level.rivals[1].speed) >= 1.1, "Gary starts in the level, fast Chip is held until the first swallow")
	check.call(level.quests.size() == 2 and level.quests[0].id == "l5_fish" and int(level.quests[0].count) == 2 and level.quests[1].id == "l5_mug_chip" and level.quests[1].filter.mugged_from == "Chip" and level.has("random_quest"), "level 5 quests are fish x2, mug Chip plus random")
	var offered: Dictionary = {}
	for spawn: Dictionary in level.spawns:
		offered[str(spawn.get("food_id", ""))] = true
		for food: String in Config.targets[spawn.type].foods:
			offered[food] = true
	for food: String in level.random_foods:
		check.call(offered.has(food), "random quest food %s appears in level 5" % food)
	# Debut: only Gary at the start, Chip and his taunt after the first swallowed snack.
	main.start_level(5)
	var game: BeachGame = main.game
	game.set_physics_process(false)
	await host.settle()
	game.dismiss_intro()
	check.call(game.pilots.size() == 1 and game.pilots[0].gull.rival_name == "Gary" and game.pending_rivals.size() == 1, "level 5 starts with Gary only")
	# Task 027: right side of the beach (palm, bench, bin, rocks) no longer overlaps.
	var view_x: float = 1120.0
	game.camera_x = view_x
	game.camera.position.x = view_x
	game.beach.camera_x = view_x
	await host.snapshot("level5-right-side-props")
	game.camera_x = 0.0
	game.camera.position.x = 0.0
	game.beach.camera_x = 0.0
	var is_taunt: Callable = func(t: Dictionary) -> bool: return t.text == "CHIP: FINDERS KEEPERS!"
	game._swallowed({"id": "hotdog"})
	check.call(game.pilots.size() == 2 and game.pilots[1].gull.rival_name == "Chip", "Chip joins after the first swallow")
	check.call(not game.effects.texts.any(is_taunt) and game.taunt_wait > 0.0, "Chip's taunt waits after he is released")
	game.effects.freeze = 0.0
	game.taunt_wait = 0.0
	game._physics_process(1.0 / 60)
	check.call(not game.effects.texts.any(is_taunt), "taunt is not shown while the score announcement is visible")
	game.overlay.score_announcement.hide()
	game.effects.texts.clear()
	game._physics_process(1.0 / 60)
	var taunt: Array = game.effects.texts.filter(is_taunt)
	check.call(taunt.size() == 1, "Chip's intro taunt is shown once")
	if taunt.size() == 1:
		var chip: Vector2 = game.pilots[1].gull.position
		var box: Rect2 = _rect(game, taunt[0])
		check.call(not box.intersects(Rect2(chip - Vector2(12, 28), Vector2(24, 36))), "taunt covers neither Chip nor his name tag")
		check.call(box.position.x >= game.camera_x - 160.0 and box.end.x <= game.camera_x + 160.0, "taunt stays on screen")
	await host.snapshot("level5-chip-intro")
	# Mugging Chip completes l5_mug_chip.
	var chip_pilot: RivalPilot = game.pilots[1]
	chip_pilot.carried_food_id = "hotdog"
	chip_pilot.took_food(25)
	game.player.position = chip_pilot.gull.position
	game.player.state = BeachGull.State.STRIKE
	game.player.previous_beak = chip_pilot.gull.position
	game.player.sweep_beak = chip_pilot.gull.position
	game._mugging()
	host.eat_pending(game)
	var mug: Array = game.quests.quests.filter(func(q: Dictionary) -> bool: return q.id == "l5_mug_chip")
	check.call(mug.size() == 1 and mug[0].done, "mugging Chip completes l5_mug_chip")
	# Rival sim: both rivals dive and steal, and they contest food.
	var r: Dictionary = await preload("res://tests/rival_ai_checks.gd").simulate(host, main, 5, 90.0)
	print("RIVAL SIM level 5: %s" % str(r))
	check.call(r.pilots == 2, "level 5 sim has Gary and Chip")
	for i: int in r.pilots:
		check.call(r.dives[i] >= 3 and r.thefts[i] >= 1 and r.crashes[i] == 0, "level 5 rival %d dives and steals without crashing (%d dives, %d thefts)" % [i, r.dives[i], r.thefts[i]])
	check.call(r.out_of_bounds == 0 and r.edge_max <= 1.5, "level 5 rivals stay inside the beach")
	check.call(r.shared_target > 0 or main.game.pilots.any(func(p: RivalPilot) -> bool: return p.mugs > 0), "level 5 rivals contest food (%d shared frames)" % r.shared_target)
