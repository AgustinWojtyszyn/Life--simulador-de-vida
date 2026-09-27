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
	
	var residents := get_nodes_in_group("city_residents")
	check(residents.size() > 0, "Must have NPCs for idle test")
	
	# Test 1: NPC in wait state should not move
	var npc = residents[0]
	npc.wait_time = 5.0
	npc.velocity = Vector2.ZERO
	var initial_pos: Vector2 = npc.global_position
	
	await frames(300)  # 5 seconds at 60fps
	
	var pos_diff = npc.global_position.distance_to(initial_pos)
	check(pos_diff < 0.01, "NPC in idle/wait state should not move. Moved: " + str(pos_diff))
	
	# Test 2: NPC in idle state should not move
	npc.wait_time = 5.0
	npc.velocity = Vector2.ZERO
	initial_pos = npc.global_position
	
	await frames(300)
	
	pos_diff = npc.global_position.distance_to(initial_pos)
	check(pos_diff < 0.01, "NPC in second idle period should not move. Moved: " + str(pos_diff))
	
	# Test 3: NPC with activity should not move position
	npc.wait_time = 5.0
	npc.velocity = Vector2.ZERO
	npc.activity = "phone"
	initial_pos = npc.global_position
	
	await frames(300)
	
	pos_diff = npc.global_position.distance_to(initial_pos)
	check(pos_diff < 0.01, "NPC with activity should not move. Moved: " + str(pos_diff))
	
	print("NPC IDLE TEST: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
