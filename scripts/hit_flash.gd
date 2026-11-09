class_name HitFlash
extends RefCounted
## White hit flash on one character's sprite. Cutout and rival materials carry a `flash` uniform; sprites
## with no material get a flash-only one for the length of the flash and drop it again at zero.

const PLAIN: Shader = preload("res://assets/shaders/sprite_flash.gdshader")

## Seconds to flash for; 0 when flashing is off or reduce-motion is on.
static func duration() -> float:
	var t: Dictionary = Config.tuning.juice
	return float(t.flash_time) if bool(t.flash) and GameState.options.shake else 0.0

## `left` seconds remain: the flash fades linearly and lands on exactly 0.
static func apply(sprite: CanvasItem, left: float) -> void:
	var amount: float = clampf(left/float(Config.tuning.juice.flash_time),0.0,1.0)
	var material: ShaderMaterial = sprite.material as ShaderMaterial
	if material == null:
		if amount <= 0.0:
			return
		material = ShaderMaterial.new()
		material.shader = PLAIN
		sprite.material = material
	material.set_shader_parameter("flash",amount)
	if amount <= 0.0 and material.shader == PLAIN:
		sprite.material = null
