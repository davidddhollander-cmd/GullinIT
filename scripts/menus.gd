class_name BeachMenus
extends Control
signal requested(action: String, payload: Variant)
var content: VBoxContainer
var back_action: String = "title"

func _ready() -> void:
	theme = BeachUI.theme()
	BeachUI.full(self)

## The Feather count: icon and number on a small bright tablet in the top-right corner. The number label is named "Feathers".
func _feather_tablet(parent: Control = null) -> void:
	var tablet: PanelContainer = PanelContainer.new()
	tablet.name = "FeatherTablet"
	tablet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = Color("ffe08a")
	box.border_color = Color("a8581c")
	box.set_border_width_all(1)
	box.anti_aliasing = false
	box.set_corner_radius_all(2)
	box.content_margin_left = 3
	box.content_margin_right = 4
	box.content_margin_top = 1
	box.content_margin_bottom = 1
	tablet.add_theme_stylebox_override("panel",box)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation",2)
	tablet.add_child(row)
	var icon: TextureRect = TextureRect.new()
	icon.texture = BeachUI.FEATHER_ICON
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.custom_minimum_size = Vector2(10,10)
	icon.size_flags_vertical = SIZE_SHRINK_CENTER
	row.add_child(icon)
	var count: Label = BeachUI.label(row,str(GameState.feathers()),BeachUI.FONT_NATIVE,BeachUI.INK)
	count.name = "Feathers"
	if parent != null: # in a row: the menu's layout places it
		parent.add_child(tablet)
		return
	add_child(tablet)
	tablet.position = Vector2(298.0 - tablet.get_combined_minimum_size().x,13.0) # right edge fixed

func clear(title: String, subtitle: String = "", card: bool = false, title_size: int = BeachUI.FONT_DISPLAY) -> VBoxContainer:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	var margin: MarginContainer = BeachUI.margin(self,6)
	var panel: PanelContainer = BeachUI.wood_panel(margin)
	_ink_labels.call_deferred(panel)
	if card:
		panel.size_flags_horizontal = SIZE_SHRINK_BEGIN
		panel.size_flags_vertical = SIZE_SHRINK_CENTER
	content = VBoxContainer.new()
	panel.add_child(content)
	BeachUI.label(content,title,title_size,BeachUI.GOLD)
	if not subtitle.is_empty():
		BeachUI.label(content,subtitle,BeachUI.FONT_NATIVE,Color("a9d7d2"))
	return content

# Menu text was picked for dark panels; on the cream board, swap the light colours for dark ones.
# Labels inside buttons keep their colours (buttons stay dark teal).
const ON_CREAM: Dictionary = {
	BeachUI.CREAM: BeachUI.INK,
	BeachUI.GOLD: Color("a8581c"),
	Color("a9d7d2"): Color("397a85"),
	Color("80bcb8"): Color("397a85"),
}

func _ink_labels(node: Node) -> void:
	# A queued board pass must never recolour a later title rebuild.
	if not is_instance_valid(node):
		return
	for child: Node in node.get_children():
		if child is Button or child.name == "ScoresToBeat":
			continue
		if child is Label:
			var color: Color = (child as Label).get_theme_color("font_color")
			if ON_CREAM.has(color):
				(child as Label).add_theme_color_override("font_color",ON_CREAM[color])
		_ink_labels(child)

func choose(action: String, payload: Variant = null) -> void:
	requested.emit(action,payload)

func hint(parent: Control, text: String) -> void:
	var node: Label = BeachUI.label(parent,text,8,Color("80bcb8"))
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.custom_minimum_size.x = 150

const GLINT: Shader = preload("res://assets/shaders/title_glint.gdshader")
const DEV_TAPS: int = 7
var logo_taps: int = 0

# Hidden switch: tapping the logo DEV_TAPS times marks this install as the developer's, so analytics can leave it out.
func _logo_tapped(tagline: Label) -> void:
	logo_taps += 1
	if logo_taps < DEV_TAPS:
		return
	logo_taps = 0
	GameState.options.dev_player = true
	GameState.save_progress()
	Analytics.track("dev_device")
	tagline.text = "DEV DEVICE: NOT COUNTED"

