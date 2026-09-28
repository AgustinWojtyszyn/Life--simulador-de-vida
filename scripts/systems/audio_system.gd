extends Node

# VIDA keeps its soundtrack self-contained and original. Music is synthesized
# once per track/country and cached; traffic uses a tiny pooled set of spatial
# loop players instead of spawning short engine clips every few seconds.
const SAMPLE_RATE := 16000
const MAX_TRAFFIC_VOICES := 4
# Diatonic progressions; the sixth and third degrees use minor triads.
const TRACKS := [
	{"name": "Barrio de Sol", "tempo": 72.0, "progression": [0, 5, 9, 7], "melody": [0, 4, 7, 5, 4, 2, 4, 5], "minor": false},
	{"name": "Tarde de plaza", "tempo": 66.0, "progression": [0, 4, 7, 5], "melody": [4, 5, 7, 5, 4, 2, 0, 2], "minor": false},
	{"name": "Ciudad tranquila", "tempo": 82.0, "progression": [0, 7, 9, 5], "melody": [0, 2, 4, 5, 7, 5, 4, 2], "minor": false},
	{"name": "Domingo largo", "tempo": 62.0, "progression": [0, 4, 5, 7], "melody": [0, 4, 5, 7, 5, 4, 2, 0], "minor": false},
	{"name": "Paseo de mañana", "tempo": 75.0, "progression": [0, 9, 7, 5], "melody": [7, 9, 7, 5, 4, 5, 4, 2], "minor": false},
	{"name": "Verano en la vereda", "tempo": 88.0, "progression": [0, 5, 4, 7], "melody": [0, 2, 4, 7, 5, 4, 5, 7], "minor": false},
	{"name": "Noche cálida", "tempo": 58.0, "progression": [0, 7, 5, 4], "melody": [4, 7, 9, 7, 5, 4, 2, 0], "minor": false},
]

var music_players := []
var active_music := 0
var current_country := "ar"
var track_index := 0
var enabled := true
var music_linear := 0.65
var music_cache := {}
var sfx_cache := {}
var traffic_voices := []
var traffic_clock := 0.0
var traffic_world_id := 0
var music_fade: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.name = "Music_%d" % i
		player.volume_db = -40.0
		add_child(player)
		music_players.append(player)

func start_world(country_id: String) -> void:
	var country_changed := current_country != country_id
	current_country = country_id
	var chosen := int(WorldManager.settings.get("music_track", country_seed(country_id)))
	chosen = posmod(chosen, TRACKS.size())
	var current: AudioStreamPlayer = music_players[active_music]
	if current.playing and chosen == track_index and not country_changed:
		reset_traffic_world()
		return
	track_index = chosen
	if enabled:
		play_track(track_index, false)
	reset_traffic_world()

func stop_world() -> void:
	for player in music_players:
		player.stop()
	for voice in traffic_voices:
		if is_instance_valid(voice):
			voice.stop()
	traffic_voices.clear()
	traffic_world_id = 0

func set_enabled(value: bool) -> void:
	enabled = value
	if not enabled:
		stop_world()
	elif WorldManager.playing:
		start_world(WorldManager.country.id)

func set_music_volume(value: float) -> void:
	music_linear = clampf(value, 0.0, 1.0)
	var target := target_music_db()
	for i in music_players.size():
		var player: AudioStreamPlayer = music_players[i]
		if i == active_music and player.playing:
			player.volume_db = target

func target_music_db() -> float:
	return -40.0 if music_linear <= 0.01 else linear_to_db(music_linear) - 4.0

func track_count() -> int:
	return TRACKS.size()

func track_name(index: int = -1) -> String:
	var target := track_index if index < 0 else posmod(index, TRACKS.size())
	return str(TRACKS[target]["name"])

func next_track() -> void:
	play_track(track_index + 1, true)

func previous_track() -> void:
	play_track(track_index - 1, true)

func play_track(index: int, crossfade: bool = true) -> void:
	if not enabled:
		return
	if music_fade != null and music_fade.is_valid():
		music_fade.kill()
	track_index = posmod(index, TRACKS.size())
	WorldManager.settings["music_track"] = track_index
	var stream := _get_track_stream(current_country, track_index)
	var current: AudioStreamPlayer = music_players[active_music]
	if not current.playing or not crossfade:
		for player in music_players:
			player.stop()
			player.volume_db = -40.0
		current.stream = stream
		current.volume_db = target_music_db()
		current.play()
		return
	var next_slot := 1 - active_music
	var incoming: AudioStreamPlayer = music_players[next_slot]
	incoming.stop()
	incoming.stream = stream
	incoming.volume_db = -40.0
	incoming.play()
	active_music = next_slot
	music_fade = create_tween()
	music_fade.tween_property(current, "volume_db", -40.0, 1.25).set_trans(Tween.TRANS_SINE)
	music_fade.parallel().tween_property(incoming, "volume_db", target_music_db(), 1.25).set_trans(Tween.TRANS_SINE)
	music_fade.tween_callback(current.stop)

