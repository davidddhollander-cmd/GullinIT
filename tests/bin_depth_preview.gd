extends Node2D
## Captures a rear-lane walker behind and a front-lane walker in front of a wheelie bin.
func _ready() -> void:
	var props: Array = [{"type":"wheelie_bin","x":226},{"type":"wheelie_bin","x":326}]
	var backdrop := BeachBackdrop.new()
	add_child(backdrop)
	backdrop.setup(props)
	var spawner := BeachSpawner.new()
	spawner.setup(self,{"seed":3,"id":1,"time_limit":90.0,"awareness_mult":1.0,"props":props,
		"spawns":[{"type":"kiosk_customer","x":200.0},{"type":"kiosk_customer","x":300.0}]})
	for i: int in 2:
		spawner.lane_holds[spawner.targets[i]] = {"y":-14.0 if i == 0 else 12.0,"t":10.0}
	spawner.apply_spacing(3.0)
	var camera := Camera2D.new()
	add_child(camera)
	camera.position = Vector2(270,90)
	call_deferred("_capture")

func _capture() -> void:
	for i: int in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-output")
	get_viewport().get_texture().get_image().save_png("res://test-output/bin-depth.png")
	get_tree().quit()
