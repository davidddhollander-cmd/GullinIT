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
		check.call(is_equal_approx(float(material.get_shader_parameter("wind_strength")),float(game.level.wind.strength)),"palm starts with its level's wind strength")
		check.call(is_equal_approx(float(material.get_shader_parameter("wind_direction")),float(game.level.wind.dir)),"palm starts with its level's wind direction")
	check.call(palms==3 and beach.palm_materials.size()==palms,"all three palms are connected to gameplay wind")
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
