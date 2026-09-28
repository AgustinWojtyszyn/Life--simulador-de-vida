extends SceneTree

var failures := 0
var npc_data: Array = []

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
	
	var residents := get_nodes_in_group("city_residents")
	check(residents.size() >= 30, "Must have at least 30 NPCs for stability test. Found: " + str(residents.size()))
	
	# Initialize tracking data
	for npc in residents:
		npc_data.append({
			"npc": npc,
			"last_pos": npc.global_position,
			"blocked_time": 0.0,
			"max_displacement": 0.0,
			"was_idle": false
		})
	
	# Simulate 60 seconds at 60fps
	for frame in range(3600):
		await physics_frame
		
		for data in npc_data:
			var npc = data["npc"]
			if not is_instance_valid(npc):
				continue
			
			var current_pos: Vector2 = npc.global_position
			var displacement: float = current_pos.distance_to(data["last_pos"])
			
			# Check idle stability
			if npc.wait_time > 0:
				if displacement > 0.01:
					check(false, "NPC " + npc.name + " moved " + str(displacement) + "px while idle at frame " + str(frame))
				data["was_idle"] = true
			else:
				data["was_idle"] = false
				# Check max displacement per frame (no teleports)
				var max_expected = npc.speed * (1.0/60.0) * 2.0  # 2x tolerance
				if displacement > max_expected:
					check(false, "NPC " + npc.name + " teleported " + str(displacement) + "px in one frame at frame " + str(frame))
			
			data["max_displacement"] = maxf(data["max_displacement"], displacement)
			data["last_pos"] = current_pos
	
	# Check no NPCs are stuck inside solids
	for data in npc_data:
		var npc = data["npc"]
		if not is_instance_valid(npc):
			continue
		for solid in world.solid_rects:
			if solid.has_point(npc.global_position):
				check(false, "NPC " + npc.name + " is inside solid rect: " + str(solid))
	
	print("NPC STABILITY TEST: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
