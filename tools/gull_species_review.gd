extends Node2D
const ROOT := "res://assets/reference/gull-species-v1/"
const PILOTS := "res://assets/pilots/gull-species-v1/"
var manifest: Dictionary
var textures: Dictionary = {}
var page := 0

func _ready() -> void:
	get_window().content_scale_size = Vector2i(400,270)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().size = Vector2i(1600,1080)
	manifest = JSON.parse_string(FileAccess.get_file_as_string(ROOT+"concepts.json"))
	for item: Dictionary in manifest.concepts:
		for pose: String in ["stand","fly"]:
			textures[item.id+"-"+pose] = ImageTexture.create_from_image(Image.load_from_file(PILOTS+item.id+"-"+pose+".png"))
			textures[item.id+"-"+pose+"-detail"] = ImageTexture.create_from_image(Image.load_from_file(PILOTS+item.id+"-"+pose+"-detail.png"))
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	call_deferred("_capture")

func _draw() -> void:
	if manifest.is_empty():
		return
	draw_rect(Rect2(0,0,400,270),Color("a9d5ce"))
	draw_rect(Rect2(0,0,400,25),Color("183b4e"))
	var font := ThemeDB.fallback_font
	if page < 3:
		var species: Dictionary = manifest.species[page]
		draw_string(font,Vector2(9,17),species.name.to_upper()+" / THREE DESIGNS",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("fff4da"))
		draw_string(font,Vector2(9,40),["STANDARD / SILVER GREY + PINK LEGS","SMALL + FAST / BLACK LEGS + CLEAN BLACK TIPS","LARGE / BLACK BACK + HEAVY BILL"][page],HORIZONTAL_ALIGNMENT_LEFT,-1,7,Color("183b4e"))
		draw_rect(Rect2(0,130,400,15),Color("e5c68c"))
		for option: int in 3:
			var item: Dictionary = _item(species.id,["A","B","C"][option])
			var centre := 67.0+option*133.0
			_label(font,centre,61,item.option+" / "+item.name.to_upper(),7)
			_detail(item.id+"-stand-detail",Vector2(centre,130),Vector2(112,66))
			_detail(item.id+"-fly-detail",Vector2(centre,227),Vector2(116,77))
			_label(font,centre,242,"STAND + FLIGHT",6)
		draw_rect(Rect2(0,252,400,18),Color("183b4e"))
		draw_string(font,Vector2(9,264),"DESIGN DETAIL / STANDING + FLIGHT / ADULT PLUMAGE",HORIZONTAL_ALIGNMENT_LEFT,-1,6,Color("fff4da"))
	else:
		draw_string(font,Vector2(9,17),"THREE GULL TYPES / PROPOSED GAME SCALE",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("fff4da"))
		draw_string(font,Vector2(9,41),"OPTION B COMPARISON / ACTUAL LOGICAL PIXEL SIZES",HORIZONTAL_ALIGNMENT_LEFT,-1,7,Color("183b4e"))
		draw_rect(Rect2(0,118,400,25),Color("e5c68c"))
		for i: int in 3:
			var species: Dictionary = manifest.species[i]
			var centre := 67.0+i*133.0
			_image(species.id+"-b-stand",Vector2(centre,118),0.5)
			_label(font,centre,134,["HERRING / 22 PX","KITTIWAKE / 17 PX","GREAT BLACK-BACKED / 28 PX"][i],6)
			_image(species.id+"-b-fly",Vector2(centre,218),0.5)
			_label(font,centre,241,["STANDARD","SMALLER + FASTER","LARGER"][i],7)
		draw_string(font,Vector2(9,263),"SIZE + SPEED ROLES ARE GAME DESIGN CHOICES; BALANCE TO FOLLOW",HORIZONTAL_ALIGNMENT_LEFT,-1,6,Color("183b4e"))

func _item(species: String,option: String) -> Dictionary:
	for item: Dictionary in manifest.concepts:
		if item.species==species and item.option==option:
			return item
	return {}

func _image(id: String,baseline: Vector2,factor: float) -> void:
	var texture: Texture2D = textures[id]
	var size := texture.get_size()*factor
	draw_texture_rect(texture,Rect2(baseline-Vector2(size.x/2,size.y),size),false)

func _detail(id: String,baseline: Vector2,limit: Vector2) -> void:
	var texture: Texture2D = textures[id]
	var size := texture.get_size()
	var factor := minf(limit.x/size.x,limit.y/size.y)
	_image(id,baseline,factor)

func _label(font: Font,x: float,y: float,text: String,size: int) -> void:
	var width := font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
	draw_string(font,Vector2(x-width/2,y),text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color("183b4e"))

func _capture() -> void:
	for index: int in 4:
		page = index
		queue_redraw()
		for i: int in 4:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var id: String = manifest.species[index].id if index<3 else "size-comparison"
		assert(get_viewport().get_texture().get_image().save_png("res://assets/previews/gull-species-"+id+"-v1.png")==OK)
	get_tree().quit()
