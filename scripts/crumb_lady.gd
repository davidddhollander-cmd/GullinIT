class_name CrumbLady
extends Node2D
## Level 4 crumb lady. Walks her patrol, stops every few seconds to throw a crumb fan, and swats a
## gull that lands or pecks beside her. All timings come from the level's `feeding` block.
## Her animation is driven from tick() (frame = clip time x fps) so the release and swat frames are exact.
signal threw(from: Vector2, facing: float)
signal swatted(gull: BeachGull)
enum State { WALK, THROW, SWAT }
var state: State = State.WALK
var facing: float = 1.0
var cfg: Dictionary
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var sprite: AnimatedSprite2D
var throw_timer: float = 0.0
var swat_cooldown: float = 0.0
var clip_time: float = 0.0
var acted: bool = false ## the release / hit frame has already fired in this clip

func setup(feeding: Dictionary, seed_value: int) -> void:
	cfg = feeding
	rng.seed = seed_value
	var art: Dictionary = Config.sprites.crumb_lady
	position = Vector2(float(cfg.lady.x),float(Config.tuning.world.ground))
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Config.frames("crumb_lady")
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE*float(art.visual_scale)
	sprite.position.y = float(art.sprite_offset_y)
	add_child(sprite)
	throw_timer = _next_throw()
	_show(&"walk")

func _next_throw() -> float:
	return rng.randf_range(float(cfg.interval[0]),float(cfg.interval[1]))

func _clip_length(clip: StringName) -> float:
	var anim: Dictionary = Config.sprites.crumb_lady.animations[clip]
	return float(anim.frames.size())/float(anim.fps)

func _frame_index(clip: StringName) -> int:
	return int(clip_time*float(Config.sprites.crumb_lady.animations[clip].fps))

func _show(clip: StringName) -> void:
	var anim: Dictionary = Config.sprites.crumb_lady.animations[clip]
	var n: int = anim.frames.size()
	var index: int = _frame_index(clip)
	sprite.animation = clip
	sprite.frame = index%n if bool(anim.loop) else mini(index,n-1)
	sprite.flip_h = facing < 0.0

func _begin(next: State) -> void:
	state = next
	clip_time = 0.0
	acted = false

## True when a gull is standing or pecking within swat range.
func gull_in_reach(gull: BeachGull, extra: float = 0.0) -> bool:
	return is_instance_valid(gull) and gull.state == BeachGull.State.GROUNDED and absf(gull.position.x-position.x) <= float(cfg.swat_range)+extra

func tick(delta: float, gull: BeachGull) -> void:
	swat_cooldown = maxf(0.0,swat_cooldown-delta)
	clip_time += delta
	match state:
		State.WALK:
			var range_: Array = cfg.lady.home
			position.x += facing*float(cfg.walk_speed)*delta
			if position.x >= float(range_[1]):
				facing = -1.0
			elif position.x <= float(range_[0]):
				facing = 1.0
			throw_timer -= delta
			if swat_cooldown <= 0.0 and gull_in_reach(gull):
				facing = signf(gull.position.x-position.x) if gull.position.x != position.x else facing
				swat_cooldown = float(cfg.swat_cooldown)
				_begin(State.SWAT)
			elif throw_timer <= 0.0:
				_begin(State.THROW) # she stops and faces the way she was walking
			else:
				_show(&"walk")
				return
		State.THROW:
			if not acted and _frame_index(&"throw") >= int(cfg.release_frame):
				acted = true
				threw.emit(position+Vector2(facing*float(cfg.hand[0]),float(cfg.hand[1])),facing)
			if clip_time >= _clip_length(&"throw"):
				throw_timer = _next_throw()
				_begin(State.WALK)
		State.SWAT:
			if not acted and _frame_index(&"swat") >= int(cfg.swat_hit_frame):
				acted = true
				if gull_in_reach(gull,float(cfg.swat_range)*0.5):
					swatted.emit(gull)
			if clip_time >= _clip_length(&"swat"):
				_begin(State.WALK)
	_show(&"walk" if state == State.WALK else (&"throw" if state == State.THROW else &"swat"))
