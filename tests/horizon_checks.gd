extends RefCounted
## Horizon strip: per-level strip id and start x, resting on the sea (bottom on y 93), whole-pixel 0.1x parallax wrapping at 640.

static func backdrop(host: Node, level: int) -> BeachBackdrop:
	var beach: BeachBackdrop = BeachBackdrop.new()
	beach.horizon = Config.levels[level].get("horizon", "")
	beach.overcast = Config.levels[level].get("sky", "") == "overcast"
	beach.horizon_x = float(Config.levels[level].get("horizon_x", BeachBackgroundArt.HORIZON_START_X))
	host.add_child(beach)
	beach.setup([])
	return beach

static func offset(beach: BeachBackdrop, camera_x: float) -> float:
	beach.background_art.update(camera_x, 0.0)
	return beach.background_art.horizon.region_rect.position.x

static func run(host: Node, check: Callable) -> void:
	var l2: BeachBackdrop = backdrop(host, 1)
	var l5: BeachBackdrop = backdrop(host, 4)
	var l7: BeachBackdrop = backdrop(host, 6)
	var l8: BeachBackdrop = backdrop(host, 7)
	var l1: BeachBackdrop = backdrop(host, 0)
	var strip: Sprite2D = l5.background_art.horizon
	check.call(strip != null and strip.position.y + strip.region_rect.size.y == 94.0 and strip.texture.get_height() == 24, "level 5 horizon strip ends on y 93")
	check.call(Config.levels[1].horizon == "headland-hills" and Config.levels[4].horizon == "island-lighthouse" and Config.levels[6].horizon == "headland-lighthouse-blue", "levels 2, 5 and 7 name their strips")
	# L2: plain hills, cut edge on the screen's left edge at the start.
	check.call(l2.background_art.horizon != null and offset(l2, 160.0) == 0.0, "level 2 strip starts at its left edge")
	# L5: island cols 250-393 land at screen x 150-293 at the start, lighthouse (col 328) at 228.
	check.call(offset(l5, 160.0) == 100.0, "level 5 island sits at screen x 150 at the start")
	# L7: mirrored; at the last camera position col 639 is the last pixel on screen and the blue lighthouse sits at its right edge.
	var end_x: float = float(Config.levels[6].world.width) - 160.0
	var at_end: float = offset(l7, end_x)
	check.call(at_end == 320.0 and 639.0 - at_end == 319.0 and 630.0 - at_end >= 0.0, "level 7 lighthouse is on screen at the right end, col 639 at x 319")
	check.call(offset(l7, 160.0) + 319.0 < 630.0, "level 7 lighthouse is off screen at the start")
	# Scroll: 0.1x, whole pixels, wrapping at 640.
	check.call(offset(l5, 1234.0) == 207.0, "horizon scrolls 0.1x in whole pixels")
	check.call(offset(l5, 160.0 + 6300.0) == 90.0 and offset(l5, 160.0 + 6400.0) == 100.0, "horizon offset wraps at 640")
	# Default start x is 90 when a level has no "horizon_x".
	var plain: BeachBackdrop = BeachBackdrop.new()
	plain.horizon = "headland-hills"
	host.add_child(plain)
	plain.setup([])
	check.call(plain.horizon_x == 90.0 and offset(plain, 160.0) == 550.0, "horizon_x defaults to 90")
	check.call(l1.background_art.horizon == null, "a level without the field has no horizon strip")
	# Overcast sky: L4 and L8 grey, others keep the blue.
	var l4: BeachBackdrop = backdrop(host, 3)
	check.call(l4.background_art.top_color == BeachBackgroundArt.SKY_OVERCAST and l8.background_art.top_color == BeachBackgroundArt.SKY_OVERCAST, "levels 4 and 8 load the overcast sky")
	check.call(l5.background_art.top_color == Color8(91, 199, 216) and l2.background_art.sky.texture.get_image().get_pixel(0, 0).is_equal_approx(Color8(91, 199, 216)), "a level without sky keeps #5BC7D8")
	check.call(l4.background_art.sky.texture.get_image().get_pixel(0, 0).is_equal_approx(BeachBackgroundArt.SKY_OVERCAST), "overcast sky strip is grey")
	# L4 cliffs cut edge (strip col 0) is never on screen: screen shows cols o..o+319, col 0 visible only at o == 0 or o > 320.
	var worst_ok: bool = true
	var cam: float = 160.0
	while cam <= float(Config.levels[3].world.width) - 160.0:
		var o: float = offset(l4, cam)
		worst_ok = worst_ok and o >= 1.0 and o <= 320.0
		cam += 10.0
	var o_end: float = offset(l4, float(Config.levels[3].world.width) - 160.0)
	check.call(worst_ok and o_end >= 1.0 and o_end <= 320.0 and Config.levels[7].horizon == "windfarm", "level 4 cliffs col 0 never on screen")
	for beach: BeachBackdrop in [l1, l2, l4, l5, l7, l8, plain]:
		beach.queue_free()
