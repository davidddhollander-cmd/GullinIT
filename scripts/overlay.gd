class_name BeachOverlay
extends Control
var game: BeachGame
var font: Font = preload("res://assets/fonts/gull_pixel.fnt")
var score_label: Label
var time_label: Label
var wind_label: Label
var intro_panel: PanelContainer
var start_button: Button
var trainer_card: TrainerCard
var trainer_intro: bool = false ## Training Day opens with the trainer card instead of the intro panel
var training_panel: PanelContainer
var lesson_label: Label
var lesson_prompt: Label
var pause_button: Button
var top: HBoxContainer
var quest_panel: PanelContainer
var quest_box: HBoxContainer
var quest_labels: Array[Label] = []
var score_announcement: Label
var score_announcement_tween: Tween
var rival_score_panel: PanelContainer
var rival_score_list: VBoxContainer
var rival_score_labels: Array[Label] = []
var you_score_label: Label
var goal_label: Label
var shown_score: float = 0.0 ## the top-left score counts up toward the real one
var score_announcement_fonts: Array[Font] = [
	preload("res://assets/arcade_score_blue.fnt"),
	preload("res://assets/arcade_score_hot.fnt"),
]
var score_announcement_font_index: int = 0
const SCORE_ANNOUNCEMENT_HOLD: float = BeachEffects.SCORE_MESSAGE_HOLD
const SCORE_ANNOUNCEMENT_FADE: float = BeachEffects.SCORE_MESSAGE_FADE
const TOP_BAR_HEIGHT: int = 17
const TOP_BAR_FONT_SIZE: int = 6
const TIME_WARNING: float = 20.0 ## seconds left when the timer turns red and flashes
const QUEST_STRIP_HEIGHT: float = 10.0 ## small-font quest row directly under the top bar
const SCORE_CALLOUT_TOP: float = TOP_BAR_HEIGHT + QUEST_STRIP_HEIGHT + 2.0 ## pop-ups sit below the strip
const GOAL_PANEL: Rect2 = Rect2(232,SCORE_CALLOUT_TOP,84,43) ## scoreboard slot under the quest strip: up to 3 rivals, YOU and the star goal
const BOARD_FONT_SIZE: int = 8
const HUD_FONT: Font = preload("res://assets/fonts/gull_hud.fnt")

