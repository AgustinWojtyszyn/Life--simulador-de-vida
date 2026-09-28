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
	
	# Run for 3 minutes simulating gameplay
	for section in range(18):
		await frames(600)
		
		# Check for invalid references
		for sprite in world.occluders:
			if not is_instance_valid(sprite):
				check(false, "Invalid occluder reference found")
		
		# Check NPCs are valid
		for npc in get_nodes_in_group("city_residents"):
			if not is_instance_valid(npc):
				check(false, "Invalid NPC reference")
		
		# Check vehicles are valid
		for vehicle in get_nodes_in_group("city_traffic"):
			if not is_instance_valid(vehicle):
				check(false, "Invalid vehicle reference")
	
	print("RUNTIME STABILITY TEST: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
