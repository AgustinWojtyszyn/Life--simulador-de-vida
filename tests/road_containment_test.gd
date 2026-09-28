extends SceneTree

var failures := 0
var road_violations := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func frames(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame

func run() -> void:
	var world: Node2D = load("res://scenes/playground.tscn").instantiate()
	root.add_child(world)
	await frames(10)
	
	var vehicles := get_nodes_in_group("city_traffic")
	check(vehicles.size() >= 10, "Must have vehicles for road containment test")
	
	# Simulate multiple laps
	for lap in range(3):
		for frame in range(600):  # 10 seconds per lap
			await physics_frame
			for vehicle in vehicles:
				if not is_instance_valid(vehicle):
					continue
				# Check if vehicle is on road or intersection
				if not is_on_road_or_intersection(vehicle.position, world):
					road_violations += 1
					if road_violations <= 5:
						print("ROAD_VIOLATION: ", vehicle.name, " at ", vehicle.position)
	
	check(road_violations == 0, "Vehicles must stay on road. Violations: " + str(road_violations))
	
	print("ROAD CONTAINMENT TEST: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures, ", road_violations, " road violations)")
	quit(0 if failures == 0 else 1)

func is_on_road_or_intersection(pos: Vector2, world: Node2D) -> bool:
	# Check if position is within any road or intersection area
	for road in world.roads():
		if road.grow(20).has_point(pos):
			return true
	# Check intersections (where horizontal and vertical roads meet)
	for h_road in world.roads():
		if h_road.size.x > 1000:  # Horizontal
			for v_road in world.roads():
				if v_road.size.y > 1000:  # Vertical
					var intersection_center := Vector2(v_road.get_center().x, h_road.get_center().y)
					if pos.distance_to(intersection_center) < 80:
						return true
	return false
