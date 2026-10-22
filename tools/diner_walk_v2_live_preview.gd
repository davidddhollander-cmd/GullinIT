extends Node2D

var rng := RandomNumberGenerator.new()
var walkers: Array[Dictionary] = []
var paused := false

func _ready() -> void:
	Audio.music.stop()
	get_window().content_scale_size = Vector2i(320, 180)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	rng.seed = 211
	walkers.append(_make_walker(Vector2(48, 85), 9.0, 1.0, false))
	walkers.append(_make_walker(Vector2(270, 153), 27.0, -1.0, true))
	queue_redraw()

func _make_walker(at: Vector2, speed: float, direction: float, leaving: bool) -> Dictionary:
	var actor := BeachTarget.new()
	add_child(actor)
	actor.setup("pier_diner", at.x, rng, 1.0, {"food_id":"fish_chips"})
	actor.position = at
	actor.facing = direction
	actor.leaving = leaving
	actor.update_art_pose(true)
	return {"actor":actor, "speed":speed, "direction":direction}

func _process(delta: float) -> void:
	if paused:
		return
	for walker: Dictionary in walkers:
		var actor: BeachTarget = walker.actor
		var direction: float = walker.direction
		actor.position.x += float(walker.speed) * direction * delta
		if actor.position.x > 292.0:
			direction = -1.0
		elif actor.position.x < 28.0:
			direction = 1.0
		walker.direction = direction
		actor.facing = direction
		actor.update_art_pose(true)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		paused = not paused
		for walker: Dictionary in walkers:
			var actor: BeachTarget = walker.actor
			actor.sprite.speed_scale = 0.0 if paused else 1.0

func _draw() -> void:
	var ink := Color("17394b")
	draw_rect(Rect2(0, 0, 320, 180), Color("a9d5ce"))
	draw_rect(Rect2(0, 0, 320, 22), ink)
	draw_rect(Rect2(0, 85, 320, 4), Color("e6c284"))
	draw_rect(Rect2(0, 153, 320, 4), Color("e6c284"))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(8, 15), "DINER WALK V2 / SPACE PAUSES", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("fff4da"))
	draw_string(font, Vector2(8, 34), "NORMAL ROUTINE / 9 PX PER SECOND", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, ink)
	draw_string(font, Vector2(8, 105), "FAST DEPARTURE / 27 PX PER SECOND", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, ink)
