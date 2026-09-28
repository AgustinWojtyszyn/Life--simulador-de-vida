extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func capture(viewport: SubViewport, file: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("res://build/" + file + ".png")

func run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1100, 780)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var scene := Node2D.new()
	viewport.add_child(scene)
	var background := Polygon2D.new()
	background.polygon = PackedVector2Array([Vector2.ZERO, Vector2(1100, 0), Vector2(1100, 780), Vector2(0, 780)])
	background.color = Color("bec4b4")
	scene.add_child(background)
	var Visual = load("res://scripts/character_visual.gd")
	var Profile = load("res://scripts/data/player_profile.gd")
	for gender in 2:
		for skin in 3:
			for hair in 3:
				var visual = Visual.new()
				visual.profile = Profile.new()
				visual.profile.gender = "female" if gender == 0 else "male"
				visual.profile.skin = skin
				visual.profile.hair = hair
				visual.profile.hair_color = hair
				visual.position = Vector2(65 + (skin * 3 + hair) * 118, 165 + gender * 195)
				visual.scale = Vector2.ONE * 3
				scene.add_child(visual)
	for direction in 8:
		var vehicle = load("res://scripts/city_vehicle.gd").new()
		vehicle.model = "sports_v2"
		vehicle.position = Vector2(80 + (direction % 4) * 265, 520 + (direction / 4) * 190)
		vehicle.scale = Vector2.ONE * 2.3
		scene.add_child(vehicle)
		vehicle.set_physics_process(false)
		vehicle.heading = direction * PI / 4
		vehicle.update_art()
		var marker := Polygon2D.new()
		marker.polygon = PackedVector2Array([Vector2(-3, 0), Vector2(3, 0), Vector2(3, 3), Vector2(-3, 3)])
		marker.color = Color.RED
		vehicle.add_child(marker)
	await capture(viewport, "palette_and_coupe")
	for node in scene.get_children():
		if node != background:
			node.queue_free()
	await process_frame
	var models := ["compact", "taxi", "sedan", "hatchback", "van", "pickup", "classic", "suv", "colectivo"]
	for row in models.size():
		var label := Label.new()
		label.text = models[row]
		label.position = Vector2(4, 25 + row * 83)
		label.modulate = Color.BLACK
		scene.add_child(label)
		for direction in 8:
			var vehicle = load("res://scripts/city_vehicle.gd").new()
			vehicle.model = models[row]
			vehicle.position = Vector2(150 + direction * 125, 74 + row * 83)
			scene.add_child(vehicle)
			vehicle.set_physics_process(false)
			vehicle.heading = direction * PI / 4
			vehicle.update_art()
	await capture(viewport, "vehicle_families")
	print("VISUAL REVIEW CAPTURED")
	quit()
