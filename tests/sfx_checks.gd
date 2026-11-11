class_name SfxChecks
extends RefCounted
## Task 079: new cues, the species cue map, and the character-voice gating of Audio.react.

const SHAKEDOWN: GDScript = preload("res://tests/shakedown_checks.gd")
const CUES: Array[String] = ["dive", "snatch", "bb_screech_long", "bb_screech_short", "bb_dive", "bb_stun", "bb_hit", "bb_shakedown", "bb_slam", "bb_stomp",
	"dog_bark", "whistle", "swat_thwack", "wing_flap_1", "wing_flap_2", "voice_hey_man", "voice_my_chips_woman", "voice_wah_kid"]

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
	check.call(length.call("voice_wah_kid") <= 0.75 and length.call("voice_hey_man") >= 0.15 and length.call("voice_hey_man") <= 0.5,"voice cues keep to their lengths")
	check.call(length.call("swat_thwack") <= 0.8 and length.call("wing_flap_1") >= 0.15 and length.call("wing_flap_1") <= 0.35,"thwack and flaps keep to their lengths")
	check.call(float(Config.tuning.voices.volume_db) > -9.0 and float(Config.tuning.flap.min_gap) >= 0.2,"voices raised, flap block present")
	# Every event cue exists for every register (wah is kid only and the other registers fall back to it).
	for event: String in Config.tuning.voices.events:
		for line: String in Config.tuning.voices.events[event].cues:
			var found: int = 0
			for register: String in Audio.VOICE_REGISTERS:
				found += 1 if Audio.streams.has("voice_%s_%s" % [line,register]) else 0
			check.call(found == (1 if line == "wah" else 3) and Audio.streams.has("voice_%s_kid" % line),"event %s line %s loads for its registers" % [event,line])
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
	# Register selection per kind, and runtime pitch stays jitter-only (within +-5% of the kind's base).
	for kind: String in Config.tuning.voices.pitch:
		var spec: Dictionary = Config.tuning.voices.pitch[kind]
		var mid: float = (float(spec.pitch[0])+float(spec.pitch[1]))*0.5
		var register_ok: bool = true
		var pitch_ok: bool = true
		for i: int in 12:
			_quiet()
			var voiced: AudioStreamPlayer = Audio.react("theft",kind,Node.new())
			var pool: Array = []
			for line: String in Config.tuning.voices.events.theft.cues:
				pool.append(Audio.streams["voice_%s_%s" % [line,spec.register]])
			register_ok = register_ok and voiced != null and voiced.stream in pool
			pitch_ok = pitch_ok and voiced != null and absf(voiced.pitch_scale/mid-1.0) <= 0.05 and voiced.pitch_scale >= float(spec.pitch[0])-0.0001 and voiced.pitch_scale <= float(spec.pitch[1])+0.0001
		check.call(register_ok,"kind %s speaks in its %s register" % [kind,spec.register])
		check.call(pitch_ok,"kind %s runtime pitch is jitter only (+-5%%)" % kind)
	_quiet()
	var woof: AudioStreamPlayer = Audio.react("cry","man",a)
	check.call(woof != null and woof.stream == Audio.streams["voice_wah_kid"],"wah has only a kid register; other kinds fall back to it")

	# A swat that knocks the player plays the thwack and not the stun cue; a stroke plays one flap, held by min_gap.
	var swat_before: Array = Audio.get_children()
	herring.player.invulnerable = 0.0
	herring.player.stun_shield = 0
	herring.player.state = BeachGull.State.GLIDE
	herring.player.swatted(-1.0,herring.player.position+Vector2(-10,0))
	var knocked: Array = []
	for node: Node in Audio.get_children():
		if node is AudioStreamPlayer and not node in swat_before:
			knocked.append((node as AudioStreamPlayer).stream)
	check.call(Audio.streams["swat_thwack"] in knocked and not Audio.streams["stun"] in knocked and not Audio.streams["bb_stun"] in knocked,"swatting the player plays swat_thwack and not stun")
	check.call(Audio.swat_recent(),"the swat stamps Audio.swat_ms")
	Audio.flap_ms = Time.get_ticks_msec()-5000
	var flaps_before: int = Audio.get_child_count()
	herring.player.wing_stroke.emit()
	herring.player.wing_stroke.emit()
	check.call(Audio.get_child_count()-flaps_before == 1,"a stroke plays one flap and min_gap blocks the repeat")
	Audio.flap_ms = Time.get_ticks_msec()-int(float(Config.tuning.flap.min_gap)*1000.0)-20
	flaps_before = Audio.get_child_count()
	herring.player.wing_stroke.emit()
	check.call(Audio.get_child_count()-flaps_before == 1,"a stroke after min_gap plays another flap")
	var bark_cues: Array[String] = Audio.dog_barks.duplicate()
	check.call(not bark_cues.is_empty() and bark_cues.all(func(c: String) -> bool: return Audio.streams.has(c)),"dog barks resolve to loaded cues")
	Audio.dog_barks = ["dog_bark"] # the fallback when no recorded bark is shipped
	Audio.set_approvals({}) # the shipped verdicts reject the generated bark; this checks the fallback mechanism
	var fallback: AudioStreamPlayer = Audio.bark()
	check.call(fallback != null and fallback.stream == Audio.streams["dog_bark"],"with no recorded barks the generated dog_bark plays")
	Audio.set_approvals(Audio._read_approvals())
	Audio.dog_barks = bark_cues

	# Cosmetic audio never consumes the level-seeded rng.
	var state: int = herring.rng.state
	for i: int in 30:
		_quiet()
		Audio.react("theft","woman",a)
		herring._hit_sound()
		herring.species_cue("dive","dive")
	check.call(herring.rng.state == state and Audio.fx_rng != herring.rng,"Audio.react and the sfx helpers leave the level rng untouched")
	check.call(BeachTarget.new().voice_kind() == "default" and owner.voice_kind() == "man","voice_kind picks a pitch range")
	_verdict_checks(check,a,herring)
	_quiet()
	Audio.stop_all()
	for node: Node in [a,b,owner]+runners:
		node.free()
	blackback.queue_free()
	herring.queue_free()
	Config.tuning.juice.audio = previous_audio
	_waves(host,check)

