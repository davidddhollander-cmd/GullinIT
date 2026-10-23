extends RefCounted
## Task 014: PICK YOUR GULL screen, saved choice, and the per-species player stats.
const BossChecks: GDScript = preload("res://tests/boss_checks.gd")
const IDS: Array[String] = ["herring", "great-black-backed", "kittiwake"]

static func _gull(host: Node, id: String) -> BeachGull:
	var gull := BeachGull.new()
	gull.species = id
	host.add_child(gull)
	gull.apply_species_stats()
	gull.position = Vector2(300, 60)
	gull.aim = gull.position
	return gull

static func _button(root: Node, text: String) -> Button:
	for node: Node in root.find_children("*", "Button", true, false):
		if (node as Button).text == text:
			return node as Button
	return null

static func _stats(host: Node, check: Callable) -> void:
	var data: Dictionary = Config.species.species
	var f: Dictionary = Config.tuning.flight
	var d: Dictionary = Config.tuning.dive
	var w: Dictionary = Config.tuning.wind
	var drift: Dictionary = {}
	for id: String in IDS:
		var s: Dictionary = data[id]
		# Flight: cruise speed is the base multiplied by the species value.
		var flyer: BeachGull = _gull(host, id)
		flyer.aim = flyer.position + Vector2(500, 0)
		for i: int in 240:
			flyer.tick(1.0 / 60, 0, 0.0)
			flyer.position.y = 60.0
			flyer.velocity.y = 0.0
			flyer.position.x = 300.0
		check.call(is_equal_approx(flyer.velocity.x, float(f.max_speed) * float(s.flight)), id + " flight speed follows data/species.json")
		flyer.queue_free()
		# Dive: the speed cap scales.
		var diver: BeachGull = _gull(host, id)
		diver.state = BeachGull.State.STRIKE
		diver.direction = Vector2.DOWN
		diver.aim = diver.position + Vector2(0, 90)
		diver.dive_speed = 9999.0
		diver.tick(1.0 / 60, 0, 0.0)
		check.call(is_equal_approx(diver.dive_speed, float(d.max_speed) * float(s.dive)), id + " dive speed follows data/species.json")
		diver.queue_free()
		# Wind push: drift while winding up (no steering) scales.
		var drifter: BeachGull = _gull(host, id)
		drifter.state = BeachGull.State.WINDUP
		drifter.timer = 99.0
		for i: int in 30:
			drifter.tick(1.0 / 60, 1, 1.0)
			drifter.position.y = 60.0
			drifter.velocity.y = 0.0
		drift[id] = drifter.position.x - 300.0
		drifter.queue_free()
		# Stun: the tumble lasts duration * stun.
		var tumbler: BeachGull = _gull(host, id)
		tumbler.stun()
		check.call(is_equal_approx(tumbler.timer, float(Config.tuning.tumble.duration) * float(s.stun)), id + " stun duration follows data/species.json")
		tumbler.queue_free()
	for id: String in IDS:
		check.call(drift["herring"] > 0.0 and is_equal_approx(drift[id] / drift["herring"], float(data[id].wind)), id + " wind push follows data/species.json")

static func _shove(suite: Node, check: Callable) -> void:
	suite.main.start_level(6)
	var game: BeachGame = suite.main.game
	game.set_physics_process(false)
	game.running = true
	game.intro = 0
	var pilot: RivalPilot = game.pilots[0]
	var food_target: BeachTarget
	for target: BeachTarget in game.spawner.targets:
		if target.food:
			food_target = target
			break
	pilot.target = food_target
	var food: Vector2 = food_target.food_position()
	for id: String in ["herring", "great-black-backed"]:
		game.player.species = id
		game.player.apply_species_stats()
		pilot.gull.state = BeachGull.State.GROUNDED
		BossChecks._strike_at(pilot.gull, food)
		BossChecks._strike_at(game.player, food + Vector2(8, 0))
		var points: int = game.score.points
		BeachBoss.shove_player(game)
		var bumped: bool = pilot.gull.state == BeachGull.State.STUNNED
		check.call(bumped == (id == "great-black-backed") and game.score.points == points and game.player.state == BeachGull.State.STRIKE, id + " player " + ("bumps" if bumped else "leaves alone") + " a rival diving for the same food")
	pilot.gull.state = BeachGull.State.GROUNDED
	BossChecks._strike_at(pilot.gull, food + Vector2(70, 0))
	BeachBoss.shove_player(game)
	check.call(pilot.gull.state == BeachGull.State.STRIKE, "the shove only reaches rivals within shove radius of the food")
	suite.main.clear_game()

static func run(suite: Node, check: Callable) -> void:
	var main: Node = suite.main
	await _stats(suite, check)
	await _shove(suite, check)
	# Picker flow.
	GameState.options.gull = "kittiwake"
	main._navigate("arcade")
	await suite.settle()
	check.call(main.screen == "pick" and main.menus.find_child("Card_herring", true, false) != null, "ARCADE opens PICK YOUR GULL before level select")
	check.call(main.menus.get_viewport().gui_get_focus_owner() == main.menus.find_child("Card_kittiwake", true, false), "the last pick is pre-selected")
	suite.layout(main.menus)
	suite.menu_font_grid(main.menus)
	for id: String in IDS:
		var card: Button = main.menus.find_child("Card_" + id, true, false)
		check.call(card != null and not card.disabled and (card.find_child("Status", true, false) as Label).text == "UNLOCKED", id + " card is pickable and says UNLOCKED")
		var has_sprite := false
		for sprite: AnimatedSprite2D in card.find_children("*", "AnimatedSprite2D", true, false):
			has_sprite = sprite.sprite_frames == Config.frames("gull_" + id.replace("-", "_")) and sprite.is_playing()
		check.call(has_sprite, id + " card shows the animated species sprite")
	_button(main.menus, "< BACK").pressed.emit()
	check.call(main.screen == "title", "BACK on the picker returns to the title")
	main._navigate("casual")
	(main.menus.find_child("Card_great-black-backed", true, false) as Button).pressed.emit()
	await suite.settle()
	check.call(main.screen == "select" and main.casual and GameState.options.gull == "great-black-backed", "picking a gull saves it and opens level select")
	main.start_level(2)
	check.call(main.game.player.species == "great-black-backed" and main.game.player.shoves and is_equal_approx(main.game.player.stun_mult, float(Config.species.species["great-black-backed"].stun)), "the picked species is the player in game")
	main.clear_game()
	# Locked species when unlock_all is off.
	Config.species.unlock_all = false
	main._navigate("arcade")
	await suite.settle()
	for id: String in ["great-black-backed", "kittiwake"]:
		var card: Button = main.menus.find_child("Card_" + id, true, false)
		check.call(card.disabled and (card.find_child("Status", true, false) as Label).text == "UNLOCK: 6 FEATHERS", id + " shows UNLOCK: 6 FEATHERS and is not pickable")
	check.call(not (main.menus.find_child("Card_herring", true, false) as Button).disabled, "the free herring gull stays pickable")
	suite.layout(main.menus)
	suite.menu_font_grid(main.menus)
	main._navigate("gull", "kittiwake")
	check.call(GameState.options.gull == "great-black-backed" and main.screen == "pick", "a locked gull cannot be chosen")
	check.call(GameState.chosen_gull() == "herring", "a saved gull that is not owned falls back to herring")
	Config.species.unlock_all = true
	GameState.options.gull = "herring"
	main._navigate("title")
