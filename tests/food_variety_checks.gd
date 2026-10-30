extends RefCounted
## Pizza slices and the six ice creams: data, stall flavours, family matching and bin scatter.

const SLICES: Array[String] = ["pizza_slice_cheese", "pizza_slice_pepperoni", "pizza_slice_mushroom", "pizza_slice_veggie", "pizza_slice_hawaiian", "pizza_slice_white", "pizza_slice_ham_corn", "pizza_slice_rocket", "pizza_slice_basil"]
const CONES: Array[String] = ["ice_cream_vanilla", "ice_cream_chocolate", "ice_cream_strawberry", "ice_cream_mint", "ice_cream_swirl"]

static func run(suite: Node, check: Callable) -> void:
	var drawable: bool = true
	for id: String in SLICES + CONES:
		var food: Dictionary = Config.foods.get(id, {})
		drawable = drawable and not food.is_empty() and Config.sprites.has(str(food.get("sprite", ""))) and Config.frames(str(food.sprite)).get_frame_texture(&"idle", 0) != null
	check.call(drawable, "every new pizza slice and ice cream is a food with a resolving sprite")
	var cream: Array[String] = Config.family_members("ice_cream")
	var distinct: Dictionary = {}
	for id: String in cream:
		distinct[id] = Config.foods.has(id) and Config.food_family(id) == "ice_cream"
	check.call(cream.size() == 6 and distinct.size() == 6 and not distinct.values().has(false) and cream[0] == "ice_cream", "the ice-cream family is the original plus five distinct flavours")
	check.call(Config.family_members("half_eaten_pizza").size() == 10 and Config.food_family("pizza_slice_basil") == "half_eaten_pizza", "pizza family is the half pizza plus nine slices")
	check.call(Config.food_family("hotdog") == "hotdog" and Config.family_members("hotdog") == ["hotdog"], "foods without a family are their own family")
	var quests: BeachQuests = BeachQuests.new()
	quests.quests.append({"id": "q", "event": "swallowed", "filter": {"food": "ice_cream", "direct": true}, "count": 2, "bonus": 1, "progress": 0, "done": false})
	quests.record("swallowed", {"food": "ice_cream_mint", "direct": true})
	check.call(quests.record("swallowed", {"food": "ice_cream_swirl", "direct": true}).size() == 1 and quests.record("swallowed", {"food": "hotdog", "direct": true}).is_empty(), "any ice cream flavour counts toward an ice cream quest")

	var game := BeachGame.new()
	suite.add_child(game)
	var definition: Dictionary = Config.levels[2].duplicate(true)
	definition.spawns = []
	definition.rivals = []
	definition.props = [{"type": "kiosk", "x": 180, "customer_x": 228}]
	for i: int in 8:
		definition.spawns.append({"type": "kiosk_customer", "x": 300 + i * 20, "food_id": "ice_cream", "station": "ice_cream"})
	game.setup(definition, false)
	game.set_physics_process(false)
	var seen: Dictionary = {}
	var repeats: int = 0
	var previous: String = ""
	var all_cream: bool = true
	for target: BeachTarget in game.spawner.targets:
		seen[target.food_id] = true
		repeats += 1 if target.food_id == previous else 0
		previous = target.food_id
		all_cream = all_cream and Config.food_family(target.food_id) == "ice_cream"
	check.call(game.spawner.targets.size() == 8 and all_cream and seen.size() > 1 and repeats == 0, "new stand customers each get a random ice cream, never the same flavour twice running")
	game.queue_free()

	suite.main.start_level(2)
	var level_game: BeachGame = suite.main.game
	level_game.set_physics_process(false)
	level_game.intro = 0
	level_game.running = true
	var raids: BeachStashRaids = level_game.stash_raids
	var gull: BeachGull = level_game.player
	var bin: Dictionary = raids.bins[0]
	gull.position = Vector2(float(bin.x) - 10, gull.ground_y())
	gull.facing = 1
	gull.land()
	var slices: int = 0
	for round_index: int in 8:
		bin.remaining = int(bin.capacity)
		bin.scatter_index = 0
		raids.items.clear()
		for tap: int in 12:
			raids.peck_cooldown = 0
			raids.peck()
		for item: Dictionary in raids.items:
			slices += 1 if str(item.food_id).begins_with("pizza_slice_") else 0
	check.call(slices > 0, "bin leftovers include the new pizza slices")
