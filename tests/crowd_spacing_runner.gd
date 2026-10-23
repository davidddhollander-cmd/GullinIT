extends Node
var checks: int = 0
var failures: int = 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: "+message)

func _ready() -> void:
	Audio.music.stop()
	preload("res://tests/crowd_spacing_checks.gd").run_checks(self,check)
	print("Crowd spacing: %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)
