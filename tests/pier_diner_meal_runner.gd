extends Node
var failures: int = 0
var checks: int = 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: "+message)

func _ready() -> void:
	GullInput.register_actions()
	Audio.stop_all()
	Config.tuning.juice.audio = false
	await preload("res://tests/pier_diner_meal_checks.gd").run(self,Callable(self,"check"))
	print("Pier diner meals: %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)
