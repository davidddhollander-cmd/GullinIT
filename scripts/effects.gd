class_name BeachEffects
extends Node2D
var texts: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var shake: float = 0.0
var freeze: float = 0.0
var slow: float = 0.0
var clock: float = 0.0
var kick: Vector2 = Vector2.ZERO ## camera shove along a dive, decays to zero
var trail_clock: float = 0.0
var wind_clock: float = 0.0
var font: Font = preload("res://assets/fonts/gull_pixel.fnt")
const FEATHER_TEXTURES: Array[Texture2D] = [
	preload("res://assets/sprites/feather-down-v1.png"),
	preload("res://assets/sprites/feather-gray-v1.png"),
	preload("res://assets/sprites/feather-tip-v1.png"),
	preload("res://assets/sprites/feather-fluff-v1.png"),
]
const PECK_STAR_TEXTURE: Texture2D = preload("res://assets/sprites/vfx-peck-star-v1.png")
const SNATCH_SLASH_TEXTURE: Texture2D = preload("res://assets/sprites/vfx-snatch-slash-v1.png")
const IMPACT_WEDGE_TEXTURE: Texture2D = preload("res://assets/sprites/vfx-impact-wedge-v1.png")
const CRUMB_FLECKS_TEXTURE: Texture2D = preload("res://assets/sprites/vfx-crumb-flecks-v1.png")
const DUST_PUFF_TEXTURE: Texture2D = preload("res://assets/sprites/vfx-dust-puff-v1.png")
const SPEED_STREAK_TEXTURE: Texture2D = preload("res://assets/sprites/vfx-speed-streak-v1.png")
var feather_rng := RandomNumberGenerator.new()
const SCORE_MESSAGE_HOLD: float = 3.0
const SCORE_MESSAGE_FADE: float = 1.5
const SCORE_MESSAGE_RISE_SPEED: float = 4.0

func message(at: Vector2, text: String, color: Color = Color("fff4da"), life: float = 0.0, rise_speed: float = 10.0) -> void:
	if Config.tuning.juice.floating_text:
		texts.append({"at":at,"text":text,"color":color,"life":life if life > 0.0 else float(Config.tuning.juice.float_time),"rise_speed":rise_speed})

## Ambient floating text in the sleeping-sunbather "Zzz" style: outlined letters, no backing plate, fading out.
func whisper(at: Vector2, text: String, life: float = 0.0) -> void:
	if Config.tuning.juice.floating_text:
		var seconds: float = life if life > 0.0 else float(Config.tuning.juice.float_time)
		texts.append({"at":at,"text":text,"color":BeachUI.CREAM,"life":seconds,"fade_time":seconds*0.7,"rise_speed":10.0,"plain":true})

## Short impact word (BONK!, PECK!...): outlined with no plate, in its own colour, held for the normal float time.
func shout(at: Vector2, text: String, color: Color = Color("fff4da")) -> void:
	if Config.tuning.juice.floating_text:
		texts.append({"at":at,"text":text,"color":color,"life":float(Config.tuning.juice.float_time),"rise_speed":10.0,"plain":true})

## One expanding ring that reaches exactly `radius` after `time` seconds.
func ring(at: Vector2, radius: float, time: float, width: float = 1.0, color: Color = Color("fff4da"), delay: float = 0.0) -> void:
	if not bool(Config.tuning.juice.particles):
		return
	particles.append({"ring":true,"at":at,"v":Vector2.ZERO,"gravity":0.0,"life":time,"duration":time,"delay":delay,"grow":(radius-4.0)/time,"width":width,"points":48,"color":color})
	queue_redraw()

## A combo tier went up: gold ring on the gull and the new multiplier floating above it.
func combo_pop(at: Vector2, multiplier: String) -> void:
	var t: Dictionary = Config.tuning.juice
	if bool(t.particles):
		particles.append({"ring":true,"at":at,"v":Vector2.ZERO,"gravity":0.0,"life":float(t.combo_ring_life),"duration":float(t.combo_ring_life),"delay":0.0,"grow":float(t.combo_ring_grow),"color":BeachUI.GOLD})
		queue_redraw()
	shout(at-Vector2(0,30),"X"+multiplier,BeachUI.GOLD)

