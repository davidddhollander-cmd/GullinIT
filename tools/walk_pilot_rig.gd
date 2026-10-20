extends Node2D
const STRIDE: float = 28
## Animates generated cutout artwork. No character anatomy is drawn in code.
var metadata: Dictionary
var body: Sprite2D
var limbs: Array[Dictionary] = []
var foot_world: Array[Vector2] = []
var palm: Vector2

func setup(data: Dictionary) -> void:
	metadata = data
	for side: String in ["far","near"]:
		var pieces: Dictionary = {}
		for piece: String in ["upper","lower","foot"]:
			var definition: Dictionary = data.parts[side+"-"+piece]
			var sprite := Sprite2D.new()
			sprite.texture = load(definition.file)
			sprite.centered = false
			sprite.offset = -Vector2(definition.pivot[0],definition.pivot[1])
			sprite.scale = Vector2.ONE*0.125
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.z_index = 0 if side=="far" else 2
			add_child(sprite)
			pieces[piece] = sprite
		limbs.append(pieces)
	body = Sprite2D.new()
	body.texture = load(data.body)
	body.scale = Vector2.ONE*0.5
	body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	body.z_index = 1
	add_child(body)
	pose(0,1)

static func foot_position(phase: float, ankle_height: float) -> Vector2:
	var p: float = fposmod(phase,1)
	if p<0.5:
		return Vector2(STRIDE*0.25-STRIDE*p,-ankle_height)
	var swing: float = (p-0.5)*2
	return Vector2(-STRIDE*0.25+STRIDE*0.5*swing,-ankle_height-sin(swing*PI)*4)

static func knee_position(hip: Vector2, ankle: Vector2) -> Vector2:
	var delta := ankle-hip
	var gap: float = minf(delta.length(),13.99)
	return (hip+ankle)*0.5+Vector2(delta.y,-delta.x).normalized()*sqrt(maxf(0,49-gap*gap*0.25))

func pose(phase: float, facing: float) -> void:
	scale.x = facing
	var bob: float = -0.5+cos(phase*TAU*2)*0.5
	body.position = Vector2(0,-58+body.texture.get_height()*0.25+bob)
	palm = Vector2(metadata.palm[0],metadata.palm[1])+Vector2(0,bob)
	foot_world.clear()
	for leg: int in 2:
		var hip := Vector2(-2 if leg==0 else 2,-13+bob)
		var ankle := foot_position(phase+(0.5 if leg==0 else 0),float(metadata.ankle_height))
		var knee := knee_position(hip,ankle)
		var pieces: Dictionary = limbs[leg]
		pieces.upper.position = hip
		pieces.upper.rotation = (knee-hip).angle()-PI*0.5
		pieces.lower.position = knee
		pieces.lower.rotation = (ankle-knee).angle()-PI*0.5
		pieces.foot.position = ankle
		foot_world.append(Vector2(ankle.x*facing,ankle.y)+position)
