extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func capture(path: String) -> void:
	for i in 20: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://build/mobile")
	var inputs := root.get_node("InputManager")
	inputs.touch_enabled = true
	root.size = Vector2i(960, 540)
	var app: Node = load("res://scenes/app.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.menu.create_screen()
	await capture("res://build/mobile/character.png")
	app.menu.country_screen()
	await capture("res://build/mobile/country.png")
	var wm := root.get_node("WorldManager")
	# Preview never creates or writes a player save.
	for country in ["ar", "jp", "it", "br", "us"]:
		wm.select_country(country)
		wm.location = "street"
		wm.spawn_position = Vector2(550, 1800)
		app.switch_world()
		await capture("res://build/mobile/" + country + ".png")
		app.world.get_node("Player").position = Vector2(4300, 2600)
		app.world.get_node("Player/Camera2D").reset_smoothing()
		await capture("res://build/mobile/" + country + "-services.png")
	app.world.get_node("LifePanel").show_journal()
	await capture("res://build/mobile/journal.png")
	app.world.get_node("LifePanel").close()
	app.toggle_pause()
	await capture("res://build/mobile/pause.png")
	quit()
