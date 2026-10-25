class_name BeachEffects
extends Node2D
var texts: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var shake: float = 0.0
var freeze: float = 0.0
var slow: float = 0.0
var clock: float = 0.0
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

func impact(at: Vector2, stunned: bool) -> void:
	var t: Dictionary = Config.tuning.juice
	if t.hitstop:
		freeze = float(t.stun_stop if stunned else t.snatch_stop)
	if t.shake and GameState.options.shake:
		shake = float(t.stun_shake if stunned else t.snatch_shake)

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
	_texture_particle("peck_star",PECK_STAR_TEXTURE,at,heading*(5.0+power*4.0)+Vector2.UP*5.0,life,heading.angle(),0.0,0.75+power*0.22)
	var debris_texture: Texture2D = DUST_PUFF_TEXTURE if material == "bag" else (IMPACT_WEDGE_TEXTURE if material == "glance" else CRUMB_FLECKS_TEXTURE)
	var debris_color: Color = Color("ef725c") if material == "glance" else Color.WHITE
	for index: int in count-1:
		var side: float = -1.0 if index%2 == 0 else 1.0
		var spread: float = 10.0+float(index/2)*5.0
		_texture_particle("peck_debris",debris_texture,at+normal*side*2.0,heading*(12.0+power*10.0)+normal*side*spread+Vector2.UP*(10.0+power*8.0),life+0.04*float(index%2),heading.angle(),side*(3.0+power*2.0),0.58+power*0.16,55.0,debris_color)
	queue_redraw()

## Snatch feedback happens at food/beak contact; scoring still waits for swallowing.
func snatch_contact(at: Vector2,motion: Vector2,bonus: bool = false) -> void:
	impact(at,false)
	if not bool(Config.tuning.juice.particles):
		return
	var heading: Vector2 = motion.normalized() if motion.length_squared() > 0.01 else Vector2.RIGHT
	var normal := Vector2(-heading.y,heading.x)
	var angle: float = heading.angle()
	var life: float = float(Config.tuning.juice.snatch_contact_life)
	var count: int = maxi(3,int(Config.tuning.juice.snatch_contact_count))
	_texture_particle("snatch_slash",SNATCH_SLASH_TEXTURE,at-heading*2.0,heading*18.0,life,angle,0.0,1.12 if bonus else 0.92)
	_texture_particle("snatch_streak",SPEED_STREAK_TEXTURE,at-heading*5.0,heading*9.0,life*0.72,angle,0.0,1.0 if bonus else 0.78)
	for index: int in count-2:
		var side: float = -1.0 if index%2 == 0 else 1.0
		var texture: Texture2D = IMPACT_WEDGE_TEXTURE if bonus and index == 0 else CRUMB_FLECKS_TEXTURE
		_texture_particle("snatch_fleck",texture,at+normal*side*2.0,heading*(12.0+float(index)*4.0)+normal*side*(18.0+float(index)*4.0)+Vector2.UP*8.0,life+0.04*float(index),angle,side*4.0,0.62 if bonus else 0.52,45.0)
	queue_redraw()

func sand_puff(at: Vector2, taking_off: bool = false) -> void:
	if not bool(Config.tuning.juice.particles) or at.x >= float(Config.tuning.world.promenade_start):
		return
	for i: int in 5:
		var side: float = float(i - 2)
		particles.append({"at":at + Vector2(side * 2.0, -1),"v":Vector2(side * 10.0, -12.0 - float(i % 2) * 5.0 - (5.0 if taking_off else 0.0)),"life":0.22,"duration":0.22,"color":Color("d4ad78"),"size":Vector2(2,1),"sand":true})

func feather_burst(at: Vector2, impulse: Vector2, amount: int) -> void:
	if not bool(Config.tuning.juice.particles):
		return
	for i: int in mini(amount,24):
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

func release_burst(at: Vector2, from_bin: bool = false) -> void:
	if not bool(Config.tuning.juice.particles):
		return
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
	for i: int in range(texts.size()-1,-1,-1):
		texts[i].life -= delta
		texts[i].at.y -= delta*float(texts[i].get("rise_speed",10.0))
		if texts[i].life <= 0:
			texts.remove_at(i)
	for i: int in range(particles.size()-1,-1,-1):
		particles[i].life -= delta
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

func _draw() -> void:
	var game: BeachGame = get_parent() as BeachGame
	for item: Dictionary in texts:
		var width: float = font.get_string_size(item.text,HORIZONTAL_ALIGNMENT_LEFT,-1,8).x
		var at: Vector2 = item.at-Vector2(width*0.5,0)
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
		draw_rect(Rect2(at-Vector2(2,8),Vector2(width+4,11)),backing)
		draw_string(font,at,item.text,HORIZONTAL_ALIGNMENT_LEFT,-1,8,lettering)
	for item: Dictionary in particles:
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
		var color: Color = item.get("color",Color("fff4da"))
		if item.has("duration"):
			color.a *= clampf(float(item.life)/float(item.duration),0.0,1.0)
		if item.get("crumb",false):
			var shade := Color("754a39")
			shade.a = color.a
			draw_rect(Rect2(Vector2(roundf(item.at.x),roundf(item.at.y))+Vector2(0,1),item.size),shade)
		draw_rect(Rect2(Vector2(roundf(item.at.x),roundf(item.at.y)),item.get("size",Vector2(2,1))),color)