## Task 082: the menu waves bed plays on menus and results, never in a level.
static func _waves(host: Node, check: Callable) -> void:
	var main: Node = host.main
	var previous_audio: bool = bool(Config.tuning.juice.audio)
	var saved_shop: Variant = GameState.progress.get("stage1_complete", false)
	Config.tuning.juice.audio = true
	GameState.progress["stage1_complete"] = true
	var on: Callable = func() -> bool: return Audio.ambience.playing and Audio.ambience_id == "menu_waves" and Audio.ambience.stream != null
	var db: Dictionary = Config.tuning.ambience.menu_waves_db
	check.call(float(db.title_db) < float(db.quiet_db) and float(db.quiet_db) < 0.0,"menu waves sit lower under the title music than on the quiet screens")
	check.call(Audio.ambience.bus == "SFX" and Audio.ambience.playback_type == AudioServer.PLAYBACK_TYPE_STREAM,"the ambience player uses the SFX bus and stream playback")
	check.call(Audio.ambience.get_parent() == Audio and (Audio.AMBIENCE.menu_waves as String).ends_with("menu_waves.ogg"),"one persistent ambience player lives on Audio")
	main._navigate("title")
	check.call(on.call(),"waves play on the title")
	var stream: AudioStream = Audio.ambience.stream
	main._navigate("select")
	check.call(on.call() and Audio.ambience.stream == stream,"waves play on level select")
	var pos: float = Audio.ambience.get_playback_position()
	main._navigate("shop")
	check.call(main.screen == "shop" and on.call() and Audio.ambience.stream == stream,"title to select to shop keeps the same stream playing")
	check.call(Audio.ambience.get_playback_position() >= pos or Audio.ambience.get_playback_position() < 0.5,"navigating between menus does not restart the loop")
	main._navigate("arcade")
	check.call(on.call() and Audio.ambience.stream == stream,"waves play on the gull picker")
	main._navigate("options")
	check.call(on.call(),"waves keep playing on the title options screen")
	main.start_level(2)
	Audio.ambience_tween.custom_step(1.0)
	check.call(not Audio.ambience.playing and Audio.ambience_id == "","start_level stops the waves")
	main._navigate("pause")
	check.call(not Audio.ambience.playing,"pause does not start the waves")
	main._navigate("options_pause")
	check.call(not Audio.ambience.playing,"the pause options screen does not start the waves")
	main._navigate("resume")
	main.game.dismiss_intro()
	main.game.finish()
	check.call(main.screen == "results" and on.call(),"results starts the waves")
	check.call(is_equal_approx(Audio.ambience.volume_db,Audio.AMBIENCE_SILENT_DB),"results waves wait for the sting, then fade in")
	main.clear_game()
	main._navigate("title")
	Audio.stop_ambience(0.0)
	Audio.ambience_tween.custom_step(1.0)
	Config.tuning.juice.audio = false
	Audio.play_ambience("menu_waves")
	check.call(not Audio.ambience.playing,"juice.audio off keeps the waves silent")
	Config.tuning.juice.audio = previous_audio
	GameState.progress["stage1_complete"] = saved_shop
	Audio.stop_ambience(0.0)
	Audio.ambience_tween.custom_step(1.0)

