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
	var margin: MarginContainer = BeachUI.margin(self,6)
	var panel: PanelContainer = BeachUI.wood_panel(margin)
	_ink_labels.call_deferred()
	if card:
		panel.size_flags_horizontal = SIZE_SHRINK_BEGIN
		panel.size_flags_vertical = SIZE_SHRINK_CENTER
	content = VBoxContainer.new()
	panel.add_child(content)
	BeachUI.label(content,title,BeachUI.FONT_DISPLAY,BeachUI.GOLD)
	if not subtitle.is_empty():
		BeachUI.label(content,subtitle,BeachUI.FONT_NATIVE,Color("a9d7d2"))
	return content

# Menu text was picked for dark panels; on the cream board, swap the light colours for dark ones.
# Labels inside buttons keep their colours (buttons stay dark teal).
const ON_CREAM: Dictionary = {
	BeachUI.CREAM: BeachUI.INK,
	BeachUI.GOLD: Color("a8581c"),
	Color("a9d7d2"): Color("397a85"),
	Color("80bcb8"): Color("397a85"),
}

func _ink_labels(node: Node = self) -> void:
	for child: Node in node.get_children():
		if child is Button:
			continue
		if child is Label:
			var color: Color = (child as Label).get_theme_color("font_color")
			if ON_CREAM.has(color):
				(child as Label).add_theme_color_override("font_color",ON_CREAM[color])
		_ink_labels(child)

func choose(action: String, payload: Variant = null) -> void:
	requested.emit(action,payload)

func hint(parent: Control, text: String) -> void:
	var node: Label = BeachUI.label(parent,text,8,Color("80bcb8"))
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.custom_minimum_size.x = 150

const GLINT: Shader = preload("res://assets/shaders/title_glint.gdshader")

