extends Node
## Anonymous gameplay events to PostHog. No project key, enabled=false or STATS: OFF => nothing is sent.
const MAX_ATTEMPTS: int = 2
var config: Dictionary = {"enabled": true, "host": "", "project_key": ""}
var queue: Array[Dictionary] = []
var in_flight: bool = false
var input_kind: String = "keyboard_mouse"
# Replaceable in tests: sender.call(url: String, body: String, done: Callable(ok: bool)).
var sender: Callable = _http_send
var _http: HTTPRequest
var _done: Callable

func _ready() -> void:
	var path: String = "res://data/analytics.json"
	if FileAccess.file_exists(path):
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if data is Dictionary:
			config.merge(data, true)

func active() -> bool:
	return bool(config.get("enabled", false)) and not str(config.get("project_key", "")).is_empty() and bool(GameState.options.get("stats", true))

func track(event: String, props: Dictionary = {}) -> void:
	if not active():
		return
	var properties: Dictionary = props.duplicate()
	properties.platform = "web" if OS.has_feature("web") else ("windows" if OS.has_feature("windows") else OS.get_name().to_lower())
	properties.build = str(ProjectSettings.get_setting("application/config/version", "dev"))
	properties.input = input_kind
	properties["$process_person_profile"] = false
	var body: String = JSON.stringify({
		"api_key": config.project_key, "event": event, "distinct_id": GameState.anon_id(),
		"properties": properties, "timestamp": Time.get_datetime_string_from_system(true) + "Z"})
	queue.append({"body": body, "attempts": 0})
	_pump()

func _pump() -> void:
	if in_flight or queue.is_empty():
		return
	in_flight = true
	var url: String = str(config.host).rstrip("/") + "/i/v0/e/"
	sender.call(url, queue[0].body, _finished)

func _finished(ok: bool) -> void:
	in_flight = false
	if not queue.is_empty():
		queue[0].attempts += 1
		if ok or queue[0].attempts >= MAX_ATTEMPTS:
			queue.pop_front()
	_pump()

func _http_send(url: String, body: String, done: Callable) -> void:
	if _http == null:
		_http = HTTPRequest.new()
		_http.timeout = 10.0
		add_child(_http)
		_http.request_completed.connect(func(result: int, code: int, _h: PackedStringArray, _b: PackedByteArray) -> void:
			_done.call(result == HTTPRequest.RESULT_SUCCESS and code >= 200 and code < 300))
	_done = done
	if _http.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, body) != OK:
		done.call(false)
