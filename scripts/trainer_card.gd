class_name TrainerCard
extends Control
## Screeches McCrumbs' pop-up: one frame holding the speech on the left and his portrait on the right with
## his name underneath, plus one button. BeachGame freezes the world while it is open.
## open() takes {mood, lay, how, button, counter}; the "how" paragraph is gold and **x** inside text is gold too.

signal dismissed

const ATLAS: Texture2D = preload("res://assets/sprites/trainer-screeches-portraits-v1.png")
const SPEECH: Font = preload("res://assets/fonts/gull_speech.fnt")
const CELL: int = 256
const PORTRAIT: int = 72
const SPEECH_SIZE: int = 10
const FRAME_WIDTH: float = 306.0
const FRAME_MARGIN: float = 8.0
const GAP: float = 6.0
const TEXT_WIDTH: float = FRAME_WIDTH - FRAME_MARGIN * 2.0 - PORTRAIT - GAP
const MOODS: Dictionary = {"neutral":0,"talking":1,"amused":2,"proud":3,"wince":4}
const TALK_STEP: float = 0.14
static var portraits: Array[ImageTexture] = []

var frame: PanelContainer
var button: Button
var portrait: TextureRect
var lay_label: RichTextLabel
var how_label: RichTextLabel
var counter_label: Label
var name_label: Label
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
	frame = BeachUI.panel(center,Color(0.094,0.23,0.30,0.97))
	frame.custom_minimum_size = Vector2(FRAME_WIDTH,0)
	frame.mouse_filter = MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = frame.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.content_margin_left = FRAME_MARGIN
	style.content_margin_right = FRAME_MARGIN
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	frame.add_theme_stylebox_override("panel",style)
	var body: HBoxContainer = HBoxContainer.new()
	body.add_theme_constant_override("separation",int(GAP))
	body.mouse_filter = MOUSE_FILTER_IGNORE
	frame.add_child(body)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation",4)
	column.custom_minimum_size = Vector2(TEXT_WIDTH,0)
	column.mouse_filter = MOUSE_FILTER_IGNORE
	body.add_child(column)
	counter_label = _speech_label(column,"",Color("80bcb8"))
	counter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lay_label = _paragraph(column,BeachUI.CREAM)
	how_label = _paragraph(column,BeachUI.GOLD)
	var footer: HBoxContainer = HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.mouse_filter = MOUSE_FILTER_IGNORE
	column.add_child(footer)
	button = BeachUI.button(footer,"GOT IT",dismiss)
	# Head on the right, his name centred underneath it.
	var face: VBoxContainer = VBoxContainer.new()
	face.add_theme_constant_override("separation",2)
	face.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	face.mouse_filter = MOUSE_FILTER_IGNORE
	body.add_child(face)
	portrait = TextureRect.new()
	portrait.custom_minimum_size = Vector2(PORTRAIT,PORTRAIT)
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.mouse_filter = MOUSE_FILTER_IGNORE
	face.add_child(portrait)
	name_label = _speech_label(face,str(Config.trainer.name),BeachUI.GOLD)
	name_label.custom_minimum_size = Vector2(PORTRAIT,0)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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
	label.custom_minimum_size = Vector2(TEXT_WIDTH,0)
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
	counter_label.visible = not counter_label.text.is_empty()
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