func score_message(at: Vector2, text: String, color: Color = Color("fff4da")) -> void:
	if Config.tuning.juice.floating_text:
		texts.append({
			"at":at,
			"text":text,
			"color":color,
			"life":SCORE_MESSAGE_HOLD + SCORE_MESSAGE_FADE,
			"fade_time":SCORE_MESSAGE_FADE,
			"rise_speed":SCORE_MESSAGE_RISE_SPEED,
		})

func empty_message(at: Vector2) -> void:
	if not bool(Config.tuning.juice.floating_text):
		return
	for item: Dictionary in texts:
		if item.get("source",null) == at and item.text == "EMPTY":
			item.at = at
			item.life = 0.72
			queue_redraw()
			return
	texts.append({"at":at,"source":at,"text":"EMPTY","color":Color("d7d9cf"),"life":0.72,"fade_time":0.40})
	queue_redraw()

## `weight` (0..1) lifts a snatch's freeze and shake from the light values toward the max ones. Never cuts a bigger one short.
func impact(at: Vector2, stunned: bool, weight: float = 0.0) -> void:
	var t: Dictionary = Config.tuning.juice
	if t.hitstop:
		freeze = maxf(freeze,float(t.stun_stop) if stunned else lerpf(float(t.snatch_stop),float(t.snatch_stop_max),weight))
	if t.shake and GameState.options.shake:
		shake = maxf(shake,float(t.stun_shake) if stunned else lerpf(float(t.snatch_shake),float(t.snatch_shake_max),weight))

## 0 for a crumb, 1 for a big food, from the food's longest side (also sizes the collect burst).
func food_size_amount(food_id: String) -> float:
	var t: Dictionary = Config.tuning.juice
	var size: Array = Config.foods.get(food_id,{}).get("size",[8,8])
	var longest: float = maxf(float(size[0]),float(size[1]))
	return clampf((longest-float(t.collect_size_min))/(float(t.collect_size_max)-float(t.collect_size_min)),0.0,1.0)

## How much a snatch should land: food size and combo tier, full weight for a counter snatch.
func snatch_weight(food_id: String, tier: int, bonus: bool = false) -> float:
	if bonus:
		return 1.0
	var share: float = float(Config.tuning.juice.weight_size_share)
	var top: float = maxf(1.0,float(Config.tuning.score.tiers.size()-1))
	return clampf(food_size_amount(food_id)*share+clampf(float(tier)/top,0.0,1.0)*(1.0-share),0.0,1.0)

func _texture_particle(kind: String,texture: Texture2D,at: Vector2,velocity: Vector2,life: float,angle: float = 0.0,spin: float = 0.0,scale: float = 1.0,gravity: float = 0.0,modulate: Color = Color.WHITE) -> void:
	particles.append({
		"texture_particle":true,"effect_kind":kind,"texture":texture,
		"at":at,"v":velocity,"life":life,"duration":life,
		"angle":angle,"spin":spin,"scale":scale,"gravity":gravity,
		"color":modulate,
	})

## A successful source interaction owns this burst, so input misses never fake contact.
func peck_contact(at: Vector2,direction: Vector2,strength: float = 0.0,material: String = "hard") -> void:
	if not bool(Config.tuning.juice.particles):
		return
	var heading: Vector2 = direction.normalized() if direction.length_squared() > 0.01 else Vector2.RIGHT
	var normal := Vector2(-heading.y,heading.x)
	var life: float = float(Config.tuning.juice.peck_contact_life)
	var count: int = maxi(2,int(Config.tuning.juice.peck_contact_count))
	var power: float = clampf(strength,0.0,1.0)
	_texture_particle("peck_star",PECK_STAR_TEXTURE,at,heading*(5.0+power*4.0)+Vector2.UP*5.0,life,heading.angle(),0.0,(0.75+power*0.22)*float(Config.tuning.juice.peck_star_scale))
	var debris_texture: Texture2D = DUST_PUFF_TEXTURE if material == "bag" else (IMPACT_WEDGE_TEXTURE if material == "glance" else CRUMB_FLECKS_TEXTURE)
	var debris_color: Color = Color("ef725c") if material == "glance" else Color.WHITE
	for index: int in count-1:
		var side: float = -1.0 if index%2 == 0 else 1.0
		var spread: float = 10.0+float(index/2)*5.0
		_texture_particle("peck_debris",debris_texture,at+normal*side*2.0,heading*(12.0+power*10.0)+normal*side*spread+Vector2.UP*(10.0+power*8.0),life+0.04*float(index%2),heading.angle(),side*(3.0+power*2.0),0.58+power*0.16,55.0,debris_color)
	queue_redraw()

