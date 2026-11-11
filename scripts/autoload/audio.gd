extends Node
const GULL_CALL: AudioStream = preload("res://assets/audio/263786__steaq__seagull-single-call.ogg")
var streams: Dictionary = {}
var music: AudioStreamPlayer
# Looping soundtrack: title theme on the title screen, Neon Boardwalk (124 bpm) on Training Day,
# then levels cycle through LEVEL_MUSIC (see tools/compose_music.py).
const MUSIC_TRACKS: Dictionary = {
	"title": "res://assets/audio/music/title_theme.ogg",
	"lounge": "res://assets/audio/music/lounge_loop.ogg",
	"beach": "res://assets/audio/music/beach_loop.ogg",
	"synth": "res://assets/audio/music/synth_loop.ogg",
	"drive": "res://assets/audio/music/drive_loop.ogg",
	"pier": "res://assets/audio/music/pier_loop.ogg",
}
const LEVEL_MUSIC: Array[String] = ["synth", "beach", "drive", "pier"]
const MUSIC_DB: float = -3.0
const MUSIC_DUCK_DB: float = -14.0
const MUSIC_SILENT_DB: float = -40.0
var music_track: String = ""
var music_tween: Tween
## Cosmetic randomness only: never touch the level-seeded rng, or level determinism breaks.
var fx_rng: RandomNumberGenerator = RandomNumberGenerator.new()
const BB_CUES: Array[String] = ["bb_screech_long", "bb_screech_short", "bb_dive", "bb_stun", "bb_hit", "bb_shakedown", "bb_slam", "bb_stomp"]
const VOICE_LINES: Array[String] = ["hey", "oi", "my_chips", "no_no", "whoa", "huh", "eek", "shoo", "get_off", "hah", "gotcha", "aww", "ugh", "hmph", "aah", "wah"]
const VOICE_REGISTERS: Array[String] = ["man", "woman", "kid"]
const MISC_CUES: Array[String] = ["dog_bark", "whistle", "swat_thwack", "wing_flap_1", "wing_flap_2"]
var dog_barks: Array[String] = [] ## "dog_bark_1..": real recorded barks when present, else the generated "dog_bark"
var swat_ms: int = -1000000 ## when a person's swat last knocked a gull
var flap_ms: int = -1000000
var voice_last_ms: int = -1000000 ## when any character voice last started
var voice_speaker_ms: Dictionary = {} ## speaker instance id -> last voice start
var voice_player: AudioStreamPlayer
## One persistent looping bed on the SFX bus (menu waves), so SFX volume, mute and juice.audio apply.
const AMBIENCE: Dictionary = {"menu_waves": "res://assets/audio/menu_waves.ogg"}
const AMBIENCE_SILENT_DB: float = -60.0
var ambience: AudioStreamPlayer
var ambience_id: String = ""
var ambience_tween: Tween
## SFX Lab verdicts (tools/sfx_lab): cue names the lab marked rejected. Empty or missing file allows everything.
const APPROVALS_PATH: String = "res://data/sfx_approvals.json"
const GULL_HITS: Array[String] = ["gull_hit_1", "gull_hit_2", "gull_hit_3"]
const CUE_FILES: Dictionary = {"gull_call": "263786__steaq__seagull-single-call"} ## cue -> file stem when they differ
var rejected_cues: Dictionary = {}

func _ready() -> void:
	for bus: String in ["SFX", "Music"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	apply_options()
	set_approvals(_read_approvals())
	for cue: String in ["snatch", "dive", "stun", "gust", "click"]:
		var path: String = "res://assets/audio/%s.wav" % cue
		if ResourceLoader.exists(path):
			streams[cue] = load(path)
	for cue: String in ["bag_thump", "bin_rattle", "stash_release", "release_accent", "empty_tap"]:
		streams[cue] = _stash_stream(cue)
	streams["gull_call"] = GULL_CALL
	for cue: String in ["screech_long", "screech_short", "gang_call", "gull_hit_1", "gull_hit_2", "gull_hit_3", "score", "ui_confirm", "ui_back", "ui_error", "level_end", "level_end_fail", "thunder_1", "thunder_2"] + BB_CUES + MISC_CUES:
		streams[cue] = load("res://assets/audio/%s.ogg" % cue)
	for line: String in VOICE_LINES:
		for register: String in VOICE_REGISTERS:
			var path: String = "res://assets/audio/voice_%s_%s.ogg" % [line,register]
			if ResourceLoader.exists(path):
				streams["voice_%s_%s" % [line,register]] = load(path)
	for i: int in range(1,5):
		var bark: String = "res://assets/audio/dog_bark_%d.ogg" % i
		if ResourceLoader.exists(bark):
			streams["dog_bark_%d" % i] = load(bark)
			dog_barks.append("dog_bark_%d" % i)
	if dog_barks.is_empty():
		dog_barks.append("dog_bark")
	music = AudioStreamPlayer.new()
	music.bus = "Music"
	music.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	music.volume_db = MUSIC_DB
	add_child(music)
	ambience = AudioStreamPlayer.new()
	ambience.bus = "SFX"
	ambience.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	ambience.volume_db = AMBIENCE_SILENT_DB
	add_child(ambience)

func _read_approvals() -> Dictionary:
	if not FileAccess.file_exists(APPROVALS_PATH):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(APPROVALS_PATH))
	return parsed.get("sounds", {}) if parsed is Dictionary and parsed.get("sounds") is Dictionary else {}

