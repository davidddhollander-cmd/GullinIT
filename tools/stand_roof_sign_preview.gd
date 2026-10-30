extends Node2D
## Actual production stand assembly, with unrelated wayfinding hidden for review.
class ReviewBeach extends BeachBackdrop:
	func sign_layouts() -> Array[Dictionary]:
		return []

func _ready() -> void:
	Audio.music.stop()
	var beach := ReviewBeach.new()
	add_child(beach)
	beach.setup([{"type":"kiosk","x":86,"customer_x":134},{"type":"hotdog_stand","x":234,"customer_x":186}])
	for stall: FoodStall in beach.stalls:
		stall.sync_pose()
	call_deferred("capture")

func capture() -> void:
	for frame: int in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	image.save_png("res://assets/archive/previews/stand-roof-signs-desktop-v2.png")
	image.get_region(Rect2i(0,256,1280,464)).save_png("res://assets/archive/previews/stand-roof-signs-integrated-v2.png")
	get_window().size = Vector2i(640,360)
	for frame: int in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://assets/archive/previews/stand-roof-signs-phone-v2.png")
	get_tree().quit()
