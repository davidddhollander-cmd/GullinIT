class_name BeachSweeper
extends Node2D
## Beach cleaner. Runs onto the sand, warns and swings his broom at a low gull (the player only), and in between
## brushes unowned food and litter into the closest bin. A hit is the same stun every adult swat gives, so the
## existing drop-snack and -5 penalty apply. He never eats, steals or carries food himself.
signal warned
signal swatted(gull: BeachGull)
signal dumped(count: int)
signal pile_stolen
signal left
signal said(key: String)
enum State { ENTER, PATROL, WARN, CHASE, WINDUP, SWAT, RECOVER, FIST, SURPRISE, SWEEP, DUMP, EXIT }
const ART_PATH := "res://data/sweeper_art.json"
const SPRITE_ID := "sweeper"
static var art_data: Dictionary = {}
var game: BeachGame
var state: State = State.ENTER
var facing: float = 1.0
var timer: float = 0.0
var cooldown: float = 0.0
var chase_time: float = 0.0
var lost_time: float = 0.0
var hit_done: bool = false
var landed_hit: bool = false
var swings: int = 0
var leaving: bool = false
var paused: bool = false
var brushing: bool = false
var destination: float = 0.0
var prey: BeachGull
var pile: Array[Dictionary] = []
var bin: Dictionary = {}
var push_dir: float = 1.0
var stand_x: float = 0.0
var pushing: bool = false
var dumped_pile: bool = false
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var sprite: AnimatedSprite2D
var clip_name: StringName = &""
var clip_clock: float = 0.0

static func art() -> Dictionary:
	if art_data.is_empty():
		art_data = JSON.parse_string(FileAccess.get_file_as_string(ART_PATH))
	return art_data

static func tuning() -> Dictionary:
	return Config.tuning.sweeper

## Loose food or litter nobody owns: grounded, ownerless, settled, on the sand and not already in a pile.
static func is_sweepable(item: Dictionary) -> bool:
	var t: Dictionary = tuning()
	if not bool(item.get("grounded",false)) or bool(item.get("swept",false)) or bool(item.get("recovered",false)):
		return false
	var owner: Variant = item.get("owner")
	if owner != null and is_instance_valid(owner):
		return false
	var x: float = float(item.position.x)
	return float(item.get("age",0.0)) >= float(t.litter_settle) and x >= float(t.range[0]) and x <= float(t.range[1])

static func litter_count(items: Array[Dictionary]) -> int:
	var count: int = 0
	for item: Dictionary in items:
		if is_sweepable(item):
			count += 1
	return count

func setup(owner_game: BeachGame, x: float, seed_value: int) -> void:
	game = owner_game
	rng.seed = seed_value
	position = Vector2(x,float(Config.tuning.world.ground))
	var entry: Dictionary = Config.sprites[SPRITE_ID]
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Config.frames(SPRITE_ID)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE*float(entry.visual_scale)
	add_child(sprite)
	var edge: Array = tuning().range
	facing = 1.0 if x < game.camera_x else -1.0 # runs in toward the middle of the screen
	destination = clampf(x+facing*float(tuning().enter_depth),float(edge[0]),float(edge[1]))
	_animate(&"run")

func dismiss() -> void:
	leaving = true

func gull_height(gull: BeachGull) -> float:
	return float(Config.tuning.world.ground)-gull.position.y

func _in_range(x: float, margin: float = 0.0) -> bool:
	return x >= float(tuning().range[0])-margin and x <= float(tuning().range[1])+margin

func can_mark(gull: BeachGull) -> bool:
	return is_instance_valid(gull) and gull.visible and gull.state != BeachGull.State.STUNNED and gull.invulnerable <= 0.0 and _in_range(gull.position.x,10.0)

## A gull is a mark while it is low and close; a grounded gull working a bin is noticed from further off.
func gull_low(gull: BeachGull) -> bool:
	if not can_mark(gull) or gull_height(gull) > float(tuning().notice_height):
		return false
	var gap: float = absf(gull.position.x-position.x)
	if gap <= float(tuning().notice_radius):
		return true
	return gap <= float(tuning().bin_notice_radius) and gull == game.player and not game.stash_raids.nearby_bin(true).is_empty()