## Task 083: SFX Lab verdicts, with an injected approvals map instead of the real file.
static func _verdict_checks(check: Callable, speaker: Node, game: BeachGame) -> void:
	var reject: Callable = func(stems: Array) -> void:
		var sounds: Dictionary = {}
		for stem: String in stems:
			sounds["assets/audio/%s.ogg" % stem] = {"status": "rejected"}
		for cue: String in Audio.streams: # voices are approved-only, so approve every take this test doesn't reject
			if cue.begins_with("voice_") and not cue in stems:
				sounds["assets/audio/%s.ogg" % cue] = {"status": "approved"}
		Audio.set_approvals(sounds)
	var made: Callable = func(p: AudioStreamPlayer) -> bool: return p != null
	Audio.set_approvals({})
	check.call(not Audio.rejected("snatch") and made.call(Audio.play("snatch")),"an empty approvals map allows everything")
	Audio.set_approvals({"assets/audio/dive.wav": {"status": "approved"}, "assets/audio/snatch.wav": {"status": "unreviewed"}})
	check.call(not Audio.rejected("dive") and not Audio.rejected("snatch"),"approved and unreviewed entries are allowed")
	reject.call(["snatch"])
	check.call(Audio.rejected("snatch") and Audio.play("snatch") == null,"a rejected cue doesn't play")
	Audio.set_approvals({"assets/audio/snatch.wav": {"status": "rejected", "sha1": "0000"}})
	check.call(not Audio.rejected("snatch"),"a rejected entry with a stale sha1 is ignored")
	reject.call(["263786__steaq__seagull-single-call"])
	check.call(Audio.rejected("gull_call") and Audio.play("gull_call") == null,"gull_call maps to its source file stem")
	# react skips a rejected line and picks another, and never plays a rejected take.
	var event: String = "theft"
	var lines: Array = Config.tuning.voices.events[event].cues
	var keep: String = str(lines[0])
	var banned: Array = []
	for line: Variant in lines:
		if str(line) != keep:
			banned.append("voice_%s_man" % line)
	reject.call(banned)
	var all_man: bool = true
	for i: int in 12:
		_quiet()
		var voiced: AudioStreamPlayer = Audio.react(event,"man",speaker)
		all_man = all_man and voiced != null and voiced.stream == Audio.streams["voice_%s_man" % keep]
	check.call(all_man,"react skips rejected lines and plays the remaining one in the same register")
	# Every man take rejected: another register is used, never nothing; every register rejected: null.
	var man_all: Array = []
	var every: Array = []
	for line: Variant in lines:
		man_all.append("voice_%s_man" % line)
		for register: String in Audio.VOICE_REGISTERS:
			every.append("voice_%s_%s" % [line,register])
	reject.call(man_all)
	_quiet()
	var fallback: AudioStreamPlayer = Audio.react(event,"man",speaker)
	check.call(fallback != null and not fallback.stream in [Audio.streams["voice_%s_man" % keep]],"a register with every take rejected falls back to another register")
	reject.call(every)
	_quiet()
	check.call(Audio.react(event,"man",speaker) == null,"all lines rejected gives null")
	# A kid keeps its register while any kid take is left.
	var kid_left: Array = []
	for line: Variant in lines:
		if str(line) != keep and Audio.streams.has("voice_%s_kid" % line):
			kid_left.append("voice_%s_kid" % line)
	reject.call(kid_left+["voice_%s_man" % keep,"voice_%s_woman" % keep])
	_quiet()
	var kid: AudioStreamPlayer = Audio.react(event,"toddler",speaker)
	check.call(kid != null and kid.stream == Audio.streams["voice_%s_kid" % keep],"a kid voice keeps the kid register")
	# Variant picks: rejected flaps, barks and hits are skipped; all rejected plays nothing.
	reject.call(["wing_flap_1"])
	var flaps_ok: bool = true
	for i: int in 12:
		Audio.flap_ms = Time.get_ticks_msec()-5000
		var flap: AudioStreamPlayer = Audio.flap()
		flaps_ok = flaps_ok and flap != null and flap.stream == Audio.streams["wing_flap_2"]
	check.call(flaps_ok,"a rejected wing flap is skipped")
	reject.call(["wing_flap_1","wing_flap_2"])
	Audio.flap_ms = Time.get_ticks_msec()-5000
	check.call(Audio.flap() == null,"all wing flaps rejected plays nothing")
	var barks: Array[String] = Audio.dog_barks.duplicate()
	reject.call(barks.slice(1))
	var barks_ok: bool = true
	for i: int in 8:
		var woof: AudioStreamPlayer = Audio.bark()
		barks_ok = barks_ok and woof != null and woof.stream == Audio.streams[barks[0]]
	check.call(barks_ok,"a rejected bark is skipped")
	reject.call(barks)
	check.call(Audio.bark() == null,"all barks rejected plays nothing")
	reject.call(["gull_hit_1","gull_hit_3"])
	check.call(Audio.pick(Audio.GULL_HITS) == "gull_hit_2" and Audio.pick(Audio.GULL_HITS,0) == "gull_hit_2" and Audio.pick(Audio.GULL_HITS,2) == "gull_hit_2","pick skips rejected hits")
	reject.call(Audio.GULL_HITS)
	check.call(Audio.pick(Audio.GULL_HITS) == "" and Audio.pick(Audio.GULL_HITS,1) == "","pick returns empty when every variant is rejected")
	check.call(game != null and Audio.play(Audio.pick(Audio.GULL_HITS)) == null,"a hit sound with every variant rejected plays nothing")
	_approved_voice_checks(check,speaker)
	Audio.set_approvals({})
	Audio.set_approvals({"assets/audio/x.ogg": 5, "assets/audio/y.ogg": {"status": "rejected"}})
	check.call(Audio.rejected("y") and not Audio.rejected("x"),"malformed entries are ignored")
	Audio.set_approvals({})
	Audio.dog_barks = barks