## `sounds` is the approvals file's "sounds" map (path -> {status, sha1}). Only `rejected` entries matter.
## An entry whose recorded sha1 differs from the source file on disk is stale and ignored; in an export the
## .ogg source is gone (get_sha1 is empty), so there the rejected status is authoritative.
func set_approvals(sounds: Dictionary) -> void:
	rejected_cues.clear()
	for path: Variant in sounds:
		var entry: Variant = sounds[path]
		if not entry is Dictionary or entry.get("status") != "rejected":
			continue
		var disk: String = _sha1("res://" + str(path))
		if disk != "" and entry.has("sha1") and disk != str(entry.sha1):
			continue
		rejected_cues[str(path).get_file().get_basename()] = true

func _sha1(path: String) -> String: ## "" when the source file isn't readable (exports ship only the imported copy)
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()
	if bytes.is_empty():
		return ""
	var ctx: HashingContext = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA1)
	ctx.update(bytes)
	return ctx.finish().hex_encode()

func rejected(cue: String) -> bool:
	return rejected_cues.has(CUE_FILES.get(cue, cue))

## A random cue from `cues` that isn't rejected, or "" when all are. With `start` >= 0 it is the first
## allowed cue from that index on (for deterministic alternation); "" plays nothing.
func pick(cues: Array, start: int = -1) -> String:
	var ok: Array = cues.filter(func(c: String) -> bool: return not rejected(c))
	if ok.is_empty():
		return ""
	if start < 0:
		return str(ok[fx_rng.randi()%ok.size()])
	for i: int in cues.size():
		if not rejected(str(cues[(start+i)%cues.size()])):
			return str(cues[(start+i)%cues.size()])
	return ""

# Switches the soundtrack, fading the old track out and the new one in. Calling it
# with the track that is already playing only restores full volume.
func play_music(track: String, fade: float = 0.6) -> void:
	if not MUSIC_TRACKS.has(track) or not is_instance_valid(music):
		return
	if track == music_track and music.playing:
		_fade_music(MUSIC_DB, fade * 0.5)
		return
	var stream: Variant = load(MUSIC_TRACKS[track]) if ResourceLoader.exists(MUSIC_TRACKS[track]) else null
	if not stream is AudioStream:
		return
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	music_track = track
	_kill_music_tween()
	if music.playing and fade > 0.0:
		music_tween = create_tween()
		music_tween.tween_property(music, "volume_db", MUSIC_SILENT_DB, fade * 0.5)
		music_tween.tween_callback(func() -> void: _start_music(stream, fade * 0.5))
	else:
		_start_music(stream, fade)

func _start_music(stream: AudioStream, fade: float) -> void:
	music.stream = stream
	music.volume_db = MUSIC_SILENT_DB if fade > 0.0 else MUSIC_DB
	music.play()
	_fade_music(MUSIC_DB, fade)

# Fades the current track away and stops it (the result sign plays its own reaction).
func stop_music(fade: float = 0.8) -> void:
	if not is_instance_valid(music) or not music.playing:
		return
	music_track = ""
	_kill_music_tween()
	music_tween = create_tween()
	music_tween.tween_property(music, "volume_db", MUSIC_SILENT_DB, fade)
	music_tween.tween_callback(music.stop)

# Pause menus keep the music playing but quietly underneath.
func duck_music(ducked: bool) -> void:
	if is_instance_valid(music) and music.playing:
		_fade_music(MUSIC_DUCK_DB if ducked else MUSIC_DB, 0.25)

func _fade_music(target_db: float, duration: float) -> void:
	_kill_music_tween()
	if duration <= 0.0:
		music.volume_db = target_db
		return
	music_tween = create_tween()
	music_tween.tween_property(music, "volume_db", target_db, duration)

func _kill_music_tween() -> void:
	if music_tween != null and music_tween.is_valid():
		music_tween.kill()