func _face(x: float) -> void:
	if absf(x-position.x) > 0.5:
		facing = signf(x-position.x)

func _move(target_x: float, speed: float, delta: float) -> void:
	_face(target_x)
	position.x = clampf(move_toward(position.x,target_x,speed*delta),float(tuning().range[0])-220.0,float(tuning().range[1])+220.0)

func _nearest_bin(x: float) -> Dictionary:
	var best: Dictionary = {}
	var best_gap: float = INF
	for candidate: Dictionary in game.stash_raids.bins:
		var bx: float = float(candidate.x)
		if _in_range(bx) and absf(bx-x) < best_gap:
			best = candidate
			best_gap = absf(bx-x)
	return best

func _next_litter() -> Dictionary:
	var best: Dictionary = {}
	var best_gap: float = INF
	for item: Dictionary in game.stash_raids.items:
		if is_sweepable(item) and absf(float(item.position.x)-position.x) < best_gap and not _nearest_bin(float(item.position.x)).is_empty():
			best = item
			best_gap = absf(float(item.position.x)-position.x)
	return best

func _art_point(point: Array) -> Vector2:
	var entry: Dictionary = Config.sprites[SPRITE_ID]
	var s: float = float(entry.visual_scale)
	return position+Vector2(facing*(float(point[0])-float(art().body_anchor_x))*s,float(entry.sprite_offset_y)+(float(point[1])-float(entry.frame_h)*0.5)*s)

## Frame of a driven clip: swat steps through its six frames over swat_time, sweep loops at its authored fps.
func clip_frame() -> int:
	if clip_name == &"swat":
		return clampi(int(clip_clock/float(tuning().swat_time)*6.0),0,5)
	return int(clip_clock*float(Config.sprites[SPRITE_ID].animations.sweep.fps)) % 6

func _head_x() -> float:
	var anchors: Array = art().broom_ground_anchors_source_px
	return _art_point(anchors[clip_frame() if clip_name == &"sweep" else 0]).x

func broom_point() -> Vector2:
	var reach: Array = art().swat_reach_source_px
	return _art_point(reach[clampi(clip_frame(),0,reach.size()-1)])+Vector2(facing*float(tuning().reach_bonus),0.0) # a longer, committed swing than the drawn broom

func _release_pile() -> void:
	for item: Dictionary in pile:
		item.erase("swept")
	pile.clear()
	pushing = false

func _start_sweep() -> bool:
	var item: Dictionary = _next_litter()
	if item.is_empty():
		return false
	bin = _nearest_bin(float(item.position.x))
	push_dir = signf(float(bin.x)-float(item.position.x))
	if push_dir == 0.0:
		push_dir = facing
	item.swept = true
	pile = [item]
	var head_offset: float = (float(art().broom_ground_anchors_source_px[0][0])-float(art().body_anchor_x))*float(Config.sprites[SPRITE_ID].visual_scale)
	stand_x = float(item.position.x)-push_dir*head_offset
	pushing = false
	dumped_pile = false
	state = State.SWEEP
	return true

func _start_warn(gull: BeachGull) -> void:
	_release_pile()
	prey = gull
	state = State.WARN
	timer = float(tuning().warn_time)
	_face(gull.position.x)
	warned.emit()

func _end_job(next: State, cool: bool = false) -> void:
	state = next
	if cool:
		cooldown = float(tuning().cooldown)

func _give_up() -> void:
	prey = null
	cooldown = float(tuning().cooldown)
	state = State.FIST
	timer = float(tuning().fist_time)

