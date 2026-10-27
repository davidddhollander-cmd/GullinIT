extends Node
const GULL_CALL: AudioStream = preload("res://assets/audio/263786__steaq__seagull-single-call.ogg")
var streams: Dictionary = {}
var music: AudioStreamPlayer
# Looping soundtrack: the title theme on menus, the beach loop during levels.
const MUSIC_TRACKS: Dictionary = {
	"title": "res://assets/audio/music/title_theme.ogg",
	"beach": "res://assets/audio/music/beach_loop.ogg",
}
const MUSIC_DB: float = -3.0
const MUSIC_DUCK_DB: float = -14.0
const MUSIC_SILENT_DB: float = -40.0
var music_track: String = ""
var music_tween: Tween

func _ready() -> void:
	for bus: String in ["SFX", "Music"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	apply_options()
	for cue: String in ["snatch", "dive", "stun", "gust", "click"]:
		var path: String = "res://assets/audio/%s.wav" % cue
		if ResourceLoader.exists(path):
			streams[cue] = load(path)
	for cue: String in ["bag_thump", "bin_rattle", "stash_release", "release_accent", "empty_tap"]:
		streams[cue] = _stash_stream(cue)
	streams["gull_call"] = GULL_CALL
	for cue: String in ["screech_long", "screech_short", "gang_call"]:
		streams[cue] = load("res://assets/audio/%s.ogg" % cue)
	music = AudioStreamPlayer.new()
	music.bus = "Music"
	music.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	music.volume_db = MUSIC_DB
	add_child(music)

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
	if not streams.has(cue) or not bool(Config.tuning.juice.audio):
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
