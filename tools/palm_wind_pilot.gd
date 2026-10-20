extends Node2D
## Isolated comparison scene for the approved gameplay leaf animation.
const PALM: Texture2D = preload("res://assets/sprites/retro-beach-palm-32bit.png")
const SWAY: Shader = preload("res://assets/shaders/palm_leaf_sway.gdshader")
const FRAME_COUNT: int = 160
const CAPTURE_FPS: float = 20.0
var font: Font = preload("res://assets/fonts/gull_pixel.fnt")
var materials: Array[ShaderMaterial] = []
var capturing: bool = false

func _ready() -> void:
	Audio.music.stop()
	capturing = OS.get_cmdline_user_args().has("--capture")
	get_window().content_scale_size = Vector2i(480,240)
	get_window().size = Vector2i(1440,720)
	add_palm(Vector2(80,138),2.0,false)
	add_palm(Vector2(240,138),2.0,true)
	add_palm(Vector2(400,169),1.0,true)
	if capturing:
		call_deferred("capture")

func add_palm(at: Vector2, magnification: float, animated: bool) -> void:
	var palm := Sprite2D.new()
	palm.texture = PALM
	palm.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	palm.position = at
	palm.scale = Vector2.ONE*magnification
	if animated:
		var material := ShaderMaterial.new()
		material.shader = SWAY
		palm.material = material
		materials.append(material)
	add_child(palm)

func _draw() -> void:
	draw_rect(Rect2(0,0,480,240),Color("a9d7d2"))
	draw_rect(Rect2(0,0,480,25),Color("183b4e"))
	draw_string(font,Vector2(12,17),"PALM LEAVES / SUBTLE WIND PILOT",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("fff4da"))
	draw_rect(Rect2(0,142,480,45),Color("56b7ae"))
	draw_rect(Rect2(0,186,480,28),Color("e8c58e"))
	draw_rect(Rect2(0,185,480,2),Color("fff1cc"))
	for x: int in range(10,480,37):
		draw_rect(Rect2(x,161,12,1),Color("b7dfce"))
	draw_string(font,Vector2(43,47),"STILL / 2X",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("183b4e"))
	draw_string(font,Vector2(196,47),"BREEZE / 2X",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("183b4e"))
	draw_string(font,Vector2(364,47),"GAME SIZE",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("183b4e"))
	draw_string(font,Vector2(38,232),"GENTLE WIND ->   /   LEAF BASES AND TRUNK STAY STILL",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("183b4e"))

func capture() -> void:
	DirAccess.make_dir_recursive_absolute("res://test-output/palm-wind-pilot")
	for sample: int in FRAME_COUNT:
		for material: ShaderMaterial in materials:
			material.set_shader_parameter("preview_time",float(sample)/CAPTURE_FPS)
		for frame: int in 2:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var rendered: Image = get_viewport().get_texture().get_image()
		var error: Error = rendered.save_png("res://test-output/palm-wind-pilot/%03d.png" % sample)
		if error != OK:
			push_error("Palm pilot frame capture failed: %s" % error_string(error))
			get_tree().quit(1)
			return
	# A few additional rendered samples verify calm, wind reversal and looping.
	for sample: Dictionary in [
		{"name":"calm","strength":0.0,"direction":1.0,"time":2.0},
		{"name":"reverse","strength":0.55,"direction":-1.0,"time":2.0},
		{"name":"loop-end","strength":0.55,"direction":1.0,"time":8.0},
	]:
		for material: ShaderMaterial in materials:
			material.set_shader_parameter("wind_strength",sample.strength)
			material.set_shader_parameter("wind_direction",sample.direction)
			material.set_shader_parameter("preview_time",sample.time)
		for frame: int in 2:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://test-output/palm-wind-pilot/%s.png" % sample.name)
	print("PALM PILOT: captured %d frames at %d fps using the approved shared leaf shader" % [FRAME_COUNT,int(CAPTURE_FPS)])
	get_tree().quit()