## Snatch feedback happens at food/beak contact; scoring still waits for swallowing.
func snatch_contact(at: Vector2,motion: Vector2,bonus: bool = false,weight: float = 0.0) -> void:
	impact(at,false,1.0 if bonus else weight)
	if not bool(Config.tuning.juice.particles):
		return
	var heading: Vector2 = motion.normalized() if motion.length_squared() > 0.01 else Vector2.RIGHT
	var normal := Vector2(-heading.y,heading.x)
	var angle: float = heading.angle()
	var life: float = float(Config.tuning.juice.snatch_contact_life)
	var count: int = maxi(3,int(Config.tuning.juice.snatch_contact_count))
	pixelfx_hit_spark(at,heading)
	if bonus:
		pixelfx("pixelfx_crit_hit",at,heading)
	_texture_particle("snatch_slash",SNATCH_SLASH_TEXTURE,at-heading*2.0,heading*18.0,life,angle,0.0,1.12 if bonus else 0.92)
	_texture_particle("snatch_streak",SPEED_STREAK_TEXTURE,at-heading*5.0,heading*9.0,life*0.72,angle,0.0,1.0 if bonus else 0.78)
	for index: int in count-2:
		var side: float = -1.0 if index%2 == 0 else 1.0
		var texture: Texture2D = IMPACT_WEDGE_TEXTURE if bonus and index == 0 else CRUMB_FLECKS_TEXTURE
		_texture_particle("snatch_fleck",texture,at+normal*side*2.0,heading*(12.0+float(index)*4.0)+normal*side*(18.0+float(index)*4.0)+Vector2.UP*8.0,life+0.04*float(index),angle,side*4.0,0.62 if bonus else 0.52,45.0)
	queue_redraw()

## Expanding rings from a screeching beak.
func sound_wave(at: Vector2) -> void:
	if not bool(Config.tuning.juice.particles):
		return
	for i: int in 3:
		var life: float = 0.45+0.12*i
		particles.append({"ring":true,"at":at,"v":Vector2.ZERO,"gravity":0.0,"life":life,"duration":life,"delay":0.1*i,"color":Color("fff4da")})
	queue_redraw()

## The windup ends: a tight ring where the gull let go and a camera shove along the dive.
func dive_release(at: Vector2, heading: Vector2) -> void:
	if bool(Config.tuning.juice.particles):
		for i: int in 2:
			particles.append({"ring":true,"at":at,"v":Vector2.ZERO,"gravity":0.0,"life":0.26,"duration":0.26,"delay":0.06*i,"grow":44.0,"color":Color("fff4da")})
		queue_redraw()
	if bool(Config.tuning.juice.shake) and GameState.options.shake:
		kick = heading.normalized()*float(Config.tuning.juice.dive_kick)

## Vapour streaks off the beak, longer and denser the faster the dive.
func dive_trail(beak: Vector2, heading: Vector2, speed: float, delta: float) -> void:
	if not bool(Config.tuning.juice.particles):
		return
	var t: Dictionary = Config.tuning.juice
	var ratio: float = clampf((speed-float(t.dive_trail_min_speed))/(float(Config.tuning.dive.max_speed)-float(t.dive_trail_min_speed)),0.0,1.0)
	if ratio <= 0.0:
		return
	trail_clock += delta
	if trail_clock < 0.03:
		return
	trail_clock = 0.0
	var life: float = 0.14+0.08*ratio
	particles.append({"streak":true,"at":beak-heading*3.0,"dir":heading,"length":6.0+16.0*ratio,"v":Vector2.ZERO,"gravity":0.0,"life":life,"duration":life,"color":Color(1.0,0.96,0.85,0.55+0.3*ratio)})