## Task 085: voices are approved-only (voices.require_approved), fallback and borrow_pitch come from data.
static func _approved_voice_checks(check: Callable, speaker: Node) -> void:
	var approve: Callable = func(cues: Array) -> void:
		var sounds: Dictionary = {}
		for cue: Variant in cues:
			sounds["assets/audio/%s.ogg" % cue] = {"status": "approved"}
		Audio.set_approvals(sounds)
	var cfg: Dictionary = Config.tuning.voices
	check.call(bool(cfg.require_approved),"voices.require_approved is on")
	approve.call(["voice_oi_kid"])
	check.call(Audio.rejected("voice_hey_kid") and not Audio.rejected("voice_oi_kid") and not Audio.rejected("snatch"),"an unreviewed voice take is not allowed, other sounds are unaffected")
	Audio.set_approvals({"assets/audio/voice_oi_kid.ogg": {"status": "approved", "sha1": "0000"}})
	check.call(Audio.rejected("voice_oi_kid"),"a stale approved voice take is not allowed")
	Audio.set_approvals({})
	check.call(not Audio.rejected("voice_hey_kid"),"with no approvals voices still play")
	Config.tuning.voices.require_approved = false
	approve.call(["voice_oi_kid"])
	check.call(not Audio.rejected("voice_hey_kid"),"require_approved off allows unreviewed voices")
	Config.tuning.voices.require_approved = true
	# A man with only kid takes approved plays one at the borrowed pitch.
	approve.call(["voice_hey_kid","voice_oi_kid"])
	var ok: bool = true
	var span: Array = cfg.pitch.man.pitch
	for i: int in 12:
		_quiet()
		var p: AudioStreamPlayer = Audio.react("theft","man",speaker)
		var mul: float = float(cfg.borrow_pitch.man)
		ok = ok and p != null and p.stream in [Audio.streams["voice_hey_kid"],Audio.streams["voice_oi_kid"]] and p.pitch_scale >= float(span[0])*mul-0.0001 and p.pitch_scale <= float(span[1])*mul+0.0001
	check.call(ok,"a man with only kid takes approved plays a kid take at the borrowed pitch")
	_quiet()
	var kid: AudioStreamPlayer = Audio.react("theft","toddler",speaker)
	check.call(kid != null and kid.pitch_scale >= float(cfg.pitch.toddler.pitch[0])-0.0001,"a kid is not pitch-borrowed")
	# Fallback order comes from data: kid takes first, then the order listed.
	approve.call(["voice_hey_woman","voice_hey_man","voice_oi_kid"])
	_quiet()
	check.call(Audio.react("theft","woman",speaker).stream == Audio.streams["voice_hey_woman"],"the own register comes first")
	approve.call(["voice_oi_man","voice_oi_woman"])
	var saved: Variant = cfg.fallback.kid
	cfg.fallback.kid = ["man","woman"]
	_quiet()
	var first: AudioStreamPlayer = Audio.react("theft","toddler",speaker)
	cfg.fallback.kid = ["woman","man"]
	_quiet()
	var second: AudioStreamPlayer = Audio.react("theft","toddler",speaker)
	cfg.fallback.kid = saved
	check.call(first.stream == Audio.streams["voice_oi_man"] and second.stream == Audio.streams["voice_oi_woman"],"fallback order comes from voices.fallback")
	# An event with no allowed take is silent for everyone.
	approve.call(["voice_hey_kid"])
	_quiet()
	check.call(Audio.react("swat","man",speaker) == null and Audio.react("swat","toddler",speaker) == null,"an event with no allowed take returns null")
