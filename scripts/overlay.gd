class_name BeachOverlay
extends Control
var game: BeachGame
var font: Font = preload("res://assets/fonts/gull_pixel.fnt")
var score_label: Label
var time_label: Label
var wind_label: Label
var intro_panel: PanelContainer
var start_button: Button
var training_panel: PanelContainer
var lesson_label: Label
var lesson_prompt: Label
var pause_button: Button
var top: HBoxContainer
var score_announcement: Label
var score_announcement_tween: Tween

func setup(owner_game: BeachGame) -> void:
	game = owner_game
	theme = BeachUI.theme()
	BeachUI.full(self)
	mouse_filter = MOUSE_FILTER_IGNORE
	var margin: MarginContainer = BeachUI.margin(self,5)
	margin.mouse_filter = MOUSE_FILTER_IGNORE
	var column: VBoxContainer = VBoxContainer.new()
	column.mouse_filter = MOUSE_FILTER_IGNORE
	margin.add_child(column)
	top = HBoxContainer.new()
	column.add_child(top)
	score_label = BeachUI.label(top,"0000",8,BeachUI.GOLD)
	score_label.custom_minimum_size.x = 95
	time_label = BeachUI.label(top,"75s")
	time_label.size_flags_horizontal = SIZE_EXPAND_FILL
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wind_label = BeachUI.label(top,"CALM")
	wind_label.custom_minimum_size.x = 83
	wind_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pause_button = BeachUI.button(top,"II",func() -> void: game.pause_requested.emit())
	pause_button.custom_minimum_size = Vector2(20,20)
	# This sits just below the status strip, leaving the score and timer readable.
	var announcement_row: CenterContainer = CenterContainer.new()
	add_child(announcement_row)
	announcement_row.set_anchors_preset(Control.PRESET_TOP_WIDE)
	announcement_row.offset_top = 30.0
	announcement_row.offset_bottom = 54.0
	announcement_row.mouse_filter = MOUSE_FILTER_IGNORE
	score_announcement = BeachUI.label(announcement_row,"",BeachUI.FONT_DISPLAY,BeachUI.GOLD)
	score_announcement.custom_minimum_size = Vector2(304,16)
	score_announcement.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_announcement.add_theme_constant_override("outline_size",2)
	score_announcement.add_theme_color_override("font_outline_color",BeachUI.INK)
	score_announcement.add_theme_color_override("font_shadow_color",Color(0.0,0.0,0.0,0.65))
	score_announcement.add_theme_constant_override("shadow_offset_x",1)
	score_announcement.add_theme_constant_override("shadow_offset_y",1)
	score_announcement.hide()
	var space: Control = Control.new()
	space.mouse_filter = MOUSE_FILTER_IGNORE
	space.size_flags_vertical = SIZE_EXPAND_FILL
	column.add_child(space)
	var training_center: CenterContainer = CenterContainer.new()
	add_child(training_center)
	BeachUI.full(training_center)
	training_center.anchor_bottom = 0.0
	training_center.offset_top = 28.0
	training_center.offset_bottom = 28.0
	training_center.mouse_filter = MOUSE_FILTER_IGNORE
	training_panel = BeachUI.panel(training_center,Color(0.094,0.23,0.30,0.95))
	training_panel.custom_minimum_size = Vector2(192,32)
	var training_style: StyleBoxFlat = training_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	training_style.content_margin_left = 8
	training_style.content_margin_right = 8
	training_style.content_margin_top = 4
	training_style.content_margin_bottom = 4
	training_panel.add_theme_stylebox_override("panel",training_style)
	training_panel.mouse_filter = MOUSE_FILTER_IGNORE
	var lesson_column: VBoxContainer = VBoxContainer.new()
	lesson_column.mouse_filter = MOUSE_FILTER_IGNORE
	lesson_column.add_theme_constant_override("separation",2)
	training_panel.add_child(lesson_column)
	lesson_label = BeachUI.label(lesson_column,"TRAINING DAY  /  LESSON 1/6",8,BeachUI.GOLD)
	lesson_prompt = BeachUI.label(lesson_column,"",8,BeachUI.CREAM)
	for tip_label: Label in [lesson_label,lesson_prompt]:
		tip_label.add_theme_font_size_override("font_size",6)
		tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lesson_label.mouse_filter = MOUSE_FILTER_IGNORE
	lesson_prompt.mouse_filter = MOUSE_FILTER_IGNORE
	lesson_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lesson_prompt.custom_minimum_size = Vector2(176,12)
	var center: CenterContainer = CenterContainer.new()
	add_child(center)
	BeachUI.full(center)
	center.mouse_filter = MOUSE_FILTER_IGNORE
	intro_panel = BeachUI.panel(center)
	intro_panel.mouse_filter = MOUSE_FILTER_IGNORE
	var intro: VBoxContainer = VBoxContainer.new()
	intro_panel.add_child(intro)
	BeachUI.label(intro,"TRAINING DAY" if game.training else "%02d / %s" % [game.level.id,game.level.name.to_upper()],8,BeachUI.GOLD)
	if game.training:
		BeachUI.label(intro,"SIX SHORT LESSONS. TAKE YOUR TIME.")
		BeachUI.label(intro,"AIM, FLAP, DIVE AND PECK TO LEARN.",8,Color("80bcb8"))
		BeachUI.label(intro,"YOUR NEXT STEP APPEARS ON THE BEACH.",8,BeachUI.GOLD)
	else:
		BeachUI.label(intro,"15 SNATCHES. NO TIMER." if game.casual else "STEAL LUNCH. MAKE IT COUNT.")
		BeachUI.label(intro,"CALM AIR" if game.wind.direction == 0 else ("WIND > TOWARD PIER" if game.wind.direction > 0 else "WIND < TOWARD FAMILY END"))
		var quote: Label = BeachUI.label(intro,Config.quips.rivals[(int(game.level.id)-1)%3])
		quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		quote.custom_minimum_size.x = 234
		BeachUI.label(intro,"HOLD A / SPACE / LEFT CLICK TO FLAP",8,Color("80bcb8"))
		BeachUI.label(intro,"DIVE: B / SHIFT / RIGHT CLICK",8,Color("80bcb8"))
		BeachUI.label(intro,"TAP E / X / PECK DURING THE DIVE",8,BeachUI.GOLD)
		BeachUI.label(intro,"AIM UP TO SWOOP. FAST CRASH = 0!",8,Color("80bcb8"))
	if int(game.level.id) == 1:
		intro_panel.mouse_filter = MOUSE_FILTER_STOP
		start_button = BeachUI.button(intro,"LET'S GULL IT",game.dismiss_intro)
		start_button.grab_focus()
	else:
		BeachUI.label(intro,"ANY BUTTON TO GO",8,BeachUI.GOLD)

