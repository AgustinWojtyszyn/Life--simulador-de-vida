extends Node

# VIDA keeps its soundtrack self-contained and original. Music is synthesized
# once per track/country and cached; traffic uses a tiny pooled set of spatial
# loop players instead of spawning short engine clips every few seconds.
const SAMPLE_RATE := 16000
const TRACK_SECONDS := 32.0
const MAX_TRAFFIC_VOICES := 4
const TRACKS := [
	{"name": "Barrio de Sol", "tempo": 72.0, "progression": [0, 9, 5, 7], "melody": [0, 2, 4, 2, 5, 4, 2, 1], "minor": false},
	{"name": "Ventanas al atardecer", "tempo": 66.0, "progression": [0, 5, 8, 7], "melody": [0, 2, 3, 5, 3, 2, 1, 2], "minor": true},
	{"name": "Ciudad tranquila", "tempo": 82.0, "progression": [0, 4, 5, 7], "melody": [0, 1, 3, 4, 3, 5, 4, 2], "minor": false},
	{"name": "Noche en movimiento", "tempo": 88.0, "progression": [0, 8, 5, 10], "melody": [0, 3, 2, 4, 5, 4, 2, 1], "minor": true},
	{"name": "Domingo largo", "tempo": 62.0, "progression": [0, 7, 9, 5], "melody": [0, 2, 4, 5, 4, 2, 3, 1], "minor": false},
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
	player.volume_db = -8.0 if kind == "brake" else -6.0
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
	var beat: float = 60.0 / tempo
	var bar: float = beat * 4.0
	var base_root: float = country_root(country)
	var progression: Array = profile["progression"]
	var melody: Array = profile["melody"]
	var scale: Array[int] = country_scale(country)
	var minor: bool = bool(profile["minor"])
	var third := 3 if minor else 4
	for i in frames:
		var t: float = float(i) / SAMPLE_RATE
		var bar_index: int = int(t / bar)
		var chord_index: int = posmod(bar_index, progression.size())
		var next_chord_index: int = posmod(chord_index + 1, progression.size())
		var chord_root: int = int(progression[chord_index])
		var next_root: int = int(progression[next_chord_index])
		var bar_phase: float = fposmod(t, bar) / bar
		var blend: float = clampf((bar_phase - 0.78) / 0.22, 0.0, 1.0)
		blend = blend * blend * (3.0 - 2.0 * blend)
		var pad_a := 0.0
		var pad_b := 0.0
		for interval in [0, third, 7, 12]:
			var fa := quantized_frequency(base_root * pow(2.0, float(chord_root + int(interval)) / 12.0))
			var fb := quantized_frequency(base_root * pow(2.0, float(next_root + int(interval)) / 12.0))
			var phase_offset := float(interval) * 0.13
			pad_a += sin(TAU * fa * t + phase_offset)
			pad_b += sin(TAU * fb * t + phase_offset)
		var pad := lerpf(pad_a, pad_b, blend) * 0.024
		var pulse := 0.84 + 0.16 * sin(TAU * (2.0 / TRACK_SECONDS) * t)
		pad *= pulse
		var melody_span := beat * 2.0
		var melody_step: int = int(t / melody_span)
		var degree_index: int = int(melody[posmod(melody_step, melody.size())])
		var semitone: int = scale[posmod(degree_index, scale.size())] + 12
		var melody_freq := quantized_frequency(base_root * pow(2.0, float(semitone) / 12.0))
		var note_phase := fposmod(t, melody_span)
		var attack := clampf(note_phase / 0.24, 0.0, 1.0)
		var release := exp(-note_phase * 0.72)
		var melody_env := attack * release
		var lead := (sin(TAU * melody_freq * t) * 0.020 + sin(TAU * melody_freq * 0.5 * t + 0.8) * 0.010) * melody_env
		var bass_freq := quantized_frequency(base_root * 0.5 * pow(2.0, float(chord_root) / 12.0))
		var bass := sin(TAU * bass_freq * t + 0.18) * 0.025
		var beat_phase := fposmod(t, beat)
		var soft_kick := 0.0
		if style in [2, 3] and beat_phase < 0.15:
			var kick_env := 1.0 - beat_phase / 0.15
			soft_kick = sin(TAU * (58.0 + 16.0 * kick_env) * t) * kick_env * 0.018
		var shimmer_freq := quantized_frequency(base_root * 2.0)
		var shimmer := sin(TAU * shimmer_freq * t + 1.25) * 0.005
		var left := clampf(pad + bass + lead * 0.92 + soft_kick + shimmer, -0.68, 0.68)
		var right := clampf(pad * 0.98 + bass + lead * 1.08 + soft_kick - shimmer, -0.68, 0.68)
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
	var duration: float = float({"brake": 0.30, "tap": 0.08, "interact": 0.14, "kick": 0.22}.get(kind, 0.18))
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
