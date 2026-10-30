class_name ResultBoard
extends Control

signal requested(action: String, payload: Variant)

const INK := Color("2b1c19")
const CREAM := Color("fff0c2")
const GOLD := Color("ffd166")
const SEA := Color("a9d7d2")

var level: Dictionary
var result: Dictionary
var passed: bool
var rows: Array[Label] = []
var row_values: Array[int] = []
var row_formats: Array[String] = []
var row_index: int = 0
var row_time: float = 0.0
var complete: bool = false
var stars_label: Label
var title_label: Label
var hint_label: Label
var gull: AnimatedSprite2D
var gull_base_scale: float = 1.0
var fish: ResultFishSkeleton
var buttons: Array[Button] = []
var reaction_player: AudioStreamPlayer
var reaction_time: float = 0.0
var reaction_started: bool = false
var captions: Array[Label] = []
var scores_panel: Control
var score_rows: Array[Dictionary] = []
var star_slots: Array[TextureRect] = []
var subtitle: Label
const STAR_DIM := Color(0.36, 0.2, 0.11) ## unearned stars: the gold star darkened into the plank
const LEADERBOARD_PATH := "res://data/leaderboards.json"
static var _seed_boards: Dictionary = {}

# Two inset panels on the sign: the run tally on the left, high scores on the right.
const LEFT_PANEL := Rect2(26, 64, 144, 72)
const RIGHT_PANEL := Rect2(176, 64, 118, 72)
const SCORE_SLOTS := 5
const STAR_TAB := Rect2(110, 13, 100, 24)
# Quest rows use the smaller HUD font (no "*" glyph, so done quests are marked ">").
const QUEST_FONT: Font = preload("res://assets/fonts/gull_hud.fnt")
const QUEST_FONT_SIZE := 6

func setup(for_level: Dictionary, for_result: Dictionary) -> void:
	level = for_level
	result = for_result
	passed = bool(result.get("training", false)) and bool(result.get("success", false)) or int(result.stars) > 0 or bool(result.casual)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = false
	if bool(result.get("training", false)):
		_build_training()
		complete = true
	else:
		_build()
		set_process(true)
		set_process_input(true)
	queue_redraw()

func _build_training() -> void:
	var heading: Label = BeachUI.label(self,"TRAINING COMPLETE!",BeachUI.FONT_DISPLAY,CREAM)
	_place(heading,44,292,19)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var subheading: Label = BeachUI.label(self,"THE BEACH IS YOURS.",BeachUI.FONT_NATIVE,SEA)
	_place(subheading,73,292,13)
	subheading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var note_text: String = GameState.save_error if not GameState.save_error.is_empty() else "FAMILY PICNIC UNLOCKED"
	var note: Label = BeachUI.label(self,note_text,BeachUI.FONT_NATIVE,GOLD if GameState.save_error.is_empty() else Color("ef725c"))
	_place(note,98,292,12)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var earned: int = int(result.get("feathers_earned",0))
	if earned > 0:
		var feather_note: Label = BeachUI.label(self,"+%d FEATHER  /  FEATHERS %d" % [earned,GameState.feathers()],BeachUI.FONT_NATIVE,CREAM)
		_place(feather_note,112,292,12)
		feather_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var actions: HBoxContainer = HBoxContainer.new()
	actions.position = Vector2(39,140)
	actions.size = Vector2(242,16)
	actions.add_theme_constant_override("separation",3)
	add_child(actions)
	if GameState.unlocked(2):
		_add_button(actions,"NEXT >","start",2)
	_add_button(actions,"TRAIN AGAIN","train_again")
	_add_button(actions,"LEVELS","select")
	if not buttons.is_empty():
		buttons[0].grab_focus()
	# Graduates get the full scoring reference before their first real beach.
	open_score_rules("GOT IT")

