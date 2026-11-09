extends RefCounted
## Task 067: hit flash, squash and stretch, weighted snatches, combo pop, score hop and floating-text hop.

const Shakedown = preload("res://tests/shakedown_checks.gd")
const Tumble = preload("res://tests/gull_tumble_checks.gd")

## -1 when the sprite has no material, otherwise its flash value (an unset uniform reads as 0).
static func flash_of(sprite: CanvasItem) -> float:
	var material: ShaderMaterial = sprite.material as ShaderMaterial
	if material == null:
		return -1.0
	var value: Variant = material.get_shader_parameter("flash")
	return 0.0 if value == null else float(value)

static func is_ring(item: Dictionary) -> bool:
	return item.get("ring",false)

static func run(host: Node, check: Callable) -> void:
	var shake_option: bool = bool(GameState.options.shake)
	_flash_checks(host,check)
	_squash_checks(host,check)
	_weight_checks(host,check)
	await _combo_and_score_checks(host,check)
	_text_checks(host,check)
	GameState.options.shake = shake_option

static func _flash_checks(host: Node, check: Callable) -> void:
	for path: String in ["res://assets/shaders/gull_cutout.gdshader","res://assets/shaders/rival_tint.gdshader","res://assets/shaders/sprite_flash.gdshader"]:
		var names: Array = (load(path) as Shader).get_shader_uniform_list().map(func(u: Dictionary) -> String: return str(u.name))
		check.call("flash" in names,"%s has a flash uniform" % path.get_file())
	check.call(is_equal_approx(HitFlash.duration(),float(Config.tuning.juice.flash_time)),"flash lasts flash_time")
	var game: BeachGame = Shakedown.fixture(host,"herring")
	var a: BeachGull = Tumble.actor(host,Vector2(300,100),true)
	var b: BeachGull = Tumble.actor(host,Vector2(340,100),true)
	check.call(a.sprite.material == null and b.sprite.material == null,"native-alpha gulls start with no material")
	a.stun(-1.0,Vector2(260,100))
	check.call(a.flash_left > 0.0 and b.flash_left == 0.0,"a stun flashes the stunned gull only")
	a._process(0.01)
	b._process(0.01)
	check.call(flash_of(a.sprite) > 0.0 and flash_of(a.sprite) <= 1.0 and b.sprite.material == null,"flash reaches a native-alpha sprite and not its neighbour")
	a._process(0.2)
	check.call(a.flash_left == 0.0 and a.sprite.material == null,"flash ends with no material again")
	# The two shader materials: own value each, feather tint kept, back to exactly 0.
	var cutout := ShaderMaterial.new()
	cutout.shader = preload("res://assets/shaders/gull_cutout.gdshader")
	var tint := ShaderMaterial.new()
	tint.shader = preload("res://assets/shaders/rival_tint.gdshader")
	tint.set_shader_parameter("feather_tint",Color("a5c7e6"))
	a.sprite.material = cutout
	b.sprite.material = tint
	a.hit_flash()
	a._process(0.01)
	b._process(0.01)
	check.call(flash_of(a.sprite) > 0.0 and flash_of(b.sprite) == 0.0,"a cutout flash does not touch a rival-tint gull")
	a._process(0.2)
	check.call(flash_of(a.sprite) == 0.0 and a.sprite.material == cutout,"cutout flash returns to exactly 0")
	b.hit_flash()
	b._process(0.01)
	check.call(flash_of(b.sprite) > 0.0 and flash_of(a.sprite) == 0.0 and (tint.get_shader_parameter("feather_tint") as Color).is_equal_approx(Color("a5c7e6")),"rival tint flashes alone and keeps its feather tint")
	b._process(0.2)
	check.call(flash_of(b.sprite) == 0.0,"rival tint flash returns to exactly 0")
	# People: only the one that lost food.
	var near: BeachTarget = Shakedown._person(game,600)
	var far: BeachTarget = Shakedown._person(game,640)
	near.hit_flash()
	near._process(0.01)
	far._process(0.01)
	check.call(flash_of(near.sprite) > 0.0 and far.flash_left == 0.0 and flash_of(far.sprite) <= 0.0,"a person flashes alone")
	near._process(0.2)
	check.call(flash_of(near.sprite) <= 0.0 and near.flash_left == 0.0,"a person's flash ends at 0")
	# Triggers.
	game.player.stun_shield = 1
	game.player.stun()
	check.call(game.player.flash_left > 0.0,"a blocked hit flashes the gull")
	game.player.flash_left = 0.0
	var ally := BeachGull.new()
	var gang_target: BeachTarget = Shakedown._person(game,800)
	game.brash._impact({"hit":gang_target.food_position(),"target":gang_target},ally)
	check.call(gang_target.flash_left > 0.0 and not gang_target.food,"Gang Call knocking food flashes the person")
	ally.free()
	var slam: BeachGame = Shakedown.fixture(host,"great-black-backed")
	var inner: BeachTarget = Shakedown._person(slam,300)
	var outer: BeachTarget = Shakedown._person(slam,300)
	Shakedown.ground_gull(slam,300)
	Shakedown._place(inner,slam.player.position,30.0)
	Shakedown._place(outer,slam.player.position,95.0)
	slam.brash.meter = 1.0
	slam.brash.fire()
	check.call(inner.flash_left > 0.0 and outer.flash_left == 0.0,"Shakedown's slam flashes the people it hits")
	slam.queue_free()
	# Reduce motion: no flash and no shake.
	GameState.options.shake = false
	var calm: BeachGull = Tumble.actor(host,Vector2(300,100),true)
	calm.stun(-1.0,Vector2(260,100))
	var fx := BeachEffects.new()
	fx.impact(Vector2.ZERO,true)
	check.call(calm.flash_left == 0.0 and HitFlash.duration() == 0.0 and fx.shake == 0.0 and fx.freeze > 0.0,"shake option off: no flash and no shake")
	GameState.options.shake = true
	for gull: BeachGull in [a,b,calm]:
		gull.queue_free()
	fx.free()
	game.queue_free()