func tick(delta: float, gull: BeachGull) -> void:
	if paused or delta <= 0.0:
		return
	var t: Dictionary = tuning()
	cooldown = maxf(0.0,cooldown-delta)
	clip_clock += delta
	var clip: StringName = &"idle"
	match state:
		State.ENTER:
			clip = &"run"
			_move(destination,float(t.run_speed),delta)
			if cooldown <= 0.0 and gull_low(gull):
				_start_warn(gull)
			elif is_equal_approx(position.x,destination):
				_patrol()
		State.PATROL:
			if cooldown <= 0.0 and gull_low(gull):
				_start_warn(gull)
			elif not leaving and _start_sweep():
				pass
			elif leaving:
				state = State.EXIT
			else:
				# Never stands about: he keeps walking the sand, brushing as he goes.
				clip = &"sweep" if brushing else &"walk"
				_move(destination,float(t.sweep_speed) if brushing else float(t.walk_speed),delta)
				if is_equal_approx(position.x,destination):
					_patrol()
		State.WARN:
			clip = &"alert" if timer > float(t.warn_time)*0.5 else &"warning"
			if is_instance_valid(prey):
				_face(prey.position.x)
			timer -= delta
			if not gull_low(prey):
				prey = null
				_patrol()
			elif timer <= 0.0:
				state = State.CHASE
				chase_time = 0.0
				lost_time = 0.0
				swings = 0
		State.CHASE:
			clip = &"run"
			chase_time += delta
			if not can_mark(prey):
				_give_up()
				_animate(&"fist_shake")
				return
			lost_time = lost_time+delta if gull_height(prey) > float(t.notice_height)+24.0 else 0.0
			if chase_time >= float(t.chase_timeout) or absf(prey.position.x-position.x) > float(t.lose_radius) or lost_time >= float(t.lose_grace):
				_give_up()
			else:
				_move(prey.position.x,float(t.run_speed),delta)
				if absf(prey.position.x-position.x) <= float(t.swing_range) and gull_height(prey) <= float(t.reach_height):
					state = State.WINDUP
					timer = float(t.windup_time)
		State.WINDUP:
			clip = &"windup"
			timer -= delta
			if timer > 0.1 and is_instance_valid(prey):
				_face(prey.position.x) # the last stretch is committed: the player can step out of it
			if timer <= 0.0:
				state = State.SWAT
				timer = float(t.swat_time)
				hit_done = false
				landed_hit = false
				said.emit("swing")
		State.SWAT:
			clip = &"swat"
			timer -= delta
			_swing_check(gull)
			if timer <= 0.0:
				if landed_hit:
					cooldown = float(t.cooldown)
					prey = null
					state = State.FIST
					timer = float(t.fist_time)
				elif swings < int(t.max_swings) and can_mark(prey) and gull_height(prey) <= float(t.reach_height) and absf(prey.position.x-position.x) <= float(t.swing_range)*1.5:
					# Frantic: a miss on a gull that is still in reach goes straight into another, quicker windup.
					swings += 1
					_face(prey.position.x)
					state = State.WINDUP
					timer = float(t.rewind_time)
				else:
					cooldown = float(t.cooldown)
					prey = null
					state = State.RECOVER
					timer = float(t.recover_time)
		State.RECOVER:
			clip = &"recover"
			timer -= delta
			if timer <= 0.0:
				_patrol()
		State.FIST:
			clip = &"fist_shake"
			timer -= delta
			if timer <= 0.0:
				_patrol()
		State.SURPRISE:
			clip = &"surprise"
			timer -= delta
			if timer <= 0.0:
				if cooldown <= 0.0 and gull_low(gull):
					_start_warn(gull)
				elif pile.is_empty():
					_patrol()
				else:
					state = State.SWEEP
		State.SWEEP:
			clip = _tick_sweep(delta,gull)
		State.DUMP:
			clip = &"sweep_bin"
			timer -= delta
			if not dumped_pile and timer <= float(t.dump_time)*0.55:
				_dump()
			if timer <= 0.0:
				_patrol()
		State.EXIT:
			# Runs off the side of the screen and is only removed once nobody can see him go.
			clip = &"run"
			var away: float = signf(position.x-game.camera_x)
			if away == 0.0:
				away = facing
			position.x += away*float(t.run_speed)*0.7*delta
			facing = away
			if absf(position.x-game.camera_x) > 190.0:
				left.emit()
				queue_free()
				return
	_animate(clip)

func _patrol() -> void:
	state = State.PATROL
	prey = null
	brushing = rng.randf() < 0.5
	for i: int in 6:
		destination = rng.randf_range(float(tuning().range[0]),float(tuning().range[1]))
		if absf(destination-position.x) > 80.0:
			break

