extends RefCounted
## A ground peck aimed at litter lying on the floor flings it a short way; it tumbles and lands further along.

static func litter_at(position: Vector2) -> Dictionary:
	return {"owner":null,"source":"bin","bin_x":0.0,"food_id":"","garbage":true,"garbage_kind":"can_red","extra":true,"position":position,"velocity":Vector2.ZERO,"grounded":true,"age":5.0,"rotation":0.0,"angular_velocity":0.0,"rest_angle":0.0}

## Resting litter's centre height: the ground minus half its drawn height.
static func floor_y(raids: BeachStashRaids) -> float:
	return float(Config.tuning.world.ground)-float(raids.litter_texture("can_red").get_height())*BeachStashRaids.LITTER_SCALE*0.5

static func run(host: Node, check: Callable) -> void:
	var game: BeachGame = preload("res://tests/peck_spam_checks.gd").fixture(host)
	game.stash_raids.bins.clear() # no bin competes for the peck
	var raids: BeachStashRaids = game.stash_raids
	var beak: Vector2 = game.player.beak()
	var ahead: Dictionary = litter_at(Vector2(beak.x+8.0,floor_y(raids)))
	var behind: Dictionary = litter_at(Vector2(beak.x-8.0,floor_y(raids)))
	raids.items.append(ahead)
	raids.items.append(behind)
	raids.peck_cooldown = 0.0
	check.call(raids.peck(), "peck at litter ahead is handled")
	check.call(not bool(ahead.grounded) and float(ahead.velocity.x) > 0.0 and float(ahead.velocity.y) < 0.0, "pecked litter is flung up and away from the gull")
	check.call(bool(behind.grounded), "litter behind the gull is left alone")
	var start_x: float = float(ahead.position.x)
	var spin: float = absf(float(ahead.angular_velocity))
	check.call(spin >= float(Config.tuning.juice.trash_spin_min), "flung litter tumbles")
	for i: int in 120:
		raids.tick(1.0/60.0)
	var moved: float = float(ahead.position.x)-start_x
	check.call(bool(ahead.grounded), "flung litter falls and comes to rest")
	check.call(moved > 4.0 and moved < 60.0, "flung litter travels only a short distance (%.1f px)" % moved)
	check.call(is_equal_approx(float(ahead.rotation),float(ahead.rest_angle)), "flung litter settles at its new rest angle")
	raids.peck_cooldown = 0.0
	raids.items.erase(behind)
	raids.items.erase(ahead)
	check.call(not raids.peck(), "peck with no litter in reach still falls through")
	# Every playable species can fling floor litter, whatever its beak height (litter rests at ground level, not at the beak).
	for id: String in Config.species.species.keys():
		game.player.species = id
		game.player.refresh_art()
		var floor_item: Dictionary = litter_at(Vector2(game.player.beak().x+8.0,floor_y(raids)))
		raids.items.append(floor_item)
		raids.peck_cooldown = 0.0
		check.call(raids.peck() and not bool(floor_item.grounded), "%s can peck-fling litter lying on the floor" % id)
		raids.items.erase(floor_item)
	game.queue_free()
