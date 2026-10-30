class_name BeachSquall
extends RefCounted
## Level 6 twist. Calm, a warned squall that sends the beach running for the promenade shelters and
## leaves its food on the sand, then a clearing where people drift back. Timings come from level.twist.
enum Phase { CALM, SQUALL, CLEARING }
const FLEERS: Array[String] = ["sunbather", "kiosk_customer", "picnic_family", "toddler", "pier_diner"]
const ADULTS: Array[String] = ["sunbather", "kiosk_customer", "picnic_family", "pier_diner"]
var game: BeachGame
var cfg: Dictionary
var phase: Phase = Phase.CALM
var warned: bool = false
var intensity: float = 0.0
var abandoned: int = 0
var flipped: bool = false
var start_dir: int = 1
var handled: Dictionary = {} ## target -> true once it has been sent for cover this squall
var twists: Dictionary = {} ## target -> its own twist, restored when the squall passes
var shelter_load: Dictionary = {} ## shelter x -> people sent there
var rain: BeachRain
var rival_scraps: Dictionary = {} ## rival pilot -> its own scraps weight
var next_strike: float = INF ## elapsed time of the next lightning strike during the squall
var downpour: AudioStreamPlayer ## wind-and-rain bed, faded with the squall's intensity
const DOWNPOUR_DB: float = -10.0
const OFF_EDGE: float = 40.0 ## how far past the world edge people on the sand run

func setup(owner_game: BeachGame) -> void:
	game = owner_game
	cfg = game.level.twist
	start_dir = game.wind.direction
	rain = BeachRain.new()
	rain.z_index = 6
	rain.drops = int(cfg.rain_drops)
	game.add_child(rain)
	var loop: AudioStreamOggVorbis = load("res://assets/audio/rain_loop.ogg")
	loop.loop = true
	downpour = AudioStreamPlayer.new()
	downpour.stream = loop
	downpour.bus = "SFX"
	downpour.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	game.add_child(downpour)

func phase_at(seconds: float) -> Phase:
	if seconds < float(cfg.calm):
		return Phase.CALM
	return Phase.SQUALL if seconds < float(cfg.calm) + float(cfg.squall) else Phase.CLEARING

func tick(delta: float) -> void:
	var seconds: float = game.elapsed
	if not warned and seconds >= float(cfg.calm) - float(cfg.warning):
		warned = true
		game.effects.message(Vector2(game.camera_x, 84.0), "SQUALL INCOMING!", Color("fff4da"), float(cfg.warning) + 1.0, 0.0)
		Audio.play("gust")
	var next: Phase = phase_at(seconds)
	if next != phase:
		phase = next
		if phase == Phase.SQUALL:
			_begin()
		elif phase == Phase.CLEARING:
			_clear()
	var storming: bool = phase == Phase.SQUALL
	intensity = move_toward(intensity, 1.0 if storming else 0.0, delta / maxf(0.01, float(cfg.ramp) if storming else float(cfg.ease)))
	_wind()
	if storming and seconds >= next_strike:
		_strike(seconds)
	if storming:
		for target: BeachTarget in game.spawner.targets:
			if is_instance_valid(target) and not handled.has(target):
				_flee(target)
	var tint: Array = cfg.tint
	var dark: Color = Color(tint[0], tint[1], tint[2])
	game.beach.modulate = Color.WHITE.lerp(dark, intensity)
	game.actors.modulate = Color.WHITE.lerp(dark, intensity * 0.5)
	rain.tick(delta, intensity, game.wind.direction * (4.0 + 8.0 * game.wind.strength), game.camera_x)
	var audible: bool = intensity > 0.01 and bool(Config.tuning.juice.audio)
	if audible != downpour.playing:
		if audible:
			downpour.play()
		else:
			downpour.stop()
	downpour.volume_db = DOWNPOUR_DB + linear_to_db(maxf(intensity, 0.001))

## Strength follows the squall; gusts (and one direction flip in its second half) only blow during it.
func _wind() -> void:
	var wind: BeachWind = game.wind
	var storming: bool = phase == Phase.SQUALL
	wind.base = lerpf(float(cfg.calm_wind), float(cfg.squall_wind), intensity)
	if wind.direction != start_dir:
		flipped = true
	wind.flip = storming and not flipped and game.elapsed >= float(cfg.calm) + float(cfg.squall) * 0.5
	if wind.gusts != storming:
		wind.gusts = storming
		if not storming and wind.phase >= 0.0:
			wind._next()
	if storming and wind.phase < 0.0:
		wind.countdown = minf(wind.countdown, float(cfg.gust_every))
	if wind.phase < 0.0:
		wind.strength = wind.base