func _build() -> void:
	title_label = BeachUI.label(self, ("BEACH BOSS!" if bool(result.won) else "OUT-EATEN!") if result.has("boss") else ("LUNCH IS SERVED!" if passed else "STILL HUNGRY?"), BeachUI.FONT_DISPLAY, CREAM)
	_place(title_label, 38, 292, 17)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle = BeachUI.label(self, str(level.name).to_upper() + ("  /  DEMO COMPLETE - THANKS!" if demo_finished() else ""), BeachUI.FONT_NATIVE, GOLD if demo_finished() else SEA)
	_place(subtitle, 55, 292, 9)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Left panel: the run scoreboard, captions left and values right-aligned. Quests sit
	# between the clean bonus and the snatch/stun counts; the total ends the panel.
	# A stunned run has no clean bonus; that row shows what the stuns and crashes cost instead,
	# with EARNED POINTS counted before the losses so the column still adds up to TOTAL.
	var lost := int(result.get("lost", 0))
	if int(result.stuns) > 0:
		_add_count_row("EARNED POINTS", int(result.base) + lost, 66)
		_add_count_row("LOST TO HITS", lost, 75, "-%d", Color("ef725c"))
	else:
		_add_count_row("EARNED POINTS", int(result.base), 66)
		_add_count_row("CLEAN BONUS", int(result.clean), 75, "+%d")
	var y := 84.0
	for quest: Dictionary in result.get("quests", []):
		_add_quest_row(quest, y)
		y += 9.0
	var stats := BeachUI.label(self, "", BeachUI.FONT_NATIVE, CREAM)
	stats.position = Vector2(LEFT_PANEL.position.x + 6, y)
	stats.size = Vector2(LEFT_PANEL.size.x - 12, 9)
	rows.append(stats)
	row_values.append(0)
	row_formats.append("stats")
	_update_row(rows.size() - 1, 0.0)
	_add_count_row("TOTAL", int(result.score), 126, "%d", GOLD)
	_add_rules_link()

	_build_scores_panel()

	# stars_label keeps the textual result ("**-") for tests and tooling; the three
	# star slots on the header plank are what players see.
	stars_label = BeachUI.label(self, "", BeachUI.FONT_DISPLAY, GOLD)
	_place(stars_label, 18, 292, 17)
	stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars_label.visible = false
	for i: int in 3:
		var star := TextureRect.new()
		star.texture = BeachUI.STAR_ICON
		star.modulate = STAR_DIM
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		star.position = Vector2(136 + i * 16, 17)
		star.size = Vector2(16, 16)
		star.pivot_offset = star.size * 0.5
		add_child(star)
		star.visible = not bool(result.casual)
		star_slots.append(star)
	hint_label = BeachUI.label(self, "CLICK / TAP / CONFIRM TO TALLY", BeachUI.FONT_NATIVE, Color("f9d98b"))
	_place(hint_label, 137, 280, 9)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var actions := HBoxContainer.new()
	actions.position = Vector2(42, 148)
	actions.size = Vector2(236, 14)
	actions.add_theme_constant_override("separation", 3)
	add_child(actions)
	if passed and int(level.id) < Config.levels.size() and GameState.unlocked(int(level.id) + 1):
		_add_button(actions, "NEXT >", "start", int(level.id) + 1)
	elif demo_finished() and not GameState.feedback_url().is_empty():
		_add_button(actions, "FEEDBACK", "feedback")
	_add_button(actions, "RETRY / R", "restart")
	_add_button(actions, "LEVELS", "select")
	for button: Button in buttons:
		button.disabled = true

	gull = AnimatedSprite2D.new()
	gull.sprite_frames = Config.frames("player_gull")
	gull.animation = &"idle"
	gull.position = Vector2(247, 29)
	gull_base_scale = float(Config.sprites.player_gull.get("visual_scale",1.0))
	gull.scale = Vector2.ONE * gull_base_scale
	gull.z_index = 2
	var cutout := ShaderMaterial.new()
	cutout.shader = preload("res://assets/shaders/gull_cutout.gdshader")
	gull.material = cutout
	add_child(gull)
	fish = ResultFishSkeleton.new()
	fish.position = Vector2(256, 32)
	fish.visible = false
	fish.z_index = 3
	add_child(fish)

