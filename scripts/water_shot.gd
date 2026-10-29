class_name BeachWaterShot
extends Node2D
## One water-pistol pulse. It flies straight, is swept against every gull each tick and
## expires on the sand or at the end of its range.
var velocity: Vector2 = Vector2.ZERO
var max_range: float = 150.0
var travelled: float = 0.0
var radius: Vector2 = Vector2(10.0,7.0)
var landed: bool = false ## true when the shot ended by touching the sand or running out of range

func setup(from: Vector2, shot_velocity: Vector2, range_px: float, hit_radius: Vector2) -> void:
	position = from
	velocity = shot_velocity
	max_range = range_px
	radius = hit_radius
	z_index = 5

## Advances the shot. Returns the gull it hit, or null. `landed` is set when the shot is spent.
func tick(delta: float, gulls: Array[BeachGull]) -> BeachGull:
	var previous: Vector2 = position
	var step: Vector2 = velocity*delta
	var ground: float = float(Config.tuning.world.ground)
	var next: Vector2 = previous+step
	if next.y >= ground:
		# Clip the last step at the sand so the splash lands on the ground line.
		var along: float = clampf((ground-previous.y)/step.y,0.0,1.0) if step.y > 0.0 else 0.0
		next = previous+step*along
		landed = true
	position = next
	travelled += previous.distance_to(next)
	var hit: BeachGull = BeachCollisions.first_gull_hit(previous,position,gulls,radius)
	if hit != null:
		return hit
	if travelled >= max_range or position.x < 0.0 or position.x > float(Config.tuning.world.width):
		landed = true
	queue_redraw()
	return null

func _draw() -> void:
	var direction: Vector2 = velocity.normalized()
	for i: int in 6:
		var at: Vector2 = -direction*float(i)*3.0
		var drop: Color = Color("e8fbff") if i%2 == 0 else Color("6ec6f0")
		drop.a = 1.0-float(i)*0.14
		draw_rect(Rect2(Vector2(roundf(at.x),roundf(at.y)),Vector2(2,2) if i < 4 else Vector2(1,1)),drop)
