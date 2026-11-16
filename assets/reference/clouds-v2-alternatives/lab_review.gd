extends SceneTree
## Standalone adapter around the real Art Lab. All registration is in memory.
const HERE := "res://assets/reference/clouds-v2-alternatives/"
const ART := "res://assets/sprites/background-v2/"
var lab
var config
var metadata: Dictionary = {}
var images: Dictionary = {}

func _initialize() -> void:
	call_deferred("run")

func definition(kind: String, entry: Dictionary) -> Dictionary:
	var r: Array = entry.region
	return {"file": ART + str(metadata[kind].image), "frame_w": r[2], "frame_h": r[3],
		"visual_scale": 0.5, "regions": [{"region": r, "offset": [0, 0]}],
		"animations": {"idle": {"frames": [0], "fps": 1, "loop": false}}}

func crop_texture(kind: String, index: int) -> ImageTexture:
	var r: Array = metadata[kind].clouds[index].region
	return ImageTexture.create_from_image(images[kind].get_region(Rect2i(int(r[0]), int(r[1]), int(r[2]), int(r[3]))))

func tint(texture_height: float, top: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = load("res://assets/shaders/dusk_tint.gdshader")
	material.set_shader_parameter("plate_top", top)
	material.set_shader_parameter("plate_height", texture_height)
	return material

func run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i(320, 180)
	root.content_scale_factor = 1.0
	root.size = Vector2i(320, 180)
	root.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	config = root.get_node("Config")
	for kind: String in ["original", "coastal", "pearl"]:
		var name: String = "clouds-v2" if kind == "original" else "clouds-v2-alt-" + kind
		metadata[kind] = JSON.parse_string(FileAccess.get_file_as_string(ART + name + ".json"))
		images[kind] = Image.load_from_file(ART + name + ".png")
	lab = load("res://scenes/art_lab.tscn").instantiate()
	root.add_child(lab)
	lab.set_process(false)
	lab.paused = true
	lab.zoom = 1
	lab.new_sky = true
	lab.comparisons.clear()
	lab.candidate_ids.clear()
	for kind: String in ["coastal", "pearl"]:
		for i: int in 12:
			var current_id: String = "cloud_review_original_%d" % i
			config.sprites[current_id] = definition("original", metadata.original.clouds[i])
			config.frames_cache.erase(current_id)
			var entry: Dictionary = {"current": current_id, "candidate": definition(kind, metadata[kind].clouds[i]),
				"title": "%s %s" % [kind, str(metadata[kind].clouds[i].id)],
				"description": "V2 LEFT / PLATE CENTRE / NEW RIGHT", "category": "cloud", "motion": "static"}
			var index: int = lab.comparisons.size()
			lab.comparisons.append(entry)
			lab.candidate_ids.append(lab._register(index, entry))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(HERE + "lab"))
	var plate := Image.load_from_file(ART + "sky-clouds-320x80.png")
	var boards := [Image.create(640, 720, false, Image.FORMAT_RGBA8), Image.create(640, 720, false, Image.FORMAT_RGBA8)]
	for dusk_index: int in 2:
		lab.dusk = dusk_index == 1
		lab._build_backdrop()
		# Flat-sky texture retains real backdrop, sea and sun. A plate cloud is
		# shown separately at centre so it cannot overlap either candidate.
		var flat := Image.create(320, 80, false, Image.FORMAT_RGBA8)
		flat.fill(Color("5bc7d8"))
		lab.backdrop.background_art.sky.texture = ImageTexture.create_from_image(flat)
		for variant_index: int in 2:
			var kind: String = "coastal" if variant_index == 0 else "pearl"
			for i: int in 12:
				lab._select(variant_index * 12 + i)
				lab.camera.zoom = Vector2.ONE
				lab.camera.position = Vector2(640, 90)
				lab.backdrop.camera_x = 640.0
				lab.backdrop.tick(0.0)
				lab.title_label.text = "%s %s" % [kind.to_upper(), str(metadata[kind].clouds[i].id).to_upper()]
				lab.desc_label.text = "V2 LEFT / PLATE CENTRE / NEW RIGHT"
				lab.flags_label.text = "1X DUSK" if dusk_index else "1X DAY"
				lab.reference_label.text = "PLATE"
				for side_index: int in 2:
					var cloud: AnimatedSprite2D = lab.sides[side_index].node
					var texture := crop_texture("original" if side_index == 0 else kind, i)
					var frames := SpriteFrames.new()
					frames.add_frame("default", texture)
					cloud.sprite_frames = frames
					cloud.scale = Vector2(0.5, 0.5)
					cloud.position = Vector2(560 if side_index == 0 else 720, 66)
					cloud.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
					if dusk_index:
						cloud.material = tint(texture.get_height() * 0.5, 66 - texture.get_height() * 0.25)
				var reference := Sprite2D.new()
				var reference_crop := plate.get_region(Rect2i(0, 44, 38, 16) if i < 3 else Rect2i(6, 9, 65, 20))
				reference.texture = ImageTexture.create_from_image(reference_crop)
				reference.position = Vector2(640, 48)
				if dusk_index:
					reference.material = tint(reference_crop.get_height(), 48 - reference_crop.get_height() * 0.5)
				lab.stage.add_child(reference)
				await process_frame
				await RenderingServer.frame_post_draw
				var capture := root.get_texture().get_image()
				assert(capture.get_size() == Vector2i(320, 180), "Lab capture must be native 320x180")
				var path := HERE + "lab/%s-%02d-%s-1x.png" % [kind, i + 1, "dusk" if dusk_index else "day"]
				assert(capture.save_png(path) == OK)
				if i < 4:
					boards[dusk_index].blit_rect(capture, Rect2i(0, 0, 320, 180), Vector2i(variant_index * 320, i * 180))
				print("LAB 1X ", kind, " ", i+1, " ", "DUSK" if dusk_index else "DAY", " OK")
	for i: int in 2:
		assert(boards[i].save_png(HERE + "small-clouds-%s-1x.png" % ["day" if i == 0 else "dusk"]) == OK)
		var focus := Image.create(640, 416, false, Image.FORMAT_RGBA8)
		for row: int in 4:
			focus.blit_rect(boards[i], Rect2i(0, row * 180, 640, 104), Vector2i(0, row * 104))
		assert(focus.save_png(HERE + "small-clouds-focus-%s-1x.png" % ["day" if i == 0 else "dusk"]) == OK)
	print("CLOUD ALTERNATIVES LAB: 48 native 320x180 captures, camera zoom 1, nearest filter, OK")
	quit()