# Right panel: a fixed set of rank / name / score slots. It stays hidden until the
# tally finishes, then fades in. set_high_scores() fills it; until an online board
# is connected it shows this device's best for the level.
func _build_scores_panel() -> void:
	scores_panel = Control.new()
	scores_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scores_panel.modulate.a = 0.0
	add_child(scores_panel)
	var x := RIGHT_PANEL.position.x
	var width := RIGHT_PANEL.size.x
	var header := BeachUI.label(scores_panel, "HIGH SCORES", BeachUI.FONT_NATIVE, GOLD)
	header.name = "Header"
	header.position = Vector2(x, 66)
	header.size = Vector2(width, 10)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var rule := ColorRect.new()
	rule.color = Color(1.0, 0.82, 0.4, 0.35)
	rule.position = Vector2(x + 8, 76)
	rule.size = Vector2(width - 16, 1)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scores_panel.add_child(rule)
	for slot: int in SCORE_SLOTS:
		var y := 80.0 + slot * 11.0
		var rank := BeachUI.label(scores_panel, "%d" % (slot + 1), BeachUI.FONT_NATIVE, SEA)
		rank.position = Vector2(x + 6, y)
		rank.size = Vector2(12, 10)
		var player := BeachUI.label(scores_panel, "---", BeachUI.FONT_NATIVE, CREAM)
		player.position = Vector2(x + 20, y)
		player.size = Vector2(54, 10)
		player.clip_text = true
		var points := BeachUI.label(scores_panel, "", BeachUI.FONT_NATIVE, CREAM)
		points.position = Vector2(x + 72, y)
		points.size = Vector2(width - 78, 10)
		points.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		score_rows.append({"rank": rank, "name": player, "score": points})
	var board: Array = seed_scores(int(level.id))
	if bool(result.casual):
		set_high_scores(board, "NOT RANKED")
	else:
		set_high_scores(ranked_view(board, {"name": "YOU", "score": _best(), "me": true}))
		if OnlineScores.active() and not OnlineScores.player_name().is_empty():
			OnlineScores.submit(int(level.id), _best(), _show_online)

func _best() -> int:
	return maxi(int(GameState.entry(int(level.id)).get("best", 0)), int(result.score))

# The real board replaces the seeded one once Talo answers; offline keeps the seeds.
func _show_online(entries: Array) -> void:
	if not entries.is_empty():
		set_high_scores(entries, "GLOBAL TOP 5")

# First ranked run with Talo on: the score rows give way to a name field. Enter saves the
# name and posts this run's best; an empty name keeps the board local this time.
func _ask_name() -> void:
	_show_rows(false)
	(scores_panel.get_node("Header") as Label).text = "YOUR NAME?"
	var field := LineEdit.new()
	field.name = "NameField"
	field.max_length = OnlineScores.NAME_LENGTH
	field.placeholder_text = "GULL"
	field.alignment = HORIZONTAL_ALIGNMENT_CENTER
	field.add_theme_font_size_override("font_size", BeachUI.FONT_NATIVE)
	field.position = Vector2(RIGHT_PANEL.position.x + 20, 86)
	field.size = Vector2(RIGHT_PANEL.size.x - 40, 14)
	scores_panel.add_child(field)
	var tip := BeachUI.label(scores_panel, "ENTER TO SAVE", BeachUI.FONT_NATIVE, SEA)
	tip.position = Vector2(RIGHT_PANEL.position.x, 106)
	tip.size = Vector2(RIGHT_PANEL.size.x, 10)
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	field.text_changed.connect(func(text: String) -> void:
		var clean := OnlineScores.clean_name(text)
		if clean != text:
			field.text = clean
			field.caret_column = clean.length())
	field.text_submitted.connect(func(text: String) -> void:
		field.queue_free()
		tip.queue_free()
		_show_rows(true)
		(scores_panel.get_node("Header") as Label).text = "HIGH SCORES"
		if not buttons.is_empty():
			buttons[0].grab_focus()
		if not OnlineScores.clean_name(text).is_empty():
			OnlineScores.set_player_name(text)
			OnlineScores.submit(int(level.id), _best(), _show_online))
	field.grab_focus()

func _show_rows(shown: bool) -> void:
	for row: Dictionary in score_rows:
		for label: Label in row.values():
			label.visible = shown

