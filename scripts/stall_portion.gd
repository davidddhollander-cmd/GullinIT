class_name StallPortion
extends BeachTarget
## The single serving item is a normal swept-food target until received/stolen.
## It is separate from the buyer so a reserve top-up never hides their held food.
signal intercepted(gull: BeachGull)
var recipient: BeachTarget
var linked_drop: Dictionary = {}

func prepare(id: String, random: RandomNumberGenerator, buyer: BeachTarget) -> void:
	kind = "stall_handover"
	info = {"twist":"serve"}
	rng = random
	recipient = buyer
	food_id = id
	food = true
	sprite = AnimatedSprite2D.new()
	sprite.hide()
	add_child(sprite)
	food_sprite = AnimatedSprite2D.new()
	add_child(food_sprite)
	food_sprite.sprite_frames = Config.frames(str(Config.foods[id].sprite))
	food_sprite.animation = &"idle"
	var texture: Texture2D = food_sprite.sprite_frames.get_frame_texture(&"idle",0)
	food_sprite.scale = Vector2(float(Config.foods[id].size[0]),float(Config.foods[id].size[1]))/texture.get_size()
	z_index = 4
	queue_redraw()

func _finish_theft(gull: BeachGull, risky: bool) -> void:
	last_theft_handover = last_theft_direct
	if is_instance_valid(recipient) and not linked_drop.is_empty() and recipient.dropped_item == linked_drop:
		recipient.dropped_pending = false
		recipient.dropped_item = {}
	snatched.emit(self,gull,risky)
	intercepted.emit(gull)
	queue_redraw()

func track_dropped(item: Dictionary) -> void:
	super.track_dropped(item)
	# Reuse the buyer's existing retrieval behavior for a knocked serving item.
	if is_instance_valid(recipient) and not recipient.food and not recipient.dropped_pending:
		linked_drop = item
		recipient.food_id = food_id
		recipient.dropped_pending = true
		recipient.dropped_item = item
		recipient.drop_retrieve = drop_retrieve
		recipient.drop_pickup_time = 0.0

func _draw() -> void:
	if not food:
		return
	# Bright corners identify the complete, deliberately held snatch window.
	PickupShine.draw_target_corners(self,Vector2.ZERO,food_radius()+Vector2(3,3))
