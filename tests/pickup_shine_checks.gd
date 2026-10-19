extends RefCounted

static func lit_pixels(overlay: Texture2D) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	if overlay == null:
		return found
	var image: Image = overlay.get_image()
	for y: int in image.get_height():
		for x: int in image.get_width():
			if image.get_pixel(x,y).a > 0.0:
				found.append(Vector2i(x,y))
	return found

static func run(check: Callable) -> void:
	var texture: Texture2D = BeachTarget.BAG_TEXTURES[0]
	var source: Image = texture.get_image()
	var union: Dictionary = {}
	var steps_lit: Array[int] = []
	for step: int in 5:
		var glint: Texture2D = PickupShine.frame(texture,step)
		if glint == null:
			continue
		steps_lit.append(step)
		var inside: bool = true
		for pixel: Vector2i in lit_pixels(glint):
			union[pixel] = true
			var original: Color = source.get_pixel(pixel.x,pixel.y)
			var outline: bool = absf(original.r-PickupShine.OUTLINE.r)+absf(original.g-PickupShine.OUTLINE.g)+absf(original.b-PickupShine.OUTLINE.b) < 0.05
			if original.a < 0.5 or outline:
				inside = false
		check.call(inside,"shine step %d lights only opaque fill pixels" % step)
	check.call(steps_lit.size() >= 3,"the glint lights the bag in most steps: %s" % str(steps_lit))
	check.call(union.size() > 8,"the full sweep covers a visible part of the bag: %d" % union.size())
	var first: Array[Vector2i] = lit_pixels(PickupShine.frame(texture,0))
	var third: Array[Vector2i] = lit_pixels(PickupShine.frame(texture,2))
	check.call(first != third,"the band moves between steps")
	check.call(PickupShine.frame(texture,1) == PickupShine.frame(texture,1),"glint frames are cached")
	var resting: int = 0
	var shining: int = 0
	for tick: int in 260:
		if PickupShine.step(tick*0.01,0.0) < 0:
			resting += 1
		else:
			shining += 1
	check.call(resting > shining*3 and shining > 0,"items rest most of the cycle: %d rest / %d shine" % [resting,shining])
	var offsets: Dictionary = {}
	for seed: int in 6:
		offsets[PickupShine.step(0.1,float(seed))] = true
	check.call(offsets.size() > 1,"seeds stagger neighbouring items")
	var juice: Dictionary = Config.tuning.juice
	juice.shine = false
	check.call(PickupShine.overlay(texture,0.1,0.0) == null,"shine can be turned off")
	juice.shine = true