# Starter entries from data/leaderboards.json, highest first. Online scores will
# replace these; until then they give each level a field to measure against.
static func seed_scores(level_id: int) -> Array:
	if _seed_boards.is_empty() and FileAccess.file_exists(LEADERBOARD_PATH):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(LEADERBOARD_PATH))
		if parsed is Dictionary:
			_seed_boards = parsed.get("levels", {})
	var entries: Array = []
	for entry: Variant in _seed_boards.get(str(level_id), []):
		if entry is Dictionary:
			entries.append({"name": str(entry.get("name", "")), "score": int(entry.get("score", 0))})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.score) > int(b.score))
	return entries

# Merges the player into a board and returns what fits the panel: the top five
# when the player makes it, otherwise the top four plus the player's own rank.
static func ranked_view(board: Array, player: Dictionary, slots: int = SCORE_SLOTS) -> Array:
	var merged: Array = board.duplicate()
	var at := merged.size()
	for i: int in merged.size():
		if int(player.score) >= int(merged[i].score):
			at = i
			break
	merged.insert(at, player)
	for i: int in merged.size():
		merged[i] = (merged[i] as Dictionary).merged({"rank": i + 1})
	if at < slots:
		return merged.slice(0, slots)
	var view: Array = merged.slice(0, slots - 1)
	view.append(merged[at])
	return view

# entries: Array of {"name": String, "score": int, "me": bool}, highest first.
# An optional "rank" overrides the slot number (a player outside the top shows as e.g. 9).
# heading names the board, e.g. "HIGH SCORES" or "GLOBAL TOP 5".
func set_high_scores(entries: Array, heading: String = "HIGH SCORES") -> void:
	if scores_panel == null or score_rows.is_empty():
		return
	for slot: int in score_rows.size():
		var row: Dictionary = score_rows[slot]
		var has_entry := slot < entries.size()
		var entry: Dictionary = entries[slot] if has_entry else {}
		var mine := bool(entry.get("me", false))
		var color := GOLD if mine else CREAM
		(row.rank as Label).text = str(int(entry.get("rank", slot + 1)))
		(row.name as Label).text = str(entry.get("name", "---")).to_upper().left(8) if has_entry else "---"
		(row.score as Label).text = str(int(entry.get("score", 0))) if has_entry else ""
		(row.name as Label).add_theme_color_override("font_color", color if has_entry else Color("c9a77a"))
		(row.score as Label).add_theme_color_override("font_color", color)
		(row.rank as Label).add_theme_color_override("font_color", GOLD if mine else SEA)
	(scores_panel.get_node("Header") as Label).text = heading
	queue_redraw()

