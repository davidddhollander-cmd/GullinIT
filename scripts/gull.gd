class_name BeachGull
extends Node2D
## Shared flight model for the player and rivals; swept beak collisions live in Game.
signal gull_stunned
signal dive_started
signal stun_ignored
signal ground_crashed
signal peck_started
signal sand_landed(at: Vector2)
signal sand_departed(at: Vector2)
signal tumble_feathers(at: Vector2, impulse: Vector2, amount: int)
enum State { GLIDE, WINDUP, STRIKE, GROUNDED, STUNNED }
var state: State = State.GLIDE
var digestion: GullDigestion = GullDigestion.new()
var digestion_enabled: bool = false

func can_collect_food(id: String) -> bool:
	return not digestion_enabled or digestion.can_collect(id)
var velocity: Vector2 = Vector2.ZERO
var aim: Vector2 = Vector2.ZERO
var previous_beak: Vector2
var sweep_beak: Vector2
var sweep_state: State = State.GLIDE
var grounded_sweep: bool = false
var peck_used: bool = false
var peck_time: float = 0.0
var peck_sweep_active: bool = false
var peck_near_target: BeachTarget
var direction: Vector2 = Vector2.DOWN
var facing: float = 1.0
var timer: float = 0.0
var cooldown: float = 0.0
var invulnerable: float = 0.0
var climb: bool = false
var speed_factor: float = 1.0
var rival: bool = false
# Rival that only goes for loose food (Gary): never touches food a person holds.
var loose_only: bool = false
## Empty uses the role default; any species can be used by either role.
var species: String = ""
var art_id: String = "player_gull"
var art_entry: Dictionary = {}
var art_event: StringName = &""
var art_event_left: float = 0.0
var rival_name: String = "RIVAL"
var rival_tint: Color = Color("a5c7e6")
var rival_label: Label
var rival_badge: ColorRect
var upwind: bool = false
## Player-only species stats (data/species.json); rivals keep their profile tuning.
var dive_mult: float = 1.0
var stun_shield: int = 0 ## Strong skull: stuns still to shrug off
var wind_mult: float = 1.0
var stun_mult: float = 1.0
var shoves: bool = false
var dive_speed: float = 0.0
var walk_phase: float = 0.0
var coasting: bool = false
var coast_speed: float = 0.0
var wind_force: float = 0.0
var stroke_cooldown: float = 0.0
var stroke_left: float = 0.0
var stroke_started: bool = false
var sprite: AnimatedSprite2D
var carry_source: Callable ## rivals: returns the held food id ("" when empty); the player reads its own belly
var carry_food: String = ""
var carry_body: AnimatedSprite2D ## generated beak-carry frames, shown instead of `sprite` while food is held
var carry_item: Sprite2D
var carry_glint: Sprite2D
var mug_cue: bool = false ## rivals: player is in mug range, so the held food shines
var carry_beak: AnimatedSprite2D ## generated upper-beak overlay, drawn over the food
static var carry_frames_cache: Dictionary = {}
static var carry_art: Dictionary = {} ## `carry` blocks from data/gull_art.json, by art id

static func carry_for(id: String) -> Dictionary:
	if carry_art.is_empty():
		var all: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/gull_art.json"))
		for key: String in all:
			carry_art[key] = all[key].get("carry", {})
	return carry_art.get(id, {})
var detailed_art: bool = false
var art_scale: float = 1.0
var body_scale: float = 1.0 ## boss-sized rivals: multiplies the species art scale
var perch_surfaces: Array[Dictionary] = []
var support: Dictionary = {}
var departing_perch: Dictionary = {}
var tumble_angle: float = 0.0
var tumble_spin: float = 0.0
var tumble_elapsed: float = 0.0
var tumble_shed: float = 0.0
var tumble_bounced: bool = false
var tumble_recovery_angle: float = 0.0
var tumble_recovering: bool = false

func setup_perches(props: Array) -> void:
	perch_surfaces.clear()
	support = {}
	departing_perch = {}
	for prop: Dictionary in props:
		var base: float = float(prop.get("y",160))
		match str(prop.type):
			"kiosk", "hotdog_stand":
				perch_surfaces.append({"x":float(prop.x),"y":base-43.0,"half_width":23.0,"pole":false,"prop_type":str(prop.type)})
			"tower":
				perch_surfaces.append({"x":float(prop.x),"y":base-58.0,"half_width":16.0,"pole":false,"prop_type":str(prop.type)})
			"beach_lamp":
				var lamp: Dictionary = Config.sprites.beach_lamp
				var lamp_scale: float = float(lamp.get("visual_scale",1.0))
				perch_surfaces.append({"x":float(prop.x)+float(lamp.get("perch_offset_x",0.0))*lamp_scale,"y":base-float(lamp.frame_h)*lamp_scale+float(lamp.get("perch_inset_y",2.0))*lamp_scale,"half_width":3.0,"pole":true,"prop_type":str(prop.type)})
			BeachBackdrop.WHEELIE_BIN_TYPE:
				var definition: Dictionary = Config.sprites.wheelie_bin
				var height: float = float(definition.frame_h) * float(definition.get("visual_scale",1.0))
				var bin_scale: float = float(definition.get("visual_scale",1.0))
				perch_surfaces.append({"x":float(prop.x),"y":base-height+BeachBackdrop.WHEELIE_BIN_LID_INSET*bin_scale,"half_width":BeachBackdrop.WHEELIE_BIN_HALF_WIDTH*bin_scale,"pole":false,"prop_type":str(prop.type)})

