extends RefCounted
## Task 073: floating text stops covering itself. Layout runs without drawing; no real-time timers.

static func _box(fx: BeachEffects, origin: Vector2, text: String) -> Rect2:
	var width: float = fx.font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,8).x
	return Rect2(origin-Vector2(2,8),Vector2(width+4,11))

static func _boxes_clear(fx: BeachEffects, origins: Array) -> bool:
	var boxes: Array[Rect2] = []
	for i: int in origins.size():
		if origins[i] != null:
			boxes.append(_box(fx,origins[i],fx.texts[i].text))
	for i: int in boxes.size():
		for j: int in range(i+1,boxes.size()):
			if boxes[i].intersects(boxes[j]):
				return false
	return true

static func run(_host: Node, check: Callable) -> void:
	var j: Dictionary = Config.tuning.juice
	check.call(is_equal_approx(float(j.score_popup_hold),1.6) and int(j.score_popups_max) == 2,"juice holds score popups 1.6 s, at most 2 live")

	# Two score messages in one frame at one spot: the newer one moves up, the boxes do not overlap.
	var fx := BeachEffects.new()
	var at := Vector2(100,80)
	fx.score_message(at,"+70 MINE ACTUALLY.")
	fx.score_message(at,"+30 YUM")
	var origins: Array = fx.layout_texts(0.0)
	check.call(origins[0] != null and origins[1] != null and _boxes_clear(fx,origins),"two score messages at one spot do not overlap")
	check.call(origins[1] == Vector2(at.x-fx.font.get_string_size("+30 YUM",HORIZONTAL_ALIGNMENT_LEFT,-1,8).x*0.5,at.y) and origins[0].y < origins[1].y and origins[0].y == roundf(origins[0].y),"older score message moves up in whole pixels, newer keeps its spot")
	fx.free()

	# A score message, a shout and a plated message at one spot, with a fixed tip first.
	fx = BeachEffects.new()
	fx.message(at,"TIP",BeachUI.GOLD,3.0,0.0)
	var tip_origin: Vector2 = Vector2(roundf(at.x-fx.font.get_string_size("TIP",HORIZONTAL_ALIGNMENT_LEFT,-1,8).x*0.5),at.y)
	fx.score_message(at,"+70")
	fx.shout(at,"BONK!")
	fx.message(at,"MINE")
	origins = fx.layout_texts(0.0)
	check.call(origins.all(func(o: Variant) -> bool: return o != null) and _boxes_clear(fx,origins),"score, shout and plate at one spot do not overlap")
	check.call(origins[0] == tip_origin,"fixed tip does not move")
	fx.free()

	# Third score message removes the oldest.
	fx = BeachEffects.new()
	fx.score_message(at,"AAA")
	fx.score_message(at,"BBB")
	fx.score_message(at,"CCC")
	var score_texts: Array[String] = []
	for item: Dictionary in fx.texts:
		if item.get("score",false):
			score_texts.append(item.text)
	check.call(score_texts == ["BBB","CCC"],"third score message removes the oldest")
	check.call(is_equal_approx(float(fx.texts[-1].life),float(j.score_popup_hold)+BeachEffects.SCORE_MESSAGE_FADE),"score popup uses the tuned hold plus fade")
	fx.free()

	# Pure layout: a movable text pushed up by a fixed one; newest placed first.
	var placed: Array = BeachEffects.text_layout([
		{"at":Vector2(50,30),"width":20.0,"fixed":true},
		{"at":Vector2(50,30),"width":20.0,"fixed":false},
	],0.0)
	check.call(placed[0] == Vector2(50,30) and placed[1] == Vector2(50,19),"pushed text moves up to a clear whole-pixel spot")

	var newest_first: Array = BeachEffects.text_layout([
		{"at":Vector2(50,30),"width":20.0,"fixed":false},
		{"at":Vector2(50,30),"width":20.0,"fixed":false},
	],0.0)
	check.call(newest_first[1] == Vector2(50,30) and newest_first[0] == Vector2(50,19),"newest movable text keeps its spot, older moves")

	# Near the top: a text that cannot move up on screen is skipped, not drawn off the top.
	var top: Array = BeachEffects.text_layout([
		{"at":Vector2(50,10),"width":20.0,"fixed":true},
		{"at":Vector2(50,10),"width":20.0,"fixed":false},
	],0.0)
	check.call(top[0] == Vector2(50,10) and top[1] == null,"text that would be pushed off the top is skipped")
