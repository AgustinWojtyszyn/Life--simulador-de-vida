extends Node

# VIDA keeps its soundtrack self-contained and original. Music is synthesized
# once per track/country and cached; traffic uses a tiny pooled set of spatial
# loop players instead of spawning short engine clips every few seconds.
const SAMPLE_RATE := 16000
const MAX_TRAFFIC_VOICES := 4
# Music intentionally removed: VIDA keeps only functional UI, interaction and traffic SFX.

var enabled := true
var sfx_cache := {}
var traffic_voices := []
var traffic_clock := 0.0
var traffic_world_id := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func start_world(_country_id: String) -> void:
	# No soundtrack: only reset spatial traffic SFX for the new world.
	reset_traffic_world()

func stop_world() -> void:
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

# Compatibility API retained for existing HUD/settings callers. Music is disabled.
func set_music_volume(_value: float) -> void:
	pass

func target_music_db() -> float:
	return -80.0

func track_count() -> int:
	return 0

func track_name(_index: int = -1) -> String:
	return "Sin música"

func next_track() -> void:
	pass

func previous_track() -> void:
	pass

func play_track(_index: int, _crossfade: bool = true) -> void:
	pass

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
