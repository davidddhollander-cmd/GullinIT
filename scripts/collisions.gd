class_name BeachCollisions
extends RefCounted
## Swept segment tests keep 260 px/s dives from skipping 8px food.
static func segment_hits(from: Vector2, to: Vector2, point: Vector2, radius: Vector2) -> bool:
	# Scale into unit-circle space before finding the nearest point. Finding the
	# Euclidean nearest point first gives false results for anisotropic ellipses.
	var safe_radius: Vector2 = Vector2(maxf(radius.x,0.001),maxf(radius.y,0.001))
	var scaled_from: Vector2 = (from-point)/safe_radius
	var scaled_to: Vector2 = (to-point)/safe_radius
	var nearest: Vector2 = Geometry2D.get_closest_point_to_segment(Vector2.ZERO,scaled_from,scaled_to)
	return nearest.length_squared() <= 1.0

static func resolve(gull: BeachGull, targets: Array[BeachTarget], props: Array[Dictionary]) -> void:
	# A crash or defensive hit wins the frame; its penalty cannot be followed by
	# a food award from the strike segment that led into the stun.
	if gull.state == BeachGull.State.STUNNED:
		return
	var striking: bool = gull.sweep_state == BeachGull.State.STRIKE
	var walking: bool = gull.grounded_sweep
	if not striking and not walking:
		return
	if striking and not gull.peck_sweep_active:
		return
	var d: Dictionary = Config.tuning.dive
	var angle: float = rad_to_deg(atan2(gull.direction.y,absf(gull.direction.x)))
	if striking:
		for prop: Dictionary in props:
			if prop.type != "umbrella":
				continue
			if angle >= float(d.umbrella_angle) and segment_hits(gull.previous_beak,gull.sweep_beak,Vector2(prop.x,118),Vector2(20,6)):
				gull.pullup()
				return
	for target: BeachTarget in targets:
		if not target.food:
			continue
		if walking and target.kind != "sunbather":
			continue
		# Pier food is protected from steep overhead dives, including edge clipping.
		if striking and target.info.twist == "umbrella" and angle >= float(d.umbrella_angle):
			continue
		if not gull.can_collect_food(target.food_id) or target.leaving or (target.info.twist == "shield" and target.defense > 0):
			continue
		var radius: Vector2 = Vector2(float(d.beak_w),float(d.beak_h))*0.5+target.food_radius()
		if segment_hits(gull.previous_beak,gull.sweep_beak,target.food_position(),radius):
			if target.take(gull):
				gull.consume_peck()
				return
		elif striking and gull.peck_near_target == null and segment_hits(gull.previous_beak,gull.sweep_beak,target.food_position(),radius+Vector2.ONE*float(d.near_miss_margin)):
			gull.peck_near_target = target
	# Keep a grazing contact provisional until the active window ends. A clean
	# contact later in the same peck takes precedence over the knockdown.
	if striking and (gull.peck_time <= 0.0 or gull.state != BeachGull.State.STRIKE) and is_instance_valid(gull.peck_near_target):
		gull.peck_near_target.knock_food(gull)
		gull.consume_peck()
