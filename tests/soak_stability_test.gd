extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func finite_position(node: Node2D) -> bool:
	return is_finite(node.position.x) and is_finite(node.position.y)

func run() -> void:
	WorldManager.select_country("ar")
	WorldManager.location = "street"
	WorldManager.spawn_position = Vector2(1550, 620)
	WorldManager.playing = false
	var world: Node2D = load("res://scenes/playground.tscn").instantiate()
	root.add_child(world)
	await physics_frame
	await process_frame

	var residents := get_nodes_in_group("city_residents")
	var vehicles := get_nodes_in_group("city_traffic")
	check(residents.size() > 0, "Soak test requires active residents")
	check(vehicles.size() >= 8, "Soak test requires active traffic")
	var resident_start := {}
	var vehicle_start := {}
	for npc in residents:
		resident_start[npc.get_instance_id()] = npc.position
	for car in vehicles:
		vehicle_start[car.get_instance_id()] = car.position
	var initial_nodes := get_node_count()

	for frame in 360:
		await physics_frame
		await process_frame
		if frame % 60 == 0:
			for npc in residents:
				if is_instance_valid(npc):
					check(finite_position(npc), "NPC position must remain finite during soak")
					check(npc.position.x > -200 and npc.position.y > -200 and npc.position.x < world.map_size.x + 200 and npc.position.y < world.map_size.y + 200, "NPC must remain near world bounds")
			for car in vehicles:
				if is_instance_valid(car):
					check(finite_position(car), "Vehicle position must remain finite during soak")
					check(car.position.x > -500 and car.position.y > -500 and car.position.x < world.map_size.x + 500 and car.position.y < world.map_size.y + 500, "Vehicle must remain near route bounds")

	var moved_residents := 0
	for npc in residents:
		if is_instance_valid(npc) and npc.position.distance_to(resident_start.get(npc.get_instance_id(), npc.position)) > 5.0:
			moved_residents += 1
	var moved_vehicles := 0
	for car in vehicles:
		if is_instance_valid(car) and car.position.distance_to(vehicle_start.get(car.get_instance_id(), car.position)) > 20.0:
			moved_vehicles += 1
	check(moved_residents >= maxi(1, int(residents.size() / 5)), "A meaningful share of NPCs must make progress during soak")
	check(moved_vehicles >= maxi(1, int(vehicles.size() / 2)), "A meaningful share of vehicles must make progress during soak")
	check(get_node_count() <= initial_nodes + 24, "Soak must not show unbounded node growth")

	world.queue_free()
	await process_frame
	print("SOAK STABILITY: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