func is_supported_by(prop_type: String, at_x: float) -> bool:
	return state == State.GROUNDED and not support.is_empty() and str(support.get("prop_type","")) == prop_type and absf(float(support.get("x",INF))-at_x) < 0.1

func landing_perch() -> Dictionary:
	if not landing_aim():
		return {}
	var nearest: Dictionary = {}
	for surface: Dictionary in perch_surfaces:
		if position.y+float(Config.tuning.flight.feet_offset) > float(surface.y)+0.1:
			continue
		if absf(aim.x-float(surface.x)) > float(surface.half_width)+3.0 or aim.y < float(surface.y)-10.0:
			continue
		if nearest.is_empty() or float(surface.y)<float(nearest.y):
			nearest = surface
	return nearest

func resolve_perches(before: Vector2, started: State) -> void:
	# Swoops pass over rooftops and poles; only ordinary flight lands on them.
	if started in [State.WINDUP, State.STRIKE] or not support.is_empty() or state == State.STUNNED or position.y <= before.y:
		return
	var offset: Vector2 = Vector2(0,float(Config.tuning.flight.feet_offset))
	var first: Dictionary = {}
	var first_t: float = 2.0
	for surface: Dictionary in perch_surfaces:
		if surface == departing_perch:
			continue
		var t: float = (float(surface.y)-before.y-offset.y)/(position.y-before.y)
		if t < 0 or t > 1:
			continue
		var hit_x: float = lerpf(before.x,position.x,t)+offset.x
		if absf(hit_x-float(surface.x))<=float(surface.half_width) and t<first_t:
			first = surface
			first_t = t
	if first.is_empty():
		return
	# Resolve the first crossed top even when a fast frame passes several surfaces.
	position.x = clampf(lerpf(before.x,position.x,first_t),float(first.x)-float(first.half_width),float(first.x)+float(first.half_width))
	position.y = float(first.y)-float(Config.tuning.flight.feet_offset)
	if velocity.length()<=float(Config.tuning.flight.landing_speed):
		support = first
		if bool(first.pole):
			position.x = first.x
			velocity.x = 0
		land()
	else:
		# A quick shallow pass bounces back into flight instead of snapping to rest.
		velocity.y = -minf(absf(velocity.y),35.0)
		pullup()

func _ready() -> void:
	sprite = AnimatedSprite2D.new()
	add_child(sprite)
	carry_body = AnimatedSprite2D.new()
	carry_item = Sprite2D.new()
	carry_glint = Sprite2D.new()
	carry_beak = AnimatedSprite2D.new()
	for node: CanvasItem in [carry_body, carry_item, carry_glint, carry_beak]:
		node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		node.visible = false
		add_child(node)
	if rival:
		rival_badge = ColorRect.new()
		rival_badge.position = Vector2(-22,-30)
		rival_badge.size = Vector2(44,10)
		rival_badge.color = Color("183b4e")
		rival_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(rival_badge)
		rival_label = Label.new()
		rival_label.position = Vector2(-22,-30)
		rival_label.size = Vector2(44,10)
		rival_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rival_label.add_theme_font_override("font",preload("res://assets/fonts/gull_pixel.fnt"))
		rival_label.add_theme_font_size_override("font_size",8)
		add_child(rival_label)
	refresh_art()
	Config.reloaded.connect(refresh_art)
	previous_beak = beak()
	sweep_beak = previous_beak

func refresh_art() -> void:
	art_id = "rival_gull" if rival else "player_gull"
	var species_id: String = "gull_" + species.replace("-","_")
	if not species.is_empty() and Config.sprites.has(species_id):
		art_id = species_id
	art_entry = Config.sprites[art_id]
	detailed_art = art_entry.has("regions") or bool(art_entry.get("native_alpha",false))
	art_scale = float(art_entry.get("visual_scale",1.0)) * body_scale
	sprite.sprite_frames = Config.frames(art_id)
	sprite.scale = Vector2.ONE * art_scale
	sprite.material = null
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if rival:
		if is_instance_valid(rival_label):
			rival_label.text = rival_name.to_upper()
			rival_label.add_theme_color_override("font_color",Color("fff4da"))
	if detailed_art and not bool(art_entry.get("native_alpha",false)):
		var cutout: ShaderMaterial = ShaderMaterial.new()
		cutout.shader = preload("res://assets/shaders/rival_tint.gdshader") if rival else preload("res://assets/shaders/gull_cutout.gdshader")
		if rival:
			cutout.set_shader_parameter("feather_tint",rival_tint)
		sprite.material = cutout
	sprite.play(&"glide")
	art_event = &""
	art_event_left = 0.0

