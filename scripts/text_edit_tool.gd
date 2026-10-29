class_name TextEditTool
extends CanvasLayer
## Debug-only UI editor. F3 freezes the game and outlines every Label, Button and RichTextLabel.
## Click one in the game window, then in the editor window you can:
##   - change its text live,
##   - select its parent (menu, pane, panel) and set that section's width and height,
##   - delete a section (it is hidden, and Undo brings it back).
## "Copy changes" puts everything on the clipboard as a list to paste into a chat, with the
## data/trainer.json source for trainer-card text. Drawn text (effects pops, baked signs) has no node.

const TOGGLE_KEY: Key = KEY_F3
const GOLD: Color = Color("ffc65c")
const TEAL: Color = Color("80bcb8")
const GOLD_OPEN: String = "[color=#ffc65c]"
const GOLD_CLOSE: String = "[/color]"
const REFRESH_SECONDS: float = 0.3
const MAX_SIZE: float = 1000.0
const PREVIEW_TEXTS: int = 6

var active: bool = false
var targets: Array[Control] = []
var hovered: Control
var selected: Control
var edits: Dictionary = {} ## text edits: instance id -> {node, original, applied}
var resizes: Dictionary = {} ## size edits: instance id -> {node, original: Vector2}
var deletions: Array[Dictionary] = [] ## hidden sections, oldest first: {node, texts}
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
var width_spin: SpinBox
var height_spin: SpinBox
var size_label: Label
var undo_button: Button

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
		width_spin.editable = false
		height_spin.editable = false
		size_label.text = ""
		_update_status()
		return
	path_label.text = "%s  %s" % [target.get_class(),describe_path(target)]
	var is_text: bool = is_text_node(target)
	var source: String = str(target.get_meta("text_source",""))
	if not is_text:
		source_label.text = "A section: set its size below, or delete it. Contains: " + preview(target)
	else:
		source_label.text = "Source: data/trainer.json  %s" % source if not source.is_empty() else "Source: search the repo for the OLD text"
	original_label.text = ("Original: " + original_of(target)) if is_text else ""
	edit_box.editable = is_text
	edit_box.text = readable(target,text_of(target)) if is_text else ""
	width_spin.editable = true
	height_spin.editable = true
	var minimum: Vector2 = target.custom_minimum_size
	width_spin.set_value_no_signal(minimum.x if minimum.x > 0.0 else target.size.x)
	height_spin.set_value_no_signal(minimum.y if minimum.y > 0.0 else target.size.y)
	_show_size()
	_update_status()

## One level up: a label's panel, a panel's menu. Stops at the top of the UI tree.
func select_parent() -> void:
	if is_instance_valid(selected) and selected.get_parent() is Control:
		select(selected.get_parent() as Control)

# --- Text ----------------------------------------------------------------------------------------

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
	if not is_instance_valid(selected) or not is_text_node(selected):
		return
	var id: int = selected.get_instance_id()
	if not edits.has(id):
		edits[id] = {"node": selected, "original": text_of(selected), "applied": text_of(selected)}
	selected.set("text",stored(selected,value))
	edits[id].applied = text_of(selected)
	if text_of(selected) == str(edits[id].original):
		edits.erase(id)
	_update_status()

# --- Size ----------------------------------------------------------------------------------------

## Sets one axis (0 width, 1 height) of the selected section's minimum size. Containers grow to fit
## their children, so a value smaller than the contents has no visible effect.
func apply_size(axis: int, value: float) -> void:
	if not is_instance_valid(selected):
		return
	var id: int = selected.get_instance_id()
	if not resizes.has(id):
		resizes[id] = {"node": selected, "original": selected.custom_minimum_size}
	var minimum: Vector2 = selected.custom_minimum_size
	minimum[axis] = value
	selected.custom_minimum_size = minimum
	if selected.custom_minimum_size == resizes[id].original:
		resizes.erase(id)
	_update_status()
	_show_size.call_deferred()

func reset_size_selected() -> void:
	if not is_instance_valid(selected):
		return
	var id: int = selected.get_instance_id()
	if resizes.has(id):
		selected.custom_minimum_size = resizes[id].original
		resizes.erase(id)
	select(selected)

func _show_size() -> void:
	if size_label != null and is_instance_valid(selected):
		size_label.text = "Size now %d x %d (minimum %d x %d)" % [roundi(selected.size.x),roundi(selected.size.y),roundi(selected.custom_minimum_size.x),roundi(selected.custom_minimum_size.y)]

# --- Delete --------------------------------------------------------------------------------------

## What a section contains, so a pasted report says which menu or pane was meant.
static func texts_inside(node: Node, out: Array[String] = []) -> Array[String]:
	if is_text_node(node) and not str(node.get("text")).is_empty() and out.size() < PREVIEW_TEXTS:
		out.append(str(node.get("text")).replace("\n"," / ").left(60))
	for child: Node in node.get_children():
		texts_inside(child,out)
	return out

static func preview(node: Node) -> String:
	var quoted: PackedStringArray = []
	for text: String in texts_inside(node):
		quoted.append("\"%s\"" % text)
	return ", ".join(quoted) if not quoted.is_empty() else "no text"

## Hides the selected section. Undo (or Revert all) brings it back.
func delete_selected() -> void:
	if not is_instance_valid(selected):
		return
	deletions.append({"node": selected, "texts": preview(selected)})
	selected.visible = false
	select(null)
	refresh_targets()