func _process(_delta: float) -> void:
	score_label.text = "%04d  X%s" % [game.score.points,str(Config.tuning.score.tiers[game.score.tier])]
	time_label.text = "TRAINING" if game.training else ("%d/%d" % [game.score.items,Config.tuning.score.casual_items] if game.casual else "%02ds" % ceili(maxf(0,float(game.level.time_limit)-game.elapsed)))
	wind_label.text = "CALM" if absf(game.player.wind_force) < 0.01 else "%s %d%%" % ["WIND >" if game.player.wind_force > 0 else "< WIND",roundi(absf(game.player.wind_force)*100)]
	intro_panel.visible = game.intro > 0
	training_panel.visible = game.training and game.running and game.intro <= 0
	if game.training:
		lesson_label.text = "TRAINING DAY  /  LESSON %d/6" % mini(game.lesson + 1, 6)
		lesson_prompt.text = game.training_text()
	pause_button.visible = game.running

func show_score_announcement(food_id: String, earned: int) -> void:
	if not Config.foods.has(food_id):
		return
	if is_instance_valid(score_announcement_tween):
		score_announcement_tween.kill()
	var food: Dictionary = Config.foods[food_id]
	score_announcement.text = "%s +%d" % [str(food.name).to_upper(),earned]
	# Training text occupies the normal top-center slot, so shift the transient
	# callout below it rather than covering the current instruction.
	var row: Control = score_announcement.get_parent() as Control
	row.offset_top = training_callout_top() if game.training else 30.0
	row.offset_bottom = row.offset_top + 24.0
	score_announcement.modulate.a = 1.0
	score_announcement.scale = Vector2(0.72,0.72)
	score_announcement.pivot_offset = score_announcement.size * 0.5
	score_announcement.show()
	score_announcement_tween = create_tween()
	score_announcement_tween.set_parallel(true)
	score_announcement_tween.tween_property(score_announcement,"scale",Vector2.ONE,0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	score_announcement_tween.tween_property(score_announcement,"modulate:a",1.0,0.12)
	score_announcement_tween.chain().tween_interval(0.3)
	score_announcement_tween.tween_property(score_announcement,"modulate:a",0.0,0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	score_announcement_tween.tween_callback(score_announcement.hide)

func _draw_digestion(offset: Vector2) -> void:
	var belly: GullDigestion = game.player.digestion
	if belly.snacks.is_empty() and belly.rest <= 0:
		return
	var point: Vector2 = game.player.position-offset+Vector2(-25,15)
	point.x = clampf(point.x,2,268)
	point.y = clampf(point.y,32,155)
	draw_rect(Rect2(point,Vector2(50,15)),Color("183b4e"))
	if belly.rest > 0:
		draw_string(font,point+Vector2(2,8),"DIGEST",HORIZONTAL_ALIGNMENT_LEFT,-1,8,BeachUI.CREAM)
		draw_rect(Rect2(point+Vector2(2,11),Vector2(46*(1-belly.rest/2),2)),BeachUI.GOLD)
		return
	for i: int in belly.snacks.size():
		var snack: Dictionary = belly.snacks[i]
		var texture: Texture2D = Config.frames(Config.foods[snack.id].sprite).get_frame_texture(&"idle",0)
		draw_texture_rect(texture,Rect2(point+Vector2(2+i*12,1),Vector2(10,10)),false,Color.WHITE if i == 0 else Color(0.65,0.7,0.7))
	draw_rect(Rect2(point+Vector2(2,12),Vector2(46*belly.progress/belly.duration(belly.snacks[0].id),2)),BeachUI.GOLD)
	var definition: Dictionary = Config.foods[belly.snacks[0].id]
	var size: Vector2 = Vector2(definition.size[0],definition.size[1])
	draw_texture_rect(Config.frames(definition.sprite).get_frame_texture(&"idle",0),Rect2(game.player.beak()-offset-size*0.5,size),false)

func _draw() -> void:
	if game == null:
		return
	draw_rect(Rect2(0,0,320,28),Color("183b4e"))
	draw_rect(Rect2(5,19,85,2),Color("397a85"))
	draw_rect(Rect2(5,19,85*game.score.window/float(Config.tuning.score.combo_window),2),BeachUI.GOLD)
	var offset: Vector2 = Vector2(game.camera_x-160,0)
	_draw_digestion(offset)
	var aim: Vector2 = game.player.aim-offset
	if game.running:
		if not game.training:
			var goal: int = int(Config.tuning.score.casual_items) if game.casual else int(game.level.stars[0])
			var progress: int = game.score.items if game.casual else game.score.points
			var title: String = "PRACTICE" if game.casual else ("NEXT LEVEL" if int(game.level.id) < GameState.last_playable_level() else ("DEMO GOAL" if GameState.demo_locked(int(game.level.id) + 1) else "FINAL GOAL"))
			draw_rect(Rect2(232,44,84,29),Color(0.094,0.23,0.30,0.9))
			draw_string(font,Vector2(237,53),title,HORIZONTAL_ALIGNMENT_LEFT,-1,8,BeachUI.CREAM)
			draw_rect(Rect2(237,57,74,4),Color("397a85"))
			draw_rect(Rect2(237,57,74*clampf(float(progress)/maxi(1,goal),0,1),4),BeachUI.GOLD)
			draw_string(font,Vector2(237,70),"%d / %d" % [progress,goal],HORIZONTAL_ALIGNMENT_LEFT,-1,8,BeachUI.CREAM)
		if game.training:
			var training_target: Vector2 = game.training_target() - offset
			if training_target.x >= 4 and training_target.x <= 316 and training_target.y >= 28 and training_target.y <= 165:
				draw_arc(training_target,12,0,TAU,24,BeachUI.GOLD,2)
				draw_arc(training_target,16,0,TAU,24,Color(1.0,0.95,0.7,0.55),1)
		var hint: Dictionary = context_hint()
		if not hint.is_empty():
			var hint_box: Rect2 = hint_rect(str(hint.text))
			var danger: bool = bool(hint.get("danger",false))
			draw_rect(hint_box,Color(0.09,0.20,0.26,0.85))
			if danger:
				draw_rect(hint_box,Color("ef725c"),false,1.0)
			draw_string(font,hint_box.position+Vector2(3,8),str(hint.text),HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("ef725c") if danger else BeachUI.CREAM)
		if game.player.landing_aim() and game.player.state != BeachGull.State.GROUNDED:
			var landing_x: float = clampf(aim.x,8,312)
			draw_line(Vector2(landing_x-6,159),Vector2(landing_x+6,159),BeachUI.CREAM,2)
		draw_arc(aim,4,0,TAU,12,Color("fff4da"))
		draw_line(aim-Vector2(7,0),aim+Vector2(7,0),Color("fff4da"))
		draw_line(aim-Vector2(0,7),aim+Vector2(0,7),Color("fff4da"))
		var pos: Vector2 = game.player.position-offset
		if _you_marker_visible():
			var tag_pos: Vector2 = you_marker_rect(pos).position+Vector2(2,9)
			var marker_alpha: float = 1.0 if game.training else clampf((4.5-game.intro_dismissed_elapsed)/0.5,0.0,1.0)
			draw_rect(Rect2(tag_pos-Vector2(2,9),Vector2(24,11)),Color(0.09,0.20,0.26,0.88*marker_alpha))
			draw_string(font,tag_pos,"YOU",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color(1.0,0.96,0.85,marker_alpha))
		if game.player.cooldown > 0:
			var ratio: float = clampf(game.player.cooldown/float(Config.tuning.dive.cooldown),0.0,1.0)
			draw_rect(Rect2(pos+Vector2(-16,-25),Vector2(32,4)),BeachUI.INK)
			draw_rect(Rect2(pos+Vector2(-15,-24),Vector2(30*(1.0-ratio),2)),BeachUI.GOLD)
			draw_string(font,pos+Vector2(-18,-28),"DIVE",HORIZONTAL_ALIGNMENT_LEFT,-1,8,BeachUI.CREAM)
		if game.player.state == BeachGull.State.STRIKE and Config.tuning.juice.speed_lines:
			draw_line(pos-game.player.direction*25,pos-game.player.direction*13,BeachUI.CREAM,1)
		if game.player.state == BeachGull.State.STRIKE:
			var beak: Vector2 = game.player.beak()-offset
			var peck_color: Color = BeachUI.GOLD if game.player.peck_time > 0 else (Color("ef725c") if game.player.peck_used else BeachUI.CREAM)
			draw_arc(beak,6,0,TAU,12,peck_color,2)
			if game.player.peck_time > 0:
				draw_line(beak-Vector2(7,10),beak-Vector2(7-14*game.player.peck_time/float(Config.tuning.dive.peck_window),10),peck_color,2)
	if touch_buttons_visible():
		_draw_touch_buttons()
	var left_food: bool = false
	var right_food: bool = false
	var left_threat: bool = false
	var right_threat: bool = false
	for target: BeachTarget in game.spawner.targets:
		var x: float = target.position.x-offset.x
		if x < 0 and x > -320:
			left_food = left_food or target.food
			left_threat = left_threat or target.defense > 0
		if x > 320 and x < 640:
			right_food = right_food or target.food
			right_threat = right_threat or target.defense > 0
	var arrow_y: float = maxf(116.0,training_panel.get_rect().end.y+22.0) if game.training else 108.0
	for item: Array in [[left_food,Vector2(3,arrow_y),"< FOOD",BeachUI.GOLD],[right_food,Vector2(280,arrow_y),"FOOD >",BeachUI.GOLD],[left_threat,Vector2(3,arrow_y+11),"< !",Color("ef725c")],[right_threat,Vector2(302,arrow_y+11),"! >",Color("ef725c")]]:
		if item[0]:
			draw_string(font,item[1],item[2],HORIZONTAL_ALIGNMENT_LEFT,-1,8,item[3])
	# Zone boundaries follow the longer map rather than equal screen thirds.
	draw_rect(Rect2(108,172,104,3),Color("9b6650"))
	for boundary: float in [0.0,float(Config.tuning.world.promenade_start),float(Config.tuning.world.pier_start),float(Config.tuning.world.width)]:
		var x: float = 108+boundary/float(Config.tuning.world.width)*104
		draw_rect(Rect2(x,171,1,5),BeachUI.CREAM)
	draw_rect(Rect2(108+game.player.position.x/float(Config.tuning.world.width)*104,171,3,4),BeachUI.INK)
	if game.debug:
		draw_rect(Rect2(4,30,240,21),BeachUI.INK)
		draw_string(font,Vector2(7,38),"FPS %d  V %d,%d  WIND %.2f" % [Engine.get_frames_per_second(),game.player.velocity.x,game.player.velocity.y,game.wind.strength],HORIZONTAL_ALIGNMENT_LEFT,-1,8,BeachUI.CREAM)
		draw_string(font,Vector2(7,48),"STATE %d TARGETS %d F2 RELOAD" % [game.player.state,game.spawner.targets.size()],HORIZONTAL_ALIGNMENT_LEFT,-1,8,BeachUI.GOLD)
		for target: BeachTarget in game.spawner.targets:
			draw_arc(target.position-offset,float(target.info.awareness)*target.awareness_mult,0,TAU,24,Color(1,0.5,0.4,0.4))
			if target.food:
				var radius: Vector2 = target.food_radius()
				draw_rect(Rect2(target.food_position()-offset-radius,radius*2),BeachUI.GOLD,false)
		draw_rect(Rect2(game.player.beak()-offset-Vector2(4,3),Vector2(8,6)),Color("ef725c"),false)

func _you_marker_visible() -> bool:
	return game != null and (game.training or (game.intro_dismissed_elapsed >= 0.0 and game.intro_dismissed_elapsed < 4.5))

func you_marker_rect(pos: Vector2) -> Rect2:
	var initial := Vector2(roundf(clampf(pos.x-10,2,294)),roundf(clampf(pos.y-23,30,165)))
	var obstacles: Array[Rect2] = []
	obstacles.append(Rect2(232,44,84,29) if not game.training else training_panel.get_global_rect())
	var hint: Dictionary = context_hint()
	if not hint.is_empty():
		obstacles.append(hint_rect(str(hint.text)).grow(1))
	for sign: Dictionary in game.beach.sign_layouts():
		var board: Rect2 = sign.rect
		board.position.x -= game.camera_x-160
		obstacles.append(board.grow(2))
	# Try the preferred height first, then other clear rows above the bird.
	var rows: Array[float] = [initial.y]
	for y: int in range(int(initial.y)-1,29,-1):
		rows.append(float(y))
	for y: float in rows:
		var candidate := Rect2(initial.x,y,24,11)
		var clear: bool = true
		for obstacle: Rect2 in obstacles:
			if candidate.intersects(obstacle):
				clear = false
				break
		if clear:
			return candidate
	# Near the top, keep the marker readable beside the training panel.
	return Rect2(292,30,24,11)

func input_word(kind: String) -> String:
	if game.input.touch_visible:
		return kind.to_upper()
	match kind:
		"flap":
			return "A" if game.input.gamepad else "SPACE"
		"peck":
			return "X" if game.input.gamepad else "E"
	return kind.to_upper()

# One contextual hint at a time, chosen from the gull's current situation.
func context_hint() -> Dictionary:
	if game == null or not game.running:
		return {}
	var peck: String = input_word("peck")
	var flap: String = input_word("flap")
	if game.player.state == BeachGull.State.GROUNDED:
		if game.stash_raids.nearby_toddler() != null:
			return {"text":"TAP %s AT TODDLER" % peck}
		if game.stash_raids.has_nearby_source():
			return {"text":"TAP %s TO SEARCH" % peck}
		return {"text":"WALK FOR SCRAPS / HOLD %s TO FLY" % flap}
	if game.player.state == BeachGull.State.STRIKE:
		if game.player.crash_warning():
			return {"text":"PULL UP! CRASH AHEAD","danger":true}
		if not game.player.peck_used:
			return {"text":"TAP %s AT THE SNACK" % peck}
		return {"text":"PECK ACTIVE" if game.player.peck_time > 0 else "PECK SPENT - DIVE AGAIN"}
	if game.player.landing_aim():
		return {"text":"LANDING / HOLD %s TO CLIMB" % flap}
	return {}

# Fixed slot: below the score callout (or the lesson panel), left of the goal panel,
# and above the zone signs, so the hint never crosses world labels.
func hint_rect(text: String) -> Rect2:
	var width: float = ceilf(font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,8).x) + 6.0
	var y: float = training_panel.get_global_rect().end.y + 2.0 if game.training else 56.0
	return Rect2(4.0,roundf(y),width,11.0)

func touch_buttons_visible() -> bool:
	return game != null and game.running and game.input.touch_visible

func peck_available() -> bool:
	return game.player.state in [BeachGull.State.GROUNDED,BeachGull.State.WINDUP,BeachGull.State.STRIKE]

func _draw_touch_buttons() -> void:
	for kind: String in GullInput.TOUCH_BUTTONS:
		var box: Rect2 = GullInput.TOUCH_BUTTONS[kind]
		var held: bool = (kind == "flap" and game.input.touch_climb)
		var alpha: float = 0.35 if kind == "peck" and not peck_available() else 1.0
		draw_rect(box,Color(0.14,0.33,0.41,(0.7 if held else 0.42)*alpha))
		draw_rect(box,Color(1.0,0.96,0.85,0.55*alpha),false,1.0)
		var caption: String = kind.to_upper()
		var text_width: float = font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,8).x
		draw_string(font,Vector2(roundf(box.position.x+(box.size.x-text_width)*0.5),roundf(box.position.y+box.size.y*0.5+3)),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color(1.0,0.96,0.85,0.9*alpha))

# During lessons the panel and hint fill the top slot, so the callout drops just
# below the zone sign boards (over the sea) instead of covering them.
func training_callout_top() -> float:
	var top: float = training_panel.get_global_rect().end.y + 15.0
	for sign: Dictionary in game.beach.sign_layouts():
		top = maxf(top,(sign.rect as Rect2).end.y + 3.0)
	return roundf(top)
