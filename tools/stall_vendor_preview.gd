extends Node2D
## Reproducible gameplay-scale captures of preparation, exposed food and snatch.
var game: BeachGame
var full_body_review: bool = false
const Checks = preload("res://tests/stall_service_checks.gd")

func _ready() -> void:
	Audio.music.stop()
	game = BeachGame.new()
	add_child(game)
	var definition: Dictionary = Config.levels[2].duplicate(true)
	definition.spawns = []
	definition.rivals = []
	definition.props = [{"type":"kiosk","x":90,"customer_x":138},{"type":"hotdog_stand","x":246,"customer_x":198}]
	definition.zones = [{"name":"COUNTER +50%","from":0,"to":320}]
	game.setup(definition,false)
	game.set_physics_process(false)
	game.running = true
	game.intro = 0
	game.overlay.hide()
	game.player.position = Vector2(130,88)
	for entry: Dictionary in [{"x":137,"id":"ice_cream","appearance":"shopper_mullet"},{"x":199,"id":"hotdog","appearance":"shopper_sundress"}]:
		var buyer := game.spawner.create("kiosk_customer",float(entry.x),{"food_id":entry.id,"appearance":entry.appearance})
		buyer.food = false
		buyer.food_sprite.hide()
		buyer.respawn = 0
	Checks.step(game,0.1)
	call_deferred("_capture")

func save_frame(label: String) -> void:
	for i: int in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://assets/previews/stall-vendor-%s-v2.png" % label)

func _capture() -> void:
	await save_frame("prepare")
	Checks.step(game,0.65)
	await save_frame("handover")
	get_window().size = Vector2i(640,360)
	await save_frame("counter-phone")
	get_window().size = Vector2i(1280,720)
	var food: BeachTarget = game.stalls.portions[0]
	var player: BeachGull = game.player
	player.state = BeachGull.State.STRIKE
	player.sweep_state = BeachGull.State.STRIKE
	player.direction = Vector2(0.8,0.6)
	player.velocity = player.direction*200
	player.position = food.food_position()-player.direction*12
	player.tick(0.0,0,0)
	player.peck_sweep_active = true
	player.grounded_sweep = false
	player.previous_beak = food.food_position()-Vector2(10,8)
	player.sweep_beak = food.food_position()+Vector2(10,8)
	BeachCollisions.resolve(player,game.stalls.portions,game.beach.props)
	game.effects.queue_redraw()
	await save_frame("snatch")
	game.queue_free()
	await get_tree().process_frame
	game = BeachGame.new()
	add_child(game)
	var family_level: Dictionary = Config.levels[1].duplicate(true)
	family_level.rivals = []
	family_level.props = [{"type":"kiosk","x":110,"customer_x":158}]
	family_level.zones = [{"name":"FAMILY COUNTER","from":0,"to":320}]
	family_level.spawns = [{"type":"picnic_family","x":157,"family_id":"preview"},{"type":"toddler","x":150,"family_id":"preview"},{"type":"toddler","x":184,"family_id":"preview"}]
	game.setup(family_level,false)
	game.set_physics_process(false)
	game.overlay.hide()
	game.player.hide()
	var mum: BeachTarget = game.spawner.targets[0]
	var child: BeachTarget = game.spawner.targets[1]
	mum.supply_crisps = 0
	mum.family_trip = BeachTarget.FamilyTrip.BUY
	child.food = false
	child.food_sprite.hide()
	child.wants_ice_cream = true
	game.stalls.request_family(mum)
	Checks.wait_for_food(game)
	Checks.step(game,0.35)
	await save_frame("family")
	Checks.step(game,0.75)
	Checks.wait_for_food(game)
	Checks.step(game,0.35)
	await save_frame("reserve")
	game.queue_free()
	await get_tree().process_frame
	full_body_review = true
	for index: int in 4:
		var actor := AnimatedSprite2D.new()
		actor.sprite_frames = VendorArt.frames(index>=2)
		actor.animation = &"poses"
		actor.frame = 0 if index%2==0 else 5
		actor.scale = Vector2(0.5,0.5)
		actor.position = Vector2(45+index*76,119)
		actor.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(actor)
	queue_redraw()
	await save_frame("full-body")
	for audio_player: Node in Audio.get_children():
		if audio_player is AudioStreamPlayer:
			audio_player.stop()
	await get_tree().create_timer(0.05).timeout
	get_tree().quit()

func _draw() -> void:
	if not full_body_review:
		return
	draw_rect(Rect2(0,0,320,180),Color("a9d7d2"))
	draw_rect(Rect2(0,145,320,35),Color("e5c68c"))
	var font: Font = preload("res://assets/fonts/gull_pixel.fnt")
	draw_string(font,Vector2(10,24),"GENERATED FULL-BODY VENDORS",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("183b4e"))
	for index: int in 4:
		var label: String = ("ICE" if index<2 else "DOG")+ (" IDLE" if index%2==0 else " SET")
		draw_string(font,Vector2(10+index*76,166),label,HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("183b4e"))
