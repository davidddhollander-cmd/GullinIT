extends Node2D
func _ready():
 var background=ColorRect.new()
 background.color=Color8(24,59,78)
 background.size=Vector2(320,180)
 add_child(background)
 var title=Label.new()
 title.text="RUNTIME SIGN PREVIEW - GULLPIXEL"
 title.position=Vector2(8,8)
 title.size=Vector2(304,16)
 title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 title.add_theme_font_override("font",load("res://assets/fonts/gull_pixel.fnt"))
 title.add_theme_font_size_override("font_size",8)
 title.add_theme_color_override("font_color",Color8(255,244,218))
 add_child(title)
 var holder=Node2D.new()
 holder.position=Vector2(160,104)
 add_child(holder)
 var sprite=Sprite2D.new()
 sprite.texture=load("res://assets/lab/pier-restaurant-props-v1/beach-hole-restaurant-v2.png")
 sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 holder.add_child(sprite)
 var label=Label.new()
 label.text="THE BEACH HOLE"
 label.position=Vector2(-47,-37)
 label.size=Vector2(94,15)
 label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 label.add_theme_font_override("font",load("res://assets/fonts/gull_pixel.fnt"))
 label.add_theme_font_size_override("font_size",8)
 label.add_theme_color_override("font_color",Color8(24,59,78))
 label.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 holder.add_child(label)