func _strike(seconds: float) -> void:
	rain.strike()
	var gap: Array = cfg.get("lightning_every", [6.0, 12.0])
	next_strike = seconds + rain.rng.randf_range(float(gap[0]), float(gap[1]))

func _begin() -> void:
	_strike(game.elapsed)
	if not game.pending_rivals.is_empty():
		game._release_rivals()
	for pilot: RivalPilot in game.pilots:
		var ground: Dictionary = pilot.personality.get("ground", {})
		rival_scraps[pilot] = ground.get("scraps", null)
		ground["scraps"] = maxf(float(ground.get("scraps", 0.0)), float(cfg.rival_scraps))
		pilot.personality["ground"] = ground

func _clear() -> void:
	for target: BeachTarget in handled.keys():
		if not is_instance_valid(target):
			continue
		target.panic.release_shelter()
		if twists.has(target):
			target.info.twist = twists[target]
	twists.clear()
	handled.clear()
	for pilot: RivalPilot in rival_scraps.keys():
		var original: Variant = rival_scraps[pilot]
		if original == null:
			pilot.personality.ground.erase("scraps")
		else:
			pilot.personality.ground["scraps"] = original
	rival_scraps.clear()

func _flee(target: BeachTarget) -> void:
	handled[target] = true
	if target.kind not in FLEERS or target.is_loose() or target.leaving:
		return
	var world: Dictionary = Config.tuning.world
	var snacks: Array = world.stash_snacks
	# People caught out on the sand drop what they hold; those already by the promenade keep it.
	var on_sand: bool = target.position.x < float(world.promenade_start)
	if target.food and on_sand:
		_abandon(target.food_id, target.food_position(), target.facing)
		target.food = false
		target.food_sprite.hide()
		target.respawn = float(world.respawn_min)
	var spare: int = 0
	if target.kind == "sunbather":
		spare = mini(target.stash_remaining, int(cfg.bag_items))
		target.stash_remaining -= spare
	elif target.kind == "picnic_family":
		spare = int(cfg.picnic_items)
	for i: int in spare:
		_abandon(str(snacks[(i + int(target.position.x)) % snacks.size()]), target.position - Vector2(0.0, 10.0), 1.0 if i % 2 == 0 else -1.0)
	# The sand clears completely: those caught out run off the nearest edge until it passes.
	target.panic.shelter(target, _off_edge(target) if on_sand else _shelter_for(target))
	if target.panic.state == CrowdPanic.State.SHELTER and target.kind in ADULTS and not on_sand:
		# Sheltering adults hold food under cover like the pier diners: steep dives are blocked.
		twists[target] = target.info.twist
		target.info = target.info.duplicate()
		target.info.twist = "umbrella"

func _abandon(food_id: String, at: Vector2, side: float) -> void:
	abandoned += 1
	game.stash_raids.items.append({"food_id": food_id, "source": "abandoned", "snack": {"abandoned": true}, "position": at, "velocity": Vector2(side * 30.0, -55.0), "grounded": false, "age": 0.0})

func _off_edge(target: BeachTarget) -> float:
	var width: float = float(Config.tuning.world.width)
	return -OFF_EDGE if target.position.x < width * 0.5 else width + OFF_EDGE

func _shelter_for(target: BeachTarget) -> float:
	var promenade: float = float(Config.tuning.world.promenade_start)
	var best: Dictionary = {}
	var best_cost: float = INF
	for prop: Dictionary in game.beach.props:
		if str(prop.type) in cfg.shelters and float(prop.x) >= promenade:
			var cost: float = absf(float(prop.x) - target.position.x) + 40.0 * int(shelter_load.get(prop.x, 0))
			if cost < best_cost:
				best = prop
				best_cost = cost
	if best.is_empty():
		return promenade + 40.0
	var load: int = int(shelter_load.get(best.x, 0))
	shelter_load[best.x] = load + 1
	return clampf(float(best.x) + (load % 3 - 1) * 14.0, 20.0, float(Config.tuning.world.width) - 20.0)
