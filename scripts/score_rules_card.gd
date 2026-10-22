class_name ScoreRulesCard
extends Control
## Modal "SCORE RULES" reference: every multiplier and penalty in one card.
## Opened from the pause menu, the result sign's bonus line and the end of
## Training Day. Values come from data/tuning.json so the card never drifts.

signal closed

const TITLE_FONT: Font = preload("res://assets/arcade_score_hot.fnt")
const NAME_W: float = 52.0
const RULE_W: float = 150.0
const VALUE_W: float = 66.0

var close_button: Button

static func open(parent: Control, button_text: String = "GOT IT") -> ScoreRulesCard:
	var card := ScoreRulesCard.new()
	parent.add_child(card)
	card.build(button_text)
	return card

func build(button_text: String) -> void:
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
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	style.border_color = BeachUI.GOLD
	style.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 1)
	panel.add_child(column)

	var title: Label = BeachUI.label(column, "SCORE RULES", BeachUI.FONT_DISPLAY, Color.WHITE)
	title.add_theme_font_override("font", TITLE_FONT)
	title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.65))
	title.add_theme_constant_override("shadow_offset_x", 1)
	title.add_theme_constant_override("shadow_offset_y", 1)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var t: Dictionary = Config.tuning.score
	var tiers: Array = t.tiers
	_section(column, "BONUSES", BeachUI.GOLD)
	_row(column, "COMBO", "EAT AGAIN WITHIN %d SEC" % int(t.combo_window), "X%s-X%s" % [_num(tiers[1]), _num(tiers[tiers.size() - 1])])
	_row(column, "RISKY", "STEAL WHILE THEY WATCH", _pct(t.risky))
	_row(column, "UPWIND", "DIVE INTO THE WIND", _pct(t.upwind))
	_row(column, "MUGGED", "ROB A RIVAL GULL", _pct(t.mugged))
	_row(column, "COUNTER", "PECK IT OFF THE STALL", _pct(t.handover))
	_row(column, "CLEAN RUN", "NO STUNS ALL LEVEL", "%s TOTAL" % _pct(t.clean))
	_section(column, "PENALTIES", Color("ef725c"))
	_row(column, "SWATTED", "DROP SNACK. COMBO OVER", "-5", Color("ef725c"))
	_row(column, "CRASH", "DIVE INTO THE SAND", "HALF POINTS", Color("ef725c"))

	var actions := CenterContainer.new()
	column.add_child(actions)
	close_button = BeachUI.button(actions, button_text, close, 96)
	# Keep keyboard and pad focus inside the card while it is open.
	var own: NodePath = close_button.get_path()
	for side: String in ["focus_neighbor_left", "focus_neighbor_right", "focus_neighbor_top", "focus_neighbor_bottom", "focus_next", "focus_previous"]:
		close_button.set(side, own)
	close_button.grab_focus.call_deferred()

func close() -> void:
	closed.emit()
	queue_free()

func _section(parent: Control, text: String, color: Color) -> void:
	var label: Label = BeachUI.label(parent, text, BeachUI.FONT_NATIVE, color)
	label.custom_minimum_size.y = 9

func _row(parent: Control, name_text: String, rule: String, value: String, value_color: Color = BeachUI.GOLD) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(row)
	BeachUI.label(row, name_text, BeachUI.FONT_NATIVE, BeachUI.CREAM).custom_minimum_size = Vector2(NAME_W, 9)
	BeachUI.label(row, rule, BeachUI.FONT_NATIVE, Color("a9d7d2")).custom_minimum_size = Vector2(RULE_W, 9)
	var amount: Label = BeachUI.label(row, value, BeachUI.FONT_NATIVE, value_color)
	amount.custom_minimum_size = Vector2(VALUE_W, 9)
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func _pct(value: Variant) -> String:
	return "+%d%%" % roundi(float(value) * 100.0)

func _num(value: Variant) -> String:
	var number := float(value)
	return str(int(number)) if is_equal_approx(number, roundf(number)) else "%.1f" % number
