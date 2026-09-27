extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://build/previews")
	var wm := root.get_node("WorldManager")
	for country in wm.countries:
		wm.country = country
		wm.district = country.cities[0].districts[0]
		var world: Node2D = load("res://scenes/playground.tscn").instantiate()
		root.add_child(world)
		var camera: Camera2D = world.get_node("Player/Camera2D")
		camera.position_smoothing_enabled = false
		camera.zoom = Vector2(0.75, 0.75)
		world.get_node("Player").position = Vector2(445, 540)
		for i in 20: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/previews/" + country.id + "_street.png")
		for view in [{"name": "home_frontage", "at": Vector2(1550, 345)}, {"name": "side_street", "at": Vector2(1840, 820)}]:
			camera.zoom = Vector2(0.85, 0.85)
			world.get_node("Player").position = view.at
			for i in 8: await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://build/previews/" + country.id + "_" + view.name + ".png")
		world.set_process(false)
		for sprite in world.occluders: sprite.get_parent().show()
		camera.zoom = Vector2(0.28, 0.28)
		world.get_node("Player").position = Vector2(1200, 800)
		for i in 3: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/previews/" + country.id + "_overview.png")
		world.queue_free()
		await process_frame
	quit()
