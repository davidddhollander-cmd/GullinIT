extends RefCounted
## pixelfx spike: the hit-spark sheet is registered, spawns on snatch contact, mirrors for leftward
## snatches, frees itself, and the tuning flag turns it off.

static func run(suite: Node, check: Callable) -> void:
	check.call(Config.sprites.has("pixelfx_hit_spark") and FileAccess.file_exists(str(Config.sprites.pixelfx_hit_spark.file)),
		"pixelfx hit spark sprite entry and sheet exist")
	var frames: SpriteFrames = Config.frames("pixelfx_hit_spark")
	check.call(frames.has_animation(&"burst") and frames.get_frame_count(&"burst") == 13 and not frames.get_animation_loop(&"burst"),
		"pixelfx hit spark exposes a 13-frame one-shot burst")

	suite.main.start_level(1)
	var game: BeachGame = suite.main.game
	game.set_physics_process(false)
	var effects: BeachEffects = game.effects
	var right: AnimatedSprite2D = effects.pixelfx_hit_spark(Vector2(100,80),Vector2.RIGHT)
	var left: AnimatedSprite2D = effects.pixelfx_hit_spark(Vector2(100,80),Vector2.LEFT)
	check.call(right != null and left != null and right.z_index == 5 and not right.flip_h and left.flip_h,
		"hit spark sits in effect band 5 and mirrors for a leftward snatch")
	check.call(is_equal_approx(right.offset.x,-left.offset.x),
		"mirroring keeps the pivot on the contact point")

	var before: int = effects.get_child_count()
	effects.snatch_contact(Vector2(90,70),Vector2.RIGHT,false)
	check.call(effects.get_child_count() == before+1, "snatch contact spawns one pixelfx hit spark")

	Config.tuning.juice.pixelfx = false
	check.call(effects.pixelfx_hit_spark(Vector2(100,80),Vector2.RIGHT) == null, "the juice.pixelfx flag turns the spark off")
	Config.tuning.juice.pixelfx = true

	await suite.get_tree().create_timer(0.6).timeout
	check.call(not is_instance_valid(right) and not is_instance_valid(left),
		"hit sparks free themselves after the animation ends")
	suite.main.clear_game()
	await suite.settle()
