extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func capture(name: String) -> void:
	for i in 24:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/phase1-" + name + ".png")

func run() -> void:
	var manager: Node = root.get_node("WorldManager")
	var app: Node = load("res://scenes/app.tscn").instantiate()
	root.add_child(app)
	await capture("menu")
	app.menu.create_screen()
	await capture("creator")
	for id in ["ar", "us", "jp", "it", "br"]:
		var p := PlayerProfile.new()
		p.player_name = "Alex"
		p.gender = "female"
		manager.new_game(p, id)
		await capture(id + "-home")
		manager.travel("street")
		await capture(id + "-street")
		app.world.get_node("Player").position = Vector2(2100, 900)
		app.world.get_node("Player/Camera2D").reset_smoothing()
		await capture(id + "-expansion")
	# Landscape aspect ratios and optional mobile overlay use the same scene.
	root.size = Vector2i(1280, 800)
	await capture("16-10")
	root.size = Vector2i(1600, 686)
	await capture("ultrawide")
	root.size = Vector2i(1280, 720)
	root.get_node("InputManager").touch_enabled = true
	manager.travel("home")
	await capture("touch")
	await create_timer(1.0).timeout
	var before := Time.get_ticks_usec()
	for i in 120:
		await process_frame
	print("PHASE1 PREVIEW: PASS; final scene FPS sample=", snappedf(120000000.0 / (Time.get_ticks_usec() - before), 0.1))
	quit()
