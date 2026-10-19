class_name BeachScraps
extends Node2D
signal collected(position: Vector2, food_id: String)
var crumbs: Array[Dictionary] = []
var clock: float = 0.0
var collector: BeachGull

func _ready() -> void:
	for x: int in range(60, int(Config.tuning.world.width) - 20, int(Config.tuning.world.scrap_spacing)):
		crumbs.append({"x": float(x), "wait": 0.0,"food_id":"single_chip" if crumbs.size()%3 == 2 else "crumbs"})

func tick(delta: float, gull: BeachGull) -> void:
	clock += delta
	collector = gull
	for crumb: Dictionary in crumbs:
		if crumb.wait > 0:
			crumb.wait = maxf(0, crumb.wait - delta)
			continue
		var radius: float = float(Config.foods[crumb.food_id].pickup_radius[0]) + float(Config.tuning.dive.beak_w)*0.5
		if gull.state == BeachGull.State.GROUNDED and gull.can_collect_food(crumb.food_id) and absf(gull.beak().x - float(crumb.x)) < radius:
			crumb.wait = Config.tuning.world.scrap_respawn
			collected.emit(Vector2(crumb.x, Config.tuning.world.ground),crumb.food_id)
	queue_redraw()

func _draw() -> void:
	for crumb: Dictionary in crumbs:
		if crumb.wait <= 0:
			var point: Vector2 = Vector2(crumb.x, Config.tuning.world.ground)
			var definition: Dictionary = Config.foods[crumb.food_id]
			var size: Vector2 = Vector2(definition.size[0],definition.size[1])
			var texture: Texture2D = Config.frames(definition.sprite).get_frame_texture(&"idle",0)
			var rect: Rect2 = Rect2(point-Vector2(size.x*0.5,size.y),size)
			draw_texture_rect(texture,rect,false)
			if collector == null or collector.can_collect_food(crumb.food_id):
				var glint: Texture2D = PickupShine.overlay(texture,clock,float(crumb.x))
				if glint != null:
					draw_texture_rect(glint,rect,false)
