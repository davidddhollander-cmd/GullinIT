class_name BeachUI
extends RefCounted
const INK: Color = Color("183b4e")
const CREAM: Color = Color("fff4da")
const GOLD: Color = Color("ffc65c")
const CORAL: Color = Color("ef725c")
const FONT_NATIVE: int = 8
const FONT_DISPLAY: int = 16
const BACK_WIDTH: float = 59.0
const BACK_HEIGHT: float = 13.0
# The wood frame PNG holds 2 pixels per game pixel. With the canvas_items stretch mode the extra
# detail reaches the screen, so the frame is drawn finer than the 320x180 grid.
const WOOD_FRAME_HIRES: Texture2D = preload("res://assets/ui/wood-frame.png")
const WOOD_FRAME_SCALE: int = 2
const PIXEL_FONT: Font = preload("res://assets/fonts/gull_pixel.fnt")
const FEATHER_ICON: Texture2D = preload("res://assets/sprites/feather-icon-v1.png")
const STAR_ICON: Texture2D = preload("res://assets/sprites/score-star-retro-16.png")
static var _wood_frame: ImageTexture

static func wood_frame() -> ImageTexture:
	if _wood_frame == null:
		_wood_frame = ImageTexture.create_from_image(WOOD_FRAME_HIRES.get_image())
		_wood_frame.set_size_override(WOOD_FRAME_HIRES.get_size() / WOOD_FRAME_SCALE)
	return _wood_frame

static func theme() -> Theme:
	var result: Theme = Theme.new()
	result.default_font = preload("res://assets/fonts/gull_pixel.fnt")
	result.default_font_size = FONT_NATIVE
	result.set_color("font_color","Label",CREAM)
	for state: String in ["normal","hover","pressed","focus","disabled"]:
		var box: StyleBoxFlat = StyleBoxFlat.new()
		box.bg_color = Color("245369") if state == "normal" else Color("397a85")
		if state == "disabled":
			box.bg_color = Color("304956")
		box.border_color = GOLD if state == "focus" else Color("80bcb8")
		box.set_border_width_all(1 if state == "focus" else 0)
		box.set_corner_radius_all(3)
		box.anti_aliasing = false
		box.content_margin_left = 8
		box.content_margin_right = 8
		box.content_margin_top = 6
		box.content_margin_bottom = 6
		result.set_stylebox(state,"Button",box)
	result.set_color("font_color","Button",CREAM)
	result.set_color("font_hover_color","Button",CORAL)
	result.set_color("font_pressed_color","Button",CORAL)
	result.set_color("font_hover_pressed_color","Button",CORAL)
	result.set_color("font_focus_color","Button",GOLD)
	result.set_color("font_disabled_color","Button",Color("6b858b"))
	result.set_color("font_outline_color","Button",INK)
	result.set_constant("outline_size","Button",1)
	result.set_constant("separation","VBoxContainer",5)
	result.set_constant("separation","HBoxContainer",6)
	return result

static func label(parent: Node, value: String, size: int = FONT_NATIVE, color: Color = CREAM) -> Label:
	var node: Label = Label.new()
	node.text = value
	# GullPixel is an 8 px bitmap face. Non-native sizes resample its one-pixel
	# strokes, so labels such as BEST lose parts of letters at 7 px. Keep menu
	# type on the native grid (8 px body, 16 px display).
	var crisp_size: int = FONT_DISPLAY if size > FONT_NATIVE else FONT_NATIVE
	node.add_theme_font_size_override("font_size",crisp_size)
	node.add_theme_color_override("font_color",color)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

## A smaller button for BACK and similar exits: 59 x 13, centred in its row or column. The theme's 6 px
## top and bottom padding would hold a button at 20 px, so its styles are copied with slimmer padding.
## A Feather icon just left of an 8 px label's text, whatever its alignment.
## Call it after the text is final; the icon does not follow later changes.
static func feather_icon(label: Label) -> TextureRect:
	var icon: TextureRect = TextureRect.new()
	icon.texture = FEATHER_ICON
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var text_width: float = PIXEL_FONT.get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,FONT_NATIVE).x
	var start: float = 0.0
	if label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER:
		start = (label.size.x - text_width) * 0.5
	elif label.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT:
		start = label.size.x - text_width
	icon.position = Vector2(floorf(start) - 12.0,floorf((label.size.y - 10.0) * 0.5))
	label.add_child(icon)
	return icon

static func back_button(parent: Node, value: String, action: Callable, width: float = BACK_WIDTH) -> Button:
	var node: Button = button(parent,value,action,width)
	node.custom_minimum_size.y = BACK_HEIGHT
	node.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	node.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var base: Theme = theme()
	for state: String in ["normal","hover","pressed","focus","disabled"]:
		var box: StyleBoxFlat = base.get_stylebox(state,"Button").duplicate() as StyleBoxFlat
		box.content_margin_top = (BACK_HEIGHT - float(FONT_NATIVE)) * 0.5
		box.content_margin_bottom = (BACK_HEIGHT - float(FONT_NATIVE)) * 0.5
		node.add_theme_stylebox_override(state,box)
	return node

static func button(parent: Node, value: String, action: Callable, width: float = 0) -> Button:
	var node: Button = Button.new()
	node.text = value
	node.custom_minimum_size = Vector2(width,21)
	node.pressed.connect(func() -> void:
		Audio.play("gull_call", 1.0, -8.0)
		if value.begins_with("<"):
			Audio.play("ui_back", 1.0, -4.0)
		action.call())
	parent.add_child(node)
	return node

static func full(node: Control) -> void:
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

static func margin(parent: Control, amount: int) -> MarginContainer:
	var node: MarginContainer = MarginContainer.new()
	parent.add_child(node)
	full(node)
	for edge: String in ["left","top","right","bottom"]:
		node.add_theme_constant_override("margin_"+edge,amount)
	return node

static func panel(parent: Control, color: Color = INK) -> PanelContainer:
	var node: PanelContainer = PanelContainer.new()
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = color
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	node.add_theme_stylebox_override("panel",box)
	parent.add_child(node)
	return node

## Menu panel: the weathered-wood rope frame around a cream board. The frame art leaves 10-11 px of
## wood on each side; content sits a further 5 px in, the same gap menus leave between buttons.
static func wood_panel(parent: Control) -> PanelContainer:
	var node: PanelContainer = PanelContainer.new()
	var box: StyleBoxTexture = StyleBoxTexture.new()
	box.texture = wood_frame()
	box.texture_margin_left = 13
	box.texture_margin_right = 13
	box.texture_margin_top = 12
	box.texture_margin_bottom = 12
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 15
	box.content_margin_bottom = 16
	node.add_theme_stylebox_override("panel",box)
	parent.add_child(node)
	return node
