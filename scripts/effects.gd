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
var feather_rng := RandomNumberGenerator.new()
const SCORE_MESSAGE_HOLD: float = 3.0
const SCORE_MESSAGE_FADE: float = 1.5
const SCORE_MESSAGE_RISE_SPEED: float = 4.0

func message(at: Vector2, text: String, color: Color = Color("fff4da")) -> void:
	if Config.tuning.juice.floating_text:
		texts.append({"at":at,"text":text,"color":color,"life":float(Config.tuning.juice.float_time)})

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
	if t.particles and not stunned:
		for i: int in int(t.feathers):
			var angle: float = TAU * i / float(t.feathers)
			particles.append({"at":at,"v":Vector2(cos(angle),sin(angle))*35,"life":0.5})

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
		var color: Color = item.get("color",Color("fff4da"))
		if item.has("duration"):
			color.a *= clampf(float(item.life)/float(item.duration),0.0,1.0)
		if item.get("crumb",false):
			var shade := Color("754a39")
			shade.a = color.a
			draw_rect(Rect2(Vector2(roundf(item.at.x),roundf(item.at.y))+Vector2(0,1),item.size),shade)
		draw_rect(Rect2(Vector2(roundf(item.at.x),roundf(item.at.y)),item.get("size",Vector2(2,1))),color)
