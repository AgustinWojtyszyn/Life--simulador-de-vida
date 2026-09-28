extends SceneTree

func _initialize() -> void:
	call_deferred("run")
func capture(path: String) -> void:
	for frame in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://build/grounding")
	root.size = Vector2i(1280, 720)
	var board := Node2D.new()
	board.scale = Vector2.ONE * .625
	root.add_child(board)
	var pavement := Polygon2D.new()
	pavement.polygon = PackedVector2Array([Vector2.ZERO, Vector2(1280,0), Vector2(1280,720), Vector2(0,720)])
	pavement.color = Color("404c55")
	board.add_child(pavement)
	var models := ["compact", "sedan", "sports", "van", "colectivo"]
	for row in models.size():
		for col in 8:
			var car = load("res://scripts/city_vehicle.gd").new()
			car.model = models[row]
			car.position = Vector2(80 + col * 160, 110 + row * 135)
			board.add_child(car)
			car.set_physics_process(false)
			car.heading = col * PI / 4
			car.update_art()
			car.queue_redraw()
			var label := Label.new()
			label.text = models[row] + " " + str(col)
			label.position = car.position + Vector2(-65, 20)
			board.add_child(label)
	await capture("res://build/grounding/directions.png")
	board.queue_free()
	await process_frame
	var wm := root.get_node("WorldManager")
	wm.location = "street"
	root.get_node("InputManager").touch_enabled = true
	root.size = Vector2i(960, 540)
	var world = load("res://scenes/playground.tscn").instantiate()
	root.add_child(world)
	var bus = world.get_node("Colectivo")
	var player = world.get_node("Player")
	for step in 3:
		bus.progress = bus.curve.get_baked_length() * (.1 + step * .28)
		bus.position = bus.curve.sample_baked(bus.progress)
		bus.heading = bus.tangent(bus.progress).angle()
		bus.update_art()
		player.position = bus.position + Vector2(0, -90)
		player.get_node("Camera2D").reset_smoothing()
		for frame in 20: await physics_frame
		await capture("res://build/grounding/landscape-bus-%d.png" % step)
	world.queue_free()
	await process_frame
	quit()