func setup(owner_game: BeachGame) -> void:
	game = owner_game
	theme = BeachUI.theme()
	BeachUI.full(self)
	mouse_filter = MOUSE_FILTER_IGNORE
	var margin: MarginContainer = BeachUI.margin(self,5)
	margin.add_theme_constant_override("margin_top",2)
	margin.mouse_filter = MOUSE_FILTER_IGNORE
	var column: VBoxContainer = VBoxContainer.new()
	column.mouse_filter = MOUSE_FILTER_IGNORE
	margin.add_child(column)
	top = HBoxContainer.new()
	top.custom_minimum_size.y = 11
	top.add_theme_constant_override("separation",5)
	column.add_child(top)
	score_label = BeachUI.label(top,"0000",8,BeachUI.GOLD)
	score_label.custom_minimum_size.x = 95
	time_label = BeachUI.label(top,"75")
	time_label.size_flags_horizontal = SIZE_EXPAND_FILL
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wind_label = BeachUI.label(top,"CALM")
	wind_label.custom_minimum_size.x = 83
	wind_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pause_button = BeachUI.button(top,"II",func() -> void: game.pause_requested.emit())
	pause_button.custom_minimum_size = Vector2(14,11)
	for item: Control in [wind_label,pause_button]:
		item.add_theme_font_override("font",HUD_FONT)
		item.add_theme_font_size_override("font_size",TOP_BAR_FONT_SIZE)
	for item: Label in [score_label,time_label,wind_label]:
		item.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# Override only the compact HUD button, keeping menu/touch typography intact.
	for state: String in ["normal","hover","pressed","focus","disabled"]:
		var style: StyleBoxFlat = pause_button.get_theme_stylebox(state).duplicate() as StyleBoxFlat
		style.content_margin_left = 3
		style.content_margin_right = 3
		style.content_margin_top = 1
		style.content_margin_bottom = 1
		pause_button.add_theme_stylebox_override(state,style)
	# This sits just below the status strip, leaving the score and timer readable.
	var announcement_row: CenterContainer = CenterContainer.new()
	add_child(announcement_row)
	announcement_row.set_anchors_preset(Control.PRESET_TOP_WIDE)
	announcement_row.offset_top = SCORE_CALLOUT_TOP
	announcement_row.offset_bottom = SCORE_CALLOUT_TOP + 24.0
	announcement_row.mouse_filter = MOUSE_FILTER_IGNORE
	score_announcement = BeachUI.label(announcement_row,"",BeachUI.FONT_DISPLAY,Color.WHITE)
	score_announcement.custom_minimum_size = Vector2(304,16)
	score_announcement.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_announcement.add_theme_font_override("font",score_announcement_fonts[0])
	score_announcement.add_theme_color_override("font_shadow_color",Color(0.0,0.0,0.0,0.65))
	score_announcement.add_theme_constant_override("shadow_offset_x",1)
	score_announcement.add_theme_constant_override("shadow_offset_y",1)
	score_announcement.hide()
	rival_score_panel = BeachUI.panel(self,Color(0.055,0.14,0.19,0.92))
	rival_score_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	rival_score_panel.offset_left = GOAL_PANEL.position.x - 320.0
	rival_score_panel.offset_top = GOAL_PANEL.position.y
	rival_score_panel.offset_right = -4.0
	rival_score_panel.mouse_filter = MOUSE_FILTER_IGNORE
	var rival_panel_style: StyleBoxFlat = rival_score_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	rival_panel_style.content_margin_left = 2.0
	rival_panel_style.content_margin_right = 2.0
	rival_panel_style.content_margin_top = 1.0
	rival_panel_style.content_margin_bottom = 0.0
	rival_panel_style.border_color = BeachUI.CREAM
	rival_panel_style.set_border_width_all(1)
	rival_score_panel.add_theme_stylebox_override("panel",rival_panel_style)
	rival_score_list = VBoxContainer.new()
	rival_score_list.add_theme_constant_override("separation",0)
	rival_score_list.mouse_filter = MOUSE_FILTER_IGNORE
	rival_score_panel.add_child(rival_score_list)
	sync_rival_scores()
	var space: Control = Control.new()
	space.mouse_filter = MOUSE_FILTER_IGNORE
	space.size_flags_vertical = SIZE_EXPAND_FILL
	column.add_child(space)
	# Dark backing keeps the checklist readable over clouds and above world name tags.
	quest_panel = BeachUI.panel(self,Color(0.094,0.23,0.30,0.85))
	var quest_style: StyleBoxFlat = quest_panel.get_theme_stylebox("panel") as StyleBoxFlat
	quest_style.content_margin_left = 3
	quest_style.content_margin_right = 3
	quest_style.content_margin_top = 1
	quest_style.content_margin_bottom = 1
	quest_panel.mouse_filter = MOUSE_FILTER_IGNORE
	quest_panel.position = Vector2(3,TOP_BAR_HEIGHT + 1)
	quest_box = HBoxContainer.new()
	quest_box.mouse_filter = MOUSE_FILTER_IGNORE
	quest_box.add_theme_constant_override("separation",6)
	quest_panel.add_child(quest_box)
	for quest: Dictionary in game.quests.quests:
		var row: Label = BeachUI.label(quest_box,"",TOP_BAR_FONT_SIZE,BeachUI.CREAM)
		row.add_theme_font_override("font",HUD_FONT)
		row.add_theme_font_size_override("font_size",TOP_BAR_FONT_SIZE)
		row.add_theme_color_override("font_shadow_color",Color(0.0,0.0,0.0,0.65))
		row.add_theme_constant_override("shadow_offset_x",1)
		row.add_theme_constant_override("shadow_offset_y",1)
		quest_labels.append(row)
	var training_center: CenterContainer = CenterContainer.new()
	add_child(training_center)
	BeachUI.full(training_center)
	training_center.anchor_bottom = 0.0
	training_center.offset_top = TOP_BAR_HEIGHT
	training_center.offset_bottom = TOP_BAR_HEIGHT
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
	lesson_label = BeachUI.label(lesson_column,"LESSON 1/%d" % BeachGame.TRAINING_LESSONS,8,BeachUI.GOLD)
	lesson_prompt = BeachUI.label(lesson_column,"",8,BeachUI.CREAM)
	for tip_label: Label in [lesson_label,lesson_prompt]:
		tip_label.add_theme_font_size_override("font_size",6)
		tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lesson_label.mouse_filter = MOUSE_FILTER_IGNORE
	lesson_prompt.mouse_filter = MOUSE_FILTER_IGNORE
	lesson_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lesson_prompt.add_theme_font_override("font", TrainerCard.SPEECH)
	lesson_prompt.add_theme_font_size_override("font_size", TrainerCard.SPEECH_SIZE)
	lesson_prompt.custom_minimum_size = Vector2(176, 10)
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
		BeachUI.label(intro,"NINE SHORT LESSONS. TAKE YOUR TIME.")
		BeachUI.label(intro,"NO TIMER. NO SCORE. NO MANNERS.",8,Color("80bcb8"))
		BeachUI.label(intro,"FOLLOW THE GOLDEN RING.",8,BeachUI.GOLD)
	else:
		# Just the pass mark and the quests; controls live in the training day.
		if game.level.has("objective"):
			BeachUI.label(intro,str(game.level.objective))
		var seconds: int = int(game.level.time_limit)
		BeachUI.label(intro,"15 SNATCHES. NO TIMER." if game.casual else "SCORE %d IN %d:%02d
TO PASS TO THE NEXT LEVEL" % [int(game.level.stars[0]),seconds/60,seconds%60])
		if not game.quests.quests.is_empty():
			# Quests sit in the small HUD font so a long list stays clear of the pass mark.
			_small(BeachUI.label(intro,"QUESTS",8,BeachUI.GOLD))
			for quest: Dictionary in game.quests.quests:
				_small(BeachUI.label(intro,"- %s  +%d" % [quest.text,int(quest.bonus)],8,Color("80bcb8")))
	trainer_intro = BeachGame.trainer_cards and game.training
	if trainer_intro:
		intro_panel.hide()
	elif int(game.level.id) == 1:
		intro_panel.mouse_filter = MOUSE_FILTER_STOP
		start_button = BeachUI.button(intro,"LET'S GULL IT",game.dismiss_intro)
		start_button.grab_focus()
	else:
		BeachUI.label(intro,"ANY BUTTON TO GO",8,BeachUI.GOLD)
	# Last child, so the pop-up draws over everything. Its button is the Training Day start button.
	trainer_card = TrainerCard.new()
	add_child(trainer_card)
	if trainer_intro:
		start_button = trainer_card.button

func _small(label: Label) -> Label:
	label.add_theme_font_override("font",HUD_FONT)
	label.add_theme_font_size_override("font_size",TOP_BAR_FONT_SIZE)
	return label

func _process(delta: float) -> void:
	var counting: bool = shown_score < game.score.points
	shown_score = move_toward(shown_score,game.score.points,maxf(20.0,(game.score.points-shown_score)*4.0)*delta) if counting else float(game.score.points)
	score_label.text = "%04d  X%s" % [roundi(shown_score),str(Config.tuning.score.tiers[game.score.tier])]
	score_label.add_theme_color_override("font_color",BeachUI.CREAM if counting else BeachUI.GOLD)
	var time_left: float = maxf(0,float(game.level.time_limit)-game.elapsed)
	time_label.text = "TRAINING" if game.training else ("%d/%d" % [game.score.items,Config.tuning.score.casual_items] if game.casual else "%02d" % ceili(time_left))
	var warning: bool = not game.training and not game.casual and game.running and time_left <= TIME_WARNING
	time_label.add_theme_color_override("font_color",Color("ef725c") if warning else BeachUI.CREAM)
	time_label.modulate.a = 0.35 if warning and Time.get_ticks_msec()%500 < 200 else 1.0
	wind_label.text = "CALM" if absf(game.player.wind_force) < 0.01 else "%s %d%%" % ["WIND >" if game.player.wind_force > 0 else "< WIND",roundi(absf(game.player.wind_force)*100)]
	intro_panel.visible = game.intro > 0 and not trainer_intro
	training_panel.visible = game.lesson_active() and game.running and game.intro <= 0 and not game.trainer_open
	if game.training:
		lesson_label.text = "LESSON %d/%d" % [mini(game.lesson + 1, BeachGame.TRAINING_LESSONS), BeachGame.TRAINING_LESSONS]
		lesson_prompt.text = game.training_text()
	elif game.screech_lesson:
		lesson_label.text = "LESSON %d/%d" % [mini(game.screech_step + 1, BeachGame.SCREECH_STEPS), BeachGame.SCREECH_STEPS]
		lesson_prompt.text = game.screech_lesson_text()
	pause_button.visible = game.running
	sync_quests()
	if rival_score_labels.size() != game.pilots.size():
		sync_rival_scores()
	rival_score_panel.visible = not game.lesson_active() and game.running and game.intro <= 0.0
	for i: int in rival_score_labels.size():
		var pilot: RivalPilot = game.pilots[i]
		rival_score_labels[i].text = "%03d" % pilot.score
	if you_score_label != null:
		you_score_label.text = "%03d" % game.score.points
		var status: Dictionary = goal_status()
		goal_label.text = "%s %d" % [str(status.title),int(status.goal)] if not game.casual else "%d/%d" % [int(status.progress),int(status.goal)]

# One row per quest, laid out horizontally: "- text" until done, green "> text" after; counted quests add n/N.
func sync_quests() -> void:
	quest_box.visible = not quest_labels.is_empty() and game.intro <= 0.0
	quest_panel.visible = quest_box.visible
	# Replays of the training day keep the lesson panel on top, so the list sits below it.
	# training_panel's rect is relative to training_center, which starts below the top bar.
	quest_panel.position.y = TOP_BAR_HEIGHT + training_panel.get_rect().end.y + 1.0 if game.lesson_active() else TOP_BAR_HEIGHT + 1.0
	for i: int in mini(quest_labels.size(),game.quests.quests.size()):
		var quest: Dictionary = game.quests.quests[i]
		var count: int = int(quest.count)
		quest_labels[i].text = "%s %s%s" % [">" if quest.done else "-",quest.text,"" if count <= 1 else " %d/%d" % [int(quest.progress),count]]
		quest_labels[i].add_theme_color_override("font_color",Color("7fdc6a") if quest.done else BeachUI.CREAM)

func sync_rival_scores() -> void:
	if not is_instance_valid(rival_score_list) or game == null:
		return
	for child: Node in rival_score_list.get_children():
		rival_score_list.remove_child(child)
		child.queue_free()
	rival_score_labels.clear()
	for pilot: RivalPilot in game.pilots:
		var row: HBoxContainer = HBoxContainer.new()
		row.mouse_filter = MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation",2)
		rival_score_list.add_child(row)
		var name_label: Label = BeachUI.label(row,pilot.gull.rival_name.to_upper(),BOARD_FONT_SIZE,pilot.gull.rival_tint)
		name_label.size_flags_horizontal = SIZE_EXPAND_FILL
		var label: Label = BeachUI.label(row,"%03d" % pilot.score,BOARD_FONT_SIZE,BeachUI.CREAM)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		rival_score_labels.append(label)
	var you_row: HBoxContainer = HBoxContainer.new()
	you_row.mouse_filter = MOUSE_FILTER_IGNORE
	you_row.add_theme_constant_override("separation",2)
	rival_score_list.add_child(you_row)
	var you_name: Label = BeachUI.label(you_row,"YOU",BOARD_FONT_SIZE,BeachUI.GOLD)
	you_name.size_flags_horizontal = SIZE_EXPAND_FILL
	you_score_label = BeachUI.label(you_row,"000",BOARD_FONT_SIZE,BeachUI.GOLD)
	you_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	goal_label = BeachUI.label(rival_score_list,"",BOARD_FONT_SIZE,Color("7fd0d8"))
	goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var height: float = 3.0 + float(game.pilots.size() + 2) * float(BOARD_FONT_SIZE)
	rival_score_panel.offset_bottom = rival_score_panel.offset_top + height
	rival_score_panel.show()

func show_score_announcement(food_id: String, earned: int) -> void:
	if not Config.foods.has(food_id):
		return
	if is_instance_valid(score_announcement_tween):
		score_announcement_tween.kill()
	var food: Dictionary = Config.foods[food_id]
	score_announcement.add_theme_font_override("font",score_announcement_fonts[score_announcement_font_index])
	score_announcement_font_index = (score_announcement_font_index + 1) % score_announcement_fonts.size()
	score_announcement.text = "%s +%d" % [str(food.name).to_upper(),earned]
	# Training text occupies the normal top-center slot, so shift the transient
	# callout below it rather than covering the current instruction.
	var row: Control = score_announcement.get_parent() as Control
	row.offset_top = training_callout_top() if game.lesson_active() else SCORE_CALLOUT_TOP
	row.offset_bottom = row.offset_top + 24.0
	score_announcement.modulate.a = 1.0
	score_announcement.scale = Vector2(0.72,0.72)
	score_announcement.pivot_offset = score_announcement.size * 0.5
	score_announcement.show()
	score_announcement_tween = create_tween()
	score_announcement_tween.set_parallel(true)
	score_announcement_tween.tween_property(score_announcement,"scale",Vector2.ONE,0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	score_announcement_tween.tween_property(score_announcement,"modulate:a",1.0,0.12)
	# Parallel mode would start the fade and hide alongside the hold, so chain each step.
	score_announcement_tween.chain().tween_interval(SCORE_ANNOUNCEMENT_HOLD)
	score_announcement_tween.chain().tween_property(score_announcement,"modulate:a",0.0,SCORE_ANNOUNCEMENT_FADE).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	score_announcement_tween.chain().tween_callback(score_announcement.hide)

func _draw_digestion(offset: Vector2) -> void:
	var belly: GullDigestion = game.player.digestion
	if belly.snacks.is_empty() and belly.rest <= 0:
		return
	# Beside the gull (right, or left near the screen edge) so it never covers what is below.
	var point: Vector2 = game.player.position-offset+Vector2(18,-8)
	if point.x > 268:
		point.x -= 86
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

const METER_RECT: Rect2 = Rect2(92,4,36,8)

func meter_fill() -> float:
	if game.slowmo_active():
		return clampf(float(game.slowmo_end_msec-Time.get_ticks_msec())/(float(game.perk_value("duration",2.5))*1000.0),0.0,1.0)
	return game.bullet_meter

## Bullet time meter in the top bar, and the Keen eye arrow over the best snack.
func _draw_perks(offset: Vector2) -> void:
	if game.perk_id == "bullet_time":
		var ready: bool = game.slowmo_ready()
		draw_rect(METER_RECT,BeachUI.INK)
		draw_rect(METER_RECT.grow(-1),Color("397a85"))
		draw_rect(Rect2(METER_RECT.position+Vector2.ONE,Vector2(34*meter_fill(),6)),BeachUI.GOLD if ready or game.slowmo_active() else Color("7fd0d8"))
		if ready:
			draw_rect(METER_RECT,BeachUI.CREAM,false,1.0)
			draw_string(HUD_FONT,METER_RECT.position+Vector2(6,6),"SLOW",HORIZONTAL_ALIGNMENT_LEFT,-1,6,BeachUI.INK)
	elif not game.brash.power().is_empty():
		_draw_brash()
	var target: BeachTarget = game.keen_target()
	if target != null:
		var at: Vector2 = target.food_position()-offset
		if at.x > 4 and at.x < 316:
			var tip: Vector2 = Vector2(at.x,maxf(at.y-target.food_radius().y-3+sin(Time.get_ticks_msec()*0.008)*1.5,TOP_BAR_HEIGHT+5))
			draw_colored_polygon(PackedVector2Array([tip,tip+Vector2(-4,-5),tip+Vector2(4,-5)]),BeachUI.GOLD)
			draw_polyline(PackedVector2Array([tip,tip+Vector2(-4,-5),tip+Vector2(4,-5),tip]),BeachUI.INK,1.0)

## Brashness meter in the top bar; it pulses with the power's name when full.
func _draw_brash() -> void:
	var full: bool = game.brash.is_full()
	var pulse: bool = full and int(Time.get_ticks_msec()/250)%2 == 0
	draw_rect(METER_RECT,BeachUI.INK)
	draw_rect(METER_RECT.grow(-1),Color("5a3a4a"))
	draw_rect(Rect2(METER_RECT.position+Vector2.ONE,Vector2(34*game.brash.meter,6)),BeachUI.CREAM if pulse else (BeachUI.GOLD if full else Color("ef725c")))
	draw_rect(METER_RECT,BeachUI.CREAM if full else Color("397a85"),false,1.0)
	draw_string(HUD_FONT,METER_RECT.position+Vector2(4,6),"CALL!" if full else "BRASH",HORIZONTAL_ALIGNMENT_LEFT,-1,6,BeachUI.INK if full else BeachUI.CREAM)
	# Lesson steps 2 and 3 point at the bar: a pulsing gold outline.
	if game.screech_lesson and game.screech_step in [1,2] and int(Time.get_ticks_msec()/300)%2 == 0:
		draw_rect(METER_RECT.grow(2),BeachUI.GOLD,false,1.0)

func goal_status() -> Dictionary:
	if game.casual:
		return {"title":"PRACTICE","progress":game.score.items,"goal":int(Config.tuning.score.casual_items)}
	var index: int = 0
	while index < game.level.stars.size()-1 and game.score.points >= int(game.level.stars[index]):
		index += 1
	return {"title":"1 STAR" if index == 0 else "%d STARS" % (index+1),"progress":game.score.points,"goal":int(game.level.stars[index])}

func _draw() -> void:
	if game == null:
		return
	draw_rect(Rect2(0,0,320,TOP_BAR_HEIGHT),Color("183b4e"))
	draw_rect(Rect2(5,TOP_BAR_HEIGHT-3,85,2),Color("397a85"))
	draw_rect(Rect2(5,TOP_BAR_HEIGHT-3,85*game.score.window/float(Config.tuning.score.combo_window),2),BeachUI.GOLD)
	var offset: Vector2 = Vector2(game.camera_x-160,0)
	_draw_digestion(offset)
	if game.running:
		_draw_perks(offset)
	var aim: Vector2 = game.player.aim-offset
	if game.running:
		if game.training:
			var training_target: Vector2 = game.training_target() - offset
			if training_target.x >= 4 and training_target.x <= 316 and training_target.y >= 28 and training_target.y <= 165:
				draw_arc(training_target,12,0,TAU,24,BeachUI.GOLD,2)
				draw_arc(training_target,16,0,TAU,24,Color(1.0,0.95,0.7,0.55),1)
		elif game.screech_lesson:
			var lesson_target: Vector2 = game.screech_lesson_target() - offset
			if lesson_target.x >= 4 and lesson_target.x <= 316 and lesson_target.y >= 28 and lesson_target.y <= 165:
				draw_arc(lesson_target,12,0,TAU,24,BeachUI.GOLD,2)
				draw_arc(lesson_target,16,0,TAU,24,Color(1.0,0.95,0.7,0.55),1)
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
			var peck_color: Color = BeachUI.GOLD if game.player.peck_window_open() else (Color("ef725c") if game.player.peck_used else BeachUI.CREAM)
			draw_arc(beak,6,0,TAU,12,peck_color,2)
			if game.player.auto_peck():
				draw_string(font,beak+Vector2(-18,-10),"AUTO PECK",HORIZONTAL_ALIGNMENT_LEFT,-1,8,BeachUI.GOLD)
			elif game.player.peck_time > 0:
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
	var right_food_x: float = 280.0
	var right_threat_x: float = 302.0
	for item: Array in [[left_food,Vector2(3,arrow_y),"< FOOD",BeachUI.GOLD],[right_food,Vector2(right_food_x,arrow_y),"FOOD >",BeachUI.GOLD],[left_threat,Vector2(3,arrow_y+11),"< !",Color("ef725c")],[right_threat,Vector2(right_threat_x,arrow_y+11),"! >",Color("ef725c")]]:
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
	obstacles.append(rival_score_panel.get_global_rect().grow(2) if not game.training else training_panel.get_global_rect())
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
	# During lessons the panel already gives the ground and peck instruction;
	# repeating it in a second box only competes with the lesson.
	if game.lesson_active() and game.player.state == BeachGull.State.GROUNDED:
		return {}
	if game.player.state == BeachGull.State.GROUNDED:
		if game.stash_raids.nearby_toddler() != null:
			return {"text":"TAP %s AT TODDLER" % peck}
		if game.stash_raids.has_nearby_source():
			return {"text":"TAP %s TO SEARCH" % peck}
		return {"text":"WALK FOR SCRAPS / %s %s TO FLY" % ["TAP" if game.player.control_mode == "realistic" else "HOLD",flap]}
	if game.player.state == BeachGull.State.STRIKE:
		if game.player.crash_warning():
			return {"text":"PULL UP! CRASH AHEAD","danger":true}
		if game.player.auto_peck():
			return {"text":"AUTO PECK"}
		if not game.player.peck_used:
			return {} if game.training else {"text":"TAP %s AT THE SNACK" % peck}
		return {"text":"PECK ACTIVE" if game.player.peck_time > 0 else "PECK SPENT - DIVE AGAIN"}
	if game.player.landing_aim():
		return {"text":"LANDING / HOLD %s TO CLIMB" % flap}
	return {}

# Fixed slot: below the score callout (or the lesson panel), left of the goal panel,
# and above the zone signs, so the hint never crosses world labels.
func hint_rect(text: String) -> Rect2:
	var width: float = ceilf(font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,8).x) + 6.0
	var y: float = training_panel.get_global_rect().end.y + 2.0 if game.lesson_active() else SCORE_CALLOUT_TOP + 26.0
	return Rect2(4.0,roundf(y),width,11.0)

func touch_buttons_visible() -> bool:
	return game != null and game.running and game.input.touch_visible

func peck_available() -> bool:
	return game.player.state in [BeachGull.State.GROUNDED,BeachGull.State.WINDUP,BeachGull.State.STRIKE]

func _draw_touch_buttons() -> void:
	if game.input.aim_finger >= 0:
		draw_arc(game.input.stick_anchor,float(Config.tuning.touch.stick_radius),0,TAU,24,Color(1.0,0.96,0.85,0.28),1.0)
		draw_circle(game.input.stick_pos,4.0,Color(1.0,0.96,0.85,0.55))
	if game.input.slowmo_ready:
		var slow_box: Rect2 = GullInput.SLOWMO_BUTTON
		draw_rect(slow_box,Color(0.78,0.6,0.1,0.6))
		draw_rect(slow_box,Color(1.0,0.96,0.85,0.8),false,1.0)
		draw_string(font,Vector2(slow_box.position.x+5,slow_box.position.y+14),"SLOW" if game.perk_id == "bullet_time" else "CALL",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color(1.0,0.96,0.85))
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
