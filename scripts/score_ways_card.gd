class_name ScoreWaysCard
extends Control
## End-of-training overview: the four ways to score, safest to best, each with one still of the moment before contact.
## Copy lives in data/trainer.json "score_ways"; bonus values come from data/tuning.json.

signal closed

const TITLE_FONT: Font = preload("res://assets/arcade_score_hot.fnt")
const STILL_DIR: String = "res://assets/sprites/score-ways/"
const STILL_SIZE: Vector2i = Vector2i(74,42)
const COLUMN_GAP: int = 3
const TITLE_H: float = 11.0 ## one line; the GullPixel font has no comma, so the copy avoids them
const TEXT_H: float = 33.0 ## three lines
const SCORE_H: float = 22.0 ## two lines

var close_button: Button
var stills: Array[TextureRect] = []

static func open(parent: Control) -> ScoreWaysCard:
	var card := ScoreWaysCard.new()
	parent.add_child(card)
	card.build()
	return card

func build() -> void:
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
	style.content_margin_left = 3
	style.content_margin_right = 3
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	style.border_color = BeachUI.GOLD
	style.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	panel.add_child(column)

	var title: Label = BeachUI.label(column, "HOW TO SCORE", BeachUI.FONT_DISPLAY, Color.WHITE)
	title.add_theme_font_override("font", TITLE_FONT)
	title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.65))
	title.add_theme_constant_override("shadow_offset_x", 1)
	title.add_theme_constant_override("shadow_offset_y", 1)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", COLUMN_GAP)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(row)
	for way: Dictionary in Config.trainer.score_ways:
		_add_way(row, way)

	var actions := CenterContainer.new()
	column.add_child(actions)
	close_button = BeachUI.button(actions, "GOT IT", close, 96)
	# Keep keyboard and pad focus inside the card while it is open.
	var own: NodePath = close_button.get_path()
	for side: String in ["focus_neighbor_left", "focus_neighbor_right", "focus_neighbor_top", "focus_neighbor_bottom", "focus_next", "focus_previous"]:
		close_button.set(side, own)
	close_button.grab_focus.call_deferred()

func close() -> void:
	closed.emit()
	queue_free()

func _add_way(parent: Control, way: Dictionary) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(box)
	_text(box, str(way.title), BeachUI.CREAM, TITLE_H)
	var frame := TextureRect.new()
	frame.custom_minimum_size = STILL_SIZE
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE # stills are 4x (296x168) and scale 1:1 onto screen pixels at 1280x720
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.texture = load(STILL_DIR + str(way.still) + ".png")
	stills.append(frame)
	box.add_child(frame)
	_text(box, str(way.text), Color("a9d7d2"), TEXT_H)
	_text(box, score_text(way), BeachUI.GOLD, SCORE_H)

func _text(parent: Control, text: String, color: Color, height: float) -> void:
	var label: Label = BeachUI.label(parent, text, BeachUI.FONT_NATIVE, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(STILL_SIZE.x, height)

## "{combo}", "{mugged}" and "{handover}" in the copy read the real bonus from tuning.
static func score_text(way: Dictionary) -> String:
	var t: Dictionary = Config.tuning.score
	var tiers: Array = t.tiers
	return str(way.score).format({"combo": str(int(tiers[tiers.size() - 1])), "mugged": roundi(float(t.mugged) * 100.0), "handover": roundi(float(t.handover) * 100.0)})
