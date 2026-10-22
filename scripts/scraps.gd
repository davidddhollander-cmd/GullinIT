class_name BeachScraps
extends Node2D
signal collected(position: Vector2, food_id: String)
var crumbs: Array[Dictionary] = []
var clock: float = 0.0
var collector: BeachGull

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var variant: int = 0
	for x: int in range(60, int(Config.tuning.world.width) - 20, int(Config.tuning.world.scrap_spacing)):
		var food_id: String = "single_chip" if crumbs.size()%3 == 2 else "crumbs"
		crumbs.append({"x": float(x), "wait": 0.0,"food_id":food_id,"variant":variant%3})
		if food_id == "crumbs":
			variant += 1

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
			var display_size: Array = definition.get("display_size",definition.size)
			var size: Vector2 = Vector2(display_size[0],display_size[1])
			var texture: Texture2D = Config.frames(definition.sprite).get_frame_texture(&"idle",int(crumb.variant) if crumb.food_id == "crumbs" else 0)
			var rect: Rect2 = Rect2(point-Vector2(size.x*0.5,size.y),size)
			draw_texture_rect(texture,rect,false)
			if crumb.food_id != "crumbs" and (collector == null or collector.can_collect_food(crumb.food_id)):
				var glint: Texture2D = PickupShine.overlay(texture,clock,float(crumb.x))
				if glint != null:
					draw_texture_rect(glint,rect,false)
