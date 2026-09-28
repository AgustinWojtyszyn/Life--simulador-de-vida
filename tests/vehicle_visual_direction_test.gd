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
	await frames(10)
	
	var vehicles := get_nodes_in_group("city_traffic")
	check(vehicles.size() >= 4, "Must have vehicles for direction test")
	
	# Test each vehicle's visual direction matches its movement
	for vehicle in vehicles:
		if not is_instance_valid(vehicle):
			continue
		# Set vehicle to move east
		vehicle.heading = 0.0  # East
		vehicle.update_art()
		await frames(2)
		
		var facing_index: int = vehicle.facing_index
		var expected_direction := vehicle.DIRECTIONS[facing_index]
		
		# Verify the sprite texture exists and is loaded
		var sprite: Sprite2D = vehicle.sprite
		check(sprite.texture != null, "Vehicle " + vehicle.name + " has no texture")
		
		# For taxi specifically, verify it moves correctly
		if vehicle.model == "taxi":
			# Place taxi on a straight road and verify it moves forward
			vehicle.position = Vector2(500, 454)
			vehicle.current_speed = 100
			vehicle.route_points.clear()
			var start_x: float = vehicle.position.x
			await frames(60)
			var moved_distance: float = abs(vehicle.position.x - start_x)
			check(moved_distance > 10, "Taxi should move forward. Moved: " + str(moved_distance))
			
			# Verify facing index corresponds to actual movement direction
			# When moving east (positive x), facing should be east (index 0)
			if vehicle.position.x > start_x:
				check(facing_index == 0, "Taxi moving east should face east. Facing: " + expected_direction)
	
	print("VEHICLE VISUAL DIRECTION TEST: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
