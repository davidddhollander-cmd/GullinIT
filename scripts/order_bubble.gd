extends Control
## Tiny world-anchored UI, advanced only by the scaled purchase clock.
const DURATION: float = 0.9
const INK := Color("183b4e")
const PAPER := Color("fff4da")
var clock: float = 0.0
var panel: StyleBoxFlat

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	size = Vector2(16,9)
	z_index = 5
	z_as_relative = false
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	panel = StyleBoxFlat.new()
	panel.bg_color = PAPER
	panel.border_color = INK
	panel.set_border_width_all(1)
	panel.set_corner_radius_all(3)
	panel.anti_aliasing = false
	modulate.a = 0.0

func dot_phase() -> int:
	return int(clock/0.12)%3

func advance(delta: float) -> bool:
	clock += delta
	modulate.a = minf(clampf(clock/0.06,0.0,1.0),clampf((DURATION-clock)/0.12,0.0,1.0))
	queue_redraw()
	return clock>=DURATION

func _draw() -> void:
	draw_style_box(panel,Rect2(Vector2.ZERO,size))
	# UI speech tail, not character artwork.
	draw_colored_polygon(PackedVector2Array([Vector2(5,8),Vector2(9,8),Vector2(6,12)]),INK)
	draw_colored_polygon(PackedVector2Array([Vector2(6,8),Vector2(8,8),Vector2(6,10)]),PAPER)
	for index: int in 3:
		draw_rect(Rect2(4+index*3,4 if index==dot_phase() else 5,2,1),INK)