## Wind made visible: faint gust lines across the screen, sand skating along the ground, and brighter lines
## around a flying gull that the wind is helping. Everything scales with the gull's smoothed wind force.
func wind_tick(delta: float, camera_x: float, gull: BeachGull, camera_y: float = 90.0) -> void:
	var t: Dictionary = Config.tuning.juice
	if not bool(t.particles) or not bool(t.wind_streaks):
		return
	var strength: float = absf(gull.wind_force)
	if strength < float(t.wind_min):
		return
	var heading := Vector2(signf(gull.wind_force),0.0)
	wind_clock += delta
	var interval: float = 1.0/(float(t.wind_rate)*strength)
	while wind_clock >= interval:
		wind_clock -= interval
		var at := Vector2(camera_x+feather_rng.randf_range(-170.0,170.0),feather_rng.randf_range(14.0+camera_y-90.0,float(Config.tuning.world.ground)-8.0))
		var life: float = feather_rng.randf_range(0.5,0.9)
		particles.append({"streak":true,"at":at,"dir":heading,"length":6.0+feather_rng.randf()*8.0+8.0*strength,"v":heading*(70.0+60.0*strength),"gravity":0.0,"life":life,"duration":life,"color":Color(1.0,0.96,0.85,0.32)})
		if strength >= float(t.wind_sand_min) and at.x < float(Config.tuning.world.promenade_start):
			var sand_life: float = feather_rng.randf_range(0.35,0.6)
			var ground: float = float(Config.tuning.world.ground)
			particles.append({"at":Vector2(at.x,ground-feather_rng.randf_range(0.0,7.0)),"v":Vector2(heading.x*(80.0+50.0*strength),-feather_rng.randf_range(0.0,6.0)),"gravity":0.0,"life":sand_life,"duration":sand_life,"color":Color("d4ad78"),"size":Vector2(2,1),"sand":true})
		# Wind that is lifting or pushing a flying gull gets its own brighter lines beside the bird.
		if gull.state != BeachGull.State.GROUNDED and gull.state != BeachGull.State.STUNNED and gull.wind_lift() >= 0.5:
			var near: Vector2 = gull.position+Vector2(-heading.x*feather_rng.randf_range(2.0,14.0),feather_rng.randf_range(-12.0,12.0))
			particles.append({"streak":true,"at":near,"dir":heading,"length":10.0+8.0*strength,"v":heading*(90.0+60.0*strength),"gravity":0.0,"life":0.4,"duration":0.4,"color":Color(1.0,1.0,1.0,0.6)})
	queue_redraw()

## Short wind stripes fanned across `heading`, left drifting along it. Used for swings, flicks and launches.
func wind_stripes(at: Vector2, heading: Vector2, count: int = 3, length: float = 10.0, spread: float = 5.0) -> void:
	if not bool(Config.tuning.juice.particles):
		return
	var normal := Vector2(-heading.y,heading.x)
	for i: int in count:
		var side: float = float(i)-float(count-1)*0.5
		var life: float = feather_rng.randf_range(0.16,0.26)
		particles.append({"streak":true,"at":at+normal*side*spread+heading*feather_rng.randf_range(-3.0,3.0),"dir":heading,"length":length*feather_rng.randf_range(0.7,1.3),"v":heading*30.0,"gravity":0.0,"life":life,"duration":life,"color":Color(1.0,0.97,0.88,0.7)})
	queue_redraw()

## Swing stripe: a tapered ribbon through `points` (the head position on each animation frame, smoothed with a
## Catmull-Rom curve) that is revealed over `duration` seconds so it tracks the drawn head. Point 0 is the
## backswing, so the stripe only starts once the head passes point 1.
func swoosh(points: Array[Vector2], duration: float) -> void:
	if not bool(Config.tuning.juice.particles) or points.size() < 3:
		return
	var tail: float = float(Config.tuning.juice.swoosh_tail)
	var life: float = (float(points.size()-1)+0.5+tail)/float(points.size())*duration
	particles.append({"ribbon":true,"points":points.duplicate(),"tail":tail,"swing":duration,"life":life,"duration":life})
	queue_redraw()

func _ribbon_point(points: Array, u: float) -> Vector2:
	var last: int = points.size()-1
	var i: int = clampi(int(floor(u)),0,last-1)
	return points[i].cubic_interpolate(points[i+1],points[maxi(i-1,0)],points[mini(i+2,last)],clampf(u-float(i),0.0,1.0))

