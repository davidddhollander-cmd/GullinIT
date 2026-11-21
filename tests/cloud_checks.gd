extends RefCounted
## Level clouds (task 096): a layout per level, drift that follows the wind, wrap, pause and dusk.

static func positions(layer: CloudLayer) -> Array:
	return layer.clouds.map(func(c: Dictionary) -> float: return c.x)

static func run(host: Node, check: Callable) -> void:
	var seen: Dictionary = {}
	var sheet_ids: Dictionary = {}
	for sheet: String in Config.tuning.clouds.sheets:
		for entry: Dictionary in Config.read_json("res://assets/sprites/background-v2/%s.json" % sheet).clouds:
			sheet_ids[entry.id] = true
	var ids_exist: bool = true
	for level: Dictionary in Config.levels:
		seen[JSON.stringify(level.get("clouds", []))] = true
		for placed: Dictionary in level.get("clouds", []):
			ids_exist = ids_exist and sheet_ids.has(placed.id) and [0.5, 1.0, 2.0].has(float(placed.scale))
	check.call(seen.size() == Config.levels.size() and not seen.has("[]"), "every level has its own cloud layout")
	check.call(ids_exist, "level clouds use real cloud ids at crisp scales")

	# Drift on a game beach: heading follows the wind, calm stands still, pause freezes, wrap stays on screen.
	var beach: BeachBackdrop = BeachBackdrop.new()
	beach.cloud_layout = Config.levels[2].clouds
	beach.wind_dir = 1
	beach.strength = 0.5
	host.add_child(beach)
	beach.setup([])
	var layer: CloudLayer = beach.background_art.clouds
	check.call(layer.clouds.size() == Config.levels[2].clouds.size(), "the beach draws its level's clouds")
	var start: Array = positions(layer)
	beach.tick(1.0)
	var moved: Array = positions(layer)
	var right: bool = true
	for i: int in start.size():
		right = right and (moved[i] > start[i] or moved[i] < start[i] - layer.clouds[i].width) # a wrapped cloud counts
	check.call(right, "clouds drift right in a right wind")
	beach.wind_dir = -1
	beach.tick(1.0)
	var left: bool = true
	for i: int in start.size():
		left = left and (layer.clouds[i].x < moved[i] or layer.clouds[i].x > moved[i] + layer.clouds[i].width)
	check.call(left, "clouds drift left in a left wind")
	var before: Array = positions(layer)
	beach.tick(0.0)
	check.call(positions(layer) == before, "a frozen beach clock freezes the clouds")
	beach.strength = 0.0
	beach.wind_dir = 0
	beach.tick(2.0)
	check.call(positions(layer) == before, "calm wind leaves the clouds still")
	var gust_bigger: bool = true
	beach.wind_dir = 1
	beach.strength = 0.3
	var calm_x: Array = positions(layer)
	beach.tick(0.5)
	var slow_step: float = absf(layer.clouds[0].x - calm_x[0])
	beach.strength = 0.8
	calm_x = positions(layer)
	beach.tick(0.5)
	gust_bigger = absf(layer.clouds[0].x - calm_x[0]) > slow_step
	check.call(gust_bigger, "a stronger wind moves clouds faster")
	var on_screen: bool = true
	for step: int in 400:
		beach.tick(0.5)
		for cloud: Dictionary in layer.clouds:
			on_screen = on_screen and cloud.x >= -cloud.width and cloud.x <= CloudLayer.SCREEN_W
	check.call(on_screen, "clouds wrap and stay within a screen width of the edges")
	# Bigger clouds are nearer: one second of the same wind moves them further.
	var probe: CloudLayer = CloudLayer.new()
	probe.setup(Config.levels[0].clouds, false)
	probe.update(100.0, 1, 0.5)
	var probe_start: Array = positions(probe)
	probe.update(100.1, 1, 0.5)
	var slow: Array = [INF, INF]
	var fast: Array = [0.0, 0.0]
	for i: int in probe.clouds.size():
		var step: float = fposmod(probe.clouds[i].x - probe_start[i] + 160.0, CloudLayer.SCREEN_W + probe.clouds[i].width) - 160.0
		if probe.clouds[i].depth < slow[0]:
			slow = [probe.clouds[i].depth, step]
		if probe.clouds[i].depth > fast[0]:
			fast = [probe.clouds[i].depth, step]
	check.call(slow[0] < fast[0] and slow[1] < fast[1], "bigger clouds drift faster")
	probe.free()
	beach.free()

	# Dusk (the title screen's sky; no level is a sunset now) tints the clouds, day does not; an empty layout falls back to the default.
	var dusk_beach: BeachBackdrop = BeachBackdrop.new()
	dusk_beach.sunset = true
	dusk_beach.cloud_layout = Config.levels[7].clouds
	host.add_child(dusk_beach)
	dusk_beach.setup([])
	check.call(dusk_beach.background_art.clouds.clouds[0].sprite.material != null, "dusk tints the clouds")
	dusk_beach.free()
	var fallback: BeachBackgroundArt = BeachBackgroundArt.new(false)
	check.call(fallback.clouds.clouds.size() == Config.tuning.clouds.default_layout.size() and fallback.clouds.clouds[0].sprite.material == null, "no layout falls back to the default clouds, untinted by day")
	fallback.free()
