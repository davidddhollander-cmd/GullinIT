class_name BeachMenus
extends Control
signal requested(action: String, payload: Variant)
var content: VBoxContainer
var back_action: String = "title"

func _ready() -> void:
	theme = BeachUI.theme()
	BeachUI.full(self)

func clear(title: String, subtitle: String = "") -> VBoxContainer:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	var margin: MarginContainer = BeachUI.margin(self,12)
	var panel: PanelContainer = BeachUI.panel(margin,Color(0.094,0.23,0.30,0.96))
	content = VBoxContainer.new()
	panel.add_child(content)
	BeachUI.label(content,title,BeachUI.FONT_DISPLAY,BeachUI.GOLD)
	if not subtitle.is_empty():
		BeachUI.label(content,subtitle,BeachUI.FONT_NATIVE,Color("a9d7d2"))
	return content

func choose(action: String, payload: Variant = null) -> void:
	requested.emit(action,payload)

func title() -> void:
	clear("GULLIN' IT", "SMALL BIRD. BIG APPETITE.")
	var gap: Control = Control.new()
	gap.custom_minimum_size.y = 6
	content.add_child(gap)
	var row: HBoxContainer = HBoxContainer.new()
	content.add_child(row)
	var buttons: VBoxContainer = VBoxContainer.new()
	row.add_child(buttons)
	BeachUI.button(buttons,"ARCADE  >",func() -> void: choose("arcade"),115).grab_focus()
	BeachUI.button(buttons,"CASUAL  /  PRACTICE",func() -> void: choose("casual"),115)
	var small: HBoxContainer = HBoxContainer.new()
	buttons.add_child(small)
	BeachUI.button(small,"OPTIONS",func() -> void: choose("options"))
	if not OS.has_feature("web"):
		BeachUI.button(small,"QUIT",func() -> void: choose("quit"))
	var art: TextureRect = TextureRect.new()
	art.texture = Config.frames("player_gull").get_frame_texture(&"glide",0)
	art.custom_minimum_size = Vector2(112,65)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(art)
	BeachUI.label(content,"AIM. CLIMB. DIVE. BORROW SOME LUNCH.",8,Color("80bcb8"))
	BeachUI.label(content,"MOUSE / KEYS / CONTROLLER / TOUCH",8,Color("80bcb8"))

func level_select(casual: bool) -> void:
	var trained: bool = bool(GameState.entry(1).get("training_complete", false))
	clear("PICK YOUR BEACH", "PRACTICE / 15 SNATCHES, NO TIMER" if casual else ("ARCADE / TRAINING DAY FIRST" if not trained else "ARCADE / EARN A STAR TO MOVE ON"))
	content.add_theme_constant_override("separation",2)
	var outer: MarginContainer = content.get_parent().get_parent() as MarginContainer
	for edge: String in ["top","bottom"]:
		outer.add_theme_constant_override("margin_" + edge,6)
	var grid: GridContainer = GridContainer.new()
	grid.columns = 3
	grid.size_flags_vertical = SIZE_EXPAND_FILL
	content.add_child(grid)
	for level: Dictionary in Config.levels:
		var id: int = level.id
		var record: Dictionary = GameState.entry(id)
		var unlocked: bool = GameState.unlocked(id)
		var stars: String = "*".repeat(int(record.get("stars",0)))
		var status: String = "FULL GAME" if GameState.demo_locked(id) else ("LOCKED" if not unlocked else (("REPLAY LESSONS" if trained else "BEGIN LESSON") if id == 1 else "BEST %d" % int(record.get("best",0))))
		var caption: String = "%02d %s\n%s\n%s" % [id,stars,level.name.to_upper().replace(" ","\n"),status]
		var button: Button = BeachUI.button(grid,caption,func() -> void: choose("start",id),82)
		button.size_flags_horizontal = SIZE_EXPAND_FILL
		button.size_flags_vertical = SIZE_EXPAND_FILL
		button.disabled = not unlocked
		if id == 1:
			button.grab_focus()
	var actions: HBoxContainer = HBoxContainer.new()
	content.add_child(actions)
	var with_feedback: bool = not GameState.feedback_url().is_empty()
	var action_width: int = 86 if with_feedback else 100
	if trained:
		BeachUI.button(actions,"TRAIN AGAIN",func() -> void: choose("train_again"),action_width)
	if with_feedback:
		BeachUI.button(actions,"FEEDBACK",func() -> void: choose("feedback"),action_width)
	BeachUI.button(actions,"< BACK",func() -> void: choose("title"),action_width)

func pause() -> void:
	clear("TAKING A BREATHER", "YOUR LUNCH CAN WAIT.")
	BeachUI.button(content,"RESUME",func() -> void: choose("resume")).grab_focus()
	BeachUI.button(content,"RESTART",func() -> void: choose("restart"))
	BeachUI.button(content,"OPTIONS",func() -> void: choose("options_pause"))
	BeachUI.button(content,"LEVEL SELECT",func() -> void: choose("select"))

func options(from_pause: bool) -> void:
	clear("MAKE YOURSELF AT HOME")
	content.add_theme_constant_override("separation", 2)
	back_action = "pause" if from_pause else "title"
	for bus: String in ["Master","SFX","Music"]:
		var row: HBoxContainer = HBoxContainer.new()
		content.add_child(row)
		BeachUI.label(row,bus.to_upper()).custom_minimum_size.x = 55
		var slider: HSlider = HSlider.new()
		slider.size_flags_horizontal = SIZE_EXPAND_FILL
		slider.min_value = 0
		slider.max_value = 1
		slider.step = 0.05
		slider.value = GameState.options[bus]
		slider.custom_minimum_size.y = 12
		row.add_child(slider)
		slider.value_changed.connect(func(value: float) -> void:
			GameState.options[bus] = value
			Audio.apply_options())
	var toggles: HBoxContainer = HBoxContainer.new()
	content.add_child(toggles)
	for key: String in ["shake","touch"]:
		var toggle: Button = BeachUI.button(toggles,key.to_upper()+": "+("ON" if GameState.options[key] else "OFF"),func() -> void:
			GameState.options[key] = not bool(GameState.options[key])
			options(from_pause))
		toggle.size_flags_horizontal = SIZE_EXPAND_FILL
	if not OS.has_feature("mobile"):
		BeachUI.button(content,"FULLSCREEN / F11",func() -> void: choose("fullscreen"))
	BeachUI.button(content,"SAVE / BACK",func() -> void:
		GameState.save_progress()
		choose(back_action)).grab_focus()

func results(level: Dictionary, result: Dictionary) -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	var board := ResultBoard.new()
	add_child(board)
	board.requested.connect(choose)
	board.setup(level, result)