func _draw_ribbon(item: Dictionary) -> void:
	var points: Array = item.points
	var head: float = (float(item.duration)-float(item.life))/float(item.swing)*float(points.size())-0.5
	var tail: float = float(item.tail)
	var from: float = maxf(1.0,head-tail)
	var to: float = minf(head,float(points.size()-1))
	if to <= from:
		return
	var max_width: float = float(Config.tuning.juice.swoosh_width)
	var steps: int = int(ceil((to-from)*10.0))
	var previous: Vector2 = _ribbon_point(points,from).round()
	for step: int in range(1,steps+1):
		var u: float = lerpf(from,to,float(step)/float(steps))
		var at: Vector2 = _ribbon_point(points,u).round()
		var along: float = clampf((u-(head-tail))/tail,0.0,1.0)
		var color := Color(1.0,1.0,1.0) if along > 0.8 else (Color("fff4da") if along > 0.45 else Color("bfe3ee"))
		color.a = 0.25+0.7*along
		draw_line(previous,at,color,maxf(1.0,roundf(max_width*along)))
		previous = at

## The broom lands on the sand: dust rolling out both ways, a sand puff, wind along the floor and a small shake.
func ground_slam(at: Vector2, facing: float) -> void:
	if not bool(Config.tuning.juice.particles):
		return
	var t: Dictionary = Config.tuning.juice
	var base := Vector2(at.x,float(Config.tuning.world.ground))
	if base.x < float(Config.tuning.world.promenade_start):
		pixelfx("pixelfx_heavy_landing",base,Vector2(facing,0.0),null,float(t.slam_scale))
		sand_puff(base,true)
	for side: float in [-1.0,1.0]:
		wind_stripes(base+Vector2(side*3.0,-2.0),Vector2(side,0.0),2,9.0,2.0)
	if bool(t.shake) and GameState.options.shake:
		shake = maxf(shake,float(t.slam_shake))

## A landed swat: the usual hit spark where the gull was caught and stripes streaming behind its launch.
func swat_hit(at: Vector2, heading: Vector2) -> void:
	pixelfx_hit_spark(at,heading)
	wind_stripes(at,heading,4,12.0,4.0)

## Sand kicked up and a stripe dragged behind the bristles on a brush stroke.
func brush_dust(at: Vector2, push_dir: float) -> void:
	if not bool(Config.tuning.juice.particles):
		return
	if at.x < float(Config.tuning.world.promenade_start):
		for i: int in 2:
			var life: float = feather_rng.randf_range(0.22,0.34)
			particles.append({"at":at+Vector2(push_dir*feather_rng.randf_range(0.0,3.0),-1),"v":Vector2(push_dir*feather_rng.randf_range(14.0,34.0),-feather_rng.randf_range(8.0,22.0)),"life":life,"duration":life,"color":Color("d4ad78"),"size":Vector2(2,1) if i == 0 else Vector2(1,1),"sand":true})
	wind_stripes(at+Vector2(-push_dir*3.0,-3.0),Vector2(push_dir,0.0),1,8.0,0.0)

func sand_puff(at: Vector2, taking_off: bool = false) -> void:
	if not bool(Config.tuning.juice.particles) or at.x >= float(Config.tuning.world.promenade_start):
		return
	for i: int in 5:
		var side: float = float(i - 2)
		particles.append({"at":at + Vector2(side * 2.0, -1),"v":Vector2(side * 10.0, -12.0 - float(i % 2) * 5.0 - (5.0 if taking_off else 0.0)),"life":0.22,"duration":0.22,"color":Color("d4ad78"),"size":Vector2(2,1),"sand":true})

func feather_burst(at: Vector2, impulse: Vector2, amount: int) -> void:
	if not bool(Config.tuning.juice.particles):
		return
	for i: int in mini(amount,40):
		var life: float = feather_rng.randf_range(0.8,1.35)
		particles.append({
			"feather":true,"at":at+Vector2(feather_rng.randf_range(-4,4),feather_rng.randf_range(-4,4)),
			"v":impulse*0.25+Vector2(feather_rng.randf_range(-42,42),feather_rng.randf_range(-55,-12)),
			"life":life,"duration":life,"angle":feather_rng.randf_range(-PI,PI),
			"spin":feather_rng.randf_range(-5,5),"phase":feather_rng.randf_range(0,TAU),
			"texture":FEATHER_TEXTURES[feather_rng.randi_range(0,FEATHER_TEXTURES.size()-1)],
			"size":Vector2.ONE*feather_rng.randf_range(5.0,9.0),
		})
	queue_redraw()

