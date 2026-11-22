extends CanvasLayer
## First-run controls chooser: two big clickable panels (MOUSE ONLY / KEYBOARD + MOUSE) over the beach.
## Copy lives in data/trainer.json "controls_chooser". Emits chosen("steer" | "dive_aim"); Main saves it.
## Each panel is a keybinding diagram: a pixel mouse (+ arrow keys) with 1 px gold leader lines out to labels.
## The diagram icons are plain pixel UI glyphs drawn with rects on whole pixels (not characters).
signal chosen(role: String)

const SMALL_FONT: Font = preload("res://assets/fonts/gull_hud.fnt")
const PANEL_SIZE: Vector2 = Vector2(256, 162)
const OPTION_SIZE: Vector2 = Vector2(114, 126)

## Diagram control. Records every label rect, line rect and icon rect (labels, lines, solids)
## so tests can check nothing collides.
class Diagram extends Control:
	const SIZE: Vector2 = Vector2(106, 90)
	const ARROWS: Dictionary = {
		"up": ["..#..", ".###.", "#####"],
		"left": ["..#", ".##", "###", ".##", "..#"],
		"down": ["#####", ".###.", "..#.."],
		"right": ["#..", "##.", "###", "##.", "#.."],
	}
	var kind: String = "mouse"
	var copy: Dictionary = {}
	var labels: Array[Dictionary] = [] # {text, rect}
	var lines: Array[Rect2] = []
	var solids: Array[Rect2] = []
	var _mice: Array[Dictionary] = []
	var _keys: Array[Vector2] = []

	func _init(icon_kind: String, text: Dictionary) -> void:
		kind = icon_kind
		copy = text
		custom_minimum_size = SIZE
		size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if kind == "mouse":
			_layout_mouse()
		else:
			_layout_keys()

	## align: 0 = x is the left edge, 1 = centred on x, 2 = x is the right edge.
	func _label(text: String, x: int, top: int, align: int) -> void:
		var w: int = int(ceil(SMALL_FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 6).x))
		var left: int = x - (w / 2 if align == 1 else (w if align == 2 else 0))
		labels.append({"text": text, "rect": Rect2(left, top, w, 6)})

	func _h(x1: int, x2: int, y: int) -> void:
		lines.append(Rect2(mini(x1, x2), y, absi(x2 - x1) + 1, 1))

	func _v(x: int, y1: int, y2: int) -> void:
		lines.append(Rect2(x, mini(y1, y2), 1, absi(y2 - y1) + 1))

	## Adds a mouse and returns its anchor points.
	func _mouse(x0: int, y0: int, w: int, h: int, bh: int, wheel: int, hi_left: bool) -> Dictionary:
		var wx: int = x0 + (w - wheel) / 2
		var rx: int = wx + wheel + 1
		_mice.append({"x0": x0, "y0": y0, "w": w, "h": h, "bh": bh, "wx": wx, "wheel": wheel, "rx": rx, "hi_left": hi_left})
		solids.append(Rect2(x0, y0, w, h))
		return {"btn_y": y0 + bh / 2, "wheel_x": wx + wheel / 2, "right": x0 + w, "bottom": y0 + h}

	func _layout_mouse() -> void:
		var m: Dictionary = _mouse(38, 20, 30, 44, 18, 4, true)
		var ly: int = int(m.btn_y)
		_label(str(copy.peck), 53, 9, 1)
		_v(int(m.wheel_x), 16, 19)
		_label(str(copy.flap), 30, ly - 3, 2)
		_h(32, 37, ly)
		_label(str(copy.dive), 76, ly - 3, 0)
		_h(int(m.right), 74, ly)
		_v(int(m.wheel_x), int(m.bottom), int(m.bottom) + 3)
		_label(str(copy.body), 53, int(m.bottom) + 6, 1)

	func _layout_keys() -> void:
		for entry: Array in [[48, 12], [38, 22], [48, 22], [58, 22]]: # up, left, down, right
			_keys.append(Vector2(int(entry[0]), int(entry[1])))
			solids.append(Rect2(int(entry[0]), int(entry[1]), 9, 9))
		_label(str(copy.flap), 52, 0, 1)
		_v(52, 7, 11)
		_label(str(copy.steer), 32, 23, 2)
		_h(34, 37, 26)
		_label(str(copy.steer), 73, 23, 0)
		_h(67, 71, 26)
		_v(52, 31, 33)
		_label(str(copy.drop), 52, 36, 1)
		var m: Dictionary = _mouse(43, 51, 20, 28, 12, 4, false)
		var ly: int = int(m.btn_y)
		_label(str(copy.dive), 71, ly - 3, 0)
		_h(int(m.right), 69, ly)
		_label(str(copy.peck), 40, 44, 2)
		_h(42, int(m.wheel_x), 47)
		_v(int(m.wheel_x), 47, 50)
		_v(int(m.wheel_x), int(m.bottom), int(m.bottom) + 2)
		_label(str(copy.body), 53, int(m.bottom) + 5, 1)

	func _draw() -> void:
		for m: Dictionary in _mice:
			var x0: int = m.x0
			var y0: int = m.y0
			var right_w: int = x0 + int(m.w) - 1 - int(m.rx)
			draw_rect(Rect2(x0, y0, m.w, m.h), BeachUI.INK)
			draw_rect(Rect2(x0 + 1, y0 + 1, int(m.w) - 2, int(m.h) - 2), BeachUI.CREAM)
			draw_rect(Rect2(x0 + 1, y0 + m.bh, int(m.w) - 2, 1), BeachUI.INK)
			draw_rect(Rect2(int(m.wx) - 1, y0 + 1, 1, int(m.bh) - 1), BeachUI.INK)
			draw_rect(Rect2(int(m.wx) + int(m.wheel), y0 + 1, 1, int(m.bh) - 1), BeachUI.INK)
			draw_rect(Rect2(m.wx, y0 + 2, m.wheel, int(m.bh) - 5), BeachUI.GOLD) # wheel
			draw_rect(Rect2(m.rx, y0 + 1, right_w, int(m.bh) - 1), BeachUI.GOLD) # right button
			if m.hi_left:
				draw_rect(Rect2(x0 + 1, y0 + 1, int(m.wx) - x0 - 2, int(m.bh) - 1), BeachUI.GOLD)
		var names: Array[String] = ["up", "left", "down", "right"]
		for i: int in _keys.size():
			draw_rect(Rect2(_keys[i], Vector2(9, 9)), BeachUI.INK)
			draw_rect(Rect2(_keys[i] + Vector2(1, 1), Vector2(7, 7)), BeachUI.GOLD)
			var rows: Array = ARROWS[names[i]]
			var glyph: Vector2 = _keys[i] + Vector2((9 - str(rows[0]).length()) / 2, (9 - rows.size()) / 2)
			for y: int in rows.size():
				for x: int in str(rows[y]).length():
					if str(rows[y])[x] == "#":
						draw_rect(Rect2(glyph + Vector2(x, y), Vector2(1, 1)), BeachUI.INK)
		for line: Rect2 in lines:
			draw_rect(line, BeachUI.GOLD)
		var ascent: float = SMALL_FONT.get_ascent(6)
		for entry: Dictionary in labels:
			var r: Rect2 = entry.rect
			draw_string(SMALL_FONT, Vector2(r.position.x, r.position.y + ascent), str(entry.text), HORIZONTAL_ALIGNMENT_LEFT, -1, 6, BeachUI.CREAM)

