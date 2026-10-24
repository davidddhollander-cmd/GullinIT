extends Node2D
## Captures the actual level roster and a staged crossing at native game scale.
var backdrop: BeachBackdrop
var camera: Camera2D
var spawner: BeachSpawner = BeachSpawner.new()

func _ready() -> void:
	var level: Dictionary = Config.levels[0]
	backdrop = BeachBackdrop.new()
	add_child(backdrop)
	backdrop.setup(level.props)
	spawner.setup(self,level)
	spawner.apply_spacing(3.0)
	camera = Camera2D.new()
	add_child(camera)
	camera.enabled = true
	call_deferred("_capture")

func _capture() -> void:
	await _save(480.0,"families")
	await _save(800.0,"stands")
	spawner.reset_spacing()
	var mums: Array[BeachTarget] = []
	for target: BeachTarget in spawner.targets:
		if target.kind == "picnic_family":
			mums.append(target)
	if mums.size() >= 2:
		mums[0].position.x = 510.0
		mums[1].position.x = 512.0
	spawner.apply_spacing(3.0)
	await _save(510.0,"crossing")
	get_tree().quit()

func _save(x: float, label: String) -> void:
	camera.position = Vector2(x,90)
	backdrop.camera_x = x
	backdrop.queue_redraw()
	for i: int in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://assets/previews/crowd-spacing-%s-v2.png" % label)