func _water_animation(sprite_id: String, clip: StringName, at: Vector2, angle: float = 0.0) -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	sprite.name = sprite_id.to_pascal_case()
	sprite.sprite_frames = Config.frames(sprite_id)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = Vector2(roundf(at.x),roundf(at.y))
	sprite.rotation = angle
	sprite.z_index = 1
	add_child(sprite)
	sprite.animation_finished.connect(sprite.queue_free,CONNECT_ONE_SHOT)
	sprite.play(clip)
	return sprite

func water_splash(at: Vector2) -> AnimatedSprite2D:
	if not bool(Config.tuning.juice.particles):
		return null
	# The crown is drawn at the bottom of its frame: lift it so the base sits on `at`.
	return _water_animation("water_splash",&"impact",at-Vector2(0,10))

## Body hit: droplets thrown out and up off the gull (the splash sprite plays at the same spot), so a soak reads as contact.
func water_soak(at: Vector2, from: Vector2) -> void:
	if not bool(Config.tuning.juice.particles):
		return
	var away: float = signf(at.x-from.x) if absf(at.x-from.x) > 1.0 else 1.0
	for i: int in 14:
		var fan: float = float(i)/13.0*2.0-1.0
		var life: float = 0.45+float(i%4)*0.07
		particles.append({"at":at+Vector2(fan*3,-2),"v":Vector2(away*(18.0+float(i%3)*14.0)+fan*34,-48-float(i%4)*14),"life":life,"duration":life,"color":Color("fff4da") if i%3==0 else Color("6ec6f0"),"size":Vector2(2,2) if i%3!=1 else Vector2(1,2),"gravity":170.0,"crumb":true})
	queue_redraw()

## One-shot sheet effect rendered by pixelfx (see assets/sprites/pixelfx/NOTICE.md). Sheets are drawn
## facing right; the sprite entry's `pivot` (pixel in the frame) lands on `at`, and a leftward heading
## mirrors it. Effects live in z band 5.
func pixelfx(sprite_id: String, at: Vector2, heading: Vector2 = Vector2.RIGHT, parent: Node = null, scale_mul: float = 1.0) -> AnimatedSprite2D:
	if not bool(Config.tuning.juice.particles) or not bool(Config.tuning.juice.get("pixelfx",false)):
		return null
	var entry: Dictionary = Config.sprites[sprite_id]
	var pivot: Array = entry.pivot
	var sprite := AnimatedSprite2D.new()
	sprite.name = sprite_id.to_pascal_case()
	sprite.sprite_frames = Config.frames(sprite_id)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var mirrored: bool = heading.x < 0.0
	sprite.flip_h = mirrored
	# AnimatedSprite2D is centred and does not mirror `offset`, so mirror the x shift by hand.
	var shift := Vector2(float(entry.frame_w)*0.5-float(pivot[0]),float(entry.frame_h)*0.5-float(pivot[1]))
	sprite.offset = Vector2(-shift.x if mirrored else shift.x,shift.y)
	sprite.position = Vector2(roundf(at.x),roundf(at.y))
	sprite.scale = Vector2.ONE*float(entry.get("scale",1.0))*scale_mul
	sprite.z_index = 5
	sprite.z_as_relative = false
	(parent if parent != null else self).add_child(sprite)
	sprite.animation_finished.connect(sprite.queue_free,CONNECT_ONE_SHOT)
	sprite.play(&"burst")
	return sprite

## Stars and birds circling a stunned gull's head. The sheet loops, so it rides the gull for the stun then frees itself.
func pixelfx_stunned(gull: BeachGull) -> AnimatedSprite2D:
	var sprite: AnimatedSprite2D = pixelfx("pixelfx_stunned",Vector2(0,-14),Vector2.RIGHT,gull)
	if sprite != null:
		get_tree().create_timer(maxf(gull.timer,0.2)).timeout.connect(sprite.queue_free)
	return sprite

## Gold sparkle where a snack scores, sized by the food: crumbs get a pinch, a hot dog or pizza slice the full burst.
func collect_burst(at: Vector2, food_id: String = "") -> AnimatedSprite2D:
	var t: Dictionary = Config.tuning.juice
	return pixelfx("pixelfx_collect_burst",at,Vector2.RIGHT,null,lerpf(float(t.collect_scale_min),1.0,food_size_amount(food_id)))

func pixelfx_hit_spark(at: Vector2, heading: Vector2) -> AnimatedSprite2D:
	return pixelfx("pixelfx_hit_spark",at,heading)

