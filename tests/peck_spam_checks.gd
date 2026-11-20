extends RefCounted
## Task 102: every ground peck press gives feedback, and rapid presses next to food are not silently dropped.

const BLACKBACK: String = "great-black-backed"

static func fixture(host: Node) -> BeachGame:
	var game := BeachGame.new()
	host.add_child(game)
	var definition: Dictionary = Config.levels[2].duplicate(true)
	definition.spawns = []
	definition.rivals = []
	definition.props = [{"type":"bin","x":190}]
	game.setup(definition,false)
	game.set_physics_process(false)
	game.running = true
	game.intro = 0
	game.input.key_aim = true # keyboard steering with no keys held: the gull stands still instead of walking to the mouse
	game.player.state = BeachGull.State.GROUNDED
	game.player.facing = 1
	game.player.position = Vector2(185,float(Config.tuning.world.ground)-float(Config.tuning.flight.feet_offset))
	game.player.velocity = Vector2.ZERO
	return game

static func key(pressed: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = KEY_E
	event.physical_keycode = KEY_E
	event.pressed = pressed
	return event

## Total bin pecks the game accepted so far (a final hit resets the counter, so add the bursts back in).
static func accepted(game: BeachGame) -> int:
	var bin: Dictionary = game.stash_raids.bins[0]
	var bursts: int = roundi(float(int(bin.capacity)-int(bin.remaining))/float(Config.tuning.world.bin_burst))
	return int(bin.pecks)+bursts*int(Config.tuning.world.bin_pecks)

## Taps E every `period` frames, holding it `hold` frames, for `frames` physics frames at 60 fps. Returns presses and accepted pecks.
static func spam(host: Node, period: int, hold: int, frames: int) -> Dictionary:
	var game: BeachGame = fixture(host)
	game.stash_raids.bins[0].capacity = 999
	game.stash_raids.bins[0].remaining = 999
	var presses: int = 0
	for frame: int in frames:
		if frame%period == 0:
			game._unhandled_input(key(true))
			presses += 1
		if frame%period == hold:
			game._unhandled_input(key(false))
		game._physics_process(1.0/60.0)
	var result: Dictionary = {"presses":presses,"accepted":accepted(game)}
	game.queue_free()
	return result

## AudioStreamPlayers the SFX path has started with this cue's stream (they free themselves when finished).
static func cue_players(cue: String) -> Array:
	return Audio.get_children().filter(func(node: Node) -> bool: return node is AudioStreamPlayer and node.stream == Audio.streams[cue])

static func run(host: Node, check: Callable) -> void:
	# Root cause (task 102): every grounded peck shares world.peck_cooldown (0.18 s), and a press inside it was dropped with no feedback.
	# Tapping at or under 5 per second was fine; faster tapping silently lost about half the presses.
	var seconds: float = 3.0
	var cap: int = floori(seconds/float(Config.tuning.world.peck_cooldown))
	var slow: Dictionary = spam(host,12,3,180)
	check.call(slow.accepted == slow.presses,"5 presses a second next to a bin all land (%d of %d)" % [slow.accepted,slow.presses])
	var fast: Dictionary = spam(host,9,3,180)
	check.call(fast.accepted >= cap - 2 and fast.accepted <= cap + 1,"6.7 presses a second land at the cooldown rate, none lost to bad timing (%d of %d, cap %d)" % [fast.accepted,fast.presses,cap])
	var mash: Dictionary = spam(host,6,3,180)
	check.call(mash.accepted >= cap - 2 and mash.accepted <= cap + 1,"10 presses a second stay capped at the cooldown rate (%d of %d, cap %d)" % [mash.accepted,mash.presses,cap])
	# A press with nothing in reach answers with the ground-peck pose and a quiet whiff.
	var game: BeachGame = fixture(host)
	game.player.position.x = 40.0
	var whiffs: int = cue_players("empty_tap").size()
	game.player.art_event = &""
	game._peck()
	var added: Array = cue_players("empty_tap").slice(whiffs)
	check.call(game.player.art_event == &"peck" and added.size() == 1 and is_equal_approx(added[0].volume_db,BeachGame.PECK_WHIFF_DB) and added[0].bus == "SFX",
		"a peck with nothing in range plays the ground peck and a quiet SFX-bus whiff")
	# A press that eats keeps its own effect and adds no whiff.
	game.player.position.x = 185.0
	game.stash_raids.peck_cooldown = 0.0
	whiffs = cue_players("empty_tap").size()
	game._peck()
	check.call(int(game.stash_raids.bins[0].pecks) == 1 and cue_players("empty_tap").size() == whiffs,"a peck that lands keeps its own effect and makes no whiff")
	# A press during the cooldown with food in reach is held and lands when the cooldown ends.
	game._peck()
	check.call(game.peck_buffered and int(game.stash_raids.bins[0].pecks) == 1,"a press inside the cooldown is held, not lost")
	game._physics_process(0.2) # the cooldown runs out in this frame
	game._physics_process(0.02) # and the held press fires on the next
	check.call(not game.peck_buffered and int(game.stash_raids.bins[0].pecks) == 2,"the held press lands when the cooldown ends")
	game.queue_free()
