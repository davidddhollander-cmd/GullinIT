class_name BeachRain
extends Node2D
## Weather scenery for the squall: streaks tied to the camera, slanted by the wind. Not a character.
var intensity: float = 0.0
var slant: float = 0.0
var drops: int = 150
var clock: float = 0.0
const STREAK: Color = Color(0.78, 0.88, 1.0, 0.5)

func tick(delta: float, amount: float, wind_slant: float, camera_x: float) -> void:
	clock += delta
	intensity = amount
	slant = wind_slant
	position = Vector2(camera_x - 160.0, 0.0)
	visible = amount > 0.01
	if visible:
		queue_redraw()

func _draw() -> void:
	for i: int in int(drops * intensity):
		var x: float = fposmod(i * 97.31 + clock * slant * 14.0, 340.0) - 10.0
		var y: float = fposmod(i * 53.17 + clock * 230.0, 190.0) - 6.0
		draw_line(Vector2(x, y).round(), Vector2(x + slant, y + 6.0).round(), STREAK, 1.0)