## Fades the ambience bed `id` in to `db` after `delay` seconds. The same id already playing only
## fades to the new level, it never restarts the loop.
func play_ambience(id: String, fade: float = 1.0, db: float = -12.0, delay: float = 0.0) -> void:
	if not AMBIENCE.has(id) or not is_instance_valid(ambience) or not bool(Config.tuning.juice.audio):
		return
	if not (id == ambience_id and ambience.playing):
		var stream: Variant = load(AMBIENCE[id]) if ResourceLoader.exists(AMBIENCE[id]) else null
		if not stream is AudioStream:
			return
		if stream is AudioStreamOggVorbis:
			(stream as AudioStreamOggVorbis).loop = true
		ambience_id = id
		ambience.stream = stream
		ambience.volume_db = AMBIENCE_SILENT_DB
		ambience.play()
	_kill_ambience_tween()
	ambience_tween = create_tween()
	if delay > 0.0:
		ambience_tween.tween_interval(delay)
	ambience_tween.tween_property(ambience, "volume_db", db, maxf(fade, 0.01))

func stop_ambience(fade: float = 0.8) -> void:
	if not is_instance_valid(ambience) or not ambience.playing:
		return
	ambience_id = ""
	_kill_ambience_tween()
	ambience_tween = create_tween()
	ambience_tween.tween_property(ambience, "volume_db", AMBIENCE_SILENT_DB, maxf(fade, 0.01))
	ambience_tween.tween_callback(ambience.stop)

func _kill_ambience_tween() -> void:
	if ambience_tween != null and ambience_tween.is_valid():
		ambience_tween.kill()

func stop_all() -> void:
	for player: Node in get_children():
		if player is AudioStreamPlayer:
			player.stop()

func apply_options() -> void:
	for bus: String in ["Master", "SFX", "Music"]:
		var volume: float = clampf(float(GameState.options[bus]), 0.0, 1.0)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus), linear_to_db(maxf(volume, 0.001)))
		AudioServer.set_bus_mute(AudioServer.get_bus_index(bus), volume <= 0.001)

func play(cue: String, pitch: float = 1.0, volume_db: float = 0.0) -> AudioStreamPlayer:
	if not streams.has(cue) or not bool(Config.tuning.juice.audio) or rejected(cue):
		return null
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.bus = "SFX"
	# Web builds otherwise use browser "Sample" playback, which cannot play the
	# procedurally generated cues; Godot's own mixer handles every stream.
	player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	player.stream = streams[cue]
	player.pitch_scale = pitch
	player.volume_db = volume_db
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
	return player

## A character voice for `event` (a key of tuning.voices.events). `kind` picks the pitch range, `speaker` the per-speaker gap.
## One voice at a time (theft may cut in); returns the player, or null when gated or the dice say no.
func react(event: String, kind: String, speaker: Object) -> AudioStreamPlayer:
	var cfg: Dictionary = Config.tuning.voices
	var spec: Dictionary = cfg.events.get(event, {})
	if spec.is_empty():
		return null
	var now: int = Time.get_ticks_msec()
	var id: int = speaker.get_instance_id() if speaker != null else 0
	if now-voice_last_ms < int(float(spec.gap)*1000.0) or now-int(voice_speaker_ms.get(id,-1000000)) < int(float(cfg.speaker_gap)*1000.0):
		return null
	if is_instance_valid(voice_player) and voice_player.playing and event != "theft":
		return null
	if fx_rng.randf() >= float(spec.chance):
		return null
	var cues: Array = spec.cues
	var voice: Dictionary = cfg.pitch.get(kind, cfg.pitch.default)
	var span: Array = voice.pitch
	var cue: String = _voice_cue(cues,str(voice.register))
	if cue == "":
		return null
	var player: AudioStreamPlayer = play(cue,fx_rng.randf_range(float(span[0]),float(span[1])),float(cfg.volume_db))
	if player == null:
		return null
	if is_instance_valid(voice_player) and voice_player.playing:
		voice_player.queue_free() # stop() would skip the finished signal that frees it
	voice_player = player
	voice_last_ms = now
	voice_speaker_ms[id] = now
	if voice_speaker_ms.size() > 64: # ponytail: drop stale speakers; they would pass the gap anyway
		for key: Variant in voice_speaker_ms.keys():
			if now-int(voice_speaker_ms[key]) > int(float(cfg.speaker_gap)*1000.0):
				voice_speaker_ms.erase(key)
	return player