func species_stats() -> Dictionary:
	return Config.species.get("species",{}).get(species,{})

func species_speed() -> float:
	# Rivals keep their tuned pre-picker speeds (rival_flight); the player gets the picked species' flight.
	return float(species_stats().get("rival_flight" if rival else "flight",1.0))

## The player's species changes more than flight: dive speed, wind push, stun length and shoving.
func apply_species_stats() -> void:
	var s: Dictionary = species_stats()
	dive_mult = float(s.get("dive",1.0))
	wind_mult = float(s.get("wind",1.0))
	stun_mult = float(s.get("stun",1.0))
	shoves = bool(s.get("shove",false))

func show_ground_peck() -> void:
	art_event = &"peck"
	art_event_left = 0.14

func ground_y() -> float:
	if not support.is_empty():
		return float(support.y)-float(Config.tuning.flight.feet_offset)
	return float(Config.tuning.world.ground) - float(Config.tuning.flight.feet_offset)

func landing_aim() -> bool:
	if state != State.GLIDE or climb:
		return false
	var offset: Vector2 = aim-position
	var f: Dictionary = Config.tuning.flight
	return offset.y > float(f.aim_deadzone) and absf(offset.x) <= float(f.landing_aim_width) and absf(offset.x) <= offset.y * float(f.landing_aim_ratio)

func beak() -> Vector2:
	return beak_for_state(state)

func beak_for_state(for_state: State) -> Vector2:
	if for_state == State.STRIKE:
		return position + direction * float(Config.tuning.dive.beak_offset)
	if for_state == State.GROUNDED:
		# The detailed standing/walking art carries its head above the body origin.
		return position + Vector2(facing * float(Config.tuning.dive.beak_offset), float(art_entry.get("ground_beak_y",-5)))
	return position + Vector2(facing * float(Config.tuning.dive.beak_offset), 2)

func dive(wind_dir: int) -> void:
	if state == State.GROUNDED and not support.is_empty() and cooldown <= 0.0:
		# Deliberately drop from the current one-way surface without recatching it.
		departing_perch = support
		support = {}
		state = State.GLIDE
	if state != State.GLIDE or cooldown > 0.0:
		return
	direction = (aim - position).normalized()
	if direction.length_squared() < 0.5:
		direction = Vector2(facing, 1).normalized()
	dive_speed = maxf(float(Config.tuning.dive.start_speed), velocity.length())
	coasting = false
	upwind = wind_dir != 0 and direction.x * wind_dir < 0
	state = State.WINDUP
	peck_used = false
	peck_time = 0.0
	peck_sweep_active = false
	peck_near_target = null
	timer = Config.tuning.dive.windup
	dive_started.emit()

func attempt_peck() -> bool:
	if state != State.STRIKE or peck_used:
		return false
	peck_used = true
	peck_time = float(Config.tuning.dive.peck_window)
	peck_started.emit()
	return true

func consume_peck() -> void:
	peck_time = 0.0
	peck_sweep_active = false
	peck_near_target = null