# Earned stars turn gold one after another with a small pop; unearned ones stay dim.
func _light_stars(count: int) -> void:
	for i: int in star_slots.size():
		var star := star_slots[i]
		if i >= count:
			continue
		if not is_inside_tree():
			star.modulate = Color.WHITE
			continue
		var tween := create_tween()
		tween.tween_interval(i * 0.14)
		tween.tween_callback(func() -> void:
			star.modulate = Color.WHITE
			star.scale = Vector2.ONE * 1.6)
		tween.tween_property(star, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _reveal_scores() -> void:
	if scores_panel == null:
		return
	if is_inside_tree():
		create_tween().tween_property(scores_panel, "modulate:a", 1.0, 0.25)
	else:
		scores_panel.modulate.a = 1.0
	if OnlineScores.active() and OnlineScores.player_name().is_empty() and not bool(result.casual) and not scores_panel.has_node("NameField"):
		_ask_name()

# A small "?" badge beside TOTAL opens the score rules.
func _add_rules_link() -> void:
	var badge := Button.new()
	badge.name = "RulesLink"
	badge.text = "?"
	badge.focus_mode = Control.FOCUS_NONE
	badge.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("397a85") if state in ["hover", "pressed"] else Color("245369")
		box.set_content_margin_all(1)
		box.content_margin_left = 3
		box.content_margin_right = 3
		badge.add_theme_stylebox_override(state, box)
	add_child(badge)
	badge.custom_minimum_size = Vector2(11, 11)
	badge.position = Vector2(LEFT_PANEL.position.x + 50, 125)
	badge.size = Vector2(11, 11)
	badge.pressed.connect(func() -> void: open_score_rules("BACK"))

func open_score_rules(button_text: String) -> ScoreRulesCard:
	var card := ScoreRulesCard.open(self, button_text)
	card.closed.connect(func() -> void:
		if not buttons.is_empty() and is_instance_valid(buttons[0]) and not buttons[0].disabled:
			buttons[0].grab_focus())
	return card

# The last demo level was cleared: the next level exists but belongs to the full game.
func demo_finished() -> bool:
	return passed and not bool(result.get("training", false)) and GameState.demo_locked(int(level.id) + 1) and int(level.id) < Config.levels.size()

func _add_count_row(caption: String, value: int, y: float, format: String = "%d", color: Color = CREAM) -> void:
	var x := LEFT_PANEL.position.x + 6
	var width := LEFT_PANEL.size.x - 12
	var name_label := BeachUI.label(self, caption, BeachUI.FONT_NATIVE, color)
	name_label.position = Vector2(x, y)
	name_label.size = Vector2(width, 9)
	captions.append(name_label)
	var label := BeachUI.label(self, format % 0, BeachUI.FONT_NATIVE, color)
	label.position = Vector2(x, y)
	label.size = Vector2(width, 9)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rows.append(label)
	row_values.append(value)
	row_formats.append(caption + "|" + format)

# One quest line: "* NAME" + bonus when done, "- NAME" + n/N when counted. The name is
# trimmed to leave room for the value, never wrapped.
func _add_quest_row(quest: Dictionary, y: float) -> void:
	var x := LEFT_PANEL.position.x + 6
	var width := LEFT_PANEL.size.x - 12
	var done := bool(quest.get("done", false))
	var count := int(quest.get("count", 1))
	var value_text := ""
	if done:
		value_text = "+%d" % int(quest.get("bonus", 0))
	else:
		value_text = "%d/%d" % [int(quest.get("progress", 0)), count]
	var color := GOLD if done else CREAM
	var name_label := _quest_label("", color)
	name_label.position = Vector2(x, y)
	name_label.size = Vector2(width, 9)
	var font := QUEST_FONT
	var room := width - font.get_string_size(" +%d" % 999, HORIZONTAL_ALIGNMENT_LEFT, -1, QUEST_FONT_SIZE).x
	var caption := "%s %s" % [">" if done else "-", quest.text]
	while caption.length() > 3 and font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, QUEST_FONT_SIZE).x > room:
		caption = caption.left(caption.length() - 1)
	name_label.text = caption
	name_label.size.x = room
	captions.append(name_label)
	var label := _quest_label("" if done else value_text, color)
	label.position = Vector2(x, y)
	label.size = Vector2(width, 9)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rows.append(label)
	row_values.append(int(quest.get("bonus", 0)) if done else 0)
	row_formats.append(("quest|+%d" if done else "static|" + value_text.replace("%", "%%")))

func _quest_label(value: String, color: Color) -> Label:
	var label := BeachUI.label(self, value, QUEST_FONT_SIZE, color)
	label.add_theme_font_override("font", QUEST_FONT)
	# BeachUI.label snaps sizes below 8 back to GullPixel's grid; the HUD face is native at 6.
	label.add_theme_font_size_override("font_size", QUEST_FONT_SIZE)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label

func _add_button(parent: HBoxContainer, caption: String, action: String, payload: Variant = null) -> void:
	var button := BeachUI.button(parent, caption, func() -> void: requested.emit(action, payload), 68)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.append(button)

func _place(control: Control, y: float, width: float, height: float) -> void:
	control.position = Vector2((320.0 - width) * 0.5, y)
	control.size = Vector2(width, height)

func _process(delta: float) -> void:
	if complete:
		_idle_gull(delta)
		return
	row_time += delta
	var duration := 0.42 if row_index == rows.size() - 1 else (0.28 if row_index < 2 else 0.18)
	var progress := clampf(row_time / duration, 0.0, 1.0)
	_update_row(row_index, progress)
	if progress >= 1.0:
		row_index += 1
		row_time = 0.0
		if row_index >= rows.size():
			finish_tally()

func _update_row(index: int, progress: float) -> void:
	if index < 0 or index >= rows.size():
		return
	if row_formats[index] == "stats":
		rows[index].text = "SNATCHES %d  STUNS %d" % [roundi(int(result.items) * progress), roundi(int(result.stuns) * progress)]
		return
	var parts := row_formats[index].split("|")
	if parts[0] == "static":
		return
	rows[index].text = parts[1] % roundi(row_values[index] * progress)

