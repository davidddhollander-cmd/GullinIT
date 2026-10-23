class_name BeachBoss
extends RefCounted
## Level 6 boss rules, kept out of BeachGame: Bev shoves rivals off contested food, she can only
## be mugged from behind, the beach darkens towards dusk, and the level is won by out-eating the gang.

## Scenery tint for the sunset: white at the start, the level's "sunset.to" colour at the time limit.
static func tint(level: Dictionary, elapsed: float) -> Color:
	var sunset: Dictionary = level.get("sunset", {})
	if sunset.is_empty():
		return Color.WHITE
	return Color.WHITE.lerp(Color(str(sunset.to)), clampf(elapsed / float(level.time_limit), 0.0, 1.0))

## True when the attacker is on the opposite side of the victim from where she faces.
static func is_behind(victim: BeachGull, attacker: Vector2) -> bool:
	return (attacker.x - victim.position.x) * victim.facing < 0.0

static func _bump(gull: BeachGull, from: Vector2, seconds: float) -> void:
	if gull.state != BeachGull.State.STUNNED and gull.invulnerable <= 0.0:
		gull.begin_tumble(seconds, from) # not stun(): the bump costs no food and no points

## A guarded rival (mug_from_behind) bounces frontal mugs. Returns true when the mug is blocked.
static func blocks_mug(game: BeachGame, victim: RivalPilot, attacker: BeachGull) -> bool:
	if not bool(victim.personality.get("mug_from_behind", false)) or is_behind(victim.gull, attacker.position):
		return false
	_bump(attacker, victim.gull.position, float(Config.tuning.boss.bounce_stun))
	game.effects.message(victim.gull.position - Vector2(0, 20), "NOPE!", Color("ef725c"))
	return true

## Big and bossy: a diver reaching the food Bev is striking at gets bumped away, keeping its food.
static func shove(game: BeachGame) -> void:
	for pilot: RivalPilot in game.pilots:
		var radius: float = float(pilot.personality.get("shove_radius", 0.0))
		var bev: BeachGull = pilot.gull
		if radius <= 0.0 or bev.state != BeachGull.State.STRIKE or not is_instance_valid(pilot.target) or not pilot.target.food:
			continue
		var food: Vector2 = pilot.target.food_position()
		if bev.beak().distance_to(food) > radius:
			continue
		for other: BeachGull in game.gulls:
			if other != bev and other.state == BeachGull.State.STRIKE and other.beak().distance_to(food) <= radius:
				_bump(other, bev.position, float(pilot.personality.get("shove_stun", 0.4)))
				game.effects.message(other.position - Vector2(0, 18), "MOVE IT!", Color("ffc65c"))

static func best_rival(game: BeachGame) -> int:
	var best: int = 0
	for pilot: RivalPilot in game.pilots:
		best = maxi(best, pilot.score)
	return best

## Called by BeachGame.finish() while still running, so the boss quest counts.
static func conclude(game: BeachGame) -> void:
	var best: int = best_rival(game)
	if game.score.points > 0 and game.score.points >= 2 * best:
		game._quest_event("boss_double")

## Adds the verdict to the result and saves the stage flag on a win.
static func verdict(game: BeachGame, result: Dictionary) -> void:
	result.boss = true
	result.rival_best = best_rival(game)
	result.won = game.score.points > int(result.rival_best) # the same numbers the HUD meter shows
	if result.won:
		GameState.set_flag("stage1_complete")