func tick(delta: float, wind_dir: int, strength: float) -> void:
	art_event_left = maxf(0.0,art_event_left-delta)
	var f: Dictionary = Config.tuning.flight
	var d: Dictionary = Config.tuning.dive
	var w: Dictionary = Config.tuning.wind
	var started_state: State = state
	peck_sweep_active = started_state == State.STRIKE and peck_time > 0.0
	peck_time = maxf(0.0,peck_time-delta)
	var before: Vector2 = position
	if not departing_perch.is_empty() and (position.y>float(departing_perch.y)+12.0 or absf(position.x-float(departing_perch.x))>float(departing_perch.half_width)+12.0):
		departing_perch = {}
	var perch_target: Dictionary = landing_perch()
	wind_force = move_toward(wind_force, wind_dir * strength, float(w.response) * delta)
	previous_beak = beak()
	timer -= delta
	cooldown = maxf(0.0, cooldown - delta)
	stroke_cooldown = maxf(-delta, stroke_cooldown - delta)
	stroke_started = false
	if state != State.GLIDE:
		stroke_left = 0.0
	invulnerable = maxf(0.0, invulnerable - delta)
	sprite.modulate.a = 0.5 if invulnerable > 0.0 and int(invulnerable * 12) % 2 == 0 else 1.0
	sprite.rotation = 0.0
	sprite.scale = Vector2.ONE
	sprite.speed_scale = 1.0
	match state:
		State.GLIDE, State.GROUNDED:
			var on_ground: bool = state == State.GROUNDED
			if on_ground and climb:
				if support.is_empty():
					sand_departed.emit(position + Vector2(0, float(f.feet_offset)))
				support = {}
				state = State.GLIDE
				on_ground = false
				velocity.y = -float(f.takeoff_speed)
				# The launch is the first wingbeat, so no second boost follows at once.
				stroke_cooldown = float(f.stroke_interval)
			if climb:
				coasting = false
			var side: float = signf(aim.x - position.x) if absf(aim.x - position.x) > float(f.aim_deadzone) else 0.0
			var max_speed: float = float(f.ground_speed) if on_ground else float(f.max_speed) * speed_factor * species_speed()
			if coasting and not on_ground:
				coast_speed = move_toward(coast_speed,0,float(f.coast_drag)*delta)
				max_speed = coast_speed
			var descending: bool = landing_aim()
			var horizontal_target: float = side * max_speed
			if on_ground and not support.is_empty() and bool(support.pole):
				horizontal_target = 0
				velocity.x = 0
			if descending:
				# Brake toward the landing point, gently steering against the normal wind drift.
				var landing_x: float = float(perch_target.x) if not perch_target.is_empty() and bool(perch_target.pole) else aim.x
				horizontal_target = clampf((landing_x-position.x)*float(f.landing_alignment),-float(f.landing_side_speed),float(f.landing_side_speed)) - wind_force*wind_mult*float(w.drift)
			velocity.x = move_toward(velocity.x, horizontal_target, float(f.acceleration) * delta)
			if on_ground:
				velocity.y = 0
				walk_phase += absf(velocity.x) * delta * 0.55
			elif descending:
				var landing_y: float = float(perch_target.y)-float(f.feet_offset) if not perch_target.is_empty() else ground_y()
				var sink_speed: float = minf(float(f.landing_speed),float(f.landing_touchdown_speed) + maxf(0,landing_y-position.y)*float(f.landing_slowdown))
				velocity.y = move_toward(velocity.y,sink_speed,float(f.landing_acceleration)*delta)
			else:
				# Wind soaring eases gravity and the sink cap; it never reverses them.
				var lift: float = wind_lift()
				var gravity: float = float(f.gravity) * (1.0 - float(w.lift_gravity_cut) * lift)
				var sink_cap: float = float(f.max_descent) * (1.0 - float(w.lift_descent_cut) * lift)
				var stroke: float = wingbeat(delta)
				# Preserve upward momentum across the end of a swoop; passive drag bleeds fast descent.
				if velocity.y < -float(f.max_climb):
					velocity.y = move_toward(velocity.y,-float(f.max_climb),gravity*delta)
				elif velocity.y > sink_cap:
					velocity.y = move_toward(velocity.y,sink_cap,float(f.descent_drag)*delta) - stroke*delta
				else:
					velocity.y = clampf(velocity.y + (gravity-stroke)*delta,-float(f.max_climb),sink_cap)
			position += velocity * delta
			if on_ground and not support.is_empty() and absf(position.x-float(support.x))>float(support.half_width):
				support = {}
				state = State.GLIDE
			if position.y >= ground_y():
				land()
			if absf(velocity.x) > 1:
				facing = signf(velocity.x)
			sprite.play(&"climb" if climb else &"glide")
			sprite.speed_scale = climb_loop_time() / float(f.stroke_interval) if climb else 1.0
			if stroke_started:
				sprite.frame = 0
		State.WINDUP:
			velocity.y = minf(velocity.y + float(f.gravity)*delta,float(f.max_descent))
			position += velocity * delta
			sprite.play(&"dive_windup")
			if not bool(art_entry.get("native_alpha",false)):
				sprite.scale = Vector2(1.15, 0.75)
			if position.y >= ground_y():
				land()
			elif timer <= 0:
				var launch_offset: Vector2 = aim-position
				if launch_offset.length() > float(d.aim_deadzone):
					direction = launch_offset.normalized()
				state = State.STRIKE
		State.STRIKE:
			var offset: Vector2 = aim - position
			if offset.length() > float(d.aim_deadzone):
				direction = Vector2.from_angle(rotate_toward(direction.angle(), offset.angle(), float(d.turn_rate) * delta))
			# Climbing spends momentum faster than descending builds it.
			# A tailwind pushes the swoop along; a headwind drags it in proportion to speed, mostly on shallow angles.
			var tail: float = tailwind(direction.x)
			var slope_force: float = dive_mult * float(d.acceleration) * maxf(direction.y, 0) + float(d.uphill_deceleration) * minf(direction.y, 0) + float(w.dive_tailwind) * maxf(tail,0)
			var drag: float = float(d.drag) + float(d.uphill_drag) * maxf(-direction.y,0) + (float(w.dive_drag) * wind_lift() + float(w.dive_headwind_drag) * maxf(-tail,0) * absf(direction.x)) * dive_speed
			dive_speed = clampf(dive_speed + (slope_force - drag) * delta, 0, float(d.max_speed) * dive_mult)
			velocity = direction * dive_speed
			position += velocity * delta
			upwind = direction.x * wind_force < 0
			if absf(direction.x) > 0.05:
				facing = signf(direction.x)
			sprite.play(&"snatch" if peck_time > 0.0 else &"dive")
			sprite.rotation = direction.angle() if facing > 0 else direction.angle() - PI
			var nose_down: bool = direction.y * float(d.beak_offset) > float(f.feet_offset)
			if nose_down and beak().y >= float(Config.tuning.world.ground) and velocity.y > 0:
				if crash_risk() >= 1.0:
					position.y = ground_y()
					begin_tumble()
					ground_crashed.emit()
				else:
					land()
			elif position.y >= ground_y():
				land()
			elif climb or (direction.y < 0 and dive_speed <= float(d.exit_speed)):
				pullup()
		State.STUNNED:
			tick_tumble(delta)
	if state in [State.GLIDE,State.WINDUP,State.STRIKE]:
		position.x += wind_force * wind_mult * float(w.drift) * delta
	if position.y < float(f.min_y):
		position.y = f.min_y
		velocity.y = maxf(velocity.y, 0)
		if state == State.STRIKE:
			pullup()
	position.x = clampf(position.x, 12, float(Config.tuning.world.width) - 12)
	resolve_perches(before,started_state)
	# Resolve against the geometry used during movement, even if landing or pull-up
	# changed state before Game runs its collision pass.
	sweep_state = started_state
	sweep_beak = beak_for_state(started_state)
	grounded_sweep = started_state == State.GROUNDED and state == State.GROUNDED
	sprite.flip_h = facing < 0
	sprite.visible = detailed_art or state != State.GROUNDED
	if detailed_art:
		sprite.scale *= art_scale
		if state == State.GROUNDED:
			if absf(velocity.x) > 1:
				# Tie footfalls to distance, so feet stop immediately at rest.
				sprite.animation = &"walk"
				sprite.pause()
				var count: int = sprite.sprite_frames.get_frame_count(&"walk")
				sprite.frame = int(walk_phase / TAU * count) % count
				sprite.flip_h = (facing < 0) != bool(art_entry.animations.walk.get("source_left",false))
			else:
				sprite.play(&"idle")
		if art_event_left > 0.0 and sprite.sprite_frames.has_animation(art_event):
			if (state == State.GROUNDED and art_event in [&"landing",&"peck"]) or (state == State.GLIDE and not climb and art_event == &"pullup"):
				sprite.play(art_event)
		if art_entry.has("frame_beaks"):
			# Production sheets use source-space bill x=20 and sole y=12.
			# Resize around these contact anchors, keeping feet on sand/lids and
			# the airborne bill at the existing collision point through dive rotation.
			var offset := Vector2((float(d.beak_offset)-20.0*art_scale)*facing,0)
			if state == State.GROUNDED:
				offset.y = float(f.feet_offset)-12.0*art_scale
			elif state != State.STRIKE:
				offset.y = 2.0-4.0*art_scale
			sprite.position = offset.rotated(sprite.rotation)
			if state == State.STUNNED:
				# Spin around the body, without the flight bill alignment orbit.
				sprite.position = Vector2.ZERO
		if rival and is_instance_valid(rival_badge) and art_entry.has("frame_bounds"):
			# Keep the badge above raised wings and rotated dive silhouettes.
			var source_index: int = art_entry.animations[String(sprite.animation)].frames[sprite.frame]
			var bounds: Array = art_entry.frame_bounds[source_index]
			var top: float = -18.0
			for corner: Vector2 in [Vector2(bounds[0],bounds[1]),Vector2(bounds[0]+bounds[2],bounds[1]),Vector2(bounds[0],bounds[1]+bounds[3]),Vector2(bounds[0]+bounds[2],bounds[1]+bounds[3])]:
				var point: Vector2 = (corner-Vector2(art_entry.frame_w,art_entry.frame_h)*.5)*sprite.scale
				if sprite.flip_h:
					point.x = -point.x
				top = minf(top,(point.rotated(sprite.rotation)+sprite.position).y)
			rival_badge.position.y = top-12
			rival_label.position.y = top-12
	sync_carry()
	queue_redraw()