func _ready() -> void:
	layer = 60
	var copy: Dictionary = Config.trainer.controls_chooser
	var dim: ColorRect = ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0.03, 0.12, 0.16, 0.4)
	dim.theme = BeachUI.theme()
	add_child(dim)
	BeachUI.full(dim)
	var center: CenterContainer = CenterContainer.new()
	dim.add_child(center)
	BeachUI.full(center)
	var panel: PanelContainer = BeachUI.wood_panel(center)
	panel.name = "Panel"
	var box: StyleBoxTexture = panel.get_theme_stylebox("panel").duplicate() as StyleBoxTexture
	box.content_margin_left = 11
	box.content_margin_right = 11
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", box)
	panel.custom_minimum_size = PANEL_SIZE
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	panel.add_child(column)
	BeachUI.label(column, str(copy.title), BeachUI.FONT_NATIVE, BeachUI.GOLD).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var row: HBoxContainer = HBoxContainer.new()
	row.name = "Options"
	row.add_theme_constant_override("separation", 6)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(row)
	var mouse: Dictionary = copy.mouse
	var keys: Dictionary = copy.keys
	var mouse_button: Button = _option(row, "MouseOnlyButton", str(mouse.name), "mouse", mouse, "steer")
	_option(row, "KeyboardMouseButton", str(keys.name), "keys", keys, "dive_aim")
	mouse_button.grab_focus()

func _option(parent: Control, node_name: String, heading: String, kind: String, text: Dictionary, role: String) -> Button:
	var button: Button = Button.new()
	button.name = node_name
	button.custom_minimum_size = OPTION_SIZE
	button.pressed.connect(func() -> void:
		Audio.play("gull_call", 1.0, -8.0)
		chosen.emit(role))
	parent.add_child(button)
	var margin: MarginContainer = BeachUI.margin(button, 4)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var stack: VBoxContainer = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 2)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(stack)
	BeachUI.label(stack, heading, BeachUI.FONT_NATIVE, BeachUI.GOLD).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var note_label: Label = _small(stack, str(text.note), Color("a9d7d2"))
	note_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note_label.custom_minimum_size.x = OPTION_SIZE.x - 8
	stack.add_child(Diagram.new(kind, text))
	var filler: Control = Control.new()
	filler.size_flags_vertical = Control.SIZE_EXPAND_FILL
	filler.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(filler)
	return button

func _small(parent: Control, text: String, color: Color) -> Label:
	var node: Label = BeachUI.label(parent, text, 6, color)
	node.add_theme_font_override("font", SMALL_FONT)
	node.add_theme_font_size_override("font_size", 6)
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return node