static func _anchors_hold(p: BeachGull, check: Callable, label: String) -> void:
	p.tick(0.001,0,0.0)
	var scale: Vector2 = p.sprite.scale
	if p.state == BeachGull.State.GROUNDED:
		check.call(is_equal_approx(p.sprite.position.y+12.0*scale.y,float(Config.tuning.flight.feet_offset)),label+": soles stay on the ground")
	elif p.state == BeachGull.State.GLIDE:
		check.call(is_equal_approx(p.sprite.position.y+4.0*scale.y,2.0),label+": airborne anchor stays put")
	check.call(is_equal_approx(p.sprite.position.x*p.facing+20.0*scale.x,float(Config.tuning.dive.beak_offset)),label+": bill stays on its anchor")

static func _squash_checks(host: Node, check: Callable) -> void:
	var j: Dictionary = Config.tuning.juice
	var game: BeachGame = Shakedown.fixture(host,"herring")
	var p: BeachGull = game.player
	for species: String in ["herring","kittiwake","great-black-backed"]:
		p.species = species
		p.refresh_art()
		check.call(p.art_entry.has("frame_beaks"),species+" uses anchored art")
		p.land()
		p.squash(0.2,-0.2)
		p.power_scale = 1.4
		_anchors_hold(p,check,species+" landed, squashed, power scaled")
		var squashed: Vector2 = p.sprite.scale
		check.call(squashed.x > p.art_scale*1.4 and squashed.y < p.art_scale*1.4,species+" squash widens and flattens")
		for i: int in 20:
			p.tick(0.02,0,0.0)
		check.call(p.sprite.scale.is_equal_approx(Vector2.ONE*p.art_scale*1.4),species+" scale returns to art times power after the squash")
		p.power_scale = 1.0
		p.state = BeachGull.State.GLIDE
		p.position = Vector2(80,40)
		p.squash(0.1,0.1)
		_anchors_hold(p,check,species+" airborne bulge")
		p.state = BeachGull.State.STRIKE
		p.dive_speed = float(Config.tuning.dive.max_speed)
		p.direction = Vector2.RIGHT
		p.squash_left = 0.0
		var full: Vector2 = p.squash_scale()
		p.dive_speed = float(Config.tuning.dive.max_speed)*0.5
		var half: Vector2 = p.squash_scale()
		check.call(full.x > half.x and half.x > 1.0 and full.y < 1.0 and full.x <= 1.25 and full.y >= 0.8,species+" stretches along the body, more with dive speed")
		p.dive_speed = 0.0
		p.state = BeachGull.State.GLIDE
	p.species = "herring"
	p.refresh_art()
	# Landings: harder is stronger, all within the subtle range.
	p.state = BeachGull.State.GLIDE
	p.velocity = Vector2(0,60)
	p.land()
	var soft: Vector2 = p.squash_pose
	p.state = BeachGull.State.GLIDE
	p.velocity = Vector2(0,float(Config.tuning.dive.hard_landing_speed)+40.0)
	p.land()
	var hard: Vector2 = p.squash_pose
	check.call(hard.y < soft.y and soft.y < 1.0 and soft.x > 1.0 and hard.x <= 1.25 and hard.y >= 0.8,"hard landings squash harder, within 0.8-1.25")
	p.squash_left = 0.0
	game._swallowed({"id":"crumbs","value":1,"scrap":true})
	check.call(p.squash_left > 0.0 and p.squash_pose.x > 1.0 and p.squash_pose.y > 1.0,"swallowing bulges the player")
	j.squash = false
	p.squash_left = 1.0
	check.call(p.squash_scale() == Vector2.ONE,"squash switch off keeps the scale at 1")
	j.squash = true
	game.queue_free()

