class_name PickupShine
extends RefCounted
## Pixel-art glint for collectable things: a diagonal highlight sweeps across the sprite fill,
## skipping most of it on the third step, followed by a thin extra shine, then a long rest.
const OUTLINE: Color = Color("183b4e")
const LIGHT: Color = Color("fff4da")
# Steps 0-3 sweep the main band, -1 is an empty beat, 4 is the thin extra shine.
const SEQUENCE: Array[int] = [0, 1, 2, 3, -1, 4]
const BAND_START: Array[float] = [0.0, 0.3, 0.75, 1.0]
const EXTRA_AT: float = 0.45
static var masks: Dictionary = {}
static var frames: Dictionary = {}

static func enabled() -> bool:
	return bool(Config.tuning.juice.get("shine",true))

# Which step of the glint is showing at this time, or -1 while resting. The seed staggers items.
static func step(time: float, seed: float) -> int:
	var cycle: float = float(Config.tuning.juice.get("shine_cycle",2.6))
	var beat: float = float(Config.tuning.juice.get("shine_step",0.08))
	var index: int = int(fposmod(time+seed*1.7,cycle)/beat)
	return SEQUENCE[index] if index < SEQUENCE.size() else -1

# The lit-pixel overlay to draw over the sprite with the same rect and transform, or null.
static func overlay(texture: Texture2D, time: float, seed: float) -> Texture2D:
	if texture == null or not enabled():
		return null
	var current: int = step(time,seed)
	return null if current < 0 else frame(texture,current)

static func frame(texture: Texture2D, step_index: int) -> Texture2D:
	var key: int = texture.get_instance_id()*8+step_index
	if frames.has(key):
		return frames[key]
	var source: Image = masks.get(texture.get_instance_id())
	if source == null:
		source = texture.get_image()
		masks[texture.get_instance_id()] = source
	var lit: Image = Image.create(source.get_width(),source.get_height(),false,Image.FORMAT_RGBA8)
	var span: float = float(source.get_width()+source.get_height())
	var width: float = 1.0 if step_index == 4 else (2.0 if span <= 40.0 else 3.0)
	var front: float = (EXTRA_AT if step_index == 4 else BAND_START[step_index])*span
	var count: int = 0
	for y: int in source.get_height():
		for x: int in source.get_width():
			var pixel: Color = source.get_pixel(x,y)
			var diagonal: float = float(x+y)
			if pixel.a < 0.5 or diagonal < front-width or diagonal >= front:
				continue
			if absf(pixel.r-OUTLINE.r)+absf(pixel.g-OUTLINE.g)+absf(pixel.b-OUTLINE.b) < 0.05:
				continue
			lit.set_pixel(x,y,LIGHT)
			count += 1
	var result: Texture2D = ImageTexture.create_from_image(lit) if count > 0 else null
	frames[key] = result
	return result