func _swing_check(gull: BeachGull) -> void:
	if hit_done or not is_instance_valid(gull) or clip_name != &"swat":
		return
	if not (float(clip_frame()) in art().swat_hit_frames): # JSON numbers are floats
		return
	var hit_zone: Vector2 = broom_point()
	if can_mark(gull) and gull_height(gull) <= float(tuning().reach_height) and gull.position.distance_to(hit_zone) <= float(tuning().hit_radius):
		hit_done = true
		landed_hit = true
		gull.stun(float(tuning().knock_time),position)
		if gull.state == BeachGull.State.STUNNED:
			gull.velocity = Vector2(gull.velocity.x/maxf(absf(gull.velocity.x),0.001)*float(tuning().knock_speed),-float(tuning().knock_up)) # sent flying, far further than a normal tumble
			swatted.emit(gull)

func _tick_sweep(delta: float, gull: BeachGull) -> StringName:
	var t: Dictionary = tuning()
	if cooldown <= 0.0 and gull_low(gull):
		_start_warn(gull)
		return &"alert"
	var before: int = pile.size()
	pile.assign(pile.filter(func(item: Dictionary) -> bool: return game.stash_raids.items.any(func(other: Dictionary) -> bool: return is_same(other,item))))
	if pile.size() < before:
		pile_stolen.emit()
		state = State.SURPRISE
		timer = float(t.surprise_time)
		return &"surprise"
	if pile.is_empty() or not _in_range(position.x,20.0):
		_release_pile()
		_patrol()
		return &"idle"
	if not pushing:
		_face(stand_x)
		position.x = move_toward(position.x,stand_x,float(t.walk_speed)*delta)
		if is_equal_approx(position.x,stand_x):
			pushing = true
			facing = push_dir
		return &"walk"
	facing = push_dir
	position.x += push_dir*float(t.sweep_speed)*delta
	var head: float = _head_x()
	for item: Dictionary in game.stash_raids.items:
		if pile.size() < int(t.pile_max) and is_sweepable(item) and absf(float(item.position.x)-head) <= float(t.gather_radius) and (float(item.position.x)-head)*push_dir >= -2.0:
			item.swept = true
			pile.append(item)
	for index: int in pile.size():
		pile[index].position.x = head+push_dir*float(t.pile_gap)*index
	if (float(bin.x)-head)*push_dir <= float(t.dump_distance):
		state = State.DUMP
		timer = float(t.dump_time)
		dumped_pile = false
	return &"sweep"

func _dump() -> void:
	dumped_pile = true
	var count: int = pile.size()
	var items: Array[Dictionary] = game.stash_raids.items
	for index: int in range(items.size()-1,-1,-1):
		if pile.any(func(item: Dictionary) -> bool: return is_same(item,items[index])):
			items.remove_at(index)
	if bool(tuning().refill_bin):
		bin.remaining = mini(int(bin.capacity),int(bin.remaining)+count)
	pile.clear()
	game.beach.wobble_bin(float(bin.x),0.5,false)
	game.effects.food_crumble(Vector2(float(bin.x),float(bin.get("content_y",float(Config.tuning.world.ground)-18.0))),Vector2(0,-30),5)
	Audio.play("bin_rattle",1.0,-6.0)
	dumped.emit(count)

func _animate(clip: StringName) -> void:
	var entry: Dictionary = Config.sprites[SPRITE_ID]
	sprite.flip_h = facing < 0.0
	# The figure's body sits left of the cell centre, so the sprite is nudged to put the feet on the body anchor.
	sprite.position = Vector2(facing*(float(entry.frame_w)*0.5-float(art().body_anchor_x))*float(entry.visual_scale),float(entry.sprite_offset_y))
	if clip != clip_name:
		clip_name = clip
		clip_clock = 0.0
	if clip == &"swat" or clip == &"sweep":
		# The state machine owns these frames so the hit window and the pile anchor are exact.
		if sprite.animation != clip:
			sprite.animation = clip
		sprite.frame = clip_frame()
		sprite.pause()
	else:
		if sprite.animation != clip or not sprite.is_playing():
			sprite.play(clip)
		sprite.speed_scale = 0.0 if paused else 1.0
