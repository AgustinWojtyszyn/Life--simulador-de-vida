extends Node

# VIDA keeps its soundtrack self-contained and original. Music is synthesized
# once per track/country and cached; traffic uses a tiny pooled set of spatial
# loop players instead of spawning short engine clips every few seconds.
const SAMPLE_RATE := 16000
const TRACK_SECONDS := 24.0
const MAX_TRAFFIC_VOICES := 4
# All tracks use uplifting major progressions (intervals 0,4,7,9,11 = major/happy).
# Progression values = semitone steps from root (0=root, 4=major 3rd, 5=4th, 7=5th, 9=6th).
# No minor 3rds (3) or minor 7ths (10) in progressions to keep the mood warm.
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
var automatic_period := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not GameClock.changed.is_connected(on_clock_changed):
		GameClock.changed.connect(on_clock_changed)
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.name = "Music_%d" % i
		player.volume_db = -40.0
		add_child(player)
		music_players.append(player)

func start_world(country_id: String) -> void:
	var country_changed := current_country != country_id
	current_country = country_id
	var manual := bool(WorldManager.settings.get("music_manual", false))
	var chosen := int(WorldManager.settings.get("music_track", 0)) if manual else automatic_track(country_id)
	chosen = posmod(chosen, TRACKS.size())
	automatic_period = GameClock.period()
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
	WorldManager.settings["music_manual"] = true
	play_track(track_index + 1, true)

func previous_track() -> void:
	WorldManager.settings["music_manual"] = true
	play_track(track_index - 1, true)

func set_auto_music(value: bool) -> void:
	WorldManager.settings["music_manual"] = not value
	if value and WorldManager.playing:
		var chosen := automatic_track(current_country)
		if chosen != track_index:
			play_track(chosen, true)
		automatic_period = GameClock.period()

func automatic_track(country_id: String) -> int:
	var seed := country_seed(country_id)
	match GameClock.period():
		"AMANECER":
			return posmod(seed + 4, TRACKS.size())
		"ATARDECER":
			return posmod(seed + 1, TRACKS.size())
		"NOCHE":
			return 6
		_:
			return seed

func on_clock_changed() -> void:
	if not enabled or not WorldManager.playing or bool(WorldManager.settings.get("music_manual", false)):
		return
	var period := GameClock.period()
	if period == automatic_period:
		return
	automatic_period = period
	var chosen := automatic_track(current_country)
	if chosen != track_index:
		play_track(chosen, true)

func play_track(index: int, crossfade: bool = true) -> void:
	if not enabled:
		return
	track_index = posmod(index, TRACKS.size())
	WorldManager.settings["music_track"] = track_index
	var key := "%s_%d" % [current_country, track_index]
	if not music_cache.has(key):
		music_cache[key] = make_music(track_index, current_country)
	var current: AudioStreamPlayer = music_players[active_music]
	if not current.playing or not crossfade:
		for player in music_players:
			player.stop()
			player.volume_db = -40.0
		current.stream = music_cache[key]
		current.volume_db = target_music_db()
		current.play()
		return
	var next_slot := 1 - active_music
	var incoming: AudioStreamPlayer = music_players[next_slot]
	incoming.stop()
	incoming.stream = music_cache[key]
	incoming.volume_db = -40.0
	incoming.play()
	active_music = next_slot
	var tween := create_tween()
	tween.tween_property(current, "volume_db", -40.0, 1.25).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(incoming, "volume_db", target_music_db(), 1.25).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(current.stop)

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
		voice.max_distance = 760.0
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
		if distance_sq <= 820.0 * 820.0:
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
		voice.volume_db = lerpf(-20.0, -11.5 if heavy else -13.0, speed_ratio)

func country_seed(id: String) -> int:
	return {"ar": 0, "us": 2, "jp": 4, "it": 1, "br": 3}.get(id, 0)

func country_scale(id: String) -> Array[int]:
	match id:
		"jp":
			return [0, 2, 4, 7, 9]
		"br":
			return [0, 2, 4, 5, 7, 9, 10]
		"it":
			return [0, 2, 4, 5, 7, 9, 11]
		_:
			return [0, 2, 4, 7, 9, 11]

func country_root(id: String) -> float:
	return float({"ar": 130.81, "us": 116.54, "jp": 146.83, "it": 130.81, "br": 123.47}.get(id, 130.81))

func quantized_frequency(raw: float) -> float:
	return round(raw * TRACK_SECONDS) / TRACK_SECONDS

