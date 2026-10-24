class_name BenchRegistry
extends RefCounted
## Per-level seats use the same prop origin and scale as BeachBackdrop.
var seats: Array[Dictionary] = []

func setup(props: Array) -> void:
	seats.clear()
	for prop: Dictionary in props:
		if str(prop.type) != "beach_bench":
			continue
		var scale_factor: float = float(Config.sprites.beach_bench.get("visual_scale",1.0))
		var ground: Vector2 = Vector2(float(prop.x),float(prop.get("y",160.0)))
		var size := Vector2(float(Config.sprites.beach_bench.frame_w),float(Config.sprites.beach_bench.frame_h))*scale_factor
		# Include the walker's foot span so the lane changes before either shoe
		# overlaps the furniture, even when the bench has no seated visitor.
		var walking_bounds := Rect2(ground-Vector2(size.x*0.5+16.0,size.y+4.0),size+Vector2(32.0,6.0))
		seats.append({"ground":ground,"hip":ground+Vector2(0,-10)*scale_factor,"owner":null,"walking_bounds":walking_bounds})

func clear_walking_offset(origin: Vector2, offset: Vector2) -> Vector2:
	var result: Vector2 = offset
	for seat: Dictionary in seats:
		var bounds: Rect2 = seat.walking_bounds
		if bounds.has_point(origin+result):
			# Route through the foreground, never across the seat/backrest.
			result.y = maxf(result.y,bounds.end.y-origin.y)
	return result

func reserve(actor: BeachTarget, bounds: Vector2, reach: float = 220.0) -> Dictionary:
	var best: Dictionary = {}
	var distance: float = reach
	for seat: Dictionary in seats:
		var occupant: WeakRef = seat.owner
		if occupant != null and is_instance_valid(occupant.get_ref()):
			continue
		var x: float = seat.ground.x
		var gap: float = actor.position.distance_to(seat.ground)
		if x < bounds.x or x > bounds.y or gap > distance or absf(actor.position.y-seat.ground.y) > 24.0:
			continue
		best = seat
		distance = gap
	if not best.is_empty():
		best.owner = weakref(actor)
	return best

func claim(seat: Dictionary, actor: BeachTarget) -> void:
	seat.owner = weakref(actor)

func owns(seat: Dictionary, actor: BeachTarget) -> bool:
	return seats.has(seat) and seat.owner != null and seat.owner.get_ref() == actor

func release(actor: BeachTarget) -> void:
	for seat: Dictionary in seats:
		if seat.owner != null and seat.owner.get_ref() == actor:
			seat.owner = null
