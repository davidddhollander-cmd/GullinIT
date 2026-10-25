extends RefCounted
## Task 015: title SHOP button, FEATHER SHOP screen, buying, and the picker perk row.

static func _item(main: Node, id: String) -> Button:
	return main.menus.find_child("Item_" + id, true, false) as Button

static func _status(button: Button) -> String:
	return (button.find_child("Status", true, false) as Label).text

static func run(suite: Node, check: Callable) -> void:
	var main: Node = suite.main
	var saved_wallet: Dictionary = GameState.wallet.duplicate(true)
	var saved_progress: Dictionary = GameState.progress.duplicate(true)
	var saved_options: Dictionary = GameState.options.duplicate(true)
	Config.species.unlock_all = false
	GameState.wallet = {"feathers": 0}
	GameState.progress.erase("stage1_complete")
	GameState.options.perk = ""
	# SHOP button: always there, disabled until Stage 1 is beaten.
	main._navigate("title")
	await suite.settle()
	check.call(main.menus.find_child("ShopButton", true, false) == null, "the main menu has no SHOP button")
	suite.layout(main.menus)
	suite.menu_font_grid(main.menus)
	main._navigate("shop")
	check.call(main.screen == "title", "the shop will not open before stage1_complete")
	GameState.set_flag("stage1_complete")
	main._navigate("title")
	await suite.settle()
	main._navigate("shop")
	await suite.settle()
	check.call(main.screen == "shop", "SHOP opens the feather shop")
	# Poor: everything greyed, buying does nothing.
	var bullet: Button = _item(main, "bullet_time")
	check.call(bullet.disabled and _status(bullet) == "5 FEATHERS", "a perk you cannot afford shows its price greyed")
	main._navigate("buy", "bullet_time")
	check.call(not GameState.owns("bullet_time") and GameState.feathers() == 0, "buying with too few Feathers does nothing")
	# Rich enough for kittiwake (6) + keen eye (3), not bullet time.
	GameState.wallet.feathers = 10
	main._navigate("shop")
	await suite.settle()
	check.call(_status(_item(main, "kittiwake")) == "BUY  6" and _status(_item(main, "keen_eye")) == "BUY  3", "affordable items read BUY n")
	main._navigate("buy", "keen_eye")
	await suite.settle()
	check.call(GameState.owns("keen_eye") and GameState.feathers() == 7, "buying a perk spends its price")
	check.call((main.menus.find_child("Message", true, false) as Label).text == "BOUGHT!", "a purchase shows BOUGHT!")
	check.call((main.menus.find_child("Feathers", true, false) as Label).text == "FEATHERS 7", "the total updates after buying")
	check.call(_item(main, "keen_eye").disabled and _status(_item(main, "keen_eye")) == "OWNED", "a bought perk reads OWNED")
	main._navigate("buy", "keen_eye")
	check.call(GameState.feathers() == 7, "buying an owned item again does not charge")
	check.call(not GameState.buy("keen_eye", 3) and GameState.feathers() == 7, "GameState.buy refuses an owned item")
	main._navigate("buy", "kittiwake")
	await suite.settle()
	check.call(GameState.feathers() == 1 and GameState.gull_owned("kittiwake"), "buying a species spends 6 and unlocks it")
	suite.layout(main.menus)
	suite.menu_font_grid(main.menus)
	await suite.snapshot("shop")
	# Picker: bought gull pickable, perk row cycles and persists.
	main._navigate("arcade")
	await suite.settle()
	check.call(not (main.menus.find_child("Card_kittiwake", true, false) as Button).disabled, "a bought species is pickable in the picker")
	check.call((main.menus.find_child("Card_great-black-backed", true, false) as Button).disabled, "an unbought species stays locked")
	var pick: Button = main.menus.find_child("PerkPick", true, false) as Button
	check.call(pick != null and pick.text == "PERK:  < NONE >", "the picker shows a perk row once a perk is owned")
	pick.pressed.emit()
	check.call(GameState.equipped_perk() == "keen_eye" and pick.text == "PERK:  < KEEN EYE >", "clicking the perk row equips the next owned perk")
	var left := InputEventAction.new()
	left.action = "ui_left"
	left.pressed = true
	pick.gui_input.emit(left)
	check.call(GameState.equipped_perk() == "" and pick.text == "PERK:  < NONE >", "left cycles back to NONE")
	GameState.wallet.feathers = 5
	main._navigate("shop")
	main._navigate("buy", "bullet_time")
	main._navigate("arcade")
	await suite.settle()
	pick = main.menus.find_child("PerkPick", true, false) as Button
	pick.pressed.emit()
	pick.pressed.emit()
	check.call(GameState.equipped_perk() == "bullet_time" and pick.text == "PERK:  < BULLET TIME >", "the perk row cycles through every owned perk")
	await suite.settle()
	suite.layout(main.menus)
	suite.menu_font_grid(main.menus)
	for id: String in ["herring", "great-black-backed", "kittiwake"]:
		var card: Button = main.menus.find_child("Card_" + id, true, false)
		var inner: Control = card.get_child(0) as Control
		check.call(inner.get_rect().end.y <= card.size.y + 0.5, "picker card content fits inside its card with the perk row shown: " + id + " " + str(inner.get_rect().end.y) + " in " + str(card.size.y))
	await suite.snapshot("gull-picker-perk")
	GameState.options.perk = ""
	GameState.wallet = {"feathers": 0}
	GameState.load_progress()
	check.call(GameState.equipped_perk() == "bullet_time" and GameState.owns("keen_eye") and GameState.owns("kittiwake"), "bought items and the equipped perk persist through save/load")
	# The perk row hides when nothing is owned.
	GameState.wallet = {"feathers": 0}
	main._navigate("arcade")
	await suite.settle()
	check.call(main.menus.find_child("PerkPick", true, false) == null, "no perk row when no perk is owned")
	GameState.wallet = saved_wallet
	GameState.progress = saved_progress
	GameState.options = saved_options
	main._navigate("title")
