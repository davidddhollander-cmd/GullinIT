extends Node
const SAVE_VERSION: int = 3
var progress: Dictionary = {}
var wallet: Dictionary = {"feathers": 0}
var options: Dictionary = {"Master": 0.8, "SFX": 0.8, "Music": 0.35, "shake": true, "touch": false, "stats": true, "tips": [], "gull": "herring", "dev_player": false}
var _anon_id: String = ""

## Touch dive steering multiplier (0.3-1.0); old saves lack the key and get the tuning default.
func dive_steer() -> float:
	return clampf(float(options.get("dive_steer", Config.tuning.touch.dive_steer_default)), 0.3, 1.0)

var save_path: String = "user://save.json"
var save_error: String = ""
# Playtest build: every level is selectable. Set to false to restore normal progression.
var unlock_all: bool = true
# Demo build settings from data/demo.json: levels after last_level are always
# locked (even with unlock_all), and feedback_url powers the feedback buttons.
var demo: Dictionary = {"enabled": false, "last_level": 7, "feedback_url": ""}

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
	return bool(demo.get("enabled", false)) and id > int(demo.get("last_level", 7))

func last_playable_level() -> int:
	return int(demo.get("last_level", 7)) if bool(demo.get("enabled", false)) else 7

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
			if int(data.get("version", 1)) < SAVE_VERSION:
				migrate_progress(int(data.get("version", 1)))
		if data.get("wallet") is Dictionary:
			wallet.merge(data.wallet, true)
		_anon_id = str(data.get("anon_id", ""))
		if data.get("options") is Dictionary:
			options.merge(data.options, true)

## Save v2 inserted Squall as level 6 and moved the Sunset Showdown boss to 7: the old level 6 record
## (best, stars, quests) becomes level 7's, so a beaten boss stays beaten. Level 7 also opens for
## anyone who already has a record there (see unlocked), so nobody is locked out of the boss.
## Save v3 added the toddler lesson at Training Day lesson 3 (index 2), so the old "resume at the mug" step 4 is now 5.
## Every other unfinished step keeps its number: anyone past the old swoop simply meets the new lessons in order.
func migrate_progress(from_version: int = 1) -> void:
	var training: Dictionary = entry(1)
	if from_version < 3 and not bool(training.get("training_complete", false)) and int(training.get("training_step", 0)) == 4:
		training.training_step = 5
		progress["1"] = training
	var old: Variant = progress.get("6")
	if from_version < 2 and old is Dictionary and not progress.has("7"):
		var moved: Dictionary = old.duplicate()
		var done: Array = moved.get("quests", [])
		if "l6_random" in done:
			done[done.find("l6_random")] = "l7_random"
		progress["7"] = moved
		progress.erase("6")

func save_progress() -> void:
	var file: FileAccess = FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	if file == null:
		save_error = "Progress could not be saved."
		return
	file.store_string(JSON.stringify({"version": SAVE_VERSION, "progress": progress, "wallet": wallet, "options": options, "anon_id": _anon_id}))
	file.close()
	var error: Error = DirAccess.rename_absolute(save_path + ".tmp", save_path)
	save_error = "" if error == OK else "Progress could not be saved."
	# The page sends page_open before the save can load, so it reads this copy of the player's choice.
	if OS.has_feature("web"):
		var ping: String = "on" if bool(options.get("stats", true)) and not bool(options.get("dev_player", false)) else "off"
		JavaScriptBridge.eval("try { localStorage.setItem('gull_page_ping', '%s') } catch (e) {}" % ping)

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
	var next_step: int = clampi(step, 0, BeachGame.TRAINING_LESSONS)
	if next_step <= int(previous.get("training_step", 0)):
		return
	previous.training_step = next_step
	progress["1"] = previous
	save_progress()

# True (and +1 Feather) only the first time the course is completed.
func complete_training() -> bool:
	var previous: Dictionary = entry(1)
	var first: bool = not bool(previous.get("training_complete", false))
	previous.training_step = BeachGame.TRAINING_LESSONS
	previous.training_complete = true
	progress["1"] = previous
	if first:
		wallet.feathers = feathers() + 1
	save_progress()
	return first

func complete_screech_lesson() -> void:
	var previous: Dictionary = entry(2)
	previous.screech_lesson_complete = true
	progress["2"] = previous
	save_progress()

## The one-time counter tip (the first serving seen on a counter), stored on level 3's entry. Saves from the old counter lesson count as seen.
func counter_tip_seen() -> bool:
	var previous: Dictionary = entry(3)
	return bool(previous.get("counter_tip_seen", false)) or bool(previous.get("counter_lesson_complete", false))

func mark_counter_tip() -> void:
	var previous: Dictionary = entry(3)
	previous.counter_tip_seen = true
	progress["3"] = previous
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
	var own: Dictionary = entry(id)
	if int(own.get("stars", 0)) > 0 or own.has("casual_time"):
		return true # already cleared (e.g. a migrated boss record)
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
	var touch: bool = DisplayServer.is_touchscreen_available() or bool(options.get("touch",false))
	var id: String = str(options.get("control_mode","casual" if touch else "normal")) ## touch players start with auto-peck
	return id if id in CONTROL_MODES else "normal"

func set_control_mode(id: String) -> void:
	options.control_mode = id if id in CONTROL_MODES else "normal"
	save_progress()