func water_muzzle(at: Vector2, direction: Vector2) -> AnimatedSprite2D:
	if not bool(Config.tuning.juice.particles):
		return null
	var heading: Vector2 = direction.normalized() if direction.length_squared() > 0.001 else Vector2.RIGHT
	var mirror_left: bool = heading.x < 0.0
	var angle: float = wrapf(heading.angle()+PI,-PI,PI) if mirror_left else heading.angle()
	var sprite: AnimatedSprite2D = _water_animation("water_muzzle",&"burst",at,angle)
	sprite.flip_h = mirror_left
	return sprite

func release_burst(at: Vector2, from_bin: bool = false) -> void:
	if not bool(Config.tuning.juice.particles):
		return
	if from_bin:
		pixelfx("pixelfx_poof",at+Vector2(0,4))
	for i: int in 6:
		var side: float = float(i) - 2.5
		particles.append({"at":at + Vector2(side * 2.0, -2),"v":Vector2(side * 13.0,-20.0 - float(i % 3) * 5.0),"life":0.32,"duration":0.32,"color":Color("d4ad78") if from_bin else Color("f3c443"),"size":Vector2(2,2),"sand":true})

func food_crumble(at: Vector2, impulse: Vector2, amount: int = 14) -> void:
	if not bool(Config.tuning.juice.particles):
		return
	for i: int in amount:
		var fan: float = float(i)/float(maxi(1,amount-1))*2.0-1.0
		var life: float = 0.50+float(i%4)*0.07
		var color := Color("fff4da") if i%3==0 else Color("f3c443")
		particles.append({"at":at+Vector2(fan*2,-1),"v":impulse*0.28+Vector2(fan*62,-42-float(i%4)*12),"life":life,"duration":life,"color":color,"size":Vector2(2,2) if i%3!=0 else Vector2(1,2),"gravity":150.0,"crumb":true})
	queue_redraw()

func tick(delta: float) -> void:
	clock += delta
	freeze = maxf(0.0,freeze-delta)
	slow = maxf(0.0,slow-delta)
	shake = move_toward(shake,0,delta*12)
	kick = kick.move_toward(Vector2.ZERO,delta*float(Config.tuning.juice.dive_kick_decay))
	for i: int in range(texts.size()-1,-1,-1):
		texts[i].life -= delta
		texts[i].age = float(texts[i].get("age",0.0))+delta
		texts[i].at.y -= delta*float(texts[i].get("rise_speed",10.0))
		if texts[i].life <= 0:
			texts.remove_at(i)
	for i: int in range(particles.size()-1,-1,-1):
		particles[i].life -= delta
		if particles[i].get("ribbon",false):
			if particles[i].life <= 0.0:
				particles.remove_at(i)
			continue
		if particles[i].get("feather",false):
			var item: Dictionary = particles[i]
			item.v.x *= exp(-2.2*delta)
			item.v.y = minf(23.0,item.v.y+48.0*delta)
			var flutter: float = sin((float(item.duration)-float(item.life))*9.0+float(item.phase))
			item.at += (item.v+Vector2(flutter*14.0,0))*delta
			item.angle += (float(item.spin)+flutter*2.0)*delta
			item.at.y = minf(item.at.y,float(Config.tuning.world.ground)-2.0)
			if item.life <= 0.0:
				particles.remove_at(i)
			continue
		if particles[i].get("texture_particle",false):
			particles[i].at += particles[i].v*delta
			particles[i].v.y += delta*float(particles[i].get("gravity",0.0))
			particles[i].angle += delta*float(particles[i].get("spin",0.0))
			if particles[i].life <= 0.0:
				particles.remove_at(i)
			continue
		particles[i].at += particles[i].v*delta
		particles[i].v.y += delta*float(particles[i].get("gravity",65 if particles[i].get("sand",false) else 80))
		if particles[i].life <= 0:
			particles.remove_at(i)
	queue_redraw()

## Pixels a floating text is lifted by right after it appears: up and back within text_hop_time.
func text_hop(item: Dictionary) -> float:
	var t: Dictionary = Config.tuning.juice
	return roundf(float(t.text_hop)*sin(clampf(float(item.get("age",0.0))/float(t.text_hop_time),0.0,1.0)*PI))