func _process(_delta: float) -> void:
	sync_carry() # food can be swallowed, mugged or dropped after tick(): switch art on the same rendered frame

static func carry_frames(id: String, entry: Dictionary, overlay: bool) -> SpriteFrames:
	var key: String = id + ("/beak" if overlay else "")
	if not carry_frames_cache.has(key):
		var carry: Dictionary = carry_for(id)
		var texture: Texture2D = load(str(carry.overlay_file if overlay else carry.file)) as Texture2D
		var result: SpriteFrames = SpriteFrames.new()
		result.remove_animation(&"default")
		for clip: String in carry.beak_anchors:
			result.add_animation(clip)
			result.set_animation_speed(clip, float(entry.animations[clip].fps))
			result.set_animation_loop(clip, true)
			for index: int in carry.overlay_frames[clip]:
				var atlas: AtlasTexture = AtlasTexture.new()
				atlas.atlas = texture
				atlas.region = Rect2(index * int(carry.frame_w), 0, carry.frame_w, carry.frame_h)
				atlas.filter_clip = true
				result.add_frame(clip, atlas)
		carry_frames_cache[key] = result
	return carry_frames_cache[key]

func held_food_id() -> String:
	if rival:
		return str(carry_source.call()) if carry_source.is_valid() else ""
	if digestion_enabled and digestion.rest <= 0 and not digestion.snacks.is_empty():
		return str(digestion.snacks[0].id)
	return ""

