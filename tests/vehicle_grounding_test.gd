extends SceneTree

var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func run() -> void:
	for model in ["compact", "sedan", "sports", "van", "colectivo", "pickup", "suv", "taxi", "hatchback", "classic", "truck"]:
		var car = load("res://scripts/city_vehicle.gd").new()
		car.model = model
		car.position = Vector2(300, 500)
		root.add_child(car)
		car.set_physics_process(false)
		for i in 8:
			car.heading = i * PI / 4
			car.update_art()
			var rect: Rect2 = car.sprite.get_rect()
			var anchor: Vector2 = VehicleGrounding.anchor(model, i, car.art_bounds[i])
			check(car.sprite.to_global(rect.position + anchor).distance_to(car.global_position) < .001, model + ": wheel plane must follow logical body")
			check(absf(rect.get_center().x * car.visual_scale) < .01, model + ": no lateral padding displacement")
			var shadow := VehicleGrounding.shadow_bounds(model, i, car.art_bounds[i], car.visual_scale)
			check(shadow.get_center().is_zero_approx(), "Contact shadow shares logical origin")
			check(is_equal_approx(shadow.end.y, rect.end.y * car.visual_scale), "Shadow reaches real cropped wheel baseline")
			var image: Image = car.sprite.texture.get_image()
			check(Rect2(image.get_used_rect()) == car.art_bounds[i], "Grounding uses actual PNG alpha bounds")
			check(car.sprite.position == Vector2.ZERO and car.sprite.rotation == 0, "No artificial lift/rotation")
			check(car.collider.position == Vector2.ZERO, "Collision shares wheel-plane origin")
			check(rect.size.x > 0 and car.visual_scale > 0 and car.visual_scale < 4, "Valid frame / scale")
		car.route_points.assign([Vector2(300, 500), Vector2(700, 500), Vector2(700, 900), Vector2(300, 900)])
		car.build_curve()
		var seen := {}
		for step in 600:
			car.cached_gap = 10000
			car.proximity_clock = 10000
			car._physics_process(.05)
			seen[car.facing_index] = true
			check(car.position.distance_to(car.curve.sample_baked(car.progress)) < .01, "No visual correction may displace route")
			check(car.collider.rotation == car.heading, "Footprint follows turn")
		check(seen.size() == 8, model + ": all turn headings exercised")
		car.cached_gap = 0
		for step in 100: car._physics_process(.05)
		var stopped: Vector2 = car.position
		car._physics_process(.05)
		check(car.current_speed == 0 and car.position == stopped, "Stopped wheels remain anchored")
		car.free()
	print("VEHICLE GROUNDING: ", failures, " failures")
	quit(1 if failures else 0)
