class_name BeachScraps
extends Node2D
signal collected(position: Vector2, food_id: String, thrown: bool)
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
		if crumb.get("gone",false):
			continue
		if float(crumb.get("fly",0.0)) > 0.0:
			crumb.fly = maxf(0.0,float(crumb.fly)-delta) # still in the air: not pick-up-able yet
			continue
		if crumb.wait > 0:
			crumb.wait = maxf(0, crumb.wait - delta)
			continue
		var radius: float = float(Config.foods[crumb.food_id].pickup_radius[0]) + float(Config.tuning.dive.beak_w)*0.5
		if gull.state == BeachGull.State.GROUNDED and gull.can_collect_food(crumb.food_id) and absf(gull.beak().x - float(crumb.x)) < radius:
			if crumb.get("thrown",false):
				crumb.gone = true
			else:
				crumb.wait = Config.tuning.world.scrap_respawn
			collected.emit(Vector2(crumb.x, Config.tuning.world.ground),crumb.food_id,bool(crumb.get("thrown",false)))
	for i: int in range(crumbs.size()-1,-1,-1):
		if crumbs[i].get("gone",false):
			crumbs.remove_at(i) # thrown crumbs are eaten for good (by the gull or a pigeon)
	queue_redraw()

func _draw() -> void:
	for crumb: Dictionary in crumbs:
		if crumb.wait <= 0:
			var point: Vector2 = Vector2(crumb.x, Config.tuning.world.ground)
			if float(crumb.get("fly",0.0)) > 0.0: # thrown crumb arcing from her hand to the sand
				var k: float = 1.0-float(crumb.fly)/float(crumb.fly_total)
				point = Vector2(lerpf(float(crumb.x0),float(crumb.x),k),lerpf(float(crumb.hand),point.y,k)-sin(k*PI)*float(crumb.arc))
			var definition: Dictionary = Config.foods[crumb.food_id]
			var display_size: Array = definition.get("display_size",definition.size)
			var size: Vector2 = Vector2(display_size[0],display_size[1])
			var texture: Texture2D = Config.frames(definition.sprite).get_frame_texture(&"idle",0)
			var rect: Rect2 = Rect2(point-Vector2(size.x*0.5,size.y),size)
			if crumb.food_id == "crumbs":
				texture = Config.frames("food_crumbs_variants").get_frame_texture(&"idle",posmod(int(float(crumb.x)*13.0),5)) # shape picked by position
				draw_texture_rect(texture,Rect2(rect.position+Vector2(0,1),size),false,Color("754a39"))
				draw_texture_rect(texture,rect,false,Color(1.18,1.12,1.0))
			else:
				draw_texture_rect(texture,rect,false)
			if collector == null or collector.can_collect_food(crumb.food_id):
				var glint: Texture2D = PickupShine.overlay(texture,clock,float(crumb.x))
				if glint != null:
					draw_texture_rect(glint,rect,false)