## Swap to the beak-carry art while food is held: same transform as `sprite`, food at the
## per-frame beak anchor, upper beak on top. Falls back to the normal art when food is gone.
func sync_carry() -> void:
	carry_food = held_food_id() if is_instance_valid(sprite) else ""
	var active: bool = not carry_food.is_empty() and not carry_for(art_id).is_empty() and Config.foods.has(carry_food)
	if not is_instance_valid(carry_body):
		return
	if not active:
		carry_body.visible = false
		carry_item.visible = false
		carry_glint.visible = false
		carry_beak.visible = false
		if is_instance_valid(sprite) and detailed_art and sprite.sprite_frames != null:
			sprite.visible = true
		return
	var clip: StringName = &"glide"
	var local: int = 0
	if state == State.GROUNDED:
		clip = &"walk"
		local = 7 # idle pose
		if absf(velocity.x) > 1:
			local = int(walk_phase / TAU * 8) % 8
	elif climb:
		clip = &"fly"
		local = sprite.frame % 4 if sprite.animation == &"climb" else int(Time.get_ticks_msec() / 100) % 4
	if carry_body.sprite_frames == null or carry_body.get_meta(&"art_id", "") != art_id:
		carry_body.sprite_frames = carry_frames(art_id, art_entry, false)
		carry_beak.sprite_frames = carry_frames(art_id, art_entry, true)
		carry_body.set_meta(&"art_id", art_id)
	for part: AnimatedSprite2D in [carry_body, carry_beak]:
		part.animation = clip
		part.frame = local
		part.position = sprite.position
		part.rotation = sprite.rotation
		part.scale = sprite.scale
		part.flip_h = facing < 0
		part.modulate = sprite.modulate
		part.material = sprite.material
		part.visible = true
	sprite.visible = false
	var anchor: Array = carry_for(art_id).beak_anchors[String(clip)][local]
	var offset := Vector2(float(anchor[0]) * (-1.0 if facing < 0 else 1.0), float(anchor[1])) * body_scale
	var definition: Dictionary = Config.foods[carry_food]
	carry_item.texture = Config.frames(definition.sprite).get_frame_texture(&"idle", 0)
	# Full-size food, half of it hidden in the beak: show only the half that sticks out in front.
	var food_size: Vector2 = carry_item.texture.get_size()
	carry_item.region_enabled = true
	carry_item.region_rect = Rect2(Vector2(0.0 if facing < 0 else food_size.x*0.5, 0.0), Vector2(food_size.x*0.5, food_size.y))
	carry_item.scale = Vector2(float(definition.size[0]), float(definition.size[1])) / food_size
	carry_item.position = sprite.position + (offset * Vector2(sprite.scale.x / maxf(art_scale, 0.001), sprite.scale.y / maxf(art_scale, 0.001))).rotated(sprite.rotation)
	carry_item.rotation = sprite.rotation
	carry_item.modulate = sprite.modulate
	carry_item.visible = true
	carry_glint.texture = PickupShine.overlay(carry_item.texture, Time.get_ticks_msec() / 1000.0, float(get_instance_id() % 7)) if mug_cue else null
	carry_glint.visible = carry_glint.texture != null
	if carry_glint.visible:
		carry_glint.position = carry_item.position
		carry_glint.rotation = carry_item.rotation
		carry_glint.scale = carry_item.scale
		carry_glint.region_enabled = true
		carry_glint.region_rect = carry_item.region_rect

func wind_lift() -> float:
	return clampf(absf(wind_force) / float(Config.tuning.wind.lift_ref), 0.0, 1.5)