func make_music(style: int, country: String) -> AudioStreamWAV:
	var profile: Dictionary = TRACKS[posmod(style, TRACKS.size())]
	var frames: int = int(SAMPLE_RATE * TRACK_SECONDS)
	var bytes := PackedByteArray()
	bytes.resize(frames * 4)
	var tempo: float = float(profile["tempo"])
	var base_root: float = country_root(country)
	var progression: Array = profile["progression"]
	var melody: Array = profile["melody"]
	var scale: Array[int] = country_scale(country)
	var minor: bool = bool(profile["minor"])
	var third := 3 if minor else 4

	# Precompute every pitch once. Track changes must never stall gameplay by
	# evaluating pow() hundreds of thousands of times on the main thread.
	var chord_sets := []
	var bass_freqs := []
	for chord_value in progression:
		var root_step := int(chord_value)
		var tones := []
		for interval in [0, third, 7]:
			tones.append(quantized_frequency(base_root * pow(2.0, float(root_step + int(interval)) / 12.0)))
		chord_sets.append(tones)
		bass_freqs.append(quantized_frequency(base_root * 0.5 * pow(2.0, float(root_step) / 12.0)))
	var melody_freqs := []
	for degree_value in melody:
		var degree_index := int(degree_value)
		var semitone: int = scale[posmod(degree_index, scale.size())] + 12
		melody_freqs.append(quantized_frequency(base_root * pow(2.0, float(semitone) / 12.0)))
	var shimmer_freq := quantized_frequency(base_root * 2.0)

	# Chord and melody grids divide the full 24-second loop exactly. Combined
	# with cycle-quantized frequencies this removes the obvious click/restart
	# that made the old soundtrack sound broken.
	var chord_span := TRACK_SECONDS / float(progression.size())
	var melody_span := TRACK_SECONDS / float(melody.size() * 2)
	var beat_count := maxi(16, roundi(tempo * TRACK_SECONDS / 60.0))
	var beat := TRACK_SECONDS / float(beat_count)
	for i in frames:
		var t: float = float(i) / SAMPLE_RATE
		var chord_index: int = int(t / chord_span) % progression.size()
		var next_chord_index: int = (chord_index + 1) % progression.size()
		var chord_phase: float = fposmod(t, chord_span) / chord_span
		var blend: float = clampf((chord_phase - 0.76) / 0.24, 0.0, 1.0)
		blend = blend * blend * (3.0 - 2.0 * blend)
		var pad_a := 0.0
		var pad_b := 0.0
		var tones_a: Array = chord_sets[chord_index]
		var tones_b: Array = chord_sets[next_chord_index]
		for tone_index in tones_a.size():
			var phase_offset := float(tone_index) * 0.41
			# Warm pad: fundamental + soft 2nd harmonic only (no 3rd harmonic drone)
			var freq_a := float(tones_a[tone_index])
			var freq_b := float(tones_b[tone_index])
			pad_a += sin(TAU * freq_a * t + phase_offset) * 0.85
			pad_a += sin(TAU * freq_a * 2.0 * t + phase_offset * 1.3) * 0.15
			pad_b += sin(TAU * freq_b * t + phase_offset) * 0.85
			pad_b += sin(TAU * freq_b * 2.0 * t + phase_offset * 1.3) * 0.15
		var pad := lerpf(pad_a, pad_b, blend) * 0.030
		pad *= 0.88 + 0.12 * sin(TAU * (2.0 / TRACK_SECONDS) * t)

		# Warm, gentle envelope: soft attack, long sustain, smooth release
		var melody_step: int = int(t / melody_span) % melody_freqs.size()
		var note_phase := fposmod(t, melody_span) / melody_span
		# Smooth sine-based envelope for warmth (no harsh piano attack)
		var melody_env := sin(PI * note_phase)
		melody_env = melody_env * melody_env * melody_env  # Softer curve
		var note_attack := clampf(note_phase * 6.0, 0.0, 1.0)  # Gentle 16% attack
		var note_decay := exp(-2.0 * maxf(0.0, note_phase - 0.16))  # Slower decay
		var piano_env := note_attack * (0.35 + 0.65 * note_decay)
		var melody_freq: float = float(melody_freqs[melody_step])
		# Warm, mellow timbre: fundamental + soft harmonics (no harsh overtones)
		var lead := piano_env * melody_env * (
			sin(TAU * melody_freq * t) * 0.022 +
			sin(TAU * melody_freq * 2.0 * t + 0.3) * 0.008 +
			sin(TAU * melody_freq * 0.5 * t + 0.2) * 0.004
		)

		var bass_a := sin(TAU * float(bass_freqs[chord_index]) * t + 0.18)
		var bass_b := sin(TAU * float(bass_freqs[next_chord_index]) * t + 0.18)
		# Richer bass with multiple harmonics for warmth
		bass_a += sin(TAU * float(bass_freqs[chord_index]) * 2.0 * t) * 0.35
		bass_a += sin(TAU * float(bass_freqs[chord_index]) * 3.0 * t + 0.4) * 0.15
		bass_b += sin(TAU * float(bass_freqs[next_chord_index]) * 2.0 * t) * 0.35
		bass_b += sin(TAU * float(bass_freqs[next_chord_index]) * 3.0 * t + 0.4) * 0.15
		var bass := lerpf(bass_a, bass_b, blend) * 0.018

		var beat_phase := fposmod(t, beat)
		var soft_kick := 0.0
		if style in [2, 5] and beat_phase < 0.14:
			var kick_env := 1.0 - beat_phase / 0.14
			soft_kick = sin(TAU * (52.0 + 12.0 * kick_env) * t) * kick_env * 0.012
		# Very subtle stereo width from low overtone (no high-frequency tension)
		var shimmer := sin(TAU * shimmer_freq * 0.25 * t + 1.25) * 0.002
		# Soft pad volume breathe for warmth
		pad *= 0.85 + 0.15 * sin(TAU * (1.5 / TRACK_SECONDS) * t)
		var left := clampf(pad + bass + lead * 0.88 + soft_kick + shimmer, -0.65, 0.65)
		var right := clampf(pad * 0.96 + bass + lead * 1.12 + soft_kick - shimmer * 0.8, -0.65, 0.65)
		bytes.encode_s16(i * 4, int(left * 32767.0))
		bytes.encode_s16(i * 4 + 2, int(right * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = true
	wav.data = bytes
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
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
