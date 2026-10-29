extends RefCounted
## Contract for water-shot targeting. Projectile presentation is tested separately;
## these checks keep gameplay collision shared between player and rival gulls.

static func _ready_gull(gull: BeachGull, at: Vector2) -> void:
	gull.position = at
	gull.state = BeachGull.State.GLIDE
	gull.invulnerable = 0.0
	gull.visible = true

static func _park_all(gulls: Array[BeachGull]) -> void:
	for index: int in gulls.size():
		_ready_gull(gulls[index],Vector2(300.0+index*24.0,120.0))

static func run(suite: Node, check: Callable) -> void:
	suite.main.start_level(7)
	var game: BeachGame = suite.main.game
	game.set_physics_process(false)
	game.running = true
	game.intro = 0.0
	var player: BeachGull = game.player
	var rival: BeachGull = game.pilots[0].gull
	var other_rival: BeachGull = game.pilots[1].gull
	var shot_from := Vector2(100.0,70.0)
	var shot_to := Vector2(260.0,70.0)
	var hit_radius := Vector2(10.0,7.0)

	check.call(player in game.gulls and rival in game.gulls and other_rival in game.gulls,
		"water-shot candidates include the player and every active rival gull")

	_park_all(game.gulls)
	_ready_gull(player,Vector2(180.0,70.0))
	var hit: BeachGull = BeachCollisions.first_gull_hit(shot_from,shot_to,game.gulls,hit_radius)
	check.call(hit == player,"a swept water shot can select and hit the player gull")
	hit.stun(0.5,shot_from)
	check.call(player.state == BeachGull.State.STUNNED and rival.state != BeachGull.State.STUNNED,
		"a player water hit affects only the selected gull")

	_park_all(game.gulls)
	_ready_gull(rival,Vector2(180.0,70.0))
	hit = BeachCollisions.first_gull_hit(shot_from,shot_to,game.gulls,hit_radius)
	check.call(hit == rival,"the same swept water shot can select a rival gull")
	hit.stun(0.5,shot_from)
	check.call(rival.state == BeachGull.State.STUNNED and player.state != BeachGull.State.STUNNED,
		"a rival water hit affects only the selected rival")

	# The player is first in game.gulls, but the nearer rival must consume the shot.
	_park_all(game.gulls)
	_ready_gull(player,Vector2(220.0,70.0))
	_ready_gull(rival,Vector2(150.0,70.0))
	hit = BeachCollisions.first_gull_hit(shot_from,shot_to,game.gulls,hit_radius)
	check.call(hit == rival,"one water shot resolves against the nearest gull, not array order")

	_park_all(game.gulls)
	hit = BeachCollisions.first_gull_hit(shot_from,shot_to,game.gulls,hit_radius)
	check.call(hit == null,"a water shot that misses every gull has no target")

	suite.main.clear_game()
	await suite.settle()
