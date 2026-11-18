class_name ControlsCard
extends Control
## Modal "CONTROLS" reference opened from the pause menu: this device's keys (data/trainer.json "keys") and what the mouse does now.

signal closed

var close_button: Button

static func open(parent: Control, input: GullInput, button_text: String = "BACK") -> ControlsCard:
	var card := ControlsCard.new()
	parent.add_child(card)
	card.build(input, button_text)
	return card

## What the mouse does right now, or "" for pad and touch where it does not apply.
static func mouse_line(input: GullInput) -> String:
	if TrainerScript.device(input) != "keyboard":
		return ""
	return str(Config.trainer.controls_card["mouse_aim" if GameState.mouse_role() == "dive_aim" else "mouse_steer"])

func build(input: GullInput, button_text: String) -> void:
	BeachUI.full(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 20
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.08, 0.11, 0.6)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	BeachUI.full(dim)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	BeachUI.full(center)
	var panel: PanelContainer = BeachUI.panel(center, Color(0.094, 0.23, 0.30, 0.98))
	var style := panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.border_color = BeachUI.GOLD
	style.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 1)
	panel.add_child(column)
	var card: Dictionary = Config.trainer.controls_card
	var title: Label = BeachUI.label(column, str(card.title), BeachUI.FONT_NATIVE, BeachUI.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for row: Array in card.rows:
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 4)
		column.add_child(line)
		BeachUI.label(line, str(row[0]), BeachUI.FONT_NATIVE, BeachUI.CREAM).custom_minimum_size = Vector2(44, 9)
		BeachUI.label(line, TrainerScript.fill(str(row[1]), input).to_upper(), BeachUI.FONT_NATIVE, Color("a9d7d2"))
	var mouse: String = mouse_line(input)
	if not mouse.is_empty():
		BeachUI.label(column, mouse, BeachUI.FONT_NATIVE, BeachUI.GOLD).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var actions := CenterContainer.new()
	column.add_child(actions)
	close_button = BeachUI.button(actions, button_text, close, 60)
	var own: NodePath = close_button.get_path()
	for side: String in ["focus_neighbor_left", "focus_neighbor_right", "focus_neighbor_top", "focus_neighbor_bottom", "focus_next", "focus_previous"]:
		close_button.set(side, own)
	close_button.grab_focus.call_deferred()

func close() -> void:
	closed.emit()
	queue_free()