func finish_tally() -> void:
	if complete:
		return
	for index: int in rows.size():
		_update_row(index, 1.0)
	complete = true
	if bool(result.casual):
		title_label.text = "PRACTICE COMPLETE!"
		stars_label.text = ""
	else:
		stars_label.text = "*".repeat(int(result.stars)) + "-".repeat(3 - int(result.stars))
		_light_stars(int(result.stars))
		# Screeches' verdict lands with the stars; boss levels keep their own title.
		if not result.has("boss"):
			var lines: Array = Config.quips.result_titles[clampi(int(result.stars), 0, 3)]
			title_label.text = str(lines.pick_random())
	hint_label.text = _record_text()
	if not GameState.save_error.is_empty():
		hint_label.add_theme_color_override("font_color", Color("ef725c"))
	elif not bool(result.casual):
		BeachUI.feather_icon(hint_label)
	var target := _target_text()
	if not target.is_empty() and not demo_finished():
		subtitle.text += "  /  " + target
	for button: Button in buttons:
		button.disabled = false
	if not buttons.is_empty():
		buttons[0].grab_focus()
	_reveal_scores()
	_start_reaction()

# How far the run fell short of the next star; empty for Practice, boss levels and full marks.
func _target_text() -> String:
	var stars := int(result.stars)
	if bool(result.casual) or result.has("boss") or stars >= level.stars.size():
		return ""
	var short := int(level.stars[stars]) - int(result.score)
	return "%d MORE TO PASS" % short if stars == 0 else "%d MORE FOR STAR %d" % [short, stars + 1]

func _record_text() -> String:
	var record: Dictionary = GameState.entry(int(level.id))
	if not GameState.save_error.is_empty():
		return GameState.save_error
	if bool(result.casual):
		return "TIME %.1f   BEST %.1f SEC" % [float(result.elapsed), float(record.get("casual_time", result.elapsed))]
	var earned := int(result.get("feathers_earned", 0))
	var total := "FEATHERS %d" % GameState.feathers()
	return ("+%d FEATHER%s  /  %s" % [earned, "" if earned == 1 else "S", total]) if earned > 0 else total

func _start_reaction() -> void:
	if reaction_started:
		return
	reaction_started = true
	reaction_time = 0.0
	if passed:
		gull.play(&"fly")
		reaction_player = Audio.play_result_reaction(true, maxi(1, int(result.stars)))
		Audio.play("level_end",1.0,-8.0)
	else:
		gull.play(&"idle")
		reaction_player = Audio.play_result_reaction(false, 0)
		Audio.play("level_end_fail",1.0,-8.0)

func _idle_gull(delta: float) -> void:
	reaction_time += delta
	if not reaction_started:
		return
	if passed and reaction_time < 0.8:
		var strength := 1.0 + float(int(result.stars)) * 0.25
		gull.rotation = sin(reaction_time * 34.0) * 0.08 * strength
		gull.position.y = 29.0 - absf(sin(reaction_time * 17.0)) * 3.0 * strength
		gull.scale = Vector2(1.0 + sin(reaction_time * 27.0) * 0.078, 1.0) * gull_base_scale
	elif not passed and reaction_time < 0.9:
		gull.rotation = sin(reaction_time * 20.0) * 0.12
		gull.scale = Vector2(1.0 - absf(sin(reaction_time * 16.0)) * 0.156, 1.0 + absf(sin(reaction_time * 16.0)) * 0.111) * gull_base_scale
		if reaction_time > 0.35 and not fish.visible:
			fish.launch()
	else:
		gull.rotation = 0.0
		gull.position.y = 29.0 + sin(Time.get_ticks_msec() * 0.004) * 0.7
		gull.scale = Vector2.ONE * gull_base_scale
		gull.play(&"idle")