## A random allowed take among `lines` in `register`. If none is left, the other registers in turn: a line
## with no take of its own (wah is kid only) borrows one, and a kid is voiced by an adult only as a last resort.
func _voice_cue(lines: Array, register: String) -> String:
	for reg: String in [register]+VOICE_REGISTERS.filter(func(r: String) -> bool: return r != register):
		var ok: Array[String] = []
		for line: Variant in lines:
			var cue: String = "voice_%s_%s" % [line,reg]
			if streams.has(cue) and not rejected(cue):
				ok.append(cue)
		if not ok.is_empty():
			return ok[fx_rng.randi()%ok.size()]
	return ""

## A person's swat knocked a gull: the thwack, with a stamp so the player's own stun cue can yield for this frame.
func swat_hit() -> void:
	swat_ms = Time.get_ticks_msec()
	play("swat_thwack",fx_rng.randf_range(0.95,1.05))

func swat_recent() -> bool:
	return Time.get_ticks_msec()-swat_ms <= 60

## One wing stroke of the player gull; flap.min_gap keeps it light. `pitch`/`extra_db` come from the species sfx block.
func flap(pitch: float = 1.0, extra_db: float = 0.0) -> AudioStreamPlayer:
	var cfg: Dictionary = Config.tuning.flap
	var now: int = Time.get_ticks_msec()
	if now-flap_ms < int(float(cfg.min_gap)*1000.0):
		return null
	var player: AudioStreamPlayer = play(pick(["wing_flap_1","wing_flap_2"]),pitch*fx_rng.randf_range(0.92,1.08),float(cfg.volume_db)+extra_db)
	if player != null:
		flap_ms = now
	return player

## A random dog bark (a recorded one when `dog_bark_N.ogg` exists, else the generated cue).
func bark() -> AudioStreamPlayer:
	return play(pick(dog_barks))

func play_result_reaction(success: bool, intensity: int) -> AudioStreamPlayer:
	if not bool(Config.tuning.juice.audio):
		return null
	var player := AudioStreamPlayer.new()
	player.bus = "SFX"
	player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	player.volume_db = -8.0
	player.stream = _result_stream(success, intensity)
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
	return player

func _result_stream(success: bool, intensity: int) -> AudioStreamWAV:
	var rate := 22050
	var duration := 0.52 if success else 0.42
	var samples := int(rate * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i: int in samples:
		var t := float(i) / rate
		var envelope := sin(PI * t / duration)
		var value: float
		if success:
			var sweep := 720.0 - t * (230.0 + intensity * 28.0)
			value = (sin(TAU * sweep * t) + 0.32 * sin(TAU * sweep * 2.03 * t)) * envelope * 0.26
		else:
			var pulse := 1.0 if fmod(t, 0.16) < 0.085 else 0.18
			value = (sin(TAU * (145.0 - 45.0 * t) * t) + 0.22 * sin(TAU * 61.0 * t)) * envelope * pulse * 0.22
		var sample := clampi(roundi(value * 32767.0), -32768, 32767)
		data.encode_s16(i * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data
	return stream

func _stash_stream(cue: String) -> AudioStreamWAV:
	const RATE: int = 22050
	var duration: float = 0.13 if cue == "bag_thump" else (0.20 if cue == "bin_rattle" else (0.11 if cue == "release_accent" else (0.10 if cue == "empty_tap" else 0.15)))
	var samples: int = int(RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	var noise := RandomNumberGenerator.new()
	noise.seed = 7391
	var smooth_noise: float = 0.0
	for i: int in samples:
		var t: float = float(i) / RATE
		var envelope: float = pow(1.0-t/duration,2.0) * minf(1.0,t*350.0)
		smooth_noise = lerpf(smooth_noise,noise.randf_range(-1.0,1.0),0.28)
		var value: float
		match cue:
			"bag_thump":
				value = (sin(TAU*(95.0-32.0*t/duration)*t)*0.75+smooth_noise*0.25)*envelope*0.22
			"bin_rattle":
				var pulse: float = 1.0 if fmod(t,0.052) < 0.022 else 0.35
				value = (sin(TAU*713.0*t)*0.35+sin(TAU*1097.0*t)*0.25+smooth_noise*0.40)*envelope*pulse*0.13
			"release_accent":
				value = (sin(TAU*(510.0+230.0*t/duration)*t)+0.35*sin(TAU*1020.0*t))*envelope*0.13
			"empty_tap":
				var echo: float = sin(TAU*188.0*maxf(0.0,t-0.035))*0.25 if t > 0.035 else 0.0
				value = (sin(TAU*188.0*t)*0.6+echo+smooth_noise*0.15)*envelope*0.13
			_:
				value = smooth_noise*envelope*0.12
		data.encode_s16(i*2,clampi(roundi(value*32767.0),-32768,32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	return stream
