extends Node2D
## Live game: player gull holding food in its beak, both facings, shot at 4x.
var game: BeachGame

func _ready() -> void:
	GullInput.register_actions()
	Audio.stop_all()
	Config.tuning.juice.audio = false
	game = BeachGame.new()
	add_child(game)
	var level: Dictionary = Config.levels[0].duplicate(true)
	level.rivals = []
	level.crabs = {"enabled":false}
	game.setup(level,false)
	game.set_physics_process(false)
	game.running = true
	game.intro = 0.0
	game.overlay.hide()
	call_deferred("capture")

func capture() -> void:
	var p: BeachGull = game.player
	var i: int = 0
	for food: String in ["ice_cream","hotdog"]:
		for facing: int in [1,-1]:
			p.digestion.snacks.clear()
			p.digestion.rest = 0
			p.digestion.collect(food)
			p.facing = facing
			p.tick(1.0/60,0,0)
			game.camera_x = p.position.x - 160
			game.camera.position = Vector2(p.position.x, 90)
			game.beach.camera_x = game.camera_x
			for f: int in 3:
				await get_tree().process_frame
			await RenderingServer.frame_post_draw
			var img: Image = get_viewport().get_texture().get_image()
			print("gull screen ", p.global_position, " vp ", img.get_size())
			img.save_png("res://test-output/beak-%d.png" % i)
			i += 1
	get_tree().quit()
