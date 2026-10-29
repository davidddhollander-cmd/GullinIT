extends Node
var progress: Dictionary = {}
var wallet: Dictionary = {"feathers": 0}
var options: Dictionary = {"Master": 0.8, "SFX": 0.8, "Music": 0.35, "shake": true, "touch": false, "stats": true, "tips": [], "gull": "herring"}
var _anon_id: String = ""
var save_path: String = "user://save.json"
var save_error: String = ""
# Playtest build: every level is selectable. Set to false to restore normal progression.
var unlock_all: bool = false
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

# Random per-install id for anonymous analytics; created on first use and saved.
func anon_id() -> String:
	if _anon_id.is_empty():
		_anon_id = Crypto.new().generate_random_bytes(16).hex_encode()
		save_progress()
	return _anon_id

func load_progress() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if data is Dictionary:
		if data.get("progress") is Dictionary:
			progress = data.progress
		if data.get("wallet") is Dictionary:
			wallet.merge(data.wallet, true)
		_anon_id = str(data.get("anon_id", ""))
		if data.get("options") is Dictionary:
			options.merge(data.options, true)

func save_progress() -> void:
	var file: FileAccess = FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	if file == null:
		save_error = "Progress could not be saved."
		return
	file.store_string(JSON.stringify({"version": 1, "progress": progress, "wallet": wallet, "options": options, "anon_id": _anon_id}))
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
	var next_step: int = clampi(step, 0, 7)
	if next_step <= int(previous.get("training_step", 0)):
		return
	previous.training_step = next_step
	progress["1"] = previous
	save_progress()

func complete_training() -> void:
	var previous: Dictionary = entry(1)
	previous.training_step = 7
	previous.training_complete = true
	progress["1"] = previous
	save_progress()

func complete_screech_lesson() -> void:
	var previous: Dictionary = entry(2)
	previous.screech_lesson_complete = true
	progress["2"] = previous
	save_progress()

# True (and +1 Feather) only the first time a quest is completed.
func complete_quest(level_id: int, quest_id: String) -> bool:
	var previous: Dictionary = entry(level_id)
	var done: Array = previous.get("quests", [])
	if quest_id in done:
		return false
	done.append(quest_id)
	previous.quests = done
	progress[str(level_id)] = previous
	wallet.feathers = feathers() + 1
	save_progress()
	return true

func set_flag(flag: String) -> void:
	if not bool(progress.get(flag, false)):
		progress[flag] = true
		save_progress()

func feathers() -> int:
	return int(wallet.get("feathers", 0))

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

## Free gulls, bought gulls and testing mode are pickable.
func gull_owned(id: String) -> bool:
	return bool(Config.species.get("unlock_all", false)) or int(Config.species.species[id].get("price", 0)) <= 0 or owns(id)

## Shop purchases (gull species ids and perk ids) live in wallet.owned.
func owns(id: String) -> bool:
	return id in wallet.get("owned", [])

## Spends Feathers; false (nothing changes) if already owned or too poor.
func buy(id: String, price: int) -> bool:
	if owns(id) or feathers() < price:
		return false
	var owned: Array = wallet.get("owned", [])
	owned.append(id)
	wallet.owned = owned
	wallet.feathers = feathers() - price
	save_progress()
	return true

func perk_owned(id: String) -> bool:
	return Config.perks.perks.has(id) and owns(id)

## The equipped perk id, or "" for none. Only owned perks count.
func equipped_perk() -> String:
	var id: String = str(options.get("perk", ""))
	return id if perk_owned(id) else ""

func equip_perk(id: String) -> void:
	options.perk = id if id.is_empty() or perk_owned(id) else ""
	save_progress()

## The shop opens once the Stage 1 boss is beaten.
func shop_open() -> bool:
	return bool(progress.get("stage1_complete", false))

## The last pick if it exists and is owned, else the herring gull.
func chosen_gull() -> String:
	var id: String = str(options.get("gull", "herring"))
	return id if Config.species.species.has(id) and gull_owned(id) else "herring"

const CONTROL_MODES: Array[String] = ["realistic","normal","casual"]

## How hard flying and snatching are: realistic taps every wingbeat, casual pecks dives for you.
func control_mode() -> String:
	var id: String = str(options.get("control_mode","normal"))
	return id if id in CONTROL_MODES else "normal"

func set_control_mode(id: String) -> void:
	options.control_mode = id if id in CONTROL_MODES else "normal"
	save_progress()
