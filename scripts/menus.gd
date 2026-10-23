class_name BeachMenus
extends Control
signal requested(action: String, payload: Variant)
var content: VBoxContainer
var back_action: String = "title"

func _ready() -> void:
	theme = BeachUI.theme()
	BeachUI.full(self)

func clear(title: String, subtitle: String = "", card: bool = false) -> VBoxContainer:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	var margin: MarginContainer = BeachUI.margin(self,12)
	var panel: PanelContainer = BeachUI.panel(margin,Color(0.094,0.23,0.30,0.72 if card else 0.96))
	if card:
		panel.size_flags_horizontal = SIZE_SHRINK_BEGIN
		panel.size_flags_vertical = SIZE_SHRINK_CENTER
	content = VBoxContainer.new()
	panel.add_child(content)
	BeachUI.label(content,title,BeachUI.FONT_DISPLAY,BeachUI.GOLD)
	if not subtitle.is_empty():
		BeachUI.label(content,subtitle,BeachUI.FONT_NATIVE,Color("a9d7d2"))
	return content

func choose(action: String, payload: Variant = null) -> void:
	requested.emit(action,payload)

func hint(parent: Control, text: String) -> void:
	var node: Label = BeachUI.label(parent,text,8,Color("80bcb8"))
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.custom_minimum_size.x = 150

const GLINT: Shader = preload("res://assets/shaders/title_glint.gdshader")

func title() -> void:
	clear("GULLIN' IT", "The No. 1 Seagull Simulator", true)
	var heading: Label = content.get_child(0) as Label
	content.get_child(1).add_theme_color_override("font_color",Color("ef725c"))
	var logo: TextureRect = TextureRect.new()
	logo.texture = load("res://assets/sprites/title-logo.png")
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_SCALE
	logo.size = Vector2(175,26)
	logo.position.y = 1.5
	logo.material = ShaderMaterial.new()
	logo.material.shader = GLINT
	var slot: Control = Control.new()
	slot.custom_minimum_size = Vector2(175,29)
	slot.add_child(logo)
	content.add_child(slot)
	content.move_child(slot,0)
	content.remove_child(heading)
	heading.queue_free()
	var tween: Tween = logo.create_tween().set_loops()
	tween.tween_property(logo,"position:y",3.0,1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(logo,"position:y",0.0,1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var gap: Control = Control.new()
	gap.custom_minimum_size.y = 2
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
	hint(content,"AIM. CLIMB. DIVE. SNATCH.")
	hint(content,"MOUSE / KEYS / PAD / TOUCH")

func level_select(casual: bool) -> void:
	var trained: bool = bool(GameState.entry(1).get("training_complete", false))
	clear("PICK YOUR BEACH", "PRACTICE / 15 SNATCHES. NO TIMER" if casual else ("ARCADE / TRAINING DAY FIRST" if not trained else "ARCADE / EARN A STAR TO MOVE ON"))
	content.add_theme_constant_override("separation",2)
	var outer: MarginContainer = content.get_parent().get_parent() as MarginContainer
	for edge: String in ["top","bottom"]:
		outer.add_theme_constant_override("margin_" + edge,6)
	var feathers: Label = BeachUI.label(self,"FEATHERS %d" % GameState.feathers(),BeachUI.FONT_NATIVE,BeachUI.CREAM)
	feathers.name = "Feathers"
	feathers.position = Vector2(188,20)
	feathers.size = Vector2(108,9)
	feathers.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
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
		var quest_total: int = (level.get("quests",[]) as Array).size() + int(level.has("random_quest")) if id > 1 or trained else 0
		var quest_line: String = "Q %d/%d" % [(record.get("quests",[]) as Array).size(),quest_total] if unlocked and quest_total > 0 else ""
		var caption: String = "%02d %s\n%s\n%s" % [id,("%s %s" % [stars,quest_line]).strip_edges(),level.name.to_upper().replace(" ","\n"),status]
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

func gull_picker() -> void:
	clear("PICK YOUR GULL")
	content.add_theme_constant_override("separation",3)
	var outer: MarginContainer = content.get_parent().get_parent() as MarginContainer
	for edge: String in ["top","bottom"]:
		outer.add_theme_constant_override("margin_" + edge,6)
	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_vertical = SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation",4)
	content.add_child(row)
	var chosen: String = GameState.chosen_gull()
	for id: String in Config.species.species:
		var info: Dictionary = Config.species.species[id]
		var owned: bool = GameState.gull_owned(id)
		var card: Button = BeachUI.button(row,"",func() -> void: choose("gull",id),82)
		card.name = "Card_" + id
		card.size_flags_horizontal = SIZE_EXPAND_FILL
		card.size_flags_vertical = SIZE_EXPAND_FILL
		card.disabled = not owned
		var box: VBoxContainer = VBoxContainer.new()
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_theme_constant_override("separation",2)
		card.add_child(box)
		BeachUI.full(box)
		box.offset_left = 3
		box.offset_right = -3
		box.offset_top = 3
		box.offset_bottom = -3
		var stage: Control = Control.new()
		stage.custom_minimum_size = Vector2(0,30)
		stage.clip_contents = true
		stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(stage)
		var art_id: String = "gull_" + id.replace("-","_")
		var bird: AnimatedSprite2D = AnimatedSprite2D.new()
		bird.sprite_frames = Config.frames(art_id)
		bird.scale = Vector2.ONE * float(Config.sprites[art_id].visual_scale) * 1.5
		bird.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		bird.modulate = Color.WHITE if owned else Color(0.5,0.55,0.6)
		bird.position = Vector2(50,16) # the frames carry the bird left of centre
		bird.play(&"glide")
		stage.add_child(bird)
		var name_label: Label = BeachUI.label(box,str(info.name),BeachUI.FONT_NATIVE,BeachUI.GOLD if owned else Color("6b858b"))
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var blurb: Label = BeachUI.label(box,str(info.blurb),BeachUI.FONT_NATIVE,Color("a9d7d2") if owned else Color("6b858b"))
		blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		blurb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		blurb.size_flags_vertical = SIZE_EXPAND_FILL
		var status: Label = BeachUI.label(box,"UNLOCKED" if owned else "UNLOCK: %d FEATHERS" % int(info.price),BeachUI.FONT_NATIVE,BeachUI.CREAM if owned else BeachUI.CORAL)
		status.name = "Status"
		status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if id == chosen:
			card.grab_focus()
	BeachUI.button(content,"< BACK",func() -> void: choose("title"),100).size_flags_horizontal = SIZE_SHRINK_CENTER

func pause() -> void:
	clear("TAKING A BREATHER", "YOUR LUNCH CAN WAIT.")
	var resume: Button = BeachUI.button(content,"RESUME",func() -> void: choose("resume"))
	resume.grab_focus()
	BeachUI.button(content,"RESTART",func() -> void: choose("restart"))
	var pair: HBoxContainer = HBoxContainer.new()
	content.add_child(pair)
	var rules: Button = BeachUI.button(pair,"SCORE RULES",func() -> void: pass)
	rules.size_flags_horizontal = SIZE_EXPAND_FILL
	rules.pressed.connect(func() -> void:
		ScoreRulesCard.open(self,"BACK").closed.connect(func() -> void:
			if is_instance_valid(rules):
				rules.grab_focus()))
	BeachUI.button(pair,"OPTIONS",func() -> void: choose("options_pause")).size_flags_horizontal = SIZE_EXPAND_FILL
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
	for key: String in ["shake","touch","stats"]:
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
