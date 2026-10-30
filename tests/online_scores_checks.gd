extends RefCounted
## Talo high scores: name cleanup and turning a top-entries reply into result-sign rows.
## No network: tests never configure an access key, so OnlineScores stays offline.

static func _entry(position: int, alias_id: int, identifier: String, score: int) -> Dictionary:
	return {"position": position, "score": score, "playerAlias": {"id": alias_id, "identifier": identifier}}

static func run(_suite: Node, check: Callable) -> void:
	check.call(not OnlineScores.active(), "online scores stay offline in tests")
	check.call(OnlineScores.clean_name("gully 9!xyzzy") == "GULLY9XY", "names keep capitals and digits, eight at most")
	check.call(OnlineScores.display_name("GULLY#a1b2c3") == "GULLY", "the device suffix is hidden on the board")
	var top: Array = []
	for i: int in 6:
		top.append(_entry(i, 100 + i, "P%d#000000" % i, 900 - i * 100))
	var view: Array = OnlineScores.board_view({"topEntries": top, "playerEntries": [_entry(1, 101, "P1#000000", 800)]}, 101)
	check.call(view.size() == 5 and bool(view[1].me) and int(view[4].rank) == 5 and view[0].name == "P0", "a top-five player shows in place")
	view = OnlineScores.board_view({"topEntries": top, "playerEntries": [_entry(11, 7, "ME#abcdef", 120)]}, 7)
	check.call(view.size() == 5 and bool(view[4].me) and int(view[4].rank) == 12 and view[4].name == "ME" and int(view[4].score) == 120, "a lower player takes the last row with their rank")
	check.call(OnlineScores.board_view({}, 7).is_empty(), "a failed request leaves the seeded board")
