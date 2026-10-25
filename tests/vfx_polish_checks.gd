extends RefCounted
## Contact VFX timing and deterministic bin-litter tumble.

const TEXTURES: Array[Dictionary] = [
	{"path":"res://assets/sprites/vfx-peck-star-v1.png", "size":Vector2i(12,12)},
	{"path":"res://assets/sprites/vfx-snatch-slash-v1.png", "size":Vector2i(16,10)},
	{"path":"res://assets/sprites/vfx-impact-wedge-v1.png", "size":Vector2i(12,10)},
	{"path":"res://assets/sprites/vfx-crumb-flecks-v1.png", "size":Vector2i(8,8)},
	{"path":"res://assets/sprites/vfx-dust-puff-v1.png", "size":Vector2i(10,8)},
	{"path":"res://assets/sprites/vfx-speed-streak-v1.png", "size":Vector2i(14,8)},
]

static func has_effect(effects: BeachEffects,kind: String) -> bool:
	return effects.particles.any(func(item: Dictionary) -> bool: return str(item.get("effect_kind","")) == kind)

static func run(suite: Node,check: Callable) -> void:
	for specification: Dictionary in TEXTURES:
		var texture: Texture2D = load(str(specification.path)) as Texture2D
		check.call(texture != null and texture.get_size() == Vector2(specification.size),"contact VFX has its prepared runtime size: "+str(specification.path))
		if texture == null:
			continue
		var image: Image = texture.get_image()
		var opaque: int = 0
		var transparent: int = 0
		var binary_alpha: bool = true
		for y: int in image.get_height():
			for x: int in image.get_width():
				var alpha: float = image.get_pixel(x,y).a
				binary_alpha = binary_alpha and (is_zero_approx(alpha) or is_equal_approx(alpha,1.0))
				if is_zero_approx(alpha):
					transparent += 1
				else:
					opaque += 1
		check.call(binary_alpha and opaque > 0 and transparent > 0,"contact VFX is isolated with binary alpha: "+str(specification.path))

	var particles_enabled: bool = bool(Config.tuning.juice.particles)
	Config.tuning.juice.particles = true
	suite.main.start_level(2)
	var game: BeachGame = suite.main.game
	game.set_physics_process(false)
	game.intro = 0.0
	game.running = true
	var raids: BeachStashRaids = game.stash_raids
	var gull: BeachGull = game.player
	var bin: Dictionary = raids.bins[0]
	gull.position = Vector2(float(bin.x)-10.0,gull.ground_y())
	gull.facing = 1.0
	gull.land()
	game.effects.particles.clear()
	for tap: int in int(Config.tuning.world.bin_pecks):
		raids.peck_cooldown = 0.0
		check.call(raids.peck(),"bin accepts VFX peck %d" % (tap+1))
	check.call(has_effect(game.effects,"peck_star") and has_effect(game.effects,"peck_debris"),"accepted bin pecks emit textured contact and debris effects")
	var contact_count: int = game.effects.particles.filter(func(item: Dictionary) -> bool: return str(item.get("effect_kind","")).begins_with("peck_")).size()
	check.call(contact_count >= int(Config.tuning.juice.peck_contact_count)*int(Config.tuning.world.bin_pecks),"each accepted peck adds its tuned contact layer")
	game.effects.particles.clear()
	check.call(not raids.peck() and game.effects.particles.is_empty(),"rejected peck does not fake a contact effect")

	var garbage: Dictionary = {}
	for item: Dictionary in raids.items:
		if bool(item.get("garbage",false)):
			garbage = item
			break
	check.call(not garbage.is_empty() and garbage.has("rotation") and absf(float(garbage.get("angular_velocity",0.0))) >= float(Config.tuning.juice.trash_spin_min),"bin litter launches with seeded angular motion")
	if not garbage.is_empty():
		var angle_before: float = float(garbage.rotation)
		raids.tick(0.05)
		check.call(not is_equal_approx(float(garbage.rotation),angle_before),"airborne bin litter visibly changes angle")
		garbage.position.y = float(Config.tuning.world.ground)-3.0
		garbage.velocity = Vector2(10.0,50.0)
		garbage.grounded = false
		raids.tick(0.1)
		check.call(bool(garbage.grounded) and is_zero_approx(float(garbage.angular_velocity)) and is_equal_approx(float(garbage.rotation),float(garbage.rest_angle)),"landed bin litter stops at its varied resting angle")

	var target: BeachTarget
	for candidate: BeachTarget in game.spawner.targets:
		if candidate.food:
			target = candidate
			break
	check.call(target != null,"VFX fixture has a held snack target")
	if target != null:
		game.effects.particles.clear()
		game.effects.freeze = 0.0
		gull.state = BeachGull.State.STRIKE
		gull.velocity = Vector2(170.0,20.0)
		target.last_theft_direct = true
		target.last_theft_handover = false
		game._snatched(target,gull,false)
		check.call(has_effect(game.effects,"snatch_slash") and has_effect(game.effects,"snatch_streak") and game.effects.freeze > 0.0,"successful snatch emits textured VFX and hit-stop on the contact frame")
		game.effects.freeze = 0.0
		var particles_before_award: int = game.effects.particles.size()
		game._award(10,false,false,false)
		check.call(is_zero_approx(game.effects.freeze) and game.effects.particles.size() == particles_before_award,"later score award does not repeat the contact impact")

	game.effects.particles.clear()
	Config.tuning.juice.particles = false
	game.effects.peck_contact(Vector2(100,100),Vector2.RIGHT,0.5,"bin")
	game.effects.snatch_contact(Vector2(100,100),Vector2.RIGHT,false)
	check.call(game.effects.particles.is_empty(),"particles option suppresses every new textured contact effect")
	Config.tuning.juice.particles = particles_enabled
	suite.main.clear_game()
	await suite.settle()
