class_name TextEditTool
extends CanvasLayer
## Debug-only text editor. F3 freezes the game and outlines every Label, Button and RichTextLabel.
## Click one in the game window and edit its text live in the editor window. "Copy changes" puts an
## OLD/NEW list (with the data source when the text comes from data/trainer.json) on the clipboard.
## Drawn text (effects pops, baked signs) has no node and cannot be picked.

const TOGGLE_KEY: Key = KEY_F3
const GOLD: Color = Color("ffc65c")
const TEAL: Color = Color("80bcb8")
const GOLD_OPEN: String = "[color=#ffc65c]"
const GOLD_CLOSE: String = "[/color]"
const REFRESH_SECONDS: float = 0.3

var active: bool = false
var targets: Array[Control] = []
var hovered: Control
var selected: Control
var edits: Dictionary = {} ## instance id -> {node, original}
var was_paused: bool = false
var refresh_left: float = 0.0
var picker: Control
var window: Window
var path_label: Label
var source_label: Label
var original_label: Label
var edit_box: TextEdit
var status_label: Label
var copy_button: Button

func _init() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode == TOGGLE_KEY or (active and event.keycode == KEY_ESCAPE):
		if active:
			deactivate()
		else:
			activate()
		get_viewport().set_input_as_handled()

func activate() -> void:
	if active:
		return
	active = true
	was_paused = get_tree().paused
	get_tree().paused = true
	_build_ui()
	picker.show()
	window.show()
	refresh_targets()

func deactivate() -> void:
	if not active:
		return
	active = false
	get_tree().paused = was_paused
	if picker != null:
		picker.hide()
		window.hide()
	hovered = null
	selected = null

func _process(delta: float) -> void:
	if not active:
		return
	refresh_left -= delta
	if refresh_left <= 0.0:
		refresh_targets()
	hovered = target_at(picker.get_local_mouse_position())
	picker.queue_redraw()

# --- Picking -------------------------------------------------------------------------------------

static func is_text_node(node: Node) -> bool:
	return node is Label or node is Button or node is RichTextLabel

func refresh_targets() -> void:
	refresh_left = REFRESH_SECONDS
	targets.clear()
	collect_targets(get_tree().root)

func collect_targets(from: Node) -> void:
	for child: Node in from.get_children():
		if child == self or child == window:
			continue
		if is_text_node(child) and (child as Control).is_visible_in_tree() and not str(child.get("text")).is_empty():
			targets.append(child as Control)
		collect_targets(child)

## Viewport-space rectangle of a control, wherever its canvas layer or camera put it.
static func screen_rect(control: Control) -> Rect2:
	return control.get_global_transform_with_canvas() * Rect2(Vector2.ZERO,control.size)

## The smallest text element under a point, so a label inside a button panel wins over the panel.
func target_at(point: Vector2) -> Control:
	var best: Control
	var best_area: float = INF
	for target: Control in targets:
		if not is_instance_valid(target):
			continue
		var rect: Rect2 = screen_rect(target)
		if rect.has_point(point) and rect.get_area() < best_area:
			best = target
			best_area = rect.get_area()
	return best

## The game reuses some nodes for other text (the trainer card shows every lesson in the same labels).
## An edit only counts while the node still shows what the editor last put there.
func prune_stale() -> void:
	for id: int in edits.keys():
		var entry: Dictionary = edits[id]
		if not is_instance_valid(entry.node) or text_of(entry.node) != str(entry.applied):
			edits.erase(id)

func select(target: Control) -> void:
	prune_stale()
	selected = target
	if window == null:
		return
	if target == null:
		path_label.text = "Click any text in the game window"
		source_label.text = ""
		original_label.text = ""
		edit_box.text = ""
		edit_box.editable = false
		return
	path_label.text = "%s  %s" % [target.get_class(),describe_path(target)]
	var source: String = str(target.get_meta("text_source",""))
	source_label.text = "Source: data/trainer.json  %s" % source if not source.is_empty() else "Source: search the repo for the OLD text"
	original_label.text = "Original: " + original_of(target)
	edit_box.editable = true
	edit_box.text = readable(target,text_of(target))

# --- Editing -------------------------------------------------------------------------------------

static func text_of(node: Node) -> String:
	return str(node.get("text"))

## Gold highlights are shown as **marks** while editing, the way the copy in data/trainer.json writes them.
static func readable(node: Node, text: String) -> String:
	return text.replace(GOLD_OPEN,"**").replace(GOLD_CLOSE,"**") if node is RichTextLabel else text

static func stored(node: Node, text: String) -> String:
	if not (node is RichTextLabel):
		return text
	return TrainerCard.markup(text)

func original_of(node: Control) -> String:
	var id: int = node.get_instance_id()
	return readable(node,str(edits[id].original)) if edits.has(id) else readable(node,text_of(node))

## Applies the editor box's text to the selected element and records (or clears) the edit.
func apply_edit(value: String) -> void:
	if not is_instance_valid(selected):
		return
	var id: int = selected.get_instance_id()
	if not edits.has(id):
		edits[id] = {"node": selected, "original": text_of(selected), "applied": text_of(selected)}
	selected.set("text",stored(selected,value))
	edits[id].applied = text_of(selected)
	if text_of(selected) == str(edits[id].original):
		edits.erase(id)
	_update_status()

func revert_selected() -> void:
	if not is_instance_valid(selected):
		return
	var id: int = selected.get_instance_id()
	if edits.has(id):
		selected.set("text",edits[id].original)
		edits.erase(id)
	select(selected)
	_update_status()

