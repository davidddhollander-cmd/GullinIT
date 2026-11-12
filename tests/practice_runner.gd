extends Node
## Runs only tests/practice_checks.gd: godot --headless --path . tests/practice_checks.tscn
var failures: int = 0
var checks: int = 0
var main: Node

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func settle() -> void:
	for i: int in 3:
		await get_tree().process_frame

func layout(_node: Node) -> void:
	pass

func menu_font_grid(_node: Node) -> void:
	pass

func _ready() -> void:
	GullInput.register_actions()
	Audio.music.stop()
	GameState.save_path = "res://test-output/practice-save.json"
	BeachGame.trainer_cards = false
	main = preload("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	await preload("res://tests/practice_checks.gd").run(self, Callable(self, "check"))
	print("Practice: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)
