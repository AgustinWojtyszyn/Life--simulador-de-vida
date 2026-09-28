extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	var wm := root.get_node("WorldManager")
	var orientation = load("res://scripts/data/asset_orientation.gd")
	for country in wm.countries:
		wm.select_country(country.id)
		var world: Node2D = load("res://scenes/playground.tscn").instantiate()
		root.add_child(world)
		await physics_frame
		await process_frame
		var views := {}
		for object in world.city_objects:
			if object.has_meta("building_type") and object.get_script() != null and object.get_script().resource_path.find("building.gd") >= 0:
				views[object.orientation] = true
				check(object.facade != null, country.id + ": every building must have a facade")
				if object.facade != null:
					check(not object.facade.resource_path.is_empty(), country.id + ": facade must come from a real resource")
					if country.id != "ar":
						check(not object.facade.resource_path.contains("/ar/"), country.id + ": foreign city must never borrow an Argentine facade")
				var normal: String = orientation.street_facing(object.position, world.roads(), false)
				# A facade is correctly oriented if it faces the closest street OR
				# if it faces a perpendicular street (for side-street buildings).
				var dot_prod = orientation.vector(object.orientation).dot(orientation.vector(normal))
				if dot_prod < 0.7:
					# Check if the building faces a perpendicular street
					for road in world.roads():
						var nearest = object.position.clamp(road.position, road.end)
						var toward = nearest - object.position
						if toward.length() > 0 and toward.length() < 200:
							var perp_dot = orientation.vector(object.orientation).dot(toward.normalized())
							if perp_dot >= 0.7:
								dot_prod = perp_dot
								break
				check(dot_prod >= 0.7, country.id + ": facade faces its own street: " + object.building_id + " at " + str(object.position) + " facing " + object.orientation + " expected " + normal)
				check(object.rotation == 0 and not object.get_child(0).flip_h, "Building views must not rotate or mirror signs")
				if object.facade.resource_path.contains("/oriented/"):
					check(object.facade.resource_path.get_file() == object.orientation + ".png", "Declared view must use authored frame")
				if object.building_type == "pizzeria":
					check(object.facade.resource_path.contains("/oriented/it/pizzeria/"), "Pizzeria uses complete new architecture")
				for child in object.get_children():
					if child.is_in_group("interactables"):
						check(not object.footprint.grow(5).has_point(child.position), "Door remains outside building footprint")
			if object.is_in_group("parked_vehicles"):
				check(object.get_meta("orientation") in ["east", "west"], "Parking follows bay axis")
		check(views.size() >= 4, country.id + ": at least four actual orientations visible")
		if country.id == "ar":
			var bus: Node2D = world.get_node("Colectivo")
			check(bus.directional_art.size() == 8 and not bus.route_points.is_empty(), "Bus has eight real views and a turning route")
			var traffic_node = world.get_node_or_null("Traffic_0_0")
			if traffic_node == null:
				# Find any traffic node for comparison
				for child in world.get_children():
					if child.is_in_group("city_traffic") and child.route_points.is_empty():
						traffic_node = child
						break
			check(traffic_node != null, "Must have a traffic node for comparison")
			if traffic_node:
				check(bus.cruise_speed < traffic_node.cruise_speed, "Bus cruises slower than a compact car")
				check(bus.driver_acceleration < traffic_node.driver_acceleration, "Bus gains speed more gradually")
		for car in get_nodes_in_group("city_traffic"):
			car.set_physics_process(false)
			if car.route_points.is_empty(): continue
			var seen := {}
			# Sample real frame-to-frame movement throughout each closed circuit.
			# Other traffic is removed only from the proximity query for this probe.
			for other in get_nodes_in_group("city_traffic"):
				other.remove_from_group("city_traffic")
			car.player = null
			for at in range(0, int(car.curve.get_baked_length()), 3):
				car.progress = float(at)
				car.position = car.curve.sample_baked(car.progress)
				car.current_speed = 100.0
				car.proximity_clock = 1.0
				car.cached_gap = 10000.0
				car._physics_process(1.0 / 60.0)
				if car.motion_vector.length() < 0.01: continue
				var facing: String = car.DIRECTIONS[car.facing_index]
				seen[facing] = true
				check(orientation.vector(facing).dot(car.motion_vector.normalized()) >= 0.923, "Vehicle frame agrees with actual displacement within 22.5 degrees")
				check(car.sprite.rotation == 0, "No rotated vehicle PNGs")
				check(car.sprite.position == Vector2.ZERO, "Turning keeps the same ground centre")
				var frame_bounds: Rect2 = car.art_bounds[car.facing_index]
				check(car.sprite.get_rect().end.is_equal_approx(Vector2(frame_bounds.size.x * 0.5, 0)), "Region bottom-center is the common ground anchor")
			if seen.size() != 8:
				var missing := []
				for dir in ["east", "south-east", "south", "south-west", "west", "north-west", "north", "north-east"]:
					if not seen.has(dir):
						missing.append(dir)
				print("ORIENT_DEBUG: car=", car.name, " missing=", missing, " curve_len=", car.curve.get_baked_length(), " seen=", seen.keys(), " route_points=", car.route_points)
			check(seen.size() == 8, "Rounded circuit exercises all eight views")
		print("ORIENTATION: ", country.id, " ", views.keys())
		world.queue_free()
		await process_frame
	print("ORIENTATION TEST: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