func _draw() -> void:
	var game: BeachGame = get_parent() as BeachGame
	for item: Dictionary in texts:
		var width: float = font.get_string_size(item.text,HORIZONTAL_ALIGNMENT_LEFT,-1,8).x
		var at: Vector2 = item.at-Vector2(width*0.5,0)
		# A hop on appearance: a few pixels up and back in the first moments, position only (never scaled).
		at.y -= text_hop(item)
		if game != null and game.overlay != null and game.overlay.score_announcement.visible:
			var transform: Transform2D = get_global_transform_with_canvas()
			var screen_at: Vector2 = transform*at
			var row: Control = game.overlay.score_announcement.get_parent() as Control
			if Rect2(screen_at-Vector2(2,8),Vector2(width+4,11)).intersects(row.get_global_rect()):
				# Quips rise with the gull into the banner. Give them a slot below
				# both the callout and context hint, left of the goal box.
				screen_at.y = maxf(row.get_global_rect().end.y+10.0,game.overlay.hint_rect("").end.y+10.0)
				screen_at.x = clampf(screen_at.x,6.0,maxf(6.0,228.0-width))
				at = transform.affine_inverse()*screen_at
		var alpha: float = clampf(float(item.life)/float(item.fade_time),0.0,1.0) if item.has("fade_time") else 1.0
		var backing := Color("183b4e")
		backing.a = alpha
		var lettering: Color = item.color
		lettering.a *= alpha
		if item.get("plain",false):
			var outline: Color = BeachUI.INK
			outline.a = alpha
			draw_string_outline(font,at,item.text,HORIZONTAL_ALIGNMENT_LEFT,-1,8,1,outline)
		else:
			draw_rect(Rect2(at-Vector2(2,8),Vector2(width+4,11)),backing)
		draw_string(font,at,item.text,HORIZONTAL_ALIGNMENT_LEFT,-1,8,lettering)
	for item: Dictionary in particles:
		if item.get("ribbon",false):
			_draw_ribbon(item)
			continue
		if item.get("feather",false):
			var alpha: float = clampf(float(item.life)/0.4,0.0,1.0)
			var flutter: float = sin((float(item.duration)-float(item.life))*9.0+float(item.phase))
			draw_set_transform(item.at,item.angle,Vector2(0.6+absf(flutter)*0.4,1.0))
			draw_texture_rect(item.texture,Rect2(-item.size*0.5,item.size),false,Color(1,1,1,alpha))
			draw_set_transform(Vector2.ZERO)
			continue
		if item.get("texture_particle",false):
			var duration: float = float(item.duration)
			var remaining: float = clampf(float(item.life)/duration,0.0,1.0)
			var progress: float = 1.0-remaining
			var tint: Color = item.get("color",Color.WHITE)
			tint.a *= minf(1.0,remaining*2.5)
			var scale: float = float(item.get("scale",1.0))*(0.78+sin(progress*PI)*0.28)
			var size: Vector2 = item.texture.get_size()
			draw_set_transform(Vector2(roundf(item.at.x),roundf(item.at.y)),float(item.angle),Vector2.ONE*scale)
			draw_texture_rect(item.texture,Rect2(-size*0.5,size),false,tint)
			draw_set_transform(Vector2.ZERO)
			continue
		if item.get("streak",false):
			var streak_color: Color = item.color
			streak_color.a *= clampf(float(item.life)/float(item.duration),0.0,1.0)
			var start: Vector2 = Vector2(roundf(item.at.x),roundf(item.at.y))
			draw_line(start,start-item.dir*float(item.length),streak_color,1.0)
			continue
		if item.get("ring",false):
			var age: float = float(item.duration)-float(item.life)-float(item.delay)
			if age > 0.0:
				var ring_color: Color = item.color
				ring_color.a = clampf(float(item.life)/float(item.duration),0.0,1.0)
				draw_arc(item.at,4.0+age*float(item.get("grow",70.0)),0,TAU,int(item.get("points",20)),ring_color,float(item.get("width",1.0)))
			continue
		var color: Color = item.get("color",Color("fff4da"))
		if item.has("duration"):
			color.a *= clampf(float(item.life)/float(item.duration),0.0,1.0)
		if item.get("crumb",false):
			var shade := Color("754a39")
			shade.a = color.a
			draw_rect(Rect2(Vector2(roundf(item.at.x),roundf(item.at.y))+Vector2(0,1),item.size),shade)
		draw_rect(Rect2(Vector2(roundf(item.at.x),roundf(item.at.y)),item.get("size",Vector2(2,1))),color)
