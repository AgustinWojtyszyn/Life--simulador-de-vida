extends Node

# Original procedural audio for VIDA. Nothing here samples or reproduces
# third-party music: every track and effect is synthesized at runtime.
const SAMPLE_RATE := 16000
const TRACK_SECONDS := 12.0

var music_player := AudioStreamPlayer.new()
var current_country := "ar"
var track_index := 0
var track_clock := 0.0
var enabled := true
var music_cache := {}
var sfx_cache := {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	music_player.name = "Music"
	music_player.volume_db = -16.0
	add_child(music_player)

func start_world(country_id: String) -> void:
	if current_country == country_id and music_player.playing:
		return
	current_country = country_id
	track_index = country_seed(country_id) % 3
	track_clock = 0.0
	if enabled:
		play_track(track_index)

func stop_world() -> void:
	music_player.stop()

func set_enabled(value: bool) -> void:
	enabled = value
	if not enabled:
		music_player.stop()
	elif WorldManager.playing:
		start_world(WorldManager.country.id)

func set_music_volume(value: float) -> void:
	var linear := clampf(value, 0.0, 1.0)
	music_player.volume_db = -40.0 if linear <= 0.01 else linear_to_db(linear)

func _process(delta: float) -> void:
	if not enabled or not WorldManager.playing:
		return
	track_clock += delta
	if track_clock >= TRACK_SECONDS * 2.0:
		track_clock = 0.0
		track_index = (track_index + 1) % 3
		play_track(track_index)

func play_track(index: int) -> void:
	var key := "%s_%d" % [current_country, index]
	if not music_cache.has(key):
		music_cache[key] = make_music(index, current_country)
	music_player.stream = music_cache[key]
	music_player.play()

func play_sfx(kind: String, at := Vector2.ZERO) -> void:
	if not enabled or not is_instance_valid(WorldManager.active_world):
		return
	if not sfx_cache.has(kind):
		sfx_cache[kind] = make_sfx(kind)
	var player := AudioStreamPlayer2D.new()
	player.stream = sfx_cache[kind]
	player.position = at
	player.volume_db = -9.0 if kind == "engine" else -5.0
	player.max_distance = 700.0
	player.attenuation = 1.8
	WorldManager.active_world.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func play_ui(kind := "tap") -> void:
	if not enabled:
		return
	if not sfx_cache.has(kind):
		sfx_cache[kind] = make_sfx(kind)
	var player := AudioStreamPlayer.new()
	player.stream = sfx_cache[kind]
	player.volume_db = -11.0
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func country_seed(id: String) -> int:
	return {"ar": 0, "us": 1, "jp": 2, "it": 0, "br": 1}.get(id, 0)

func country_scale(id: String) -> Array[int]:
	match id:
		"jp":
			return [0, 2, 4, 7, 9] # pentatonic colour
		"br":
			return [0, 2, 4, 5, 7, 9, 10]
		"it":
			return [0, 2, 4, 5, 7, 9, 11]
		_:
			return [0, 2, 4, 7, 9, 11]

func make_music(style: int, country: String) -> AudioStreamWAV:
	var frames := int(SAMPLE_RATE * TRACK_SECONDS)
	var bytes := PackedByteArray()
	bytes.resize(frames * 4)
	var scale := country_scale(country)
	var root := {"ar": 196.0, "us": 174.61, "jp": 220.0, "it": 196.0, "br": 185.0}.get(country, 196.0)
	var tempo := [82.0, 112.0, 98.0][style]
	var beat := 60.0 / tempo
	for i in frames:
		var t := float(i) / SAMPLE_RATE
		var step := int(t / (beat * 0.5))
		var degree: int = scale[posmod(step + style * 2, scale.size())]
		var octave := 12 if (step / scale.size()) % 2 else 0
		var freq: float = root * pow(2.0, float(degree + octave) / 12.0)
		var envelope := 0.58 + 0.42 * exp(-fposmod(t, beat * 0.5) * 4.2)
		var lead := sin(TAU * freq * t) * 0.11
		var warm := sin(TAU * (freq * 0.5) * t + 0.7) * 0.075
		var sparkle := sin(TAU * (freq * 2.0) * t + 1.4) * (0.025 if style != 0 else 0.012)
		var pulse := 0.0
		if style == 1:
			pulse = sin(TAU * (root * 0.25) * t) * 0.035
		elif style == 2:
			pulse = sin(TAU * (root * 0.375) * t) * 0.028
		if country == "br":
			var phase := fposmod(t, beat)
			if phase < 0.055 or absf(phase - beat * 0.62) < 0.045:
				pulse += sin(TAU * 78.0 * t) * 0.045 * (1.0 - minf(phase / 0.055, 1.0))
		var sample := clampf((lead + warm + sparkle) * envelope + pulse, -0.72, 0.72)
		var value := int(sample * 32767.0)
		bytes.encode_s16(i * 4, value)
		bytes.encode_s16(i * 4 + 2, value)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = true
	wav.data = bytes
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = frames
	return wav

func make_sfx(kind: String) -> AudioStreamWAV:
	var duration := {"brake": 0.34, "engine": 0.5, "tap": 0.08, "interact": 0.14, "kick": 0.22}.get(kind, 0.18)
	var frames := int(SAMPLE_RATE * duration)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	for i in frames:
		var t := float(i) / SAMPLE_RATE
		var life := 1.0 - t / duration
		var sample := 0.0
		match kind:
			"brake":
				sample = (sin(TAU * (1350.0 - 900.0 * t / duration) * t) + sin(TAU * 1900.0 * t) * 0.35) * life * 0.14
			"engine":
				sample = (sin(TAU * 72.0 * t) + sin(TAU * 144.0 * t) * 0.45) * (0.08 + life * 0.05)
			"tap":
				sample = sin(TAU * 620.0 * t) * life * 0.18
			"interact":
				sample = (sin(TAU * 440.0 * t) + sin(TAU * 660.0 * t) * 0.5) * life * 0.13
			"kick":
				sample = sin(TAU * (150.0 - 80.0 * t / duration) * t) * life * 0.22
			_:
				sample = sin(TAU * 380.0 * t) * life * 0.12
		bytes.encode_s16(i * 2, int(clampf(sample, -0.9, 0.9) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = bytes
	return wav
