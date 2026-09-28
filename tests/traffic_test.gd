extends SceneTree

var failures := 0

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
	await frames(3)
	var all_cars := get_nodes_in_group("city_traffic")
	var cars := all_cars.filter(func(vehicle): return vehicle.route_points.is_empty() and vehicle.model != "colectivo")
	var player: CharacterBody2D = world.get_node("Player")
	check(all_cars.size() >= 16, "Expanded district must keep starter, circuit, grid and bus traffic")
	check(cars.size() >= 12, "Expanded avenues must add straight-moving traffic beyond the starter six")
	check(all_cars.filter(func(vehicle): return vehicle.model == "colectivo").size() >= 2, "Argentina keeps both circulating buses")
	var circuit_cars := all_cars.filter(func(vehicle): return not vehicle.route_points.is_empty() and vehicle.model != "colectivo")
	for turning in circuit_cars:
		var seen := {}
		for distance in range(0, int(turning.curve.get_baked_length()), 3):
			turning.heading = turning.tangent(float(distance)).angle()
			turning.update_art()
			seen[turning.facing_index] = true
			check(is_zero_approx(turning.sprite.rotation), "Cornering must change frames without rotating artwork")
		check(seen.size() == 8, "Circuit must use all eight directions through continuous arcs")
	for vehicle in all_cars:
		check(vehicle.cruise_speed > 140.0, "Traffic cruise speed must exceed pedestrian speed")
	var models := {}
	var starts: Array[Vector2] = []
	for car in cars:
		models[car.model] = true
		starts.append(car.position)
		check(car.get_parent() == world, "Traffic must participate in world Y sorting")
		check(car.directional_art.size() == 8, "Every moving car must have eight authored directions")
		check(is_zero_approx(car.sprite.rotation), "Vehicle textures must never rotate")
	await frames(60)
	for i in cars.size():
		check((cars[i].position.x - starts[i].x) * cars[i].direction > 15, "Both lanes must actually move")
		check(cars[i].position.y == starts[i].y, "Cars must stay in lane")
		cars[i].set_physics_process(false)
	check(models.size() >= 4, "Traffic must use at least four distinct vehicle models")
	var same_lane := cars.filter(func(vehicle): return vehicle.direction > 0.0 and is_equal_approx(vehicle.position.y, cars[0].position.y))
	if same_lane.size() < 2:
		same_lane = cars.filter(func(vehicle): return vehicle.direction > 0.0)
	check(same_lane.size() >= 2, "Traffic test needs two same-direction vehicles")
	var car: AnimatableBody2D = same_lane[0]
	# Isolate braking behaviour from unrelated cars, pedestrians and red lights.
	for other in all_cars:
		if other != car:
			other.remove_from_group("city_traffic")
	for resident in get_nodes_in_group("city_residents"):
		resident.remove_from_group("city_residents")
	for traffic_signal in get_nodes_in_group("traffic_signals"):
		traffic_signal.horizontal_state = "green"
		traffic_signal.vertical_state = "green"
	car.position = Vector2(340, car.position.y)
	car.current_speed = 66.0
	car.proximity_clock = 0.0
	player.position = Vector2(465, car.position.y - 10.0)
	for i in 720:
		car._physics_process(1.0 / 60.0)
	check(car.position.x < player.position.x - car.half_width - 12, "Car must brake before the resident")
	check(car.current_speed < 0.1, "Car must wait for the crossing to clear")
	player.position = Vector2(590, car.position.y - 90.0)
	car.proximity_clock = 0.0
	var stopped_x: float = car.position.x
	print("TRAFFIC_DEBUG: START stopped_x=", stopped_x, " speed=", car.current_speed, " gap=", car.cached_gap, " route_points=", car.route_points.size(), " physics_process=", car.can_process())
	for i in 60:
		car._physics_process(1.0 / 60.0)
		if i % 10 == 0:
			print("TRAFFIC_DEBUG: i=", i, " pos.x=", car.position.x, " speed=", car.current_speed, " gap=", car.cached_gap, " route_points=", car.route_points.size())
	if car.position.x <= stopped_x + 10:
		print("TRAFFIC_DEBUG: FAILED! stopped_x=", stopped_x, " final_x=", car.position.x, " speed=", car.current_speed, " route_points=", car.route_points.size())
	check(car.position.x > stopped_x + 10, "Car must resume after the resident leaves")
	var leader: AnimatableBody2D = same_lane[1]
	leader.add_to_group("city_traffic")
	leader.position = Vector2(620, car.position.y)
	car.position = Vector2(470, car.position.y)
	car.current_speed = 66.0
	car.proximity_clock = 0.0
	for i in 240:
		car._physics_process(1.0 / 60.0)
	check(leader.position.x - car.position.x >= leader.half_width + car.half_width + 21.9, "Queue must preserve clearance")
	check(car.current_speed < 0.1, "Follower must stop behind a stopped vehicle")
	car.position = Vector2(car.route_right - 1.0, 454)
	car.current_speed = 66.0
	car._physics_process(0.1)
	check(car.position.x < car.route_left + 20.0 and car.position.x >= car.route_left, "Cars must recycle outside the expanded visible map")
	# Isolate the collision probe from the opposite lane car at x=300.
	for other in all_cars:
		if other != car: other.collision_layer = 0
	car.position = Vector2(350, 454)
	player.position = Vector2(350 - car.half_width - 12, 444)
	await frames(3)
	check(player.test_move(player.transform, Vector2(25, 0)), "Moving vehicle body must block the player")
	print("TRAFFIC TEST: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
