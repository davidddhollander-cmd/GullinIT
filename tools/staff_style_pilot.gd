extends Node2D
var rng := RandomNumberGenerator.new()
func _ready() -> void:
	get_window().content_scale_size = Vector2i(400,200)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().size = Vector2i(1600,800)
	rng.seed = 19
	_actor("pier_diner",Vector2(50,80))
	_actor("picnic_family",Vector2(150,80))
	_pilot(0,Vector2(250,80),0.5)
	_actor("lifeguard",Vector2(350,80))
	for i: int in 3:
		_pilot(i,Vector2(65+i*135,183),0.75)
	queue_redraw()
	call_deferred("_capture")
func _actor(kind: String,at: Vector2) -> void:
	var actor := BeachTarget.new()
	add_child(actor)
	actor.setup(kind,at.x,rng,1.0)
	actor.position = at
	actor.sprite.play(&"idle")
	actor.sprite.pause()
	actor.sprite.reparent(self)
	actor.hide()
func _pilot(index: int,at: Vector2,factor: float) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = ImageTexture.create_from_image(Image.load_from_file("res://assets/reference/shopper-lifeguard-v1/shopper-pilot-%d.png" % index))
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE*factor
	sprite.position = at-Vector2(0,52*factor)
	add_child(sprite)
func _draw() -> void:
	draw_rect(Rect2(0,0,400,200),Color("a9d5ce"))
	draw_rect(Rect2(0,0,400,23),Color("183b4e"))
	var font := ThemeDB.fallback_font
	draw_string(font,Vector2(9,16),"SHOPPER PILOT + REUSED LIFEGUARD",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("fff4da"))
	for y: int in [80,183]:
		draw_rect(Rect2(0,y,400,20),Color("e5c68c"))
	for i: int in 4:
		var text: String = ["DINER","MUM","NEW SHOPPER","LIFEGUARD"][i]
		draw_string(font,Vector2(50+i*100-font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,7).x/2,95),text,HORIZONTAL_ALIGNMENT_LEFT,-1,7,Color("183b4e"))
func _capture() -> void:
	for i: int in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png("res://assets/archive/previews/shopper-style-pilot-v1.png")==OK)
	get_tree().quit()
