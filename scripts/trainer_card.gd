class_name TrainerCard
extends Control
## Screeches McCrumbs' pop-up: portrait, speech bubble, one button. BeachGame freezes the world while it is open.
## open() takes {mood, lay, how, button, counter}; the "how" paragraph is gold and **x** inside text is gold too.

signal dismissed

const ATLAS: Texture2D = preload("res://assets/sprites/trainer-screeches-portraits-v1.png")
const SPEECH: Font = preload("res://assets/fonts/gull_speech.fnt")
const CELL: int = 256
const PORTRAIT: int = 72
const SPEECH_SIZE: int = 10
const BUBBLE_WIDTH: float = 226.0
const MOODS: Dictionary = {"neutral":0,"talking":1,"amused":2,"proud":3,"wince":4}
const TALK_STEP: float = 0.14
static var portraits: Array[ImageTexture] = []

var button: Button
var portrait: TextureRect
var lay_label: RichTextLabel
var how_label: RichTextLabel
var counter_label: Label
var mood_cell: int = 0
var talk_left: float = 0.0
var talk_clock: float = 0.0

## The five 256 px cells scaled once to the on-screen size.
static func portrait_textures() -> Array[ImageTexture]:
	if portraits.is_empty():
		var atlas: Image = ATLAS.get_image()
		for index: int in range(5):
			var cell: Image = atlas.get_region(Rect2i(index*CELL,0,CELL,CELL))
			cell.resize(PORTRAIT,PORTRAIT,Image.INTERPOLATE_LANCZOS)
			portraits.append(ImageTexture.create_from_image(cell))
	return portraits

func _init() -> void:
	BeachUI.full(self)
	visible = false
	mouse_filter = MOUSE_FILTER_STOP
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.0,0.0,0.0,0.55)
	dim.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(dim)
	BeachUI.full(dim)
	var center: CenterContainer = CenterContainer.new()
	center.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(center)
	BeachUI.full(center)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation",6)
	row.mouse_filter = MOUSE_FILTER_IGNORE
	center.add_child(row)
	var bubble: PanelContainer = BeachUI.panel(row,Color(0.094,0.23,0.30,0.97))
	bubble.custom_minimum_size = Vector2(BUBBLE_WIDTH,0)
	bubble.mouse_filter = MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = bubble.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	bubble.add_theme_stylebox_override("panel",style)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation",4)
	column.mouse_filter = MOUSE_FILTER_IGNORE
	bubble.add_child(column)
	var header: HBoxContainer = HBoxContainer.new()
	header.mouse_filter = MOUSE_FILTER_IGNORE
	column.add_child(header)
	var name_label: Label = _speech_label(header,str(Config.trainer.name),BeachUI.GOLD)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	counter_label = _speech_label(header,"",Color("80bcb8"))
	counter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lay_label = _paragraph(column,BeachUI.CREAM)
	how_label = _paragraph(column,BeachUI.GOLD)
	var footer: HBoxContainer = HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.mouse_filter = MOUSE_FILTER_IGNORE
	column.add_child(footer)
	button = BeachUI.button(footer,"GOT IT",dismiss)
	portrait = TextureRect.new()
	portrait.custom_minimum_size = Vector2(PORTRAIT,PORTRAIT)
	portrait.size_flags_vertical = Control.SIZE_SHRINK_END
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.mouse_filter = MOUSE_FILTER_IGNORE
	row.add_child(portrait)
	set_process(false)

func _speech_label(parent: Node, value: String, color: Color) -> Label:
	var label: Label = BeachUI.label(parent,value,SPEECH_SIZE,color)
	label.add_theme_font_override("font",SPEECH)
	label.add_theme_font_size_override("font_size",SPEECH_SIZE)
	return label

func _paragraph(parent: Node, color: Color) -> RichTextLabel:
	var label: RichTextLabel = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = MOUSE_FILTER_IGNORE
	label.custom_minimum_size = Vector2(BUBBLE_WIDTH-16.0,0)
	label.add_theme_font_override("normal_font",SPEECH)
	label.add_theme_font_size_override("normal_font_size",SPEECH_SIZE)
	label.add_theme_color_override("default_color",color)
	parent.add_child(label)
	return label

static func markup(text: String) -> String:
	var parts: PackedStringArray = text.split("**")
	var out: String = ""
	for index: int in parts.size():
		out += ("[color=#ffc65c]%s[/color]" % parts[index]) if index%2 == 1 else parts[index]
	return out

func open(entry: Dictionary) -> void:
	mood_cell = int(MOODS.get(str(entry.get("mood","neutral")),0))
	lay_label.text = markup(str(entry.get("lay","")))
	how_label.text = markup(str(entry.get("how","")))
	how_label.visible = not str(entry.get("how","")).is_empty()
	# Where each paragraph's copy lives, for the debug text editor (F3).
	lay_label.set_meta("text_source",str(entry.get("lay_source","")))
	lay_label.set_meta("text_template",str(entry.get("lay_template","")))
	how_label.set_meta("text_source",str(entry.get("how_source","")))
	how_label.set_meta("text_template",str(entry.get("how_template","")))
	counter_label.text = str(entry.get("counter",""))
	button.text = str(entry.get("button","GOT IT")).to_upper()
	talk_left = clampf((str(entry.get("lay","")).length()+str(entry.get("how","")).length())*0.02,0.8,2.6)
	talk_clock = 0.0
	_show_cell(int(MOODS.talking))
	visible = true
	set_process(true)
	button.grab_focus()

func is_open() -> bool:
	return visible

func dismiss() -> void:
	if not visible:
		return
	visible = false
	set_process(false)
	dismissed.emit()

func _show_cell(index: int) -> void:
	portrait.texture = portrait_textures()[index]

## The bill flaps between its closed and open cells while he talks, then settles on the mood.
func _process(delta: float) -> void:
	if talk_left <= 0.0:
		_show_cell(mood_cell)
		return
	talk_left -= delta
	talk_clock += delta
	_show_cell(int(MOODS.talking) if int(talk_clock/TALK_STEP)%2 == 0 else int(MOODS.neutral))
