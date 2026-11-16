extends SceneTree
## Standalone visual QA: --path . --script assets/reference/clouds-v2/preview.gd
## Renders only the atlas; never alters the game scene or shader.
const DIR := "res://assets/reference/clouds-v2/"
const ATLAS := "res://assets/sprites/background-v2/"
const CELL := Vector2(192, 112)
var canvas: Node2D

func _initialize() -> void:
	call_deferred("render_preview")

func label_at(text: String, at: Vector2, font_size: int = 14) -> void:
	var label := Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("183b4e"))
	canvas.add_child(label)

func render_preview() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i(800, 776)
	root.content_scale_factor = 1.0
	root.size = Vector2i(800, 776)
	root.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	canvas = Node2D.new()
	root.add_child(canvas)
	var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ATLAS + "clouds-v2.json"))
	var atlas := Image.load_from_file(ATLAS + "clouds-v2.png")
	var shader: Shader = load("res://assets/shaders/dusk_tint.gdshader")
	var backdrop := ColorRect.new()
	backdrop.color = Color("fff4da")
	backdrop.size = Vector2(800, 776)
	canvas.add_child(backdrop)
	for mode: int in 2:
		var offset := Vector2(16, 40 + mode * 384)
		label_at("DAY / #5bc7d8" if mode == 0 else "DUSK / actual game shader", Vector2(16, 12 + mode * 384), 18)
		for i: int in 12:
			var entry: Dictionary = metadata.clouds[i]
			var origin := offset + Vector2((i % 4) * CELL.x, (i / 4) * CELL.y)
			var bg := Sprite2D.new()
			var bg_image := Image.create(1, 1, false, Image.FORMAT_RGBA8)
			bg_image.fill(Color("5bc7d8"))
			bg.texture = ImageTexture.create_from_image(bg_image)
			bg.centered = false
			bg.position = origin
			bg.scale = CELL - Vector2(4, 4)
			canvas.add_child(bg)
			if mode == 1:
				var sky_material := ShaderMaterial.new()
				sky_material.shader = shader
				sky_material.set_shader_parameter("plate_top", 14.0)
				sky_material.set_shader_parameter("plate_height", 80.0)
				bg.material = sky_material
			var r: Array = entry.region
			var crop := atlas.get_region(Rect2i(int(r[0]), int(r[1]), int(r[2]), int(r[3])))
			var cloud := Sprite2D.new()
			cloud.texture = ImageTexture.create_from_image(crop)
			cloud.centered = false
			var draw_scale: float = float(entry.recommended_scale) * 2.0
			cloud.scale = Vector2.ONE * draw_scale
			var local := Vector2(floor((188 - crop.get_width() * draw_scale) / 2), 14)
			cloud.position = origin + local
			canvas.add_child(cloud)
			if mode == 1:
				var tint := ShaderMaterial.new()
				tint.shader = shader
				tint.set_shader_parameter("plate_top", 14.0 + local.y * 80.0 / 108.0)
				tint.set_shader_parameter("plate_height", crop.get_height() * draw_scale * 80.0 / 108.0)
				cloud.material = tint
			label_at(str(entry.id), origin + Vector2(6, 86), 12)
	await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(DIR + "preview.png")
	print("CLOUD PREVIEW: ", error_string(error))
	quit(error)
