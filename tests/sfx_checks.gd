class_name SfxChecks
extends RefCounted
## Task 079: new cues, the species cue map, and the character-voice gating of Audio.react.

const SHAKEDOWN: GDScript = preload("res://tests/shakedown_checks.gd")
const CUES: Array[String] = ["dive", "snatch", "bb_screech_long", "bb_screech_short", "bb_dive", "bb_stun", "bb_hit", "bb_shakedown", "bb_slam", "bb_stomp",
	"voice_hey", "voice_oi", "voice_whoa", "voice_aah", "voice_huh", "voice_aww", "voice_hah", "voice_wah", "dog_bark", "whistle"]

## Quiets the voice channel so the next react() is only gated by what the test is about.
static func _quiet(ago_ms: int = 10000) -> void:
	if is_instance_valid(Audio.voice_player):
		Audio.voice_player.stop()
	Audio.voice_last_ms = Time.get_ticks_msec()-ago_ms
	Audio.voice_speaker_ms.clear()

static func run(host: Node, check: Callable) -> void:
	var previous_audio: bool = bool(Config.tuning.juice.audio)
	Config.tuning.juice.audio = true
	for cue: String in CUES:
		check.call(Audio.streams.has(cue) and Audio.streams[cue] is AudioStream,"sfx cue loads: "+cue)
	var length: Callable = func(cue: String) -> float: return (Audio.streams[cue] as AudioStream).get_length()
	check.call(length.call("dive") >= 0.45 and length.call("dive") <= 0.60,"dive swoosh is 0.45-0.60 s")
	check.call(length.call("snatch") >= 0.18 and length.call("snatch") <= 0.28,"snatch reward is 0.18-0.28 s")
	check.call(length.call("bb_dive") >= 0.6 and length.call("bb_dive") <= 0.75,"bb_dive is 0.6-0.75 s")
	check.call(length.call("bb_screech_long") <= 4.55,"bb_screech_long is trimmed to 4.5 s")
	check.call(length.call("voice_wah") <= 0.75 and length.call("voice_hey") >= 0.15 and length.call("voice_hey") <= 0.5,"voice cues keep to their lengths")
	check.call(Config.species.species["great-black-backed"].power.sound == "bb_shakedown","shakedown fires bb_shakedown")

	var blackback: BeachGame = SHAKEDOWN.fixture(host,"great-black-backed")
	var herring: BeachGame = SHAKEDOWN.fixture(host,"herring")
	check.call(blackback.species_cue("dive","dive") == "bb_dive" and blackback.species_cue("stun","stun") == "bb_stun","black-back maps dive and stun to bb_ cues")
	check.call(blackback.species_cue("screech_long","screech_long") == "bb_screech_long" and blackback.species_cue("screech_short","screech_short") == "bb_screech_short","black-back maps both screeches")
	check.call(herring.species_cue("dive","dive") == "dive" and herring.species_cue("screech_long","screech_long") == "screech_long","other species fall back to the default cue")
	check.call(blackback.species_cue("unmapped","fallback") == "fallback","an unmapped key falls back")

	var a := Node.new()
	var b := Node.new()
	_quiet()
	var first: AudioStreamPlayer = Audio.react("theft","default",a)
	check.call(first != null,"a theft voice plays")
	Audio.voice_last_ms = Time.get_ticks_msec()
	check.call(Audio.react("theft","default",b) == null,"gap: a second voice inside the event gap is refused")
	_quiet()
	check.call(Audio.react("cry","toddler",a) != null,"speaker A voices")
	_quiet(10000)
	Audio.voice_speaker_ms[a.get_instance_id()] = Time.get_ticks_msec()
	check.call(Audio.react("cry","toddler",a) == null,"speaker_gap: the same speaker is refused")
	check.call(Audio.react("cry","toddler",b) != null,"speaker_gap: a different speaker is allowed")
	# One voice at a time: a playing voice blocks everything but theft.
	Audio.voice_last_ms = Time.get_ticks_msec()-10000
	check.call(is_instance_valid(Audio.voice_player) and Audio.voice_player.playing and Audio.react("panic","default",Node.new()) == null,"a playing voice blocks other events")
	check.call(Audio.react("theft","default",Node.new()) != null,"theft may cut in once its gap has passed")
	# chance 0 never plays.
	var cry: Dictionary = Config.tuning.voices.events.cry
	var chance: float = float(cry.chance)
	cry.chance = 0.0
	var played: int = 0
	for i: int in 25:
		_quiet()
		played += 1 if Audio.react("cry","toddler",Node.new()) != null else 0
	cry.chance = chance
	check.call(played == 0,"chance 0 never plays")

	# A stampede of many runners makes one voice.
	var runners: Array[BeachTarget] = []
	for i: int in 12:
		var runner := BeachTarget.new()
		runner.kind = "kiosk_customer"
		runner.position.x = 100.0+i*10.0
		runner.panic.state = CrowdPanic.State.LOOK_UP
		runners.append(runner)
	_quiet()
	var before: int = Audio.get_child_count()
	CrowdPanic.stampede(runners,50.0)
	check.call(Audio.get_child_count()-before == 1 and runners.all(func(r: BeachTarget) -> bool: return r.panic.stampede_pending),"a 12-runner stampede produces exactly one voice")
	CrowdPanic.pulse(runners,50.0)
	check.call(Audio.get_child_count()-before == 1,"pulse plays nothing")

	# Theft reaction: one voice per new reaction, not per snatch.
	var owner := BeachTarget.new()
	owner.kind = "kiosk_customer"
	_quiet()
	before = Audio.get_child_count()
	owner.reaction.theft(owner,herring.player)
	check.call(Audio.get_child_count()-before == 1,"a new theft reaction voices once")
	_quiet()
	owner.reaction.theft(owner,herring.player)
	check.call(Audio.get_child_count()-before == 1,"a repeat theft during the same reaction stays quiet")
	# Cosmetic audio never consumes the level-seeded rng.
	var state: int = herring.rng.state
	for i: int in 30:
		_quiet()
		Audio.react("theft","woman",a)
		herring._hit_sound()
		herring.species_cue("dive","dive")
	check.call(herring.rng.state == state and Audio.fx_rng != herring.rng,"Audio.react and the sfx helpers leave the level rng untouched")
	check.call(BeachTarget.new().voice_kind() == "default" and owner.voice_kind() == "man","voice_kind picks a pitch range")
	_quiet()
	Audio.stop_all()
	for node: Node in [a,b,owner]+runners:
		node.free()
	blackback.queue_free()
	herring.queue_free()
	Config.tuning.juice.audio = previous_audio
