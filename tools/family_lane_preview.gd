extends Node2D
## Production sprites and crowd placement, with deliberately crowded families.
func _ready() -> void:
	Audio.music.stop()
	get_window().content_scale_size = Vector2i(320,200)
	get_window().size = Vector2i(1280,800)
	call_deferred("capture")

func capture() -> void:
	for row: int in 2:
		var base: float = 85+row*90
		var props: Array = [{"type":"beach_bench","x":160,"y":base-7}]
		var backdrop := BeachBackdrop.new()
		add_child(backdrop)
		backdrop.setup(props)
		backdrop.hide()
		for prop: AnimatedSprite2D in backdrop.prop_sprites:
			prop.reparent(self)
		var spawner := BeachSpawner.new()
		spawner.setup(self,{"id":3,"seed":42,"awareness_mult":1.0,"props":props,"spawns":[
			{"type":"picnic_family","x":155,"family_id":"first"},
			{"type":"toddler","x":156,"family_id":"first"},
			{"type":"toddler","x":154,"family_id":"first"}]})
		if row==1:
			var mum := spawner.create("picnic_family",157,{"family_id":"second"})
			var child := spawner.create("toddler",180,{"family_id":"second"})
			child.family_parent = mum
			mum.family_children.append(child)
		for target: BeachTarget in spawner.targets:
			target.position.y = base
			target.update_art_pose(row==1)
		spawner.apply_spacing(1.0)
		var title := Label.new()
		title.text = "MUM + TODDLERS / ONE GROUND LANE" if row==0 else "CROSSING FAMILIES / NO OVERLAP"
		title.add_theme_font_override("font",preload("res://assets/fonts/gull_pixel.fnt"))
		title.add_theme_font_size_override("font_size",8)
		title.position = Vector2(6,6+row*96)
		add_child(title)
	for frame: int in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://assets/archive/previews/family-ground-lane.png")
	get_tree().quit()

func _draw() -> void:
	draw_rect(Rect2(0,0,320,200),Color("abd6d0"))
	for base: float in [85,175]:
		draw_rect(Rect2(0,base+1,320,15),Color("e8c58e"))
