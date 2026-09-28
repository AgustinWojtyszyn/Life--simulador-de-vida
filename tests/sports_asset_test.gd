extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var car = load("res://scripts/city_vehicle.gd").new()
	car.model = "sports_v2"
	root.add_child(car)
	car.set_physics_process(false)
	var views := {}
	var scale: Vector2 = car.sprite.scale
	for i in 8:
		car.heading = float(i) * PI / 4.0
		car.update_art()
		assert(car.facing_index == i, "Every orientation must be selectable")
		views[hash(car.sprite.texture.get_image().get_data())] = true
		assert(car.sprite.scale == scale, "No per-frame resizing")
		var rect: Rect2 = car.sprite.get_rect()
		assert(is_zero_approx(rect.end.y) and is_zero_approx(rect.get_center().x), "Visible region shares bottom-center pivot")
	assert(views.size() == 8, "Eight distinct directional frames")
	print("SPORTS ASSET TEST: PASS (8 rendered views and fixed ground anchor)")
	quit()