static func _weight_checks(_host: Node, check: Callable) -> void:
	var j: Dictionary = Config.tuning.juice
	var fx := BeachEffects.new()
	check.call(fx.snatch_weight("crumbs",0) == 0.0,"a crumb at tier 0 has weight 0")
	check.call(fx.snatch_weight("hotdog",4) == 1.0 and fx.snatch_weight("crumbs",0,true) == 1.0,"a large food at the top tier and a counter snatch are full weight")
	check.call(fx.snatch_weight("hotdog",0) > 0.0 and fx.snatch_weight("hotdog",0) < 1.0 and fx.snatch_weight("hotdog",2) > fx.snatch_weight("hotdog",0),"weight grows with food size and tier")
	fx.impact(Vector2.ZERO,false,fx.snatch_weight("crumbs",0))
	check.call(is_equal_approx(fx.freeze,float(j.snatch_stop)) and is_equal_approx(fx.shake,float(j.snatch_shake)),"a crumb at tier 0 keeps today's freeze and shake")
	var light_freeze: float = fx.freeze
	var light_shake: float = fx.shake
	fx.freeze = 0.0
	fx.shake = 0.0
	fx.impact(Vector2.ZERO,false,fx.snatch_weight("hotdog",4))
	check.call(fx.freeze > light_freeze and fx.shake > light_shake and is_equal_approx(fx.freeze,float(j.snatch_stop_max)) and is_equal_approx(fx.shake,float(j.snatch_shake_max)),"a big food at a high tier freezes and shakes harder")
	# A snatch straight after a stun leaves the stun's freeze and shake alone.
	fx.freeze = 0.0
	fx.shake = 0.0
	fx.impact(Vector2.ZERO,true)
	var stun_freeze: float = fx.freeze
	var stun_shake: float = fx.shake
	var particles: bool = j.particles
	j.particles = false
	fx.snatch_contact(Vector2(100,100),Vector2.RIGHT,true,0.0)
	j.particles = particles
	check.call(fx.freeze == stun_freeze and fx.shake == stun_shake,"a snatch after a stun keeps the stun's freeze and shake")
	fx.freeze = 0.5
	fx.shake = 9.0
	fx.impact(Vector2.ZERO,false)
	check.call(fx.freeze == 0.5 and fx.shake == 9.0,"a smaller hit never cuts a larger freeze or shake short")
	fx.free()