func undo_delete() -> void:
	while not deletions.is_empty():
		var entry: Dictionary = deletions.pop_back()
		if is_instance_valid(entry.node):
			entry.node.visible = true
			break
	refresh_targets()
	_update_status()

# --- Revert --------------------------------------------------------------------------------------

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
	for id: int in resizes.keys():
		var entry: Dictionary = resizes[id]
		if is_instance_valid(entry.node):
			entry.node.custom_minimum_size = entry.original
	resizes.clear()
	for entry: Dictionary in deletions:
		if is_instance_valid(entry.node):
			entry.node.visible = true
	deletions.clear()
	refresh_targets()
	select(selected if is_instance_valid(selected) else null)
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

func edit_count() -> int:
	return edits.size() + resizes.size() + deletions.size()

func report() -> String:
	prune_stale()
	var lines: PackedStringArray = ["UI EDITS: %d text, %d size, %d deleted" % [edits.size(),resizes.size(),deletions.size()],context_line(),""]
	if not edits.is_empty():
		lines.append("TEXT EDITS (%d)" % edits.size())
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
	if not resizes.is_empty():
		lines.append("SIZE EDITS (%d)" % resizes.size())
		var number: int = 1
		for id: int in resizes.keys():
			var entry: Dictionary = resizes[id]
			var node: Control = entry.node
			if not is_instance_valid(node):
				continue
			var before: Vector2 = entry.original
			lines.append("#%d  %s  %s" % [number,node.get_class(),describe_path(node)])
			lines.append("Contains: " + preview(node))
			lines.append("custom_minimum_size: (%d, %d) -> (%d, %d)   actual size now (%d, %d)" % [roundi(before.x),roundi(before.y),roundi(node.custom_minimum_size.x),roundi(node.custom_minimum_size.y),roundi(node.size.x),roundi(node.size.y)])
			lines.append("")
			number += 1
	if not deletions.is_empty():
		lines.append("DELETIONS (%d)" % deletions.size())
		var number: int = 1
		for entry: Dictionary in deletions:
			var node: Control = entry.node
			if not is_instance_valid(node):
				continue
			lines.append("#%d  %s  %s" % [number,node.get_class(),describe_path(node)])
			lines.append("Contains: " + str(entry.texts))
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
		status_label.text = "Copied %d edit%s to the clipboard. Paste them into the chat." % [edit_count(),"" if edit_count() == 1 else "s"]

func _update_status() -> void:
	if copy_button != null:
		copy_button.text = "Copy changes (%d)" % edit_count()
		copy_button.disabled = edit_count() == 0
	if undo_button != null:
		undo_button.disabled = deletions.is_empty()

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
	window.title = "UI edit (F3 or Esc to close)"
	window.size = Vector2i(580,560)
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
	heading.text = "New text (gold marks: **like this**)"
	column.add_child(heading)
	edit_box = TextEdit.new()
	edit_box.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	edit_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	edit_box.custom_minimum_size = Vector2(0,120)
	edit_box.text_changed.connect(func() -> void: apply_edit(edit_box.text))
	column.add_child(edit_box)
	column.add_child(HSeparator.new())
	var section: Label = Label.new()
	section.text = "Section: select the parent of the text you clicked, then size it or delete it"
	section.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(section)
	var size_row: HBoxContainer = HBoxContainer.new()
	column.add_child(size_row)
	width_spin = _spin(size_row,"Width",0)
	height_spin = _spin(size_row,"Height",1)
	var reset_size: Button = Button.new()
	reset_size.text = "Reset size"
	reset_size.pressed.connect(reset_size_selected)
	size_row.add_child(reset_size)
	size_label = _label(column)
	var section_row: HBoxContainer = HBoxContainer.new()
	column.add_child(section_row)
	var parent_button: Button = Button.new()
	parent_button.text = "Select parent"
	parent_button.pressed.connect(select_parent)
	section_row.add_child(parent_button)
	var delete_button: Button = Button.new()
	delete_button.text = "Delete section"
	delete_button.pressed.connect(delete_selected)
	section_row.add_child(delete_button)
	undo_button = Button.new()
	undo_button.text = "Undo delete"
	undo_button.pressed.connect(undo_delete)
	section_row.add_child(undo_button)
	column.add_child(HSeparator.new())
	var row: HBoxContainer = HBoxContainer.new()
	column.add_child(row)
	var revert: Button = Button.new()
	revert.text = "Revert text"
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

func _spin(parent: Node, caption: String, axis: int) -> SpinBox:
	var label: Label = Label.new()
	label.text = caption
	parent.add_child(label)
	var spin: SpinBox = SpinBox.new()
	spin.min_value = 0.0
	spin.max_value = MAX_SIZE
	spin.step = 1.0
	spin.custom_minimum_size = Vector2(110,0)
	spin.value_changed.connect(func(value: float) -> void: apply_size(axis,value))
	parent.add_child(spin)
	return spin

func _picker_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		select(target_at(picker.get_local_mouse_position()))
		picker.accept_event()

func _draw_picker() -> void:
	for target: Control in targets:
		if not is_instance_valid(target):
			continue
		var rect: Rect2 = screen_rect(target)
		var edited: bool = edits.has(target.get_instance_id()) or resizes.has(target.get_instance_id())
		picker.draw_rect(rect,GOLD if edited else Color(TEAL,0.55),false,1.0)
	if is_instance_valid(hovered):
		picker.draw_rect(screen_rect(hovered),Color(1.0,1.0,1.0,0.18),true)
	if is_instance_valid(selected):
		picker.draw_rect(screen_rect(selected).grow(1.0),GOLD,false,2.0)