func _input(event: InputEvent) -> void:
	if complete or not is_visible_in_tree():
		return
	var skip := event.is_action_pressed("ui_accept")
	if event is InputEventMouseButton:
		skip = skip or (event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	if event is InputEventScreenTouch:
		skip = skip or event.pressed
	if skip:
		finish_tally()
		get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	set_process(false)
	set_process_input(false)
	if is_instance_valid(reaction_player):
		reaction_player.stop()
		reaction_player.queue_free()

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_node_ready() and not is_visible_in_tree():
		set_process(false)
		set_process_input(false)
		if is_instance_valid(fish):
			fish.set_process(false)
		if is_instance_valid(gull):
			gull.pause()
		if is_instance_valid(reaction_player):
			reaction_player.stop()

func _draw() -> void:
	# Ropes disappear behind the planks and meet in a shallow hanging V.
	for x: float in [58.0, 262.0]:
		draw_line(Vector2(160, -9), Vector2(x, 31), Color("d9c18c"), 3.0)
		draw_line(Vector2(160, -9), Vector2(x, 31), Color("75583b"), 1.0)
	# Five uneven planks keep the sign readable while giving it a hand-built silhouette.
	var plank_colors := [Color("9b5c32"), Color("aa6738"), Color("91512e"), Color("a96135"), Color("8b4b2a")]
	for i: int in 5:
		var y := 29.0 + i * 25.0
		var left := 20.0 + float((i * 7) % 5)
		var right := 300.0 - float((i * 11) % 6)
		draw_colored_polygon(PackedVector2Array([Vector2(left + 3, y), Vector2(right, y + 1), Vector2(right - 2, y + 27), Vector2(left, y + 25)]), plank_colors[i])
		draw_line(Vector2(left + 7, y + 8), Vector2(right - 12, y + 7), Color(0.30, 0.16, 0.09, 0.35), 1.0)
		draw_line(Vector2(left + 25, y + 19), Vector2(right - 26, y + 20), Color(0.91, 0.59, 0.32, 0.22), 1.0)
		for x: float in [left + 8, right - 9]:
			draw_circle(Vector2(x, y + 13), 2.0, Color("493427"))
			draw_circle(Vector2(x - 0.5, y + 12.5), 0.7, Color("c0a176"))
	if bool(result.get("training", false)) or scores_panel == null:
		return
	# Raised header plank: a short board nailed above the sign gives the stars their own backing.
	var tab := STAR_TAB
	draw_colored_polygon(PackedVector2Array([tab.position + Vector2(2, 0), Vector2(tab.end.x, tab.position.y + 1), tab.end - Vector2(1, 0), Vector2(tab.position.x, tab.end.y - 1)]), Color("a96135"))
	draw_line(tab.position + Vector2(2, 0.5), Vector2(tab.end.x, tab.position.y + 1.5), Color(0.91, 0.59, 0.32, 0.5), 1.0)
	draw_line(Vector2(tab.position.x, tab.end.y - 0.5), tab.end - Vector2(1, 0.5), Color(0.30, 0.16, 0.09, 0.6), 1.0)
	draw_rect(Rect2(tab.position + Vector2(12, 5), tab.size - Vector2(24, 9)), Color(0.16, 0.08, 0.04, 0.65))
	for x: float in [tab.position.x + 6, tab.end.x - 6]:
		draw_circle(Vector2(x, tab.get_center().y), 2.0, Color("493427"))
		draw_circle(Vector2(x - 0.5, tab.get_center().y - 0.5), 0.7, Color("c0a176"))
	# Recessed panels keep the tally and the high scores visually separate on the planks.
	for panel: Rect2 in [LEFT_PANEL, RIGHT_PANEL]:
		draw_rect(panel, Color(0.16, 0.08, 0.04, 0.6))
		draw_line(panel.position + Vector2(0, 0.5), panel.position + Vector2(panel.size.x, 0.5), Color(0.12, 0.06, 0.03, 0.8), 1.0)
		draw_line(panel.position + Vector2(0, panel.size.y - 0.5), panel.end - Vector2(0, 0.5), Color(0.91, 0.62, 0.36, 0.35), 1.0)
	# Rule above the total.
	draw_line(Vector2(LEFT_PANEL.position.x + 6, 123.5), Vector2(LEFT_PANEL.end.x - 6, 123.5), Color(1.0, 0.82, 0.4, 0.45), 1.0)
