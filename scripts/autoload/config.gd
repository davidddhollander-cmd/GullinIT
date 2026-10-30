extends Node
## JSON is the single source of gameplay tuning. Reload is transactional.
signal reloaded
var tuning: Dictionary = {}
var targets: Dictionary = {}
var foods: Dictionary = {}
var sprites: Dictionary = {}
var quips: Dictionary = {}
var species: Dictionary = {} ## data/species.json: {unlock_all, species:{id:{name,blurb,price,flight,dive,wind,stun,shove}}}
var trainer: Dictionary = {} ## data/trainer.json: Screeches McCrumbs' pop-up copy
var perks: Dictionary = {} ## data/perks.json: {slots, perks:{id:{name,blurb,price,...effect values}}}
var levels: Array[Dictionary] = []
var frames_cache: Dictionary = {}
var last_error: String = ""
var layout_rules: Dictionary = {}
var default_world: Dictionary = {}

func apply_level_world(level: Dictionary) -> void:
	tuning.world = default_world.duplicate(true)
	tuning.world.merge(level.get("world",{}),true)
	tuning.world.beach_max_x = minf(float(tuning.world.width)-20,float(tuning.world.promenade_start)-20)
	tuning.world.beach_scatter_max_x = minf(float(tuning.world.width)-12,float(tuning.world.promenade_start)-12)

func _ready() -> void:
	reload_data()

func read_json(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		last_error = "Cannot read " + path
		return {}
	var parser: JSON = JSON.new()
	if parser.parse(file.get_as_text()) != OK or not parser.data is Dictionary:
		last_error = "Invalid JSON: " + path
		return {}
	return parser.data

func reload_data() -> bool:
	last_error = ""
	var next: Dictionary = {}
	for key: String in ["tuning", "targets", "foods", "sprites", "quips", "species", "perks", "trainer"]:
		next[key] = read_json("res://data/%s.json" % key)
	var next_levels: Array[Dictionary] = []
	var next_layout: Dictionary = read_json("res://data/level_layout.json")
	for i: int in range(1, 8):
		next_levels.append(read_json("res://data/levels/level_%02d.json" % i))
	if not last_error.is_empty():
		return false
	for key: String in ["flight", "dive", "wind", "score", "world", "juice", "rival"]:
		if not next.tuning.has(key):
			last_error = "Missing tuning section: " + key
			return false
	for id: String in next.foods:
		var food: Dictionary = next.foods[id]
		if not food.get("category", "") in ["small","medium","large"] or int(food.get("points",0)) <= 0 or not next.sprites.has(food.get("sprite","")) or not next.foods.has(food.get("family",id)):
			last_error = "Invalid food definition: " + id
			return false
	for id: String in next.targets:
		for choice: String in next.targets[id].get("foods",[]):
			if not next.foods.has(choice):
				last_error = "Unknown food on target: " + id
				return false
	tuning = next.tuning
	default_world = tuning.world.duplicate(true)
	targets = next.targets
	foods = next.foods
	sprites = next.sprites
	quips = next.quips
	species = next.species
	perks = next.perks
	trainer = next.trainer
	levels = next_levels
	layout_rules = next_layout
	for i: int in levels.size():
		levels[i] = BeachLevelGenerator.generate(levels[i],layout_rules)
	frames_cache.clear()
	reloaded.emit()
	return true

## Look-alike foods share a "family" in foods.json (the base food's id); a food without one is its own family.
func food_family(id: String) -> String:
	return str(foods.get(id,{}).get("family",id))

## The base food first, then every food that names it as family.
func family_members(family: String) -> Array[String]:
	var members: Array[String] = []
	if foods.has(family):
		members.append(family)
	for id: String in foods:
		if id != family and food_family(id) == family:
			members.append(id)
	return members

func frames(sprite_id: String) -> SpriteFrames:
	if frames_cache.has(sprite_id):
		return frames_cache[sprite_id]
	if sprite_id == "old_man":
		frames_cache[sprite_id] = OldManArt.frames()
		return frames_cache[sprite_id]
	var entry: Dictionary = sprites[sprite_id]
	var result: SpriteFrames = SpriteFrames.new()
	result.remove_animation(&"default")
	for animation: String in entry.animations:
		var details: Dictionary = entry.animations[animation]
		# Independent generated animation sets can share an identity without
		# overwriting atlas cells used by its walk, bite or reaction artwork.
		var texture: Texture2D = load(details.get("file",entry.file)) as Texture2D
		var columns: int = maxi(1, texture.get_width() / int(entry.frame_w))
		result.add_animation(animation)
		result.set_animation_speed(animation, details.fps)
		result.set_animation_loop(animation, details.loop)
		for index: int in details.frames:
			var atlas: AtlasTexture = AtlasTexture.new()
			atlas.atlas = texture
			if entry.has("regions"):
				var crop: Array = entry.regions[index].region
				var offset: Array = entry.regions[index].offset
				atlas.region = Rect2(crop[0],crop[1],crop[2],crop[3])
				atlas.margin = Rect2(offset[0],offset[1],float(entry.frame_w)-float(crop[2]),float(entry.frame_h)-float(crop[3]))
			else:
				atlas.region = Rect2((index % columns) * int(entry.frame_w), (index / columns) * int(entry.frame_h), entry.frame_w, entry.frame_h)
			atlas.filter_clip = true
			result.add_frame(animation, atlas)
	frames_cache[sprite_id] = result
	return result