# Wind along a heading, positive with the wind and negative against it.
func tailwind(heading: float) -> float:
	return clampf(heading * wind_force / float(Config.tuning.wind.lift_ref), -1.5, 1.5)

func wingbeat(delta: float) -> float:
	## Held flap repeats a short downstroke at a fixed cadence; returns its average upward acceleration this tick.
	var f: Dictionary = Config.tuning.flight
	if climb and stroke_cooldown <= 0.0 and stroke_left <= 0.0:
		stroke_left = float(f.stroke_duration)
		stroke_cooldown += float(f.stroke_interval)
		stroke_started = true
	if stroke_left <= 0.0:
		return 0.0
	var share: float = minf(delta, stroke_left)
	stroke_left -= delta
	var w: Dictionary = Config.tuning.wind
	var heading: float = signf(velocity.x) if absf(velocity.x) > 1.0 else facing
	var flap_scale: float = clampf(1.0 + float(w.flap_tail) * tailwind(heading), float(w.flap_min), float(w.flap_max))
	return float(f.stroke_lift) * flap_scale / float(f.stroke_duration) * share / delta

func climb_loop_time() -> float:
	var frames: SpriteFrames = sprite.sprite_frames
	return frames.get_frame_count(&"climb") / frames.get_animation_speed(&"climb")

func land() -> void:
	var was_airborne: bool = state in [State.GLIDE, State.WINDUP, State.STRIKE]
	if was_airborne and velocity.y > 0.1:
		art_event = &"landing"
		art_event_left = 0.16
	position.y = ground_y()
	velocity.y = 0
	velocity.x = clampf(velocity.x, -float(Config.tuning.flight.ground_speed), float(Config.tuning.flight.ground_speed))
	state = State.GROUNDED
	coasting = false
	dive_speed = 0
	sprite.rotation = 0
	if was_airborne and support.is_empty():
		sand_landed.emit(position + Vector2(0, float(Config.tuning.flight.feet_offset)))

func pullup() -> void:
	# Return control to normal flight without a scripted upward movement.
	state = State.GLIDE
	coasting = true
	coast_speed = absf(velocity.x)
	cooldown = Config.tuning.dive.cooldown
	art_event = &"pullup"
	art_event_left = 0.18

func crash_risk() -> float:
	# Downward impact speed, not harmless horizontal speed, determines severity.
	if state != State.STRIKE or direction.y * float(Config.tuning.dive.beak_offset) <= float(Config.tuning.flight.feet_offset):
		return 0.0
	return maxf(velocity.y,0) / float(Config.tuning.dive.crash_vertical_speed)

func crash_warning() -> bool:
	if crash_risk() < float(Config.tuning.dive.warning_risk):
		return false
	var seconds_to_sand: float = maxf(0,float(Config.tuning.world.ground)-beak().y) / maxf(velocity.y,1)
	return seconds_to_sand <= float(Config.tuning.dive.warning_time)

func stun(duration: float = -1.0, attacker: Vector2 = Vector2.INF) -> void:
	if state == State.STUNNED or invulnerable > 0:
		return
	if stun_shield > 0:
		stun_shield -= 1
		stun_ignored.emit()
		return
	begin_tumble(duration,attacker)
	gull_stunned.emit()

func begin_tumble(duration: float = -1.0, attacker: Vector2 = Vector2.INF) -> void:
	var t: Dictionary = Config.tuning.tumble
	var away: float = signf(position.x-attacker.x) if attacker.is_finite() else signf(velocity.x)
	if away == 0.0:
		away = -signf(velocity.x) if absf(velocity.x)>1.0 else -facing
	state = State.STUNNED
	support = {}
	departing_perch = {}
	coasting = false
	dive_speed = 0.0
	consume_peck()
	peck_used = true
	art_event_left = 0.0
	stroke_left = 0.0
	timer = (float(t.duration) if duration < 0.0 else maxf(duration,float(t.recovery_time))) * stun_mult
	velocity = Vector2(away*float(t.launch_speed),-float(t.launch_up))
	facing = away
	tumble_angle = sprite.rotation
	tumble_spin = away*float(t.spin)
	tumble_elapsed = 0.0
	tumble_shed = float(t.shed_interval)
	tumble_bounced = false
	tumble_recovering = false
	sprite.play(&"idle" if sprite.sprite_frames.has_animation(&"idle") else &"glide")
	position.y = minf(position.y,tumble_floor())
	tumble_feathers.emit(position,velocity,int(Config.tuning.juice.feathers))

func tumble_floor() -> float:
	# Leave room for a folded body while it turns over on the ground.
	return float(Config.tuning.world.ground)-maxf(10.0,float(art_entry.get("art_height",16.0))*0.65)