func revert_all() -> void:
	for id: int in edits.keys():
		var entry: Dictionary = edits[id]
		if is_instance_valid(entry.node):
			entry.node.set("text",entry.original)
	edits.clear()
	select(selected)
	_update_status()

# --- Report --------------------------------------------------------------------------------------

func describe_path(node: Node) -> String:
	var names: PackedStringArray = []
	var current: Node = node
	while current != null and names.size() < 4 and current != get_tree().root:
		names.append(str(current.name))
		current = current.get_parent()
	names.reverse()
	return "/".join(names)

func context_line() -> String:
	var scene: Node = get_tree().current_scene
	var parts: PackedStringArray = []
	if scene != null:
		parts.append("screen: %s" % str(scene.get("screen")))
		var game: Variant = scene.get("game")
		if game is BeachGame and is_instance_valid(game):
			parts.append("level %d %s" % [int(game.level.id),str(game.level.name)])
			if game.training:
				parts.append("training lesson %d of %d" % [game.lesson + 1,BeachGame.TRAINING_LESSONS])
			elif game.screech_lesson:
				parts.append("screech lesson step %d of %d" % [game.screech_step + 1,BeachGame.SCREECH_STEPS])
	parts.append("control mode: " + GameState.control_mode())
	return " | ".join(parts)

func report() -> String:
	prune_stale()
	var lines: PackedStringArray = ["TEXT EDITS (%d)" % edits.size(),context_line(),""]
	var number: int = 1
	for id: int in edits.keys():
		var entry: Dictionary = edits[id]
		var node: Control = entry.node
		if not is_instance_valid(node):
			continue
		lines.append("#%d  %s  %s" % [number,node.get_class(),describe_path(node)])
		var source: String = str(node.get_meta("text_source",""))
		if not source.is_empty():
			lines.append("Source: data/trainer.json  " + source)
			var template: String = str(node.get_meta("text_template",""))
			if not template.is_empty():
				lines.append("Template: " + template)
		lines.append("OLD: " + readable(node,str(entry.original)))
		lines.append("NEW: " + readable(node,text_of(node)))
		lines.append("")
		number += 1
	return "\n".join(lines)

func copy_report() -> void:
	prune_stale()
	_update_status()
	DisplayServer.clipboard_set(report())
	var file: FileAccess = FileAccess.open("user://text_edits.txt",FileAccess.WRITE)
	if file != null:
		file.store_string(report())
	if status_label != null:
		status_label.text = "Copied %d edit%s to the clipboard. Paste them into the chat." % [edits.size(),"" if edits.size() == 1 else "s"]

func _update_status() -> void:
	if copy_button != null:
		copy_button.text = "Copy changes (%d)" % edits.size()
		copy_button.disabled = edits.is_empty()

# --- UI ------------------------------------------------------------------------------------------

func _build_ui() -> void:
	if picker != null:
		return
	picker = Control.new()
	picker.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(picker)
	picker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	picker.draw.connect(_draw_picker)
	picker.gui_input.connect(_picker_input)
	window = Window.new()
	window.visible = false # force_native can only change while the window is hidden
	window.title = "Text edit (F3 or Esc to close)"
	window.size = Vector2i(560,430)
	window.force_native = true
	window.process_mode = Node.PROCESS_MODE_ALWAYS
	window.close_requested.connect(deactivate)
	get_tree().root.add_child(window)
	var usable: Rect2i = DisplayServer.screen_get_usable_rect()
	var root: Window = get_tree().root
	window.position = Vector2i(mini(root.position.x + root.size.x + 12,usable.end.x - window.size.x),root.position.y)
	var margin: MarginContainer = MarginContainer.new()
	window.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge: String in ["left","top","right","bottom"]:
		margin.add_theme_constant_override("margin_" + edge,10)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation",6)
	margin.add_child(column)
	path_label = _label(column)
	source_label = _label(column)
	original_label = _label(column)
	var heading: Label = Label.new()
	heading.text = "New text (bold gold marks: **like this**)"
	column.add_child(heading)
	edit_box = TextEdit.new()
	edit_box.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	edit_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	edit_box.custom_minimum_size = Vector2(0,140)
	edit_box.text_changed.connect(func() -> void: apply_edit(edit_box.text))
	column.add_child(edit_box)
	var row: HBoxContainer = HBoxContainer.new()
	column.add_child(row)
	var revert: Button = Button.new()
	revert.text = "Revert this"
	revert.pressed.connect(revert_selected)
	row.add_child(revert)
	var revert_everything: Button = Button.new()
	revert_everything.text = "Revert all"
	revert_everything.pressed.connect(revert_all)
	row.add_child(revert_everything)
	copy_button = Button.new()
	copy_button.text = "Copy changes (0)"
	copy_button.disabled = true
	copy_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy_button.pressed.connect(copy_report)
	row.add_child(copy_button)
	status_label = _label(column)
	select(null)
	_update_status()

func _label(parent: Node) -> Label:
	var label: Label = Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label

func _picker_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		select(target_at(picker.get_local_mouse_position()))
		picker.accept_event()

func _draw_picker() -> void:
	for target: Control in targets:
		if not is_instance_valid(target):
			continue
		var rect: Rect2 = screen_rect(target)
		var edited: bool = edits.has(target.get_instance_id())
		picker.draw_rect(rect,GOLD if edited else Color(TEAL,0.55),false,1.0)
	if is_instance_valid(hovered):
		picker.draw_rect(screen_rect(hovered),Color(1.0,1.0,1.0,0.18),true)
	if is_instance_valid(selected):
		picker.draw_rect(screen_rect(selected).grow(1.0),GOLD,false,2.0)
