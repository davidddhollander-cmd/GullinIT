extends RefCounted
## First-run controls chooser (Arcade and VS), Shift no longer dives, GullPixel has a comma.

static func _reset(options: Dictionary) -> void:
	for key: String in ["controls_chosen","mouse_role","mouse_role_set"]:
		options.erase(key)

static func run(host: Node, check: Callable) -> void:
	var main: Node = host.main
	var saved_path: String = GameState.save_path
	GameState.save_path = "res://test-output/controls-chooser-save.json"
	main.clear_game()
	_reset(GameState.options)
	check.call(main.needs_controls_choice() and not GameState.controls_chosen(),"a fresh desktop save needs the controls chooser")
	# Arcade: choosing a level opens the chooser BEFORE any game exists (no clock or intro runs under it).
	main.start_level(2)
	check.call(is_instance_valid(main.chooser) and main.game == null and main.screen == "controls","Arcade: the chooser opens before the level exists")
	var mouse_only: Button = main.chooser.find_child("MouseOnlyButton",true,false)
	var keys_mouse: Button = main.chooser.find_child("KeyboardMouseButton",true,false)
	await host.settle()
	check.call(mouse_only != null and keys_mouse != null and not mouse_only.get_global_rect().intersects(keys_mouse.get_global_rect()) and mouse_only.has_focus(),"the chooser has two separate clickable panels, the first focused")
	var panel: Control = main.chooser.find_child("Panel",true,false)
	var screen: Rect2 = Rect2(0,0,320,180)
	check.call(screen.encloses(panel.get_global_rect()) and panel.get_global_rect().size.x >= 200 and panel.get_global_rect().size.x <= 270,"the chooser panel is centred and covers most of the canvas width: "+str(panel.get_global_rect()))
	var diagrams: int = 0
	for node: Node in main.chooser.find_children("*","Control",true,false):
		if node.has_method("_layout_keys"):
			diagrams += 1
			var rects: Array[Rect2] = []
			for entry: Dictionary in node.labels:
				rects.append(entry.rect)
			var clear: bool = true
			var why: String = ""
			for i: int in rects.size():
				for j: int in range(i + 1,rects.size()):
					if rects[i].intersects(rects[j]): clear = false; why += " L"+str(i)+"xL"+str(j)
				for line: Rect2 in node.lines:
					if rects[i].intersects(line): clear = false; why += " L"+str(i)+"xline"+str(line)
				for solid: Rect2 in node.solids:
					if rects[i].intersects(solid): clear = false; why += " L"+str(i)+"xsolid"+str(solid)
				if not Rect2(Vector2.ZERO,node.size).encloses(rects[i]): clear = false; why += " L"+str(i)+"out"+str(rects[i])+str(node.size)
			check.call(clear and rects.size() >= 4,"chooser diagram labels ("+str(rects.size())+") do not overlap each other, lines or icons"+why)
	check.call(diagrams == 2,"both chooser panels draw a keybinding diagram")
	host.layout(main.chooser)
	host.menu_font_grid(main.chooser)
	await host.snapshot("controls-chooser")
	mouse_only.pressed.emit()
	check.call(GameState.mouse_role() == "steer" and bool(GameState.options.controls_chosen) and bool(GameState.options.mouse_role_set),"MOUSE ONLY sets the steer role and the chosen flag")
	check.call(not is_instance_valid(main.chooser) and main.game != null and int(main.game.level.id) == 2,"after the choice the Arcade run starts")
	main.clear_game()
	main.start_level(3)
	check.call(not is_instance_valid(main.chooser) and main.game != null,"the chooser never returns to Arcade once chosen")
	# VS: after FIGHT!, before the VS intro card.
	main.clear_game()
	_reset(GameState.options)
	main._navigate("vs_start",{"arena": "scrap_sands","opponents": ["doreen"]})
	check.call(is_instance_valid(main.chooser) and main.game == null,"VS: the chooser opens before the match exists")
	main.chooser.find_child("KeyboardMouseButton",true,false).pressed.emit()
	check.call(GameState.mouse_role() == "dive_aim" and not GameState.key_flight and bool(GameState.options.controls_chosen),"KEYBOARD + MOUSE sets the dive_aim role")
	check.call(main.game != null and main.game.is_vs(),"after the choice the VS match starts")
	var game: BeachGame = main.game
	game.set_physics_process(false)
	game.intro = 0
	game.overlay.show_rival_popup("Doreen",game._rival_head("herring"),str(Config.vs.opponents.doreen.entry_text),6.0)
	await host.settle()
	await host.snapshot("vs-taunt-comma")
	check.call(BeachUI.PIXEL_FONT.has_char(44) and BeachUI.PIXEL_FONT.get_string_size(",",HORIZONTAL_ALIGNMENT_LEFT,-1,8).x > 0.0,"GullPixel has a comma glyph")
	check.call(BeachUI.PIXEL_FONT.has_char(59),"GullPixel has a semicolon glyph")
	main.clear_game()
	main._navigate("vs_start",{"arena": "scrap_sands","opponents": ["gary"]})
	check.call(not is_instance_valid(main.chooser) and main.game != null,"the chooser never returns to VS once chosen")
	# Older saves that already picked a mouse role never see it.
	main.clear_game()
	GameState.options.erase("controls_chosen")
	GameState.options.mouse_role_set = true
	check.call(GameState.controls_chosen() and not main.needs_controls_choice(),"a save with mouse_role_set counts as chosen")
	# Escape out of the chooser returns to the title with nothing pending.
	_reset(GameState.options)
	main.start_level(1)
	main._navigate("title")
	check.call(not is_instance_valid(main.chooser) and main.game == null and main.screen == "title","leaving the chooser (Esc) drops the pending run")
	# Shift no longer dives; right mouse, pad B stay.
	var dive_keys: Array = InputMap.action_get_events("dive").filter(func(e: InputEvent) -> bool: return e is InputEventKey)
	check.call(dive_keys.is_empty(),"no keyboard key is bound to dive (Shift removed)")
	var shift: InputEventKey = InputEventKey.new()
	shift.physical_keycode = KEY_SHIFT
	shift.pressed = true
	check.call(not InputMap.event_is_action(shift,"dive"),"Shift does not match the dive action")
	var right: InputEventMouseButton = InputEventMouseButton.new()
	right.button_index = MOUSE_BUTTON_RIGHT
	right.pressed = true
	check.call(InputMap.event_is_action(right,"dive"),"right click still dives")
	check.call(not str(Config.trainer.keys.keyboard.dive).to_lower().contains("shift"),"keyboard prompts no longer mention Shift")
	# Restore what later suites expect: chosen (so runs start), default mouse role.
	_reset(GameState.options)
	GameState.options.controls_chosen = true
	GameState.save_path = saved_path
