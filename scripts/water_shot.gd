class_name BeachWaterShot
extends Node2D
## One water-pistol pulse. It flies straight, is swept against every gull each tick and
## expires on the sand or at the end of its range.
var velocity: Vector2 = Vector2.ZERO
var max_range: float = 150.0
var travelled: float = 0.0
var radius: Vector2 = Vector2(10.0,7.0)
var landed: bool = false ## true when the shot ended by touching the sand or running out of range
var stream: AnimatedSprite2D

func setup(from: Vector2, shot_velocity: Vector2, range_px: float, hit_radius: Vector2) -> void:
	position = from
	velocity = shot_velocity
	max_range = range_px
	radius = hit_radius
	z_index = 5
	stream = AnimatedSprite2D.new()
	stream.name = "WaterStream"
	stream.sprite_frames = Config.frames("water_stream")
	stream.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	stream.rotation = velocity.angle()
	stream.play(&"travel")
	add_child(stream)

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
	return null
