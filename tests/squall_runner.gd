extends Node
## Runs only tests/squall_checks.gd: godot --headless --path . tests/squall_checks.tscn
var failures: int = 0
var checks: int = 0
var main: Node

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func _ready() -> void:
	GullInput.register_actions()
	Audio.music.stop()
	GameState.save_path = "res://test-output/squall-save.json"
	BeachGame.trainer_cards = false
	main = preload("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	await preload("res://tests/squall_checks.gd").run(self, Callable(self, "check"))
	print("Squall: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)
