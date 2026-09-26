extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var world: Node2D = load("res://scenes/playground.tscn").instantiate()
	root.add_child(world)
	var player: CharacterBody2D = world.get_node("Player")
	for view in [{"name": "street", "position": Vector2(520, 330)}, {"name": "plaza", "position": Vector2(520, 712)}, {"name": "crossing", "position": Vector2(990, 470)}]:
		player.position = view.position
		player.get_node("Camera2D").reset_smoothing()
		for i in 20:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/" + view.name + ".png")
	# Exclude shader compilation and startup from the performance sample.
	await create_timer(2.0).timeout
	var sample_start := Time.get_ticks_usec()
	for i in 180:
		await process_frame
	var sample_seconds := (Time.get_ticks_usec() - sample_start) / 1000000.0
	print("STEADY FRAME SAMPLE: ", snappedf(180.0 / sample_seconds, 0.1), " FPS; draw calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	print("CITY RENDER: PASS; FPS=", Engine.get_frames_per_second(), "; objects=", world.city_objects.size())
	quit()
