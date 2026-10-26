extends Node2D

const CAPTIONS := ["REST", "DIP", "LIFT", "THROW", "SCREECH", "RECOVER"]

func _ready() -> void:
	get_window().content_scale_size = Vector2i(640, 360)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().size = Vector2i(1280, 720)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var frames: SpriteFrames = Config.frames("player_gull")
	assert(frames.has_animation(&"screech"))
	for index: int in 6:
		var actor := AnimatedSprite2D.new()
		actor.sprite_frames = frames
		actor.animation = &"screech"
		actor.frame = index
		actor.scale = Vector2.ONE * 1.6
		actor.position = Vector2(107 + (index % 3) * 213, 141 + (index / 3) * 157)
		add_child(actor)
	call_deferred("_capture")

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color("a9d5ce"))
	draw_rect(Rect2(0, 0, 640, 36), Color("183b4e"))
	var font: Font = ThemeDB.fallback_font
	draw_string(font, Vector2(17, 24), "HERRING GULL / LONG SCREECH", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("fff4da"))
	for row: int in 2:
		var baseline: int = 161 + row * 157
		draw_rect(Rect2(0, baseline, 640, 7), Color("e5c68c"))
		for col: int in 3:
			var index: int = row * 3 + col
			draw_string(font, Vector2(59 + col * 213, baseline + 24), CAPTIONS[index], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("183b4e"))

func _capture() -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://assets/previews/gull-herring-screech-v1.png")
	for player: Node in Audio.get_children():
		if player is AudioStreamPlayer:
			player.stop()
	get_tree().quit()