func title() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	# Logo and tagline float centred over the beach; the buttons sit in a small wood box on the left.
	var margin: MarginContainer = BeachUI.margin(self,6)
	var column: VBoxContainer = VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation",4)
	margin.add_child(column)
	var logo: TextureRect = TextureRect.new()
	logo.texture = load("res://assets/sprites/title-logo.png")
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_SCALE
	logo.size = Vector2(175,26)
	logo.position.y = 1.5
	logo.material = ShaderMaterial.new()
	logo.material.shader = GLINT
	var slot: Control = Control.new()
	slot.custom_minimum_size = Vector2(175,29)
	slot.size_flags_horizontal = SIZE_SHRINK_CENTER
	slot.add_child(logo)
	column.add_child(slot)
	var tween: Tween = logo.create_tween().set_loops()
	tween.tween_property(logo,"position:y",3.0,1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(logo,"position:y",0.0,1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var tagline: Label = BeachUI.label(column,"The No. 1 Seagull Simulator",BeachUI.FONT_NATIVE,BeachUI.GOLD)
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# The bitmap font ignores outlines; a 1 px ink shadow lifts the gold off the sunset sky.
	tagline.add_theme_color_override("font_shadow_color",BeachUI.INK)
	tagline.add_theme_constant_override("shadow_offset_x",1)
	tagline.add_theme_constant_override("shadow_offset_y",1)
	var panel: PanelContainer = BeachUI.wood_panel(column)
	panel.size_flags_horizontal = SIZE_SHRINK_BEGIN
	content = VBoxContainer.new()
	content.custom_minimum_size.x = 104
	panel.add_child(content)
	_small_button(content,"ARCADE  >",func() -> void: choose("arcade")).grab_focus()
	_small_button(content,"CASUAL  /  PRACTICE",func() -> void: choose("casual"))
	var coming: Button = _small_button(content,"VS / COOP - LATER",func() -> void: pass)
	coming.name = "ComingSoonButton"
	coming.disabled = true
	var small: HBoxContainer = HBoxContainer.new()
	content.add_child(small)
	_small_button(small,"OPTIONS",func() -> void: choose("options"))
	if not OS.has_feature("web"):
		_small_button(small,"QUIT",func() -> void: choose("quit"))

func level_select(casual: bool) -> void:
	var trained: bool = bool(GameState.entry(1).get("training_complete", false))
	clear("PICK YOUR BEACH", "PRACTICE / 15 SNATCHES. NO TIMER" if casual else ("ARCADE / TRAINING DAY FIRST" if not trained else "ARCADE / EARN A STAR TO MOVE ON"))
	content.add_theme_constant_override("separation",2)
	var outer: MarginContainer = content.get_parent().get_parent() as MarginContainer
	for edge: String in ["top","bottom","left","right"]:
		outer.add_theme_constant_override("margin_" + edge,0)
	var feathers: Label = BeachUI.label(self,"FEATHERS %d" % GameState.feathers(),BeachUI.FONT_NATIVE,BeachUI.CREAM)
	feathers.name = "Feathers"
	feathers.position = Vector2(188,20)
	feathers.size = Vector2(108,9)
	feathers.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	BeachUI.feather_icon(feathers)
	# Seven cards: three on the first row (Training Day's REPLAY LESSONS card is wide), four on the second.
	var grid: VBoxContainer = VBoxContainer.new()
	grid.size_flags_vertical = SIZE_EXPAND_FILL
	grid.add_theme_constant_override("separation",2)
	content.add_child(grid)
	var rows: Array[HBoxContainer] = []
	for row_index: int in 2:
		var level_row: HBoxContainer = HBoxContainer.new()
		level_row.size_flags_vertical = SIZE_EXPAND_FILL
		level_row.add_theme_constant_override("separation",2)
		grid.add_child(level_row)
		rows.append(level_row)
	for level: Dictionary in Config.levels:
		var id: int = level.id
		var record: Dictionary = GameState.entry(id)
		var unlocked: bool = GameState.unlocked(id)
		var stars: String = "*".repeat(int(record.get("stars",0)))
		var status: String = "FULL GAME" if GameState.demo_locked(id) else ("LOCKED" if not unlocked else (("REPLAY LESSONS" if trained else "BEGIN LESSON") if id == 1 else ""))
		var caption: String = "%02d %s
%s
%s" % [id,stars,level.name.to_upper().replace(" ","
"),status]
		var button: Button = BeachUI.button(rows[0] if id <= 3 else rows[1],caption,func() -> void: choose("start",id),60)
		button.size_flags_horizontal = SIZE_EXPAND_FILL
		button.size_flags_vertical = SIZE_EXPAND_FILL
		button.disabled = not unlocked
		if id == 1:
			button.grab_focus()
	var actions: HBoxContainer = HBoxContainer.new()
	content.add_child(actions)
	var with_feedback: bool = not GameState.feedback_url().is_empty()
	var action_width: int = 86 if with_feedback else 100
	if with_feedback:
		BeachUI.button(actions,"FEEDBACK",func() -> void: choose("feedback"),action_width)
	BeachUI.back_button(actions,"< BACK",func() -> void: choose("title"))

func gull_picker() -> void:
	clear("PICK YOUR GULL")
	content.add_theme_constant_override("separation",3)
	var outer: MarginContainer = content.get_parent().get_parent() as MarginContainer
	for edge: String in ["top","bottom"]:
		outer.add_theme_constant_override("margin_" + edge,0)
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
		stage.custom_minimum_size = Vector2(0,14)
		stage.clip_contents = true
		stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(stage)
		var art_id: String = "gull_" + id.replace("-","_")
		var bird: AnimatedSprite2D = AnimatedSprite2D.new()
		bird.sprite_frames = Config.frames(art_id)
		bird.scale = Vector2.ONE * float(Config.sprites[art_id].visual_scale) * 1.0
		bird.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		bird.modulate = Color.WHITE if owned else Color(0.5,0.55,0.6)
		bird.position = Vector2(50,8) # the frames carry the bird left of centre
		bird.play(&"glide")
		stage.add_child(bird)
		var name_label: Label = BeachUI.label(box,str(info.name),BeachUI.FONT_NATIVE,BeachUI.GOLD if owned else Color("6b858b"))
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var blurb: Label = BeachUI.label(box,str(info.blurb),BeachUI.FONT_NATIVE,Color("a9d7d2") if owned else Color("6b858b"))
		blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		blurb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		blurb.size_flags_vertical = SIZE_EXPAND_FILL
		_stat_rows(box,info.get("card",{}),owned)
		# Only the herring has a power so far; the others get theirs later (docs/BRASHNESS_BACKLOG.md).
		var special: Label = _small_label(box,"SPECIAL: " + str(info.get("power",{}).get("name","SOON")),BeachUI.GOLD if owned else Color("6b858b"))
		special.name = "Special"
		special.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var status: Label = _small_label(box,"UNLOCKED" if owned else "%d FEATHERS" % int(info.price),BeachUI.CREAM if owned else BeachUI.CORAL)
		status.name = "Status"
		status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if id == chosen:
			card.grab_focus()
	var modes: VBoxContainer = VBoxContainer.new()
	modes.add_theme_constant_override("separation",0)
	content.add_child(modes)
	_control_mode_slider(modes)
	var bottom: HBoxContainer = HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(bottom)
	BeachUI.back_button(bottom,"< BACK",func() -> void: choose("title"))
	_perk_picker(bottom)

const CONTROL_MODE_TEXT: Array[String] = ["TAP EVERY WINGBEAT","HOLD TO FLAP","AUTO PECK IN DIVES"]
const SMALL_FONT: Font = preload("res://assets/fonts/gull_hud.fnt")

# REALISTIC . NORMAL . CASUAL slider under the cards: a 6 px heading, then the slider with its mode beside it. Every change saves at once.
func _control_mode_slider(parent: Control) -> void:
	var heading: Label = BeachUI.label(parent,"CONTROL DIFFICULTY LEVEL",6,BeachUI.CREAM)
	heading.add_theme_font_override("font",SMALL_FONT)
	heading.add_theme_font_size_override("font_size",6)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var slider: HSlider = HSlider.new()
	slider.name = "ControlModeSlider"
	slider.min_value = 0
	slider.max_value = 2
	slider.step = 1
	slider.tick_count = 3
	slider.ticks_on_borders = true
	slider.custom_minimum_size = Vector2(90,7)
	slider.value = GameState.CONTROL_MODES.find(GameState.control_mode())
	slider.tooltip_text = "REALISTIC / NORMAL / CASUAL"
	# The stock 16 px grabber would grow the row and squash the gull cards.
	var knob: Image = Image.create(5,7,false,Image.FORMAT_RGBA8)
	knob.fill(BeachUI.GOLD)
	for icon: String in ["grabber","grabber_highlight","grabber_disabled"]:
		slider.add_theme_icon_override(icon,ImageTexture.create_from_image(knob))
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation",6)
	parent.add_child(row)
	row.add_child(slider)
	var detail: Label = BeachUI.label(row,"",6,Color("a9d7d2"))
	detail.add_theme_font_override("font",SMALL_FONT)
	detail.add_theme_font_size_override("font_size",6)
	detail.custom_minimum_size.x = 110
	var refresh: Callable = func() -> void:
		var at: int = int(slider.value)
		detail.text = "%s: %s" % [GameState.CONTROL_MODES[at].to_upper(),CONTROL_MODE_TEXT[at]]
	slider.value_changed.connect(func(value: float) -> void:
		GameState.set_control_mode(GameState.CONTROL_MODES[int(value)])
		refresh.call())
	refresh.call()

# One owned perk may be equipped: a single button that cycles NONE and the owned perks.
func _perk_picker(parent: Control) -> void:
	var options: Array[String] = [""]
	for id: String in Config.perks.perks:
		if GameState.perk_owned(id):
			options.append(id)
	if options.size() == 1:
		return
	var caption: Callable = func() -> String:
		var id: String = GameState.equipped_perk()
		return "PERK:  < %s >" % (str(Config.perks.perks[id].name) if not id.is_empty() else "NONE")
	var step: Callable = func(dir: int) -> void:
		var at: int = options.find(GameState.equipped_perk())
		GameState.equip_perk(options[posmod(at + dir,options.size())])
	var pick: Button = BeachUI.button(parent,"",func() -> void: pass,150)
	pick.name = "PerkPick"
	pick.text = caption.call()
	pick.pressed.connect(func() -> void:
		step.call(1)
		pick.text = caption.call())
	pick.gui_input.connect(func(event: InputEvent) -> void:
		var dir: int = int(event.is_action_pressed("ui_right")) - int(event.is_action_pressed("ui_left"))
		if dir != 0:
			step.call(dir)
			pick.text = caption.call()
			pick.accept_event())

# Feathers shop: perks on the left, priced gulls on the right (two columns fit 320x180).
func shop(bought: bool = false) -> void:
	clear("FEATHER SHOP")
	content.add_theme_constant_override("separation",2)
	var outer: MarginContainer = content.get_parent().get_parent() as MarginContainer
	for edge: String in ["top","bottom"]:
		outer.add_theme_constant_override("margin_" + edge,0)
	var feathers: Label = BeachUI.label(self,"FEATHERS %d" % GameState.feathers(),BeachUI.FONT_NATIVE,BeachUI.CREAM)
	feathers.name = "Feathers"
	feathers.position = Vector2(188,20)
	feathers.size = Vector2(108,9)
	feathers.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	BeachUI.feather_icon(feathers)
	var columns: HBoxContainer = HBoxContainer.new()
	columns.size_flags_vertical = SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation",4)
	content.add_child(columns)
	var left: VBoxContainer = VBoxContainer.new()
	left.add_theme_constant_override("separation",2)
	columns.add_child(left)
	var right: VBoxContainer = VBoxContainer.new()
	right.add_theme_constant_override("separation",2)
	columns.add_child(right)
	BeachUI.label(left,"PERKS",BeachUI.FONT_NATIVE,Color("a9d7d2"))
	BeachUI.label(right,"GULLS",BeachUI.FONT_NATIVE,Color("a9d7d2"))
	var first: Button
	for id: String in Config.perks.perks:
		var info: Dictionary = Config.perks.perks[id]
		var item: Button = _shop_item(left,id,str(info.name),str(info.blurb),int(info.price),170,false)
		first = first if first != null or item.disabled else item
	for id: String in Config.species.species:
		var info: Dictionary = Config.species.species[id]
		if int(info.price) > 0:
			var item: Button = _shop_item(right,id,str(info.name),str(info.blurb),int(info.price),122,true)
			first = first if first != null or item.disabled else item
	var message: Label = BeachUI.label(right,"BOUGHT!" if bought else "",BeachUI.FONT_NATIVE,BeachUI.GOLD)
	message.name = "Message"
	var spacer: Control = Control.new()
	spacer.size_flags_vertical = SIZE_EXPAND_FILL
	right.add_child(spacer)
	var back: Button = BeachUI.back_button(right,"< BACK",func() -> void: choose("title"))
	(first if first != null else back).grab_focus()

func _shop_item(parent: Control, id: String, item_name: String, blurb: String, price: int, width: int, stacked: bool) -> Button:
	var owned: bool = GameState.owns(id)
	var affordable: bool = GameState.feathers() >= price
	var button: Button = BeachUI.button(parent,"",func() -> void: choose("buy",id),width)
	button.name = "Item_" + id
	button.custom_minimum_size.y = 32 if stacked else 24
	button.disabled = owned or not affordable
	var box: VBoxContainer = VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation",0)
	button.add_child(box)
	BeachUI.full(box)
	box.offset_left = 4
	box.offset_right = -4
	box.offset_top = 3
	box.offset_bottom = -3
	var status_text: String = "OWNED" if owned else ("BUY  %d" % price if affordable else "%d FEATHERS" % price)
	var status_color: Color = BeachUI.CREAM if owned else (BeachUI.GOLD if affordable else Color("6b858b"))
	var dim: bool = owned or not affordable
	var head: HBoxContainer = HBoxContainer.new()
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(head)
	var title_label: Label = BeachUI.label(head,item_name,BeachUI.FONT_NATIVE,Color("6b858b") if dim and not owned else BeachUI.GOLD)
	title_label.size_flags_horizontal = SIZE_EXPAND_FILL
	var blurb_label: Label = BeachUI.label(box,blurb,BeachUI.FONT_NATIVE,Color("6b858b") if dim else Color("a9d7d2"))
	blurb_label.name = "Blurb"
	var status: Label
	if stacked:
		status = BeachUI.label(box,status_text,BeachUI.FONT_NATIVE,status_color)
	else:
		status = BeachUI.label(head,status_text,BeachUI.FONT_NATIVE,status_color)
	status.name = "Status"
	return button

# Simplified card stats: one row per stat, 1-5 pips from data/species.json "card".
func _stat_rows(parent: Control, card: Dictionary, owned: bool) -> void:
	for stat: String in ["speed","dive","tough"]:
		var line: HBoxContainer = HBoxContainer.new()
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.alignment = BoxContainer.ALIGNMENT_CENTER
		line.add_theme_constant_override("separation",1)
		parent.add_child(line)
		var caption: Label = _small_label(line,stat.to_upper(),Color("a9d7d2") if owned else Color("6b858b"))
		caption.custom_minimum_size.x = 26
		for i: int in 5:
			var pip: ColorRect = ColorRect.new()
			pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pip.custom_minimum_size = Vector2(3,3)
			pip.size_flags_vertical = SIZE_SHRINK_CENTER
			var lit: bool = i < int(card.get(stat,0))
			pip.color = (BeachUI.GOLD if owned else Color("6b858b")) if lit else Color(0.0,0.0,0.0,0.3)
			line.add_child(pip)

func _small_button(parent: Control, text: String, action: Callable) -> Button:
	var node: Button = BeachUI.back_button(parent,text,action,0)
	node.size_flags_horizontal = SIZE_EXPAND_FILL
	node.add_theme_font_override("font",SMALL_FONT)
	node.add_theme_font_size_override("font_size",6)
	return node

func _small_label(parent: Control, text: String, color: Color) -> Label:
	var node: Label = BeachUI.label(parent,text,6,color)
	node.add_theme_font_override("font",SMALL_FONT)
	node.add_theme_font_size_override("font_size",6)
	return node

func pause(skippable: bool = false, can_replay: bool = false) -> void:
	clear("TAKING A BREATHER", "YOUR LUNCH CAN WAIT.")
	# A compact box: half the usual menu, 8 px heading, 6 px subtitle and 13 px buttons.
	var panel: PanelContainer = content.get_parent() as PanelContainer
	panel.size_flags_horizontal = SIZE_SHRINK_CENTER
	panel.size_flags_vertical = SIZE_SHRINK_CENTER
	content.custom_minimum_size.x = 128
	content.get_child(0).add_theme_font_size_override("font_size",BeachUI.FONT_NATIVE)
	content.get_child(1).add_theme_font_override("font",SMALL_FONT)
	content.get_child(1).add_theme_font_size_override("font_size",6)
	var resume: Button = _small_button(content,"RESUME",func() -> void: choose("resume"))
	resume.grab_focus()
	if skippable:
		_small_button(content,"SKIP LESSON",func() -> void: choose("skip_lesson"))
	elif can_replay:
		_small_button(content,"REPLAY LESSON",func() -> void: choose("screech_lesson"))
	_small_button(content,"RESTART",func() -> void: choose("restart"))
	var pair: HBoxContainer = HBoxContainer.new()
	content.add_child(pair)
	var rules: Button = _small_button(pair,"SCORE RULES",func() -> void: pass)
	rules.size_flags_horizontal = SIZE_EXPAND_FILL
	rules.pressed.connect(func() -> void:
		ScoreRulesCard.open(self,"BACK").closed.connect(func() -> void:
			if is_instance_valid(rules):
				rules.grab_focus()))
	_small_button(pair,"OPTIONS",func() -> void: choose("options_pause")).size_flags_horizontal = SIZE_EXPAND_FILL
	_small_button(content,"LEVEL SELECT",func() -> void: choose("select"))

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
	BeachUI.back_button(content,"SAVE / BACK",func() -> void:
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
