class_name ResultFishSkeleton
extends Node2D

var velocity: Vector2 = Vector2(18, -18)
var launch_position: Vector2

func _ready() -> void:
	launch_position = position
	visible = false
	set_process(false)

func launch() -> void:
	position = launch_position
	velocity = Vector2(18, -18)
	rotation = 0.0
	visible = true
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	if not visible:
		return
	velocity.y += 72.0 * delta
	position += velocity * delta
	rotation += 5.0 * delta
	if position.y > 185.0:
		visible = false
		set_process(false)

func _draw() -> void:
	var bone := Color("e8dfbd")
	var dark := Color("614536")
	draw_line(Vector2(-8, 0), Vector2(7, 0), dark, 3.0)
	draw_line(Vector2(-8, 0), Vector2(7, 0), bone, 1.0)
	for x: int in range(-5, 6, 3):
		draw_line(Vector2(x, 0), Vector2(x - 2, -3), bone, 1.0)
		draw_line(Vector2(x, 0), Vector2(x - 2, 3), bone, 1.0)
	draw_polyline(PackedVector2Array([Vector2(7, 0), Vector2(11, -4), Vector2(11, 4), Vector2(7, 0)]), bone, 1.0)
	draw_circle(Vector2(-9, 0), 2.5, bone)
	draw_circle(Vector2(-9.5, -0.5), 0.7, dark)
