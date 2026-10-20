extends Node2D
## Capture actual dropped-food effects at gameplay scale.
var game: BeachGame

func _ready() -> void:
	Audio.music.stop()
	game = BeachGame.new()
	add_child(game)
	var definition: Dictionary = Config.levels[2].duplicate(true)
	definition.spawns = []
	definition.rivals = []
	definition.props = [{"type":"beach_lamp","x":80},{"type":"kiosk","x":270,"customer_x":310}]
	definition.zones = [{"name":"PROMENADE","from":0,"to":320}]
	game.setup(definition,false)
	game.set_physics_process(false)
	game.running = true
	game.intro = 0
	game.overlay.hide()
	game.player.position = Vector2(140,108)
	game.player.velocity = Vector2(140,130)
	var buyer := game.spawner.create("kiosk_customer",185,{"food_id":"hotdog","appearance":"shopper_mullet"})
	buyer.update_art_pose(false)
	call_deferred("_capture",buyer)

func save_frame(label: String) -> void:
	for i: int in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://assets/previews/visual-tweaks-%s.png" % label)

func _capture(buyer: BeachTarget) -> void:
	await save_frame("ground")
	assert(buyer.knock_food(game.player))
	for frame: int in 9:
		game.effects.tick(1.0/60)
		game.stash_raids.tick(1.0/60)
	await save_frame("miss-burst")
	for frame: int in 15:
		game.effects.tick(1.0/60)
		game.stash_raids.tick(1.0/60)
	await save_frame("falling-trail")
	for audio_player: Node in Audio.get_children():
		if audio_player is AudioStreamPlayer:
			audio_player.stop()
	await get_tree().create_timer(0.05).timeout
	get_tree().quit()
