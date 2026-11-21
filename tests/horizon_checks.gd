extends RefCounted
## Horizon strip: level 5 has the headland resting on the sea (bottom on y 93), others none, whole-pixel parallax wrapping at 640.

static func run(host: Node, check: Callable) -> void:
	var with: BeachBackdrop = BeachBackdrop.new()
	with.horizon = Config.levels[4].get("horizon", "")
	host.add_child(with)
	with.setup([])
	var strip: Sprite2D = with.background_art.horizon
	check.call(strip != null and strip.position.y + strip.region_rect.size.y == 94.0 and strip.texture.get_height() == 24, "level 5 horizon strip ends on y 93")
	with.background_art.update(160.0, 0.0)
	# Region starts 90 px before strip x 0 (wrapped), so strip col 6 lands at screen x 96: the lighthouse is on screen.
	check.call(strip.region_rect.position.x == 550.0, "horizon strip starts 90 px in from the left edge at the level start")
	with.background_art.update(1234.0, 0.0)
	check.call(strip.region_rect.position.x == 17.0, "horizon scrolls 0.1x in whole pixels")
	with.background_art.update(160.0 + 300.0, 0.0) # 30 - 90 = -60 wraps to 580
	check.call(strip.region_rect.position.x == 580.0, "horizon offset wraps below 0")
	with.background_art.update(160.0 + 7300.0, 0.0) # 730 - 90 = 640 wraps to 0
	check.call(strip.region_rect.position.x == 0.0, "horizon offset wraps at 640")
	var without: BeachBackdrop = BeachBackdrop.new()
	without.horizon = Config.levels[7].get("horizon", "")
	host.add_child(without)
	without.setup([])
	check.call(without.background_art.horizon == null, "a level without the field has no horizon strip")
	with.queue_free()
	without.queue_free()
