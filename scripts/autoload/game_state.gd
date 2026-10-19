extends Node
var progress: Dictionary = {}
var options: Dictionary = {"Master": 0.8, "SFX": 0.8, "Music": 0.35, "shake": true, "touch": false}
var save_path: String = "user://save.json"
var save_error: String = ""
# Playtest build: every level is selectable. Set to false to restore normal progression.
var unlock_all: bool = true
# Demo build settings from data/demo.json: levels after last_level are always
# locked (even with unlock_all), and feedback_url powers the feedback buttons.
var demo: Dictionary = {"enabled": false, "last_level": 6, "feedback_url": ""}

func _ready() -> void:
	load_demo()
	load_progress()

func load_demo(path: String = "res://data/demo.json") -> void:
	if not FileAccess.file_exists(path):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if data is Dictionary:
		demo.merge(data, true)

func demo_locked(id: int) -> bool:
	return bool(demo.get("enabled", false)) and id > int(demo.get("last_level", 6))

func last_playable_level() -> int:
	return int(demo.get("last_level", 6)) if bool(demo.get("enabled", false)) else 6

func feedback_url() -> String:
	return str(demo.get("feedback_url", "")).strip_edges()

func load_progress() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if data is Dictionary:
		if data.get("progress") is Dictionary:
			progress = data.progress
		if data.get("options") is Dictionary:
			options.merge(data.options, true)

func save_progress() -> void:
	var file: FileAccess = FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	if file == null:
		save_error = "Progress could not be saved."
		return
	file.store_string(JSON.stringify({"version": 1, "progress": progress, "options": options}))
	file.close()
	var error: Error = DirAccess.rename_absolute(save_path + ".tmp", save_path)
	save_error = "" if error == OK else "Progress could not be saved."

func record(id: int, score: int, stars: int, casual_time: float = -1.0) -> void:
	var previous: Dictionary = entry(id)
	if casual_time >= 0.0:
		var best_time: float = float(previous.get("casual_time", INF))
		previous.casual_time = minf(best_time, casual_time)
	else:
		previous.best = maxi(int(previous.get("best", 0)), score)
		previous.stars = maxi(int(previous.get("stars", 0)), stars)
	progress[str(id)] = previous
	save_progress()

func save_training_step(step: int) -> void:
	var previous: Dictionary = entry(1)
	if bool(previous.get("training_complete", false)):
		return
	var next_step: int = clampi(step, 0, 6)
	if next_step <= int(previous.get("training_step", 0)):
		return
	previous.training_step = next_step
	progress["1"] = previous
	save_progress()

func complete_training() -> void:
	var previous: Dictionary = entry(1)
	previous.training_step = 6
	previous.training_complete = true
	progress["1"] = previous
	save_progress()

func entry(id: int) -> Dictionary:
	var value: Variant = progress.get(str(id), {})
	return value.duplicate() if value is Dictionary else {}

func unlocked(id: int) -> bool:
	if demo_locked(id):
		return false
	if id == 1 or unlock_all:
		return true
	var previous: Dictionary = entry(id - 1)
	return int(previous.get("stars", 0)) > 0 or previous.has("casual_time") or (id == 2 and bool(previous.get("training_complete", false)))
