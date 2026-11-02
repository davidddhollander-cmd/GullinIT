class_name StartupLoading
extends Control
## A small animated scene bridges the engine's static splash and the title menu.
@export_file("*.tscn") var next_scene_path: String = "res://scenes/main.tscn"
@export_range(0.0, 3.0) var minimum_display_time: float = 1.0
@export var preview_only: bool = false

var clock: float = 0.0
var changing_scene: bool = false
@onready var flight: Control = $Flight
@onready var gull: AnimatedSprite2D = $Flight/Gull
var background: BeachBackgroundArt

func _ready() -> void:
	_build_scene()
	# Reuse the approved, fully preserved gull atlas and its four drawn wing poses.
	gull.sprite_frames = Config.frames("player_gull")
	gull.play(&"fly")
	preview_only = preview_only or OS.get_cmdline_user_args().has("--loading-preview")
	if not preview_only:
		var error: Error = ResourceLoader.load_threaded_request(next_scene_path, "PackedScene")
		if error != OK:
			_loading_failed("Could not begin loading the title screen.")

# Same sky, sun, animated sea and sand as the beach, so the loading page matches the game.
func _build_scene() -> void:
	$Backdrop.hide()
	var stage: Node2D = Node2D.new()
	background = BeachBackgroundArt.new(false)
	stage.add_child(background)
	for strip: Array in [[Rect2(0,130,320,50),Color("e8c58e")],[Rect2(0,130,320,3),Color("fff1cc")]]:
		var rect: ColorRect = ColorRect.new()
		rect.position = strip[0].position
		rect.size = strip[0].size
		rect.color = strip[1]
		stage.add_child(rect)
	add_child(stage)
	move_child(stage,0)
	var logo: TextureRect = TextureRect.new()
	logo.texture = load("res://assets/sprites/title-logo.png")
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_SCALE
	logo.position = Vector2(100,6)
	logo.size = Vector2(120,30)
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(logo)
	var text: Label = BeachUI.label(self,"LOADING",BeachUI.FONT_DISPLAY,Color.WHITE)
	text.theme = BeachUI.theme()
	text.position = Vector2(0,104)
	text.size = Vector2(320,20)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	clock += delta
	background.update(160.0,clock)
	# Wrap only when fully offscreen; keep the flight in the sky above the lettering.
	var horizontal: float = fposmod(0.42 + clock * 0.13, 1.2) - 0.1
	flight.anchor_left = horizontal
	flight.anchor_right = horizontal
	flight.position.y = size.y * 0.30 + sin(clock * 3.0) * 1.5
	gull.rotation = sin(clock * 3.0 + 0.7) * 0.025
	if preview_only or changing_scene:
		return
	var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(next_scene_path)
	if status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		_loading_failed("Could not load the title screen. Please restart the game.")
	elif status == ResourceLoader.THREAD_LOAD_LOADED and clock >= minimum_display_time:
		var scene: PackedScene = ResourceLoader.load_threaded_get(next_scene_path) as PackedScene
		if scene == null:
			_loading_failed("The title screen could not be opened.")
			return
		changing_scene = true
		_finish_loading.call_deferred(scene)

func _finish_loading(scene: PackedScene) -> void:
	if get_tree().change_scene_to_packed(scene) != OK:
		_loading_failed("The title screen could not be opened.")

func _loading_failed(message: String) -> void:
	set_process(false)
	push_error(message)
	var label: Label = Label.new()
	label.text = message
	label.theme = BeachUI.theme()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", BeachUI.INK)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	label.offset_left = 12
	label.offset_right = -12
	label.offset_top = -30
	label.offset_bottom = -8