func _get_track_stream(country: String, track: int) -> AudioStream:
	# Try to load a real audio file first (ogg preferred)
	var real_path := "res://assets/audio/music/%s_%d.ogg" % [country, track]
	if ResourceLoader.exists(real_path):
		var real_stream: AudioStream = load(real_path)
		if real_stream is AudioStreamOggVorbis:
			real_stream.loop = true
		return real_stream
	# Fallback: procedural generation (only if no real file exists)
	var key := "%s_%d" % [country, track]
	if not music_cache.has(key):
		music_cache[key] = make_music(track, country)
	return music_cache[key]

func play_sfx(kind: String, at := Vector2.ZERO) -> void:
	if not enabled or not is_instance_valid(WorldManager.active_world):
		return
	if not sfx_cache.has(kind):
		sfx_cache[kind] = make_sfx(kind)
	var player := AudioStreamPlayer2D.new()
	player.stream = sfx_cache[kind]
	player.position = at
	player.volume_db = -10.0 if kind == "horn" else -8.0 if kind == "brake" else -6.0
	player.max_distance = 680.0
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
	player.volume_db = -12.0
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func _process(delta: float) -> void:
	if not enabled or not WorldManager.playing or WorldManager.location != "street":
		return
	traffic_clock -= delta
	if traffic_clock <= 0.0:
		traffic_clock = 0.18
		update_traffic_audio()

func reset_traffic_world() -> void:
	var new_id := WorldManager.active_world.get_instance_id() if is_instance_valid(WorldManager.active_world) else 0
	if new_id == traffic_world_id:
		return
	for voice in traffic_voices:
		if is_instance_valid(voice):
			voice.stop()
	traffic_voices.clear()
	traffic_world_id = new_id
	traffic_clock = 0.0

func ensure_traffic_voices() -> void:
	if not is_instance_valid(WorldManager.active_world):
		return
	reset_traffic_world()
	while traffic_voices.size() < MAX_TRAFFIC_VOICES:
		var voice := AudioStreamPlayer2D.new()
		voice.name = "TrafficVoice_%d" % traffic_voices.size()
		voice.max_distance = 420.0
		voice.attenuation = 2.2
		voice.volume_db = -18.0
		WorldManager.active_world.add_child(voice)
		traffic_voices.append(voice)

func update_traffic_audio() -> void:
	if not is_instance_valid(WorldManager.active_world):
		return
	var listener := WorldManager.active_world.get_node_or_null("Player") as Node2D
	if not is_instance_valid(listener):
		return
	ensure_traffic_voices()
	var candidates := []
	for vehicle in get_tree().get_nodes_in_group("city_traffic"):
		if not is_instance_valid(vehicle):
			continue
		var distance_sq: float = listener.global_position.distance_squared_to(vehicle.global_position)
		if distance_sq <= 420.0 * 420.0:
			candidates.append([distance_sq, vehicle])
	candidates.sort_custom(func(a, b): return float(a[0]) < float(b[0]))
	for i in traffic_voices.size():
		var voice: AudioStreamPlayer2D = traffic_voices[i]
		if i >= candidates.size():
			voice.stop()
			continue
		var vehicle = candidates[i][1]
		var heavy := str(vehicle.model) in ["colectivo", "van", "pickup", "suv"]
		var cache_key := "engine_heavy" if heavy else "engine_light"
		if not sfx_cache.has(cache_key):
			sfx_cache[cache_key] = make_engine_loop(heavy)
		var stream: AudioStreamWAV = sfx_cache[cache_key]
		if voice.stream != stream:
			voice.stream = stream
			voice.play()
		elif not voice.playing:
			voice.play()
		voice.global_position = vehicle.global_position
		var cruise := maxf(1.0, float(vehicle.cruise_speed))
		var speed_ratio := clampf(float(vehicle.current_speed) / cruise, 0.0, 1.15)
		voice.pitch_scale = (0.72 if heavy else 0.90) + speed_ratio * (0.22 if heavy else 0.30)
		voice.volume_db = lerpf(-32.0, -22.0 if heavy else -24.0, speed_ratio)

func country_seed(id: String) -> int:
	return {"ar": 0, "us": 2, "jp": 4, "it": 1, "br": 3}.get(id, 0)

func country_root(id: String) -> float:
	return float({"ar": 130.81, "us": 116.54, "jp": 146.83, "it": 130.81, "br": 123.47}.get(id, 130.81))