func title() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	# Logo and tagline float centred over the beach; the buttons sit in a small wood box on the left.
	var margin: MarginContainer = BeachUI.margin(self,6)
	var column: VBoxContainer = VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation",4)
	margin.add_child(column)
	var logo: TextureRect = TextureRect.new()
	logo.texture = load("res://assets/sprites/title-logo.png")
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_SCALE
	logo.size = Vector2(112,28)
	logo.position = Vector2(31.5,1.0)
	logo.material = ShaderMaterial.new()
	logo.material.shader = GLINT
	var slot: Control = Control.new()
	slot.custom_minimum_size = Vector2(175,30)
	slot.size_flags_horizontal = SIZE_SHRINK_CENTER
	slot.add_child(logo)
	column.add_child(slot)
	var tween: Tween = logo.create_tween().set_loops()
	tween.tween_property(logo,"position:y",3.0,1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(logo,"position:y",0.0,1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var tagline: Label = BeachUI.label(column,"The No. 1 Seagull Simulator",BeachUI.FONT_NATIVE,BeachUI.CREAM)
	tagline.name = "TitleTagline"
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.size_flags_horizontal = SIZE_SHRINK_CENTER
	# Bitmap glyphs ignore outlines. A snug ink backing gives the same strong
	# contrast over moving clouds and either sky, without changing row height.
	var backing := StyleBoxFlat.new()
	backing.bg_color = BeachUI.INK
	backing.set_content_margin_all(0)
	backing.set_expand_margin_all(2)
	backing.anti_aliasing = false
	tagline.add_theme_stylebox_override("normal",backing)
	logo.gui_input.connect(func(event: InputEvent) -> void:
		if event.is_pressed() and (event is InputEventMouseButton or event is InputEventScreenTouch):
			_logo_tapped(tagline)
	)
	var gap: Control = Control.new()
	gap.custom_minimum_size.y = 6
	column.add_child(gap)
	var panel: PanelContainer = BeachUI.wood_panel(column)
	panel.size_flags_horizontal = SIZE_SHRINK_BEGIN
	content = VBoxContainer.new()
	content.custom_minimum_size.x = 104
	panel.add_child(content)
	_big_button(content,"ARCADE  >",func() -> void: choose("arcade")).grab_focus()
	_big_button(content,"PRACTICE  >",func() -> void: choose("practice"))
	_big_button(content,"VS  >",func() -> void: choose("vs")).name = "VsButton"
	var small: HBoxContainer = HBoxContainer.new()
	content.add_child(small)
	_small_button(small,"OPTIONS",func() -> void: choose("options"))
	if not OS.has_feature("web"):
		_small_button(small,"QUIT",func() -> void: choose("quit"))

const LEVELS_PER_PAGE: int = 3
const PAGE_ARROW: Texture2D = preload("res://assets/ui/page-arrow-gold.png")
const LEVEL_SELECT_HEIGHT: float = 126.0 ## three quarters of the full-screen board
const LEVEL_CARD_HEAD: float = 34.0 ## number+stars row, then the thumbnail, sit above the name
const LEVEL_CARD_HEIGHT: float = 64.0 ## number row 8 + thumb 18 + two-line name 18 + status 8 + gaps
const LOCKED_RED: Color = Color("d12f2f")
var level_page: int = 0 # kept across rebuilds and across returning from a level

func level_select() -> void:
	var trained: bool = bool(GameState.entry(1).get("training_complete", false))
	clear("STAGE 1: LEARNING THE GULLIN'","",false,BeachUI.FONT_NATIVE)
	content.add_theme_constant_override("separation",3)
	# A shorter board, centred; the feather tablet shares the title's line, inside the frame.
	var panel: PanelContainer = content.get_parent() as PanelContainer
	panel.size_flags_vertical = SIZE_SHRINK_CENTER
	panel.custom_minimum_size.y = LEVEL_SELECT_HEIGHT
	var title_row: HBoxContainer = HBoxContainer.new()
	content.add_child(title_row)
	content.move_child(title_row,0)
	var title_label: Label = content.get_child(1) as Label
	content.remove_child(title_label)
	title_row.add_child(title_label)
	title_label.size_flags_horizontal = SIZE_EXPAND_FILL
	title_label.size_flags_vertical = SIZE_SHRINK_CENTER
	_feather_tablet(title_row)
	var pages: int = ceili(float(Config.levels.size()) / LEVELS_PER_PAGE)
	level_page = clampi(level_page,0,pages - 1)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation",2)
	row.size_flags_vertical = SIZE_EXPAND_FILL
	content.add_child(row)
	_page_arrow(row,"<",level_page > 0,-1)
	var first_open: Button
	for level: Dictionary in Config.levels.slice(level_page * LEVELS_PER_PAGE,(level_page + 1) * LEVELS_PER_PAGE):
		var id: int = level.id
		var unlocked: bool = GameState.unlocked(id)
		var locked_demo: bool = GameState.demo_locked(id)
		var status: String = "" if locked_demo else ("LOCKED" if not unlocked else (("REPLAY LESSONS" if trained else "BEGIN LESSON") if id == 1 else ""))
		var words: PackedStringArray = level.name.to_upper().split(" ")
		var last_word: String = words[words.size() - 1] if words.size() > 1 else "" # name on two lines, so every card is four lines and the status line stays at the bottom
		words.resize(maxi(words.size() - 1,1))
		var name_lines: String = " ".join(words) + "
" + last_word
		var caption: String = name_lines # number and stars above, the status below, are child nodes
		var button: Button = BeachUI.button(row,caption,func() -> void: choose("start",id),70)
		button.name = "Level%02d" % id
		button.custom_minimum_size = Vector2(70,LEVEL_CARD_HEIGHT)
		button.size_flags_vertical = SIZE_EXPAND_FILL
		for state: String in ["normal","hover","pressed","focus","disabled"]:
			var card_box: StyleBoxFlat = theme.get_stylebox(state,"Button").duplicate() as StyleBoxFlat
			card_box.content_margin_top = LEVEL_CARD_HEAD # the name starts below the number and stars
			card_box.content_margin_bottom = 11 # the name sits centred between the thumbnail and the status line
			button.add_theme_stylebox_override(state,card_box)
		var head: VBoxContainer = VBoxContainer.new()
		head.mouse_filter = Control.MOUSE_FILTER_IGNORE
		head.add_theme_constant_override("separation",2)
		head.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		head.offset_top = 4
		button.add_child(head)
		var number_row: HBoxContainer = HBoxContainer.new() # "03 ***" on one centred row
		number_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		number_row.alignment = BoxContainer.ALIGNMENT_CENTER
		number_row.add_theme_constant_override("separation",3)
		head.add_child(number_row)
		BeachUI.label(number_row,"%02d" % id,BeachUI.FONT_NATIVE,BeachUI.CREAM)
		var stars: HBoxContainer = HBoxContainer.new()
		stars.name = "Stars"
		stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stars.size_flags_vertical = SIZE_SHRINK_CENTER
		stars.add_theme_constant_override("separation",1)
		number_row.add_child(stars)
		for i: int in int(GameState.entry(id).get("stars",0)):
			var star: TextureRect = TextureRect.new()
			star.texture = BeachUI.STAR_ICON
			star.custom_minimum_size = Vector2(8,8)
			star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			star.stretch_mode = TextureRect.STRETCH_SCALE
			star.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			star.mouse_filter = Control.MOUSE_FILTER_IGNORE
			stars.add_child(star)
		button.size_flags_horizontal = SIZE_EXPAND_FILL
		button.disabled = not unlocked
		_level_thumb(head,level.get("thumb",""),unlocked)
		if not status.is_empty():
			var status_label: Label = _small_label(button,status,BeachUI.GOLD if id == 1 else BeachUI.CREAM)
			status_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
			status_label.offset_top = -11
			status_label.offset_bottom = -3
			status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			status_label.name = "Status"
		if locked_demo:
			var note: Label = _small_label(button,"FULL GAME",LOCKED_RED)
			note.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
			note.offset_top = -11
			note.offset_bottom = -3
			note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			note.name = "FullGameNote"
		if unlocked and first_open == null:
			first_open = button
	_page_arrow(row,">",level_page < pages - 1,1)
	var actions: HBoxContainer = HBoxContainer.new()
	actions.add_theme_constant_override("separation",4)
	content.add_child(actions)
	if not GameState.feedback_url().is_empty():
		_small_button(actions,"FEEDBACK",func() -> void: choose("feedback")).size_flags_horizontal = SIZE_SHRINK_CENTER
	_small_button(actions,"< BACK",func() -> void: choose("title")).size_flags_horizontal = SIZE_SHRINK_CENTER
	actions.alignment = BoxContainer.ALIGNMENT_CENTER # level select: the buttons hug their text
	if first_open != null:
		first_open.grab_focus()

const LEVEL_THUMB_H: float = 18.0 ## thumbnail row height, between the number row and the name
const LEVEL_THUMB_W: float = 58.0 ## widest the row of icons may be inside a 70 px card

## Thumbs shown smaller than the shared fit, and with the cut-off neck edge rounded (image only, source PNG untouched)
const THUMB_ROUND_NECK: Dictionary = {"thumb_head_small_dog": 0.82}
const NECK_ROUND_ROWS: int = 5

## Insets the bottom rows of a trimmed image along a quarter-ellipse so a flat cut reads as rounded
func _round_bottom(image: Image) -> void:
	var h: int = image.get_height()
	var top: int = h - NECK_ROUND_ROWS
	for y: int in range(top,h):
		var first: int = -1
		var last: int = -1
		for x: int in image.get_width():
			if image.get_pixel(x,y).a > 0.0:
				if first < 0:
					first = x
				last = x
		if first < 0:
			continue
		var t: float = (y + 0.5 - top) / NECK_ROUND_ROWS
		var keep: float = (last - first + 1) * 0.5 * sqrt(maxf(0.0,1.0 - t * t))
		var mid: float = (first + last + 1) * 0.5
		for x: int in range(first,last + 1):
			if absf(x + 0.5 - mid) > keep:
				image.set_pixel(x,y,Color(0,0,0,0))

## Themed icon(s) from the level's "thumb": "sprite_id[:animation]" or an array of them, side by side
## and centred. Each is trimmed to its opaque pixels; one shared nearest-filter scale keeps relative
## sizes. Unknown or missing ids are skipped, and no row is added if none load.
func _level_thumb(head: VBoxContainer, thumb: Variant, unlocked: bool) -> void:
	var specs: Array = thumb if thumb is Array else [str(thumb)]
	var images: Array[Image] = []
	var scales: Array[float] = []
	for spec: Variant in specs:
		var parts: PackedStringArray = str(spec).split(":")
		if parts[0].is_empty() or not Config.sprites.has(parts[0]):
			continue
		var animation: StringName = StringName(parts[1] if parts.size() > 1 else "idle")
		var frames: SpriteFrames = Config.frames(parts[0])
		if not frames.has_animation(animation) or frames.get_frame_count(animation) == 0:
			continue
		var image: Image = frames.get_frame_texture(animation,0).get_image()
		if image == null or image.is_empty():
			continue
		var used: Rect2i = image.get_used_rect()
		if used.size.x > 0 and used.size.y > 0:
			var trimmed: Image = image.get_region(used)
			var shrink: float = THUMB_ROUND_NECK.get(parts[0],1.0)
			if shrink < 1.0:
				_round_bottom(trimmed)
			images.append(trimmed)
			scales.append(shrink)
	if images.is_empty():
		return
	var gap: int = 2
	var max_h: float = 0.0
	var sum_w: float = float(gap * (images.size() - 1))
	for image: Image in images:
		max_h = maxf(max_h,image.get_height())
		sum_w += image.get_width()
	var fit: float = minf(LEVEL_THUMB_H / max_h,(LEVEL_THUMB_W - gap * (images.size() - 1)) / (sum_w - gap * (images.size() - 1)))
	var row: HBoxContainer = HBoxContainer.new()
	row.name = "Thumb"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation",gap)
	row.custom_minimum_size.y = LEVEL_THUMB_H
	if not unlocked:
		row.modulate = Color(0.25,0.25,0.25,0.6) # locked: dark silhouettes
	head.add_child(row)
	for i: int in images.size():
		var image: Image = images[i]
		var icon: TextureRect = TextureRect.new()
		icon.texture = ImageTexture.create_from_image(image)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_SCALE
		icon.size_flags_vertical = SIZE_SHRINK_CENTER
		icon.custom_minimum_size = Vector2(roundf(image.get_width() * fit * scales[i]),roundf(image.get_height() * fit * scales[i]))
		row.add_child(icon)

func _page_arrow(row: HBoxContainer, text: String, shown: bool, step: int) -> void:
	if not shown:
		var gap: Control = Control.new() # keeps the cards centred when there is no page that way
		gap.custom_minimum_size.x = 13
		row.add_child(gap)
		return
	# Gold pixel arrow (assets/ui/page-arrow-gold.png points right; the left one is mirrored).
	var image: Image = PAGE_ARROW.get_image()
	if step < 0:
		image.flip_x()
	var arrow: Button = Button.new()
	arrow.name = "PageNext" if step > 0 else "PagePrev"
	arrow.tooltip_text = text
	arrow.icon = ImageTexture.create_from_image(image)
	arrow.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	arrow.custom_minimum_size = Vector2(13,17)
	arrow.size_flags_vertical = SIZE_SHRINK_CENTER
	arrow.add_theme_color_override("icon_hover_color",Color(1.25,1.25,1.25))
	arrow.add_theme_color_override("icon_focus_color",Color(1.25,1.25,1.25))
	arrow.add_theme_color_override("icon_pressed_color",Color(0.8,0.8,0.8))
	for state: String in ["normal","hover","pressed","focus"]:
		var box: StyleBoxFlat = StyleBoxFlat.new()
		box.bg_color = Color(0,0,0,0)
		box.border_color = BeachUI.GOLD if state == "focus" else Color(0,0,0,0)
		box.set_border_width_all(1)
		box.set_corner_radius_all(3)
		box.anti_aliasing = false
		box.set_content_margin_all(1)
		arrow.add_theme_stylebox_override(state,box)
	arrow.pressed.connect(func() -> void:
		Audio.play("gull_call", 1.0, -8.0)
		level_page += step
		level_select())
	row.add_child(arrow)

func gull_picker() -> void:
	clear("PICK YOUR GULL")
	content.add_theme_constant_override("separation",3)
	var outer: MarginContainer = content.get_parent().get_parent() as MarginContainer
	for edge: String in ["top","bottom"]:
		outer.add_theme_constant_override("margin_" + edge,0)
	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_vertical = SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation",4)
	content.add_child(row)
	var chosen: String = GameState.chosen_gull()
	for id: String in Config.species.species:
		var info: Dictionary = Config.species.species[id]
		var owned: bool = GameState.gull_pickable(id)
		var soon: bool = bool(info.get("coming_soon", false)) and not GameState.gull_owned(id)
		var card: Button = BeachUI.button(row,"",func() -> void: choose("gull",id),82)
		card.name = "Card_" + id
		card.size_flags_horizontal = SIZE_EXPAND_FILL
		card.size_flags_vertical = SIZE_EXPAND_FILL
		card.disabled = not owned or soon
		var box: VBoxContainer = VBoxContainer.new()
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_theme_constant_override("separation",1) # 1 px rows leave room for the two-row SPECIAL line
		card.add_child(box)
		BeachUI.full(box)
		box.offset_left = 3
		box.offset_right = -3
		box.offset_top = 3
		box.offset_bottom = -3
		_gull_card_body(box,id,owned)
		var status_text: String = "COMING SOON" if soon else ("UNLOCKED" if GameState.gull_owned(id) else ("FREE PICK" if owned else "%d FEATHERS" % int(info.price)))
		var status: Label = _small_label(box,status_text,BeachUI.CREAM if owned else BeachUI.CORAL)
		status.name = "Status"
		status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if id == chosen:
			card.grab_focus()
	var modes: VBoxContainer = VBoxContainer.new()
	modes.add_theme_constant_override("separation",0)
	content.add_child(modes)
	_control_mode_slider(modes)
	var bottom: HBoxContainer = HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(bottom)
	var back: Button = _small_button(bottom,"< BACK",func() -> void: choose("title"))
	back.size_flags_horizontal = SIZE_SHRINK_CENTER
	back.custom_minimum_size.x = 40
	_perk_picker(bottom)
	var shop_button: Button = _small_button(bottom,"SHOP" if GameState.shop_open() else "SHOP - LVL 3",func() -> void: choose("shop"))
	shop_button.name = "ShopButton"
	shop_button.size_flags_horizontal = SIZE_SHRINK_CENTER
	shop_button.custom_minimum_size.x = 40
	shop_button.disabled = not GameState.shop_open()
	_feather_tablet()

## Gull card body shared by the picker and the practice menu: bird stage, name, blurb, stats, special.
func _gull_card_body(box: VBoxContainer, id: String, owned: bool) -> void:
	var info: Dictionary = Config.species.species[id]
	var stage: Control = Control.new()
	stage.custom_minimum_size = Vector2(0,22)
	stage.clip_contents = true
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(stage)
	var art_id: String = "gull_" + id.replace("-","_")
	var bird: AnimatedSprite2D = AnimatedSprite2D.new()
	bird.sprite_frames = Config.frames(art_id)
	bird.scale = Vector2.ONE * float(Config.sprites[art_id].visual_scale) * 1.0
	bird.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bird.modulate = Color.WHITE if owned else Color(0.5,0.55,0.6)
	bird.position = Vector2(50,12) # the frames carry the bird left of centre
	bird.play(&"glide")
	stage.add_child(bird)
	var name_label: Label = BeachUI.label(box,str(info.name),BeachUI.FONT_NATIVE,BeachUI.GOLD if owned else Color("6b858b"))
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var blurb: Label = BeachUI.label(box,str(info.blurb),BeachUI.FONT_NATIVE,Color("a9d7d2") if owned else Color("6b858b"))
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	blurb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	blurb.size_flags_vertical = SIZE_EXPAND_FILL
	_stat_rows(box,info.get("card",{}),owned)
	# Two rows so long names (LIGHTNING STRIKE) stay inside the card; the blurb's fill gives up the row.
	var special: Label = _small_label(box,"SPECIAL:\n" + str(info.get("power",{}).get("name","SOON")),BeachUI.GOLD if owned else Color("6b858b"))
	special.name = "Special"
	special.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

## VS menu: modes on the left, arena, opponent and name on the right. FIGHT! sends vs_start.
func vs_menu() -> void:
	clear("VS")
	var outer: MarginContainer = content.get_parent().get_parent() as MarginContainer
	outer.remove_child(content.get_parent())
	content.get_parent().queue_free()
	for edge: String in ["top","bottom","left","right"]:
		outer.add_theme_constant_override("margin_" + edge,3)
	var columns: HBoxContainer = HBoxContainer.new()
	columns.add_theme_constant_override("separation",2)
	outer.add_child(columns)
	var left: VBoxContainer = _vs_panel(columns,96)
	BeachUI.label(left,"VS",BeachUI.FONT_DISPLAY,BeachUI.GOLD).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for mode: Array in [["ModeMatchup","MATCH-UP  >",true],["ModeLadder","LADDER\nLATER",false],["ModeMultiplayer","MULTIPLAYER\nLATER",false]]:
		var node: Button = BeachUI.button(left,mode[1],func() -> void: pass)
		node.name = mode[0]
		node.disabled = not mode[2]
		node.size_flags_horizontal = SIZE_SHRINK_CENTER
		node.custom_minimum_size.x = 84
	var right: VBoxContainer = _vs_panel(columns,0)
	right.add_theme_constant_override("separation",2)
	right.get_parent().size_flags_horizontal = SIZE_EXPAND_FILL
	var columns2: HBoxContainer = HBoxContainer.new()
	columns2.add_theme_constant_override("separation",4)
	columns2.size_flags_vertical = SIZE_EXPAND_FILL
	right.add_child(columns2)
	var picks: VBoxContainer = VBoxContainer.new()
	picks.add_theme_constant_override("separation",2)
	picks.alignment = BoxContainer.ALIGNMENT_CENTER
	columns2.add_child(picks)
	var arena: ButtonGroup = _vs_row(picks,"ARENA","ArenaRow",Array(Config.vs.arenas).filter(func(id: String) -> bool: return Config.arenas.has(id)).map(func(id: String) -> Array: return [id,str(Config.arenas[id].name).to_upper()]),true)
	var slots: Array = ["gary","","",""] ## rival ids in slot order; slot 1 is never empty
	var slot_buttons: Array[Button] = _vs_slots(picks,slots)
	# Scores and the name share the right-hand column, so two stacked arena cards still fit on the left.
	var side: VBoxContainer = VBoxContainer.new()
	side.add_theme_constant_override("separation",2)
	side.alignment = BoxContainer.ALIGNMENT_CENTER
	side.size_flags_horizontal = SIZE_EXPAND_FILL
	columns2.add_child(side)
	var refresh_scores: Callable = _vs_scores(side,arena,slots)
	BeachUI.label(side,"YOUR NAME",BeachUI.FONT_NATIVE,BeachUI.GOLD).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var field: LineEdit = LineEdit.new()
	field.name = "NameField"
	field.max_length = OnlineScores.NAME_LENGTH
	field.alignment = HORIZONTAL_ALIGNMENT_CENTER
	field.add_theme_font_size_override("font_size",BeachUI.FONT_NATIVE)
	field.custom_minimum_size = Vector2(84,14)
	field.size_flags_horizontal = SIZE_SHRINK_CENTER
	var field_box: StyleBoxFlat = StyleBoxFlat.new()
	field_box.bg_color = BeachUI.INK
	field_box.set_corner_radius_all(2)
	for state: String in ["normal","focus","read_only"]:
		field.add_theme_stylebox_override(state,field_box)
	field.add_theme_color_override("font_color",BeachUI.CREAM)
	field.add_theme_color_override("caret_color",BeachUI.GOLD)
	field.text = OnlineScores.player_name() if not OnlineScores.player_name().is_empty() else str(Config.vs.default_name)
	field.text_changed.connect(func(text: String) -> void:
		var clean: String = OnlineScores.clean_name(text)
		if clean != text:
			field.text = clean
			field.caret_column = clean.length())
	side.add_child(field)
	arena.pressed.connect(func(_button: BaseButton) -> void: refresh_scores.call())
	for button: Button in slot_buttons:
		button.pressed.connect(refresh_scores) # the slot's own handler (connected first) has already cycled it
	refresh_scores.call()
	var actions: HBoxContainer = HBoxContainer.new()
	right.add_child(actions)
	BeachUI.back_button(actions,"< BACK",func() -> void: choose("title"))
	var gap: Control = Control.new()
	gap.size_flags_horizontal = SIZE_EXPAND_FILL
	actions.add_child(gap)
	var fight: Button = BeachUI.back_button(actions,"FIGHT!",func() -> void:
		var name_text: String = OnlineScores.clean_name(field.text)
		OnlineScores.set_player_name(name_text if not name_text.is_empty() else str(Config.vs.default_name))
		choose("vs_start",{"arena": str(arena.get_pressed_button().get_meta("id")),"opponents": slots.filter(func(id: String) -> bool: return not id.is_empty())}))
	fight.name = "FightButton"
	field.text_submitted.connect(func(_text: String) -> void: fight.grab_focus())
	fight.grab_focus()

## A wood panel with a column inside; the frame's content margins are trimmed so 96 px still holds MULTIPLAYER.
func _vs_panel(parent: Control, width: float) -> VBoxContainer:
	var panel: PanelContainer = BeachUI.wood_panel(parent)
	var box: StyleBoxTexture = panel.get_theme_stylebox("panel").duplicate() as StyleBoxTexture
	box.content_margin_left = 11
	box.content_margin_right = 11
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel",box)
	panel.custom_minimum_size.x = width
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation",3)
	panel.add_child(column)
	return column

## A caption and a row of toggle cards, one always selected (the first). Entries are [id, text].
func _vs_row(parent: Control, caption: String, row_name: String, entries: Array, stacked: bool = false) -> ButtonGroup:
	BeachUI.label(parent,caption,BeachUI.FONT_NATIVE,BeachUI.GOLD).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var row: BoxContainer = BoxContainer.new()
	row.vertical = stacked
	row.name = row_name
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation",2 if stacked else 3)
	parent.add_child(row)
	var group: ButtonGroup = ButtonGroup.new()
	for entry: Array in entries:
		var card: Button = BeachUI.button(row,str(entry[1]),func() -> void: pass)
		card.toggle_mode = true
		card.button_group = group
		card.set_meta("id",entry[0])
		card.custom_minimum_size.x = 84
		card.size_flags_horizontal = SIZE_SHRINK_CENTER
		card.button_pressed = row.get_child_count() == 1
	return group

## Four numbered opponent bars. Clicking (or confirming) a bar cycles it to the next rival; slots 2-4 pass through EMPTY too.
func _vs_slots(parent: Control, slots: Array) -> Array[Button]:
	BeachUI.label(parent,"OPPONENTS",BeachUI.FONT_NATIVE,BeachUI.GOLD).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var column: VBoxContainer = VBoxContainer.new()
	column.name = "OpponentRow"
	column.add_theme_constant_override("separation",1)
	parent.add_child(column)
	var buttons: Array[Button] = []
	for i: int in slots.size():
		var bar: Button = _small_button(column,"",func() -> void: pass)
		bar.name = "Slot%d" % (i + 1)
		bar.custom_minimum_size = Vector2(0,11)
		bar.alignment = HORIZONTAL_ALIGNMENT_LEFT
		buttons.append(bar)
		bar.pressed.connect(func() -> void:
			slots[i] = vs_cycle(slots,i)
			_vs_slot_text(buttons,slots))
	_vs_slot_text(buttons,slots)
	return buttons

func _vs_slot_text(buttons: Array[Button], slots: Array) -> void:
	for i: int in buttons.size():
		var id: String = str(slots[i])
		buttons[i].text = "%d. EMPTY" % (i + 1) if id.is_empty() else "%d. %s  %s" % [i + 1,str(Config.vs.opponents[id].name).to_upper(),str(Config.vs.opponents[id].blurb)]
		buttons[i].modulate = Color(0.55,0.55,0.55) if id.is_empty() else Color.WHITE

## The rival slot `index` shows next: the roster in order, then EMPTY (not for slot 1), skipping rivals in other slots.
func vs_cycle(slots: Array, index: int) -> String:
	var order: Array = Config.vs.opponents.keys()
	if index > 0:
		order.append("")
	var start: int = order.find(str(slots[index]))
	for step: int in range(1,order.size() + 1):
		var id: String = order[(start + step) % order.size()]
		if id.is_empty() or not id in slots:
			return id
	return str(slots[index])

## SCORES TO BEAT: an inset with the top rows of the selected matchup's board. Shows the seed scores while loading,
## offline or on an empty reply. Returns a refresh Callable to call when the arena or opponent changes.
func _vs_scores(parent: Control, arena: ButtonGroup, slots: Array) -> Callable:
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "ScoresToBeat"
	panel.size_flags_horizontal = SIZE_EXPAND_FILL
	panel.size_flags_vertical = SIZE_SHRINK_CENTER
	var inset: StyleBoxFlat = StyleBoxFlat.new()
	inset.bg_color = BeachUI.INK
	inset.set_corner_radius_all(2)
	for edge: String in ["left","right","top","bottom"]:
		inset.set("content_margin_" + edge,3)
	panel.add_theme_stylebox_override("panel",inset)
	parent.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation",1)
	panel.add_child(box)
	BeachUI.label(box,"SCORES TO BEAT",BeachUI.FONT_NATIVE,BeachUI.GOLD).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var grid: GridContainer = GridContainer.new()
	grid.name = "ScoreRows"
	grid.columns = 3
	grid.add_theme_constant_override("h_separation",4)
	grid.add_theme_constant_override("v_separation",1)
	box.add_child(grid)
	var fill: Callable = func(rows: Array) -> void:
		for child: Node in grid.get_children():
			grid.remove_child(child)
			child.queue_free()
		for i: int in mini(rows.size(),VS_SCORE_ROWS):
			var row: Dictionary = rows[i]
			var color: Color = BeachUI.GOLD if bool(row.get("me",false)) else BeachUI.CREAM
			BeachUI.label(grid,str(row.get("rank",i + 1)),BeachUI.FONT_NATIVE,Color("a9d7d2") if color == BeachUI.CREAM else color)
			var who: Label = BeachUI.label(grid,str(row.name),BeachUI.FONT_NATIVE,color)
			who.size_flags_horizontal = SIZE_EXPAND_FILL
			var points: Label = BeachUI.label(grid,str(int(row.score)),BeachUI.FONT_NATIVE,color)
			points.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var seed_rows: Array = []
	for i: int in Config.vs.seed_scores.size():
		seed_rows.append(Dictionary(Config.vs.seed_scores[i]).merged({"rank": i + 1,"me": false}))
	var ticket: Array = [0]
	return func() -> void:
		ticket[0] += 1
		var mine: int = ticket[0]
		fill.call(seed_rows)
		var board: String = OnlineScores.vs_board(str(arena.get_pressed_button().get_meta("id")),slots.filter(func(id: String) -> bool: return not id.is_empty()).size())
		OnlineScores.top(board,func(rows: Array) -> void:
			if mine != ticket[0] or not is_instance_valid(grid) or rows.is_empty():
				return
			for row: Dictionary in rows:
				row.me = not OnlineScores.player_name().is_empty() and row.name == OnlineScores.player_name()
			fill.call(rows))

const VS_SCORE_ROWS: int = 5
const CONTROL_MODE_TEXT: Array[String] = ["REALISTIC: TAP EVERY WINGBEAT","NORMAL: HOLD TO FLAP","EASY: AUTO PECK IN DIVES"] ## display only; the saved ids stay realistic / normal / casual
const SMALL_FONT: Font = preload("res://assets/fonts/gull_hud.fnt")

# REALISTIC . NORMAL . CASUAL slider under the cards: a 6 px heading, then the slider with its mode beside it. Every change saves at once.
func _control_mode_slider(parent: Control) -> void:
	var heading: Label = BeachUI.label(parent,"CONTROL DIFFICULTY LEVEL",6,BeachUI.CREAM)
	heading.add_theme_font_override("font",SMALL_FONT)
	heading.add_theme_font_size_override("font_size",6)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var slider: HSlider = HSlider.new()
	slider.name = "ControlModeSlider"
	slider.min_value = 0
	slider.max_value = 2
	slider.step = 1
	slider.tick_count = 3
	slider.ticks_on_borders = true
	slider.custom_minimum_size = Vector2(90,7)
	slider.value = GameState.CONTROL_MODES.find(GameState.control_mode())
	slider.tooltip_text = "REALISTIC / NORMAL / EASY"
	# The stock 16 px grabber would grow the row and squash the gull cards.
	var knob: Image = Image.create(5,7,false,Image.FORMAT_RGBA8)
	knob.fill(BeachUI.GOLD)
	for icon: String in ["grabber","grabber_highlight","grabber_disabled"]:
		slider.add_theme_icon_override(icon,ImageTexture.create_from_image(knob))
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation",6)
	parent.add_child(row)
	row.add_child(slider)
	var detail: Label = BeachUI.label(row,"",6,Color("a9d7d2"))
	detail.add_theme_font_override("font",SMALL_FONT)
	detail.add_theme_font_size_override("font_size",6)
	detail.custom_minimum_size.x = 110
	var refresh: Callable = func() -> void:
		var at: int = int(slider.value)
		detail.text = CONTROL_MODE_TEXT[at]
	slider.value_changed.connect(func(value: float) -> void:
		GameState.set_control_mode(GameState.CONTROL_MODES[int(value)])
		refresh.call())
	refresh.call()

# One owned perk may be equipped: a single button that cycles NONE and the owned perks.
func _perk_picker(parent: Control) -> void:
	var options: Array[String] = [""]
	for id: String in Config.perks.perks:
		if GameState.perk_owned(id):
			options.append(id)
	if options.size() == 1:
		return
	var caption: Callable = func() -> String:
		var id: String = GameState.equipped_perk()
		return "PERK:  < %s >" % (str(Config.perks.perks[id].name) if not id.is_empty() else "NONE")
	var step: Callable = func(dir: int) -> void:
		var at: int = options.find(GameState.equipped_perk())
		GameState.equip_perk(options[posmod(at + dir,options.size())])
	var pick: Button = BeachUI.button(parent,"",func() -> void: pass,150)
	pick.name = "PerkPick"
	pick.text = caption.call()
	pick.pressed.connect(func() -> void:
		step.call(1)
		pick.text = caption.call())
	pick.gui_input.connect(func(event: InputEvent) -> void:
		var dir: int = int(event.is_action_pressed("ui_right")) - int(event.is_action_pressed("ui_left"))
		if dir != 0:
			step.call(dir)
			pick.text = caption.call()
			pick.accept_event())

# Feathers shop: perks on the left, priced gulls on the right (two columns fit 320x180).
func shop(bought: bool = false) -> void:
	clear("FEATHER SHOP")
	content.add_theme_constant_override("separation",2)
	var outer: MarginContainer = content.get_parent().get_parent() as MarginContainer
	for edge: String in ["top","bottom"]:
		outer.add_theme_constant_override("margin_" + edge,0)
	_feather_tablet()
	var hint: Label = BeachUI.label(self,"EARN FEATHERS BY
COMPLETING QUESTS
IN ARCADE MODE",6,Color("a9d7d2"))
	hint.name = "EarnHint"
	hint.add_theme_font_override("font",SMALL_FONT)
	hint.add_theme_font_size_override("font_size",6)
	hint.add_theme_constant_override("line_spacing",1)
	hint.position = Vector2(166,11)
	hint.size = Vector2(98,21)
	var columns: HBoxContainer = HBoxContainer.new()
	columns.size_flags_vertical = SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation",4)
	content.add_child(columns)
	var left: VBoxContainer = VBoxContainer.new()
	left.add_theme_constant_override("separation",2)
	columns.add_child(left)
	var right: VBoxContainer = VBoxContainer.new()
	right.add_theme_constant_override("separation",2)
	columns.add_child(right)
	var perks_head: HBoxContainer = HBoxContainer.new()
	left.add_child(perks_head)
	BeachUI.label(perks_head,"PERKS",BeachUI.FONT_NATIVE,Color("a9d7d2")).size_flags_vertical = SIZE_SHRINK_CENTER
	BeachUI.sticker(perks_head,"COMING SOON").name = "PerksSticker"
	# Both header rows share one height so the two item columns start level.
	var gulls_head: HBoxContainer = HBoxContainer.new()
	gulls_head.custom_minimum_size.y = perks_head.get_combined_minimum_size().y
	right.add_child(gulls_head)
	BeachUI.label(gulls_head,"GULLS",BeachUI.FONT_NATIVE,Color("a9d7d2")).size_flags_vertical = SIZE_SHRINK_CENTER
	var first: Button
	for id: String in Config.perks.perks:
		var info: Dictionary = Config.perks.perks[id]
		var item: Button = _shop_item(left,id,str(info.name),str(info.blurb),int(info.price),140,false,bool(info.get("coming_soon", false)))
		first = first if first != null or item.disabled else item
	for id: String in Config.species.species:
		var info: Dictionary = Config.species.species[id]
		if int(info.price) > 0:
			if bool(info.get("coming_soon", false)):
				BeachUI.sticker(right,"COMING SOON").name = "Sticker_" + id
			var item: Button = _shop_item(right,id,str(info.name),str(info.blurb),int(info.price),132,false,bool(info.get("coming_soon", false)))
			first = first if first != null or item.disabled else item
	var message: Label = BeachUI.label(right,"BOUGHT!" if bought else "",BeachUI.FONT_NATIVE,BeachUI.GOLD)
	message.name = "Message"
	var spacer: Control = Control.new()
	spacer.size_flags_vertical = SIZE_EXPAND_FILL
	right.add_child(spacer)
	var back: Button = _small_button(self,"< BACK",func() -> void: choose("pick")) # small font, centred on the screen under both columns
	back.size_flags_horizontal = SIZE_SHRINK_CENTER
	back.custom_minimum_size.x = 40
	back.size = Vector2(40,12)
	back.position = Vector2(140,150)
	(first if first != null else back).grab_focus()

func _shop_item(parent: Control, id: String, item_name: String, blurb: String, price: int, width: int, stacked: bool, soon: bool = false) -> Button:
	var owned: bool = GameState.owns(id)
	var affordable: bool = GameState.feathers() >= price and not soon
	var button: Button = BeachUI.button(parent,"",func() -> void: choose("buy",id),width)
	button.name = "Item_" + id
	button.custom_minimum_size.y = 27 if stacked else 18
	button.disabled = owned or not affordable or soon
	var box: VBoxContainer = VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation",0)
	button.add_child(box)
	BeachUI.full(box)
	box.offset_left = 4
	box.offset_right = -4
	box.offset_top = 2
	box.offset_bottom = -2
	var status_text: String = "OWNED" if owned else ("BUY  %d" % price if affordable else str(price))
	var status_color: Color = BeachUI.CREAM if owned else (BeachUI.GOLD if affordable else Color("6b858b"))
	var dim: bool = owned or not affordable or soon
	var head: HBoxContainer = HBoxContainer.new()
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(head)
	var title_label: Label = BeachUI.label(head,item_name,BeachUI.FONT_NATIVE,Color("6b858b") if dim and not owned else BeachUI.GOLD)
	title_label.size_flags_horizontal = SIZE_EXPAND_FILL
	var blurb_label: Label = BeachUI.label(box,blurb,6,Color("6b858b") if dim else Color("a9d7d2"))
	blurb_label.name = "Blurb"
	blurb_label.add_theme_font_override("font",SMALL_FONT)
	blurb_label.add_theme_font_size_override("font_size",6)
	# The price reads as a number plus the Feather icon instead of the word FEATHERS.
	var price_row: HBoxContainer = HBoxContainer.new()
	price_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	price_row.add_theme_constant_override("separation",1)
	(box if stacked else head).add_child(price_row)
	var status: Label = BeachUI.label(price_row,status_text,BeachUI.FONT_NATIVE,status_color)
	status.name = "Status"
	if not owned:
		var icon: TextureRect = TextureRect.new()
		icon.texture = BeachUI.FEATHER_ICON
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.custom_minimum_size = Vector2(10,10)
		icon.size_flags_vertical = SIZE_SHRINK_CENTER
		icon.modulate = Color.WHITE if affordable else Color(1,1,1,0.45)
		price_row.add_child(icon)
	return button

# Simplified card stats: one row per stat, 1-5 pips from data/species.json "card".
func _stat_rows(parent: Control, card: Dictionary, owned: bool) -> void:
	for stat: String in ["speed","dive","tough"]:
		var line: HBoxContainer = HBoxContainer.new()
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.alignment = BoxContainer.ALIGNMENT_CENTER
		line.add_theme_constant_override("separation",1)
		parent.add_child(line)
		var caption: Label = _small_label(line,stat.to_upper(),Color("a9d7d2") if owned else Color("6b858b"))
		caption.custom_minimum_size.x = 26
		for i: int in 5:
			var pip: ColorRect = ColorRect.new()
			pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pip.custom_minimum_size = Vector2(3,3)
			pip.size_flags_vertical = SIZE_SHRINK_CENTER
			var lit: bool = i < int(card.get(stat,0))
			pip.color = (BeachUI.GOLD if owned else Color("6b858b")) if lit else Color(0.0,0.0,0.0,0.3)
			line.add_child(pip)

## One button cycling through the gulls the player owns (the gull picker's rule); each pick saves like choosing in the picker.
func _gull_cycler(on_change: Callable = Callable()) -> void:
	var owned: Array[String] = []
	for id: String in Config.species.species:
		if GameState.gull_owned(id):
			owned.append(id)
	var button: Button = BeachUI.button(content,"",func() -> void: pass,0)
	button.name = "GullCycler"
	button.size_flags_horizontal = SIZE_EXPAND_FILL
	var refresh: Callable = func() -> void: button.text = str(Config.species.species[GameState.chosen_gull()].name)
	refresh.call()
	button.disabled = owned.size() < 2
	button.pressed.connect(func() -> void:
		var next: String = owned[(owned.find(GameState.chosen_gull()) + 1) % owned.size()]
		choose("gull_practice",next)
		refresh.call()
		if on_change.is_valid():
			on_change.call())
	_small_label(content,"TAP TO SWAP GULL",Color("80bcb8")).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _small_button(parent: Control, text: String, action: Callable) -> Button:
	var node: Button = BeachUI.back_button(parent,text,action,0)
	node.size_flags_horizontal = SIZE_EXPAND_FILL
	node.add_theme_font_override("font",SMALL_FONT)
	node.add_theme_font_size_override("font_size",6)
	return node

func _big_button(parent: Control, text: String, action: Callable) -> Button:
	var node: Button = _small_button(parent,text,action)
	node.remove_theme_font_override("font") # GullPixel 8 px
	node.add_theme_font_size_override("font_size",BeachUI.FONT_NATIVE)
	return node

func _small_label(parent: Control, text: String, color: Color) -> Label:
	var node: Label = BeachUI.label(parent,text,6,color)
	node.add_theme_font_override("font",SMALL_FONT)
	node.add_theme_font_size_override("font_size",6)
	return node

func pause(skippable: bool = false, replay: String = "", practice: bool = false, input: GullInput = null) -> void:
	clear("TAKING A BREATHER", "YOUR LUNCH CAN WAIT.")
	# A compact box: half the usual menu, 8 px heading, 6 px subtitle and 13 px buttons.
	var panel: PanelContainer = content.get_parent() as PanelContainer
	panel.size_flags_horizontal = SIZE_SHRINK_CENTER
	panel.size_flags_vertical = SIZE_SHRINK_CENTER
	content.custom_minimum_size.x = 128
	content.get_child(0).add_theme_font_size_override("font_size",BeachUI.FONT_NATIVE)
	content.get_child(1).add_theme_font_override("font",SMALL_FONT)
	content.get_child(1).add_theme_font_size_override("font_size",6)
	var resume: Button = _small_button(content,"RESUME",func() -> void: choose("resume"))
	resume.grab_focus()
	if skippable:
		_small_button(content,"SKIP LESSON",func() -> void: choose("skip_lesson"))
	elif not replay.is_empty():
		_small_button(content,"REPLAY LESSON",func() -> void: choose(replay))
	_small_button(content,"RESTART",func() -> void: choose("restart"))
	var pair: HBoxContainer = HBoxContainer.new()
	content.add_child(pair)
	var rules: Button = _small_button(pair,"SCORE RULES",func() -> void: pass)
	rules.size_flags_horizontal = SIZE_EXPAND_FILL
	rules.pressed.connect(func() -> void:
		ScoreRulesCard.open(self,"BACK").closed.connect(func() -> void:
			if is_instance_valid(rules):
				rules.grab_focus()))
	_small_button(pair,"OPTIONS",func() -> void: choose("options_pause")).size_flags_horizontal = SIZE_EXPAND_FILL
	if input != null:
		var controls: Button = _small_button(content,"CONTROLS",func() -> void: pass)
		controls.name = "ControlsButton"
		controls.pressed.connect(func() -> void:
			ControlsCard.open(self,input).closed.connect(func() -> void:
				if is_instance_valid(controls):
					controls.grab_focus()))
	_small_button(content,"PRACTICE MENU" if practice else "LEVEL SELECT",func() -> void: choose("practice" if practice else "select"))

## Practice hub: the two score cards, then the open-ended session on Scrap Sands with the chosen gull.
func practice_menu() -> void:
	clear("")
	content.get_child(0).free() # no title; the gull card and buttons speak for themselves
	var panel: PanelContainer = content.get_parent() as PanelContainer
	panel.size_flags_horizontal = SIZE_SHRINK_CENTER
	panel.size_flags_vertical = SIZE_SHRINK_CENTER
	content.custom_minimum_size.x = 128
	# Side by side: the practice panel, then a display-only card for the chosen gull.
	var pair: HBoxContainer = HBoxContainer.new()
	pair.alignment = BoxContainer.ALIGNMENT_CENTER
	pair.add_theme_constant_override("separation",2)
	var outer: Node = panel.get_parent()
	outer.add_child(pair)
	panel.reparent(pair)
	var card_panel: PanelContainer = BeachUI.wood_panel(pair)
	card_panel.size_flags_vertical = SIZE_SHRINK_CENTER
	var card_box: VBoxContainer = VBoxContainer.new()
	card_box.custom_minimum_size.x = 76
	card_box.add_theme_constant_override("separation",2)
	card_panel.add_child(card_box)
	var show_card: Callable = func() -> void:
		for child: Node in card_box.get_children():
			card_box.remove_child(child)
			child.queue_free()
		_gull_card_body(card_box,GameState.chosen_gull(),true)
		_ink_labels.call_deferred(card_box)
	show_card.call()
	_gull_cycler(show_card)
	var rules: Button = _small_button(content,"HOW TO SCORE",func() -> void: pass)
	rules.name = "RulesButton"
	rules.pressed.connect(func() -> void:
		ScoreRulesCard.open(self,"BACK").closed.connect(func() -> void:
			if is_instance_valid(rules):
				rules.grab_focus()))
	var ways: Button = _small_button(content,"STEAL TYPES",func() -> void: pass)
	ways.name = "WaysButton"
	ways.pressed.connect(func() -> void:
		ScoreWaysCard.open(self,"STEAL TYPES").closed.connect(func() -> void:
			if is_instance_valid(ways):
				ways.grab_focus()))
	var go: Button = _small_button(content,"LET'S PRACTICE!",func() -> void: choose("practice_start"))
	go.name = "GoButton"
	go.remove_theme_font_override("font") # SMALL_FONT has no apostrophe; the main call to action uses GullPixel 8 px
	go.add_theme_font_size_override("font_size",BeachUI.FONT_NATIVE)
	go.grab_focus()
	var practice_back: Button = _small_button(content,"< BACK",func() -> void: choose("title"))
	practice_back.size_flags_horizontal = SIZE_SHRINK_CENTER
	practice_back.custom_minimum_size.x = 40

func options(from_pause: bool) -> void:
	clear("MAKE YOURSELF AT HOME")
	content.add_theme_constant_override("separation", 2)
	back_action = "pause" if from_pause else "title"
	for bus: String in ["Master","SFX","Music"]:
		var row: HBoxContainer = HBoxContainer.new()
		content.add_child(row)
		BeachUI.label(row,bus.to_upper()).custom_minimum_size.x = 55
		var slider: HSlider = HSlider.new()
		slider.size_flags_horizontal = SIZE_EXPAND_FILL
		slider.min_value = 0
		slider.max_value = 1
		slider.step = 0.05
		slider.value = GameState.options[bus]
		slider.custom_minimum_size.y = 12
		row.add_child(slider)
		slider.value_changed.connect(func(value: float) -> void:
			GameState.options[bus] = value
			Audio.apply_options())
	var steer_row: HBoxContainer = HBoxContainer.new()
	content.add_child(steer_row)
	BeachUI.label(steer_row,"DIVE STEER").custom_minimum_size.x = 55
	var steer: HSlider = HSlider.new()
	steer.size_flags_horizontal = SIZE_EXPAND_FILL
	steer.min_value = 0.3
	steer.max_value = 1.0
	steer.step = 0.05
	steer.value = GameState.dive_steer()
	steer.custom_minimum_size.y = 12
	steer_row.add_child(steer)
	steer.value_changed.connect(func(value: float) -> void: GameState.options["dive_steer"] = value)
	var assist_button: Button = BeachUI.button(steer_row,"ASSIST: "+("ON" if GameState.assist() else "OFF"),func() -> void:
		GameState.set_assist(not GameState.assist())
		options(from_pause))
	assist_button.name = "AssistButton"
	assist_button.tooltip_text = "AUTO PECK AND AIM ASSIST IN DIVES"
	var toggles: HBoxContainer = HBoxContainer.new()
	content.add_child(toggles)
	for key: String in ["shake","touch","stats"]:
		var toggle: Button = BeachUI.button(toggles,key.to_upper()+": "+("ON" if GameState.options[key] else "OFF"),func() -> void:
			GameState.options[key] = not bool(GameState.options[key])
			options(from_pause))
		toggle.size_flags_horizontal = SIZE_EXPAND_FILL
	if not OS.has_feature("mobile"):
		var extras: HBoxContainer = HBoxContainer.new()
		content.add_child(extras)
		var keys_fly: bool = GameState.mouse_role() == "dive_aim"
		var role_button: Button = _small_button(extras,"KEYS FLY / MOUSE AIMS DIVES" if keys_fly else "MOUSE ONLY",func() -> void:
			GameState.set_mouse_role("steer" if keys_fly else "dive_aim")
			options(from_pause))
		role_button.name = "MouseRoleButton"
		role_button.tooltip_text = "KEYBOARD STEERS FLIGHT, MOUSE AIMS DIVES. CLICK FOR MOUSE ONLY" if keys_fly else "MOUSE STEERS FLIGHT AND DIVES. CLICK FOR KEYS FLY / MOUSE AIMS DIVES"
		_small_button(extras,"FULLSCREEN / F11",func() -> void: choose("fullscreen"))
	BeachUI.back_button(content,"SAVE / BACK",func() -> void:
		GameState.save_progress()
		choose(back_action)).grab_focus()

func results(level: Dictionary, result: Dictionary) -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	var board := ResultBoard.new()
	add_child(board)
	board.requested.connect(choose)
	board.setup(level, result)