static func _combo_and_score_checks(host: Node, check: Callable) -> void:
	var score := BeachScore.new()
	var rises: Array[int] = []
	score.combo_rose.connect(func(tier: int) -> void: rises.append(tier))
	var top: int = Config.tuning.score.tiers.size()-1
	for i: int in top+3:
		score.snatch(5,false,false,false)
	check.call(rises == range(1,top+1),"combo_rose fires on each tier rise and not at the cap")
	score.stunned()
	rises.clear()
	score.snatch(5,false,false,false)
	check.call(rises.is_empty(),"a reset combo does not rise")
	var game: BeachGame = Shakedown.fixture(host,"herring")
	game.effects.particles.clear()
	game.effects.texts.clear()
	game.score.snatch(5,false,false,false)
	check.call(not game.effects.particles.any(is_ring) and game.effects.texts.is_empty(),"the first snatch makes no ring and no multiplier")
	game.score.snatch(5,false,false,false)
	check.call(game.effects.particles.any(is_ring),"a tier rise draws a ring")
	check.call(game.effects.texts.any(func(t: Dictionary) -> bool: return t.text == "X"+str(Config.tuning.score.tiers[1]) and t.plain),"a tier rise floats the multiplier")
	game.effects.particles.clear()
	game.score.stunned()
	game.score.snatch(5,false,false,false)
	check.call(not game.effects.particles.any(is_ring),"no ring when the combo resets")
	# Impact words use the plate-free style; score messages keep their plate.
	game.effects.texts.clear()
	game.player.peck_started.emit()
	check.call(game.effects.texts.any(func(t: Dictionary) -> bool: return t.text == "PECK!" and t.plain and not t.has("fade_time")),"PECK! is outlined, plate-free and holds without the whisper fade")
	game.effects.score_message(Vector2.ZERO,"+5 YUM")
	check.call(not game.effects.texts.back().get("plain",false),"score messages keep their plate")
	# Score hop: position and colour only; the top bar does not move.
	await host.get_tree().process_frame
	await host.get_tree().process_frame
	var overlay: BeachOverlay = game.overlay
	for i: int in 20:
		overlay._process(0.05) # let the hop from the snatches above settle
	var rest: float = overlay.score_label.position.y
	var rects: Array[Rect2] = [overlay.top.get_rect(),overlay.time_label.get_rect(),overlay.wind_label.get_rect(),overlay.pause_button.get_rect()]
	var size: Vector2 = overlay.score_label.size
	game.score.points += 25
	overlay._process(0.016)
	overlay._process(0.016)
	check.call(overlay.score_label.position.y < rest and overlay.score_label.get_theme_color("font_color") == Color.WHITE,"score label hops and turns white when points rise")
	check.call(overlay.score_label.scale == Vector2.ONE and overlay.time_label.scale == Vector2.ONE and overlay.wind_label.scale == Vector2.ONE,"HUD labels are never scaled")
	check.call(overlay.top.get_rect() == rects[0] and overlay.time_label.get_rect() == rects[1] and overlay.wind_label.get_rect() == rects[2] and overlay.pause_button.get_rect() == rects[3] and overlay.score_label.size == size,"the top bar layout does not move")
	for i: int in 30:
		overlay._process(0.02)
	check.call(overlay.score_label.position.y == rest and overlay.score_label.get_theme_color("font_color") != Color.WHITE,"score label settles back")
	game.queue_free()

static func _text_checks(_host: Node, check: Callable) -> void:
	var fx := BeachEffects.new()
	var j: Dictionary = Config.tuning.juice
	fx.shout(Vector2.ZERO,"BONK!",Color("ef725c"))
	var word: Dictionary = fx.texts[0]
	check.call(word.plain and word.color == Color("ef725c") and not word.has("fade_time") and is_equal_approx(word.life,float(j.float_time)),"shout keeps its colour, no plate, no fade, normal float time")
	fx.whisper(Vector2.ZERO,"Zzz")
	check.call(fx.texts[1].has("fade_time"),"whisper keeps its fade")
	check.call(fx.text_hop(word) == 0.0,"text starts at rest")
	fx.tick(float(j.text_hop_time)*0.5)
	check.call(fx.text_hop(fx.texts[0]) == float(j.text_hop),"text hops a few pixels in its first 0.1 s")
	fx.tick(float(j.text_hop_time))
	check.call(fx.text_hop(fx.texts[0]) == 0.0,"text settles after the hop")
	fx.free()
