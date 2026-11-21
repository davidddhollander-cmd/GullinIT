extends RefCounted
## One signpost per level, and no two levels share a signpost spot.

const MIN_GAP := 40.0

static func run(suite: Node, check: Callable) -> void:
	var xs: Array[float] = []
	for number: int in range(1,10):
		suite.main.start_level(number)
		var game: BeachGame = suite.main.game
		game.set_physics_process(false)
		var signs: Array[Dictionary] = game.beach.sign_layouts()
		check.call(signs.size() == 1,"level %d has exactly one signpost (%d)" % [number,signs.size()])
		if not signs.is_empty():
			xs.append((signs[0].rect as Rect2).position.x)
		suite.main.clear_game()
		await suite.settle()
	for a: int in xs.size():
		for b: int in range(a+1,xs.size()):
			check.call(absf(xs[a]-xs[b]) >= MIN_GAP,"signposts of levels %d and %d are at least %d px apart (%d vs %d)" % [a+1,b+1,int(MIN_GAP),int(xs[a]),int(xs[b])])
	print("SIGNPOST_X ",xs)
