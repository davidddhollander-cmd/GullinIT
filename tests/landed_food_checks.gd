extends RefCounted
## Dropped foods with landed art splat on the sand: straight drops stand cone-up, sideways drops lie down.

static func run(suite: Node, check: Callable) -> void:
	suite.main.start_level(2)
	var game: BeachGame = suite.main.game
	game.set_physics_process(false)
	game.running = true
	game.intro = 0.0
	var raids: BeachStashRaids = game.stash_raids
	raids.items.clear()
	for vx: float in [10.0,-80.0]:
		raids.items.append({"owner":null,"food_id":"ice_cream_vanilla","position":Vector2(200,120),"velocity":Vector2(vx,0),"grounded":false,"age":0.0})
	for _i: int in 240:
		raids.tick(1.0/60.0)
	var straight: Dictionary = raids.items[0]
	var sideways: Dictionary = raids.items[1]
	check.call(bool(straight.grounded) and straight.landed == "up","a straight drop lands cone-up")
	check.call(bool(sideways.grounded) and sideways.landed == "lying" and float(sideways.landed_dir) < 0.0,"a sideways drop lies down facing its travel")
	raids.items.clear()
