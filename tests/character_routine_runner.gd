extends Node
var failures: int = 0
var checks: int = 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: "+message)

func _ready() -> void:
	preload("res://tests/character_routine_checks.gd").run(self,Callable(self,"check"))
	print("Character routines: %d checks, %d failures" % [checks,failures])
	for player: Node in Audio.get_children():
		if player is AudioStreamPlayer:
			player.stop()
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if failures == 0 else 1)
