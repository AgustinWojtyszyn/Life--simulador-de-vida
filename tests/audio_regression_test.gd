extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var audio = root.get_node("AudioSystem")
	for i in audio.track_count():
		var wav: AudioStreamWAV = audio.make_music(i, "ar")
		var bytes := wav.data
		var peak := 0
		for sample in range(0, bytes.size(), 4):
			peak = maxi(peak, absi(bytes.decode_s16(sample)))
		assert(peak > 500 and peak < 30000, "Audible music without clipping")
		assert(absi(bytes.decode_s16(0) - bytes.decode_s16(bytes.size() - 4)) < 100, "Loop seam is silent")
		assert(wav.loop_end == bytes.size() / 4, "Loop contains whole bars")
		audio.music_cache["ar_%d" % i] = wav
		if i == 0:
			wav.save_to_wav("res://build/barrio_de_sol.wav")
	audio.play_track(0, false)
	audio.next_track()
	audio.previous_track()
	assert(audio.track_index == 0)
	await create_timer(1.5).timeout
	assert(audio.music_players[audio.active_music].playing, "Rapid track switching keeps selected song playing")
	print("AUDIO REGRESSION: PASS (7 tracks, loop seams, levels, switching)")
	quit()
