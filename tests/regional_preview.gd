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
		world.queue_free()
		await process_frame
	quit()