func tick_tumble(delta: float) -> void:
	var t: Dictionary = Config.tuning.tumble
	sprite.play(&"idle" if sprite.sprite_frames.has_animation(&"idle") else &"glide")
	# A delayed frame must not simulate beyond the end of this reaction.
	var remaining: float = minf(delta,maxf(0.0,timer+delta))
	while remaining > 0.000001:
		var step: float = minf(remaining,1.0/120.0)
		remaining -= step
		tumble_elapsed += step
		velocity.x = move_toward(velocity.x,0.0,float(t.drag)*step)
		velocity.y += float(t.gravity)*step
		position += velocity*step
		if position.x < 12.0 or position.x > float(Config.tuning.world.width)-12.0:
			position.x = clampf(position.x,12.0,float(Config.tuning.world.width)-12.0)
			velocity.x = 0.0
		if position.y >= tumble_floor() and velocity.y > 0.0:
			position.y = tumble_floor()
			if not tumble_bounced:
				velocity.y = -minf(velocity.y*float(t.bounce),float(t.bounce_speed))
				velocity.x *= 0.85
				tumble_spin *= 0.8
				tumble_bounced = true
				tumble_feathers.emit(position,velocity,3)
				sand_landed.emit(Vector2(position.x,float(Config.tuning.world.ground)))
			else:
				velocity.y = 0.0
		if not tumble_recovering:
			tumble_angle += tumble_spin*step
			tumble_spin = move_toward(tumble_spin,0.0,float(t.spin_drag)*step)
		if tumble_elapsed <= float(t.shed_time):
			tumble_shed -= step
			if tumble_shed <= 0.0:
				tumble_shed += float(t.shed_interval)
				tumble_feathers.emit(position,velocity,2)
	if timer <= float(t.recovery_time):
		if not tumble_recovering:
			tumble_recovering = true
			tumble_recovery_angle = wrapf(tumble_angle,-PI,PI)
		var progress: float = clampf(1.0-maxf(timer,0.0)/float(t.recovery_time),0.0,1.0)
		tumble_angle = tumble_recovery_angle*(1.0-smoothstep(0.0,1.0,progress))
	sprite.rotation = tumble_angle
	if timer <= 0.0:
		invulnerable = float(Config.tuning.dive.invulnerability)
		sprite.rotation = 0.0
		state = State.GLIDE
		cooldown = float(Config.tuning.dive.cooldown)
		if position.y >= tumble_floor()-0.1 and velocity.y >= 0.0:
			land()

func _draw() -> void:
	var target_perch: Dictionary = landing_perch()
	if not target_perch.is_empty():
		var spot: Vector2 = Vector2(clampf(aim.x,float(target_perch.x)-float(target_perch.half_width),float(target_perch.x)+float(target_perch.half_width)),float(target_perch.y))-position
		if bool(target_perch.pole):
			spot.x = float(target_perch.x)-position.x
		draw_line(spot-Vector2(3,0),spot+Vector2(3,0),Color("fff4da"),1.0)
		draw_line(spot+Vector2(0,-4),spot,Color("fff4da"),1.0)
	if detailed_art:
		# Ground projection anchors the bird and helps judge dive height.
		var altitude: float = maxf(0,ground_y()-position.y)
		var radius: float = lerpf(8,3,clampf(altitude/130,0,1))
		draw_set_transform(Vector2(0,float(Config.tuning.world.ground)-position.y),0,Vector2(1,0.25))
		draw_circle(Vector2.ZERO,radius,Color(0.09,0.18,0.22,lerpf(0.24,0.07,clampf(altitude/130,0,1))))
		draw_set_transform(Vector2.ZERO)
		return
	if state != State.GROUNDED:
		return
	var ink: Color = Color("183b4e")
	var body: Color = Color("8aabb3") if rival else Color("fff4da")
	var feet: Color = Color("ffc65c")
	var step: float = roundf(sin(walk_phase) * 2) if absf(velocity.x) > 1 else 0.0
	draw_set_transform(Vector2.ZERO, 0, Vector2(facing, 1))
	# Feet plant on the sand; wings stay folded while walking.
	for pair: Vector2 in [Vector2(-3,step), Vector2(3,-step)]:
		draw_line(Vector2(pair.x,2),Vector2(pair.x+pair.y,5),feet,1)
		draw_rect(Rect2(pair.x+pair.y,5,3,1),feet)
	draw_rect(Rect2(-8,-4,15,7),ink)
	draw_rect(Rect2(-7,-4,13,6),body)
	draw_rect(Rect2(-11,-3,5,3),body)
	draw_rect(Rect2(4,-9,7,8),body)
	draw_rect(Rect2(8,-7,1,1),ink)
	draw_rect(Rect2(10,-4,4,2),feet)
	draw_line(Vector2(-5,-1),Vector2(2,0),Color("8aabb3") if not rival else ink,1)
	if rival:
		draw_rect(Rect2(4,-10,7,2),Color("ef725c"))
	draw_set_transform(Vector2.ZERO)
