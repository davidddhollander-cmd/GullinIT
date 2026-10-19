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
var fish: ResultFishSkeleton
var buttons: Array[Button] = []
var reaction_player: AudioStreamPlayer
var reaction_time: float = 0.0
var reaction_started: bool = false

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

func _build() -> void:
	title_label = BeachUI.label(self, "LUNCH IS SERVED!" if passed else "STILL HUNGRY?", BeachUI.FONT_DISPLAY, CREAM)
	_place(title_label, 43, 292, 17)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var subtitle := BeachUI.label(self, str(level.name).to_upper() + ("  /  DEMO COMPLETE - THANKS!" if demo_finished() else ""), BeachUI.FONT_NATIVE, GOLD if demo_finished() else SEA)
	_place(subtitle, 61, 292, 9)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_add_count_row("EARNED POINTS", int(result.base), 70)
	_add_count_row("CLEAN BONUS", int(result.clean), 81, "+%d")
	_add_count_row("SNATCHES", int(result.items), 92)
	_add_count_row("STUNS", int(result.stuns), 103)

	var events := BeachUI.label(self, "RISKY 0   UPWIND 0   MUGGED 0", BeachUI.FONT_NATIVE, SEA)
	_place(events, 114, 292, 9)
	events.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rows.append(events)
	row_values.append(0)
	row_formats.append("events")
	_add_count_row("TOTAL", int(result.score), 125)

	stars_label = BeachUI.label(self, "", BeachUI.FONT_DISPLAY, GOLD)
	_place(stars_label, 25, 292, 17)
	stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label = BeachUI.label(self, "CLICK / TAP / CONFIRM TO TALLY", BeachUI.FONT_NATIVE, Color("f9d98b"))
	_place(hint_label, 135, 292, 9)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var actions := HBoxContainer.new()
	actions.position = Vector2(42, 145)
	actions.size = Vector2(236, 14)
	actions.add_theme_constant_override("separation", 3)
	add_child(actions)
	if passed and int(level.id) < 6 and GameState.unlocked(int(level.id) + 1):
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
	gull.scale = Vector2.ONE * 0.18
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

# The last demo level was cleared: the next level exists but belongs to the full game.
func demo_finished() -> bool:
	return passed and not bool(result.get("training", false)) and GameState.demo_locked(int(level.id) + 1) and int(level.id) < 6

func _add_count_row(caption: String, value: int, y: float, format: String = "%d") -> void:
	var label := BeachUI.label(self, "%s  0" % caption, 8, CREAM)
	_place(label, y, 292, 11)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rows.append(label)
	row_values.append(value)
	row_formats.append(caption + "|" + format)

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
	if row_formats[index] == "events":
		var risky := roundi(int(result.bonuses.Risky) * progress)
		var upwind := roundi(int(result.bonuses.Upwind) * progress)
		var mugged := roundi(int(result.bonuses.Mugged) * progress)
		rows[index].text = "RISKY %d   UPWIND %d   MUGGED %d" % [risky, upwind, mugged]
		return
	var parts := row_formats[index].split("|")
	rows[index].text = "%s  %s" % [parts[0], parts[1] % roundi(row_values[index] * progress)]

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
	hint_label.text = _record_text()
	if not GameState.save_error.is_empty():
		hint_label.add_theme_color_override("font_color", Color("ef725c"))
	for button: Button in buttons:
		button.disabled = false
	if not buttons.is_empty():
		buttons[0].grab_focus()
	_start_reaction()

func _record_text() -> String:
	var record: Dictionary = GameState.entry(int(level.id))
	if not GameState.save_error.is_empty():
		return GameState.save_error
	if bool(result.casual):
		return "TIME %.1f   BEST %.1f SEC" % [float(result.elapsed), float(record.get("casual_time", result.elapsed))]
	if int(result.stars) >= 3:
		return "%.1f SEC   BEST %d   ALL 3 STARS!" % [float(result.elapsed), int(record.get("best", 0))]
	var threshold_index: int = mini(int(result.stars), 2)
	return "%.1f SEC   BEST %d   NEXT %s" % [float(result.elapsed), int(record.get("best", 0)), str(level.stars[threshold_index])]

func _start_reaction() -> void:
	if reaction_started:
		return
	reaction_started = true
	reaction_time = 0.0
	if passed:
		gull.play(&"fly")
		reaction_player = Audio.play_result_reaction(true, maxi(1, int(result.stars)))
	else:
		gull.play(&"idle")
		reaction_player = Audio.play_result_reaction(false, 0)

func _idle_gull(delta: float) -> void:
	reaction_time += delta
	if not reaction_started:
		return
	if passed and reaction_time < 0.8:
		var strength := 1.0 + float(int(result.stars)) * 0.25
		gull.rotation = sin(reaction_time * 34.0) * 0.08 * strength
		gull.position.y = 29.0 - absf(sin(reaction_time * 17.0)) * 3.0 * strength
		gull.scale = Vector2(0.18 + sin(reaction_time * 27.0) * 0.014, 0.18)
	elif not passed and reaction_time < 0.9:
		gull.rotation = sin(reaction_time * 20.0) * 0.12
		gull.scale = Vector2(0.18 - absf(sin(reaction_time * 16.0)) * 0.028, 0.18 + absf(sin(reaction_time * 16.0)) * 0.02)
		if reaction_time > 0.35 and not fish.visible:
			fish.launch()
	else:
		gull.rotation = 0.0
		gull.position.y = 29.0 + sin(Time.get_ticks_msec() * 0.004) * 0.7
		gull.scale = Vector2.ONE * 0.18
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