func key_tone(frequency: float, age: float, duration: float) -> float:
	# Soft electric-piano attack and decaying, harmonic partials. Every voice
	# releases before the next chord; no overlapping drones or subharmonics.
	var envelope := minf(age / 0.018, 1.0) * exp(-3.8 * age / duration)
	envelope *= clampf((duration - age) / 0.10, 0.0, 1.0)
	return envelope * (sin(TAU * frequency * age) + 0.18 * sin(TAU * frequency * 2.0 * age) + 0.04 * sin(TAU * frequency * 3.0 * age))

func make_music(style: int, country: String) -> AudioStreamWAV:
	var profile: Dictionary = TRACKS[posmod(style, TRACKS.size())]
	var beat := 60.0 / float(profile.tempo)
	var duration := beat * 32.0
	var frames := int(SAMPLE_RATE * duration)
	var bytes := PackedByteArray()
	bytes.resize(frames * 4)
	var progression: Array = profile.progression
	var base := country_root(country)
	var chords: Array = []
	for step in progression:
		var third := 3 if int(step) in [4, 9] else 4
		var pitches: Array[float] = []
		for interval in [0, third, 7]:
			pitches.append(base * pow(2.0, float(int(step) + interval) / 12.0))
		chords.append(pitches)
	var motif: Array = profile.melody
	for i in frames:
		var t := float(i) / SAMPLE_RATE
		var bar := int(t / (beat * 4.0))
		var tones: Array = chords[bar % chords.size()]
		var chord_age := fposmod(t, beat * 4.0)
		var pulse_age := fposmod(t, beat * 2.0)
		var note_age := fposmod(t, beat)
		var step := int(t / beat)
		var keys := 0.0
		for frequency in tones:
			keys += key_tone(float(frequency), pulse_age, beat * 1.8) * 0.036
		var bass := key_tone(float(tones[0]) * 0.5, chord_age, beat * 3.6) * 0.035
		# A sparse melody follows the current harmony and leaves breathing room.
		var lead := 0.0
		if step % 4 != 3:
			var note := int(motif[step % motif.size()]) % 3
			lead = key_tone(float(tones[note]) * 2.0, note_age, beat * 0.82) * 0.028
		var left := keys * 0.94 + bass + lead
		var right := keys + bass + lead * 0.84
		bytes.encode_s16(i * 4, int(clampf(left, -0.9, 0.9) * 32767.0))
		bytes.encode_s16(i * 4 + 2, int(clampf(right, -0.9, 0.9) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = true
	wav.data = bytes
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = frames
	return wav

func make_engine_loop(heavy: bool) -> AudioStreamWAV:
	var duration := 1.0
	var frames := int(SAMPLE_RATE * duration)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	var root := 46.0 if heavy else 68.0
	for i in frames:
		var t := float(i) / SAMPLE_RATE
		var wobble := 1.0 + sin(TAU * 2.0 * t) * 0.035
		var sample := sin(TAU * root * t) * 0.11
		sample += sin(TAU * root * 2.0 * t + 0.35) * 0.055
		sample += sin(TAU * root * 3.0 * t + 1.1) * 0.022
		sample *= wobble
		bytes.encode_s16(i * 2, int(clampf(sample, -0.8, 0.8) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = bytes
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = frames
	return wav

func make_sfx(kind: String) -> AudioStreamWAV:
	var duration: float = float({"brake": 0.30, "horn": 0.24, "tap": 0.08, "interact": 0.14, "kick": 0.22}.get(kind, 0.18))
	var frames := int(SAMPLE_RATE * duration)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	for i in frames:
		var t := float(i) / SAMPLE_RATE
		var life: float = 1.0 - t / duration
		var sample := 0.0
		match kind:
			"brake":
				sample = (sin(TAU * (980.0 - 520.0 * t / duration) * t) + sin(TAU * 1420.0 * t) * 0.22) * life * 0.10
			"horn":
				var attack := clampf(t / 0.025, 0.0, 1.0)
				var release := clampf((duration - t) / 0.055, 0.0, 1.0)
				var envelope := attack * release
				sample = (sin(TAU * 392.0 * t) * 0.11 + sin(TAU * 494.0 * t) * 0.075) * envelope
			"tap":
				sample = sin(TAU * 520.0 * t) * life * 0.14
			"interact":
				sample = (sin(TAU * 392.0 * t) + sin(TAU * 587.0 * t) * 0.35) * life * 0.11
			"kick":
				sample = sin(TAU * (145.0 - 72.0 * t / duration) * t) * life * 0.20
			_:
				sample = sin(TAU * 340.0 * t) * life * 0.10
		bytes.encode_s16(i * 2, int(clampf(sample, -0.9, 0.9) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = bytes
	return wav
