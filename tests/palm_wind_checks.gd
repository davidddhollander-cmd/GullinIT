extends RefCounted
## Verify gameplay wiring, including calm weather and JSON/art refresh.

static func run(game: BeachGame, check: Callable) -> void:
	var beach: BeachBackdrop = game.beach
	var phases: Dictionary = {}
	var palms: int = 0
	for i: int in beach.props.size():
		if beach.props[i].type != "beach_palm":
			continue
		palms += 1
		var material := beach.prop_sprites[i].material as ShaderMaterial
		check.call(material != null,"every gameplay palm uses the approved leaf material")
		if material == null:
			continue
		phases[material.get_shader_parameter("phase")] = true
		var sprite: AnimatedSprite2D = beach.prop_sprites[i]
		var entry: Dictionary = beach.props[i]
		var expected: float = float(Config.sprites.beach_palm.get("visual_scale",1.0))*float(entry.get("scale",1.0))
		check.call(sprite.flip_h==bool(entry.get("flip",false)) and is_equal_approx(sprite.scale.x,expected),"palm honours its flip and scale fields")
		check.call(is_equal_approx(sprite.position.y+float(Config.sprites.beach_palm.frame_h)*expected*0.5,float(entry.get("y",160))),"scaled palm stays planted on its base y")
		check.call(is_equal_approx(float(material.get_shader_parameter("mirror")),-1.0 if sprite.flip_h else 1.0),"mirrored palm sways the same world direction")
		check.call(is_equal_approx(float(material.get_shader_parameter("wind_strength")),float(game.level.wind.strength)),"palm starts with its level's wind strength")
		check.call(is_equal_approx(float(material.get_shader_parameter("wind_direction")),float(game.level.wind.dir)),"palm starts with its level's wind direction")
	check.call(palms>=1 and beach.palm_materials.size()==palms,"every palm is connected to gameplay wind")
	check.call(phases.size()==palms,"palms have different sway phases")
	var old_time: float = beach.time
	var old_strength: float = beach.strength
	var old_direction: int = beach.wind_dir
	for direction: int in [1,-1,0]:
		beach.wind_dir = direction
		beach.strength = 0.0 if direction==0 else 0.55
		beach.tick(0.5)
		for material: ShaderMaterial in beach.palm_materials:
			check.call(is_equal_approx(float(material.get_shader_parameter("wind_direction")),float(direction)),"palm follows wind reversal and calm")
			check.call(is_equal_approx(float(material.get_shader_parameter("wind_strength")),beach.strength),"palm follows the smoothed wind magnitude")
			check.call(is_equal_approx(float(material.get_shader_parameter("preview_time")),beach.time),"palm uses the pausable gameplay clock")
	beach._refresh()
	check.call(beach.palm_materials.size()==palms,"art reload keeps one wind material per palm")
	for material: ShaderMaterial in beach.palm_materials:
		check.call(is_zero_approx(float(material.get_shader_parameter("wind_strength"))),"art reload preserves calm wind")
		check.call(is_equal_approx(float(material.get_shader_parameter("preview_time")),beach.time),"art reload preserves animation time")
	beach.time = old_time
	beach.strength = old_strength
	beach.wind_dir = old_direction
	beach.tick(0.0)
