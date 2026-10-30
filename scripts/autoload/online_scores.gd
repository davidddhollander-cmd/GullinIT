extends Node
## Online high scores through Talo (trytalo.com): one leaderboard per level, internal name
## "<board_prefix><level id>", sorted descending with unique entries. No access key, or a
## headless/test run => offline, and the result sign keeps its seeded board.
const API: String = "https://api.trytalo.com/v1"
const NAME_LENGTH: int = 8
var config: Dictionary = {"enabled": true, "access_key": "", "board_prefix": "level-"}
var _alias_id: int = 0

func _ready() -> void:
	var path: String = "res://data/talo.json"
	if FileAccess.file_exists(path):
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if data is Dictionary:
			config.merge(data, true)
	if DisplayServer.get_name() == "headless" or Array(OS.get_cmdline_args()).any(func(a: String) -> bool: return a.trim_prefix("res://").begins_with("tests/")):
		config.enabled = false

func active() -> bool:
	return bool(config.get("enabled", false)) and not str(config.get("access_key", "")).is_empty()

func player_name() -> String:
	return str(GameState.options.get("player_name", ""))

func set_player_name(text: String) -> void:
	GameState.options.player_name = clean_name(text)
	GameState.save_progress()
	_alias_id = 0

# Board names use the 8 px GullPixel grid: capitals and digits, at most eight.
static func clean_name(text: String) -> String:
	var out: String = ""
	for c: String in text.to_upper():
		if (c >= "A" and c <= "Z") or (c >= "0" and c <= "9"):
			out += c
	return out.left(NAME_LENGTH)

# The device id keeps two players who pick the same name apart; the board shows the name only.
func identifier() -> String:
	return player_name() + "#" + GameState.anon_id().left(6)

static func display_name(talo_identifier: String) -> String:
	return talo_identifier.get_slice("#", 0)

# Posts the player's best for the level, then calls done(entries) with the board view
# (top entries plus the player's own rank) for ResultBoard.set_high_scores; [] on failure.
# done is skipped when its object was freed meanwhile (the player left the sign).
func submit(level_id: int, score: int, done: Callable) -> void:
	var entries: Array = []
	if active() and not player_name().is_empty():
		if _alias_id == 0:
			var who: Dictionary = await _call(HTTPClient.METHOD_GET, "/players/identify?service=username&identifier=" + identifier().uri_encode())
			_alias_id = int(who.get("alias", {}).get("id", 0))
		if _alias_id != 0:
			var board: String = "%s%d" % [config.board_prefix, level_id]
			if score > 0:
				await _call(HTTPClient.METHOD_POST, "/leaderboards/%s/entries" % board, {"score": score})
			var top: Dictionary = await _call(HTTPClient.METHOD_GET, "/leaderboards/%s/entries/top?limit=%d" % [board, ResultBoard.SCORE_SLOTS])
			entries = board_view(top, _alias_id)
	if done.is_valid():
		done.call(entries)

# Talo's top-entries reply as ResultBoard rows: the top five, or the top four plus the
# player's own entry when they rank lower.
static func board_view(top: Dictionary, alias_id: int, slots: int = ResultBoard.SCORE_SLOTS) -> Array:
	var view: Array = []
	var mine_shown: bool = false
	for entry: Variant in top.get("topEntries", []):
		if view.size() >= slots:
			break
		var row: Dictionary = _row(entry, alias_id)
		mine_shown = mine_shown or bool(row.me)
		view.append(row)
	var own: Array = top.get("playerEntries", [])
	if not mine_shown and not own.is_empty() and view.size() == slots:
		view[slots - 1] = _row(own[0], alias_id)
	return view

static func _row(entry: Dictionary, alias_id: int) -> Dictionary:
	var alias: Dictionary = entry.get("playerAlias", {})
	return {"name": display_name(str(alias.get("identifier", ""))), "score": int(entry.get("score", 0)),
		"rank": int(entry.get("position", 0)) + 1, "me": int(alias.get("id", -1)) == alias_id}

func _call(method: int, path: String, body: Variant = null) -> Dictionary:
	var http: HTTPRequest = HTTPRequest.new()
	http.timeout = 8.0
	add_child(http)
	var headers: PackedStringArray = ["Authorization: Bearer " + str(config.access_key), "Content-Type: application/json"]
	if _alias_id != 0:
		headers.append("x-talo-alias: %d" % _alias_id)
	if OS.has_feature("editor"):
		headers.append("x-talo-dev-build: 1")  # editor playtests are filtered out of the dashboard's real players
	var reply: Array = [HTTPRequest.RESULT_CANT_CONNECT, 0, PackedStringArray(), PackedByteArray()]
	if http.request(API + path, headers, method, "" if body == null else JSON.stringify(body)) == OK:
		reply = await http.request_completed
	http.queue_free()
	if int(reply[0]) != HTTPRequest.RESULT_SUCCESS or int(reply[1]) >= 300:
		push_warning("Talo %s failed: result %d, HTTP %d" % [path.get_slice("?", 0), reply[0], reply[1]])
		return {}
	var data: Variant = JSON.parse_string((reply[3] as PackedByteArray).get_string_from_utf8())
	return data if data is Dictionary else {}
