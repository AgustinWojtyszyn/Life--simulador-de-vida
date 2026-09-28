extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	var world = load("res://scenes/playground.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var nav = world.pedestrian_navigation
	# Actual generated buildings: every segment must clear inflated footprints.
	var detours := 0
	for rect in world.solid_rects:
		if rect.size.x < 60 or rect.size.x > 250 or rect.size.y < 20:
			continue
		var a: Vector2 = nav.nearest(rect.get_center() - Vector2(rect.size.x * 0.5 + 35, 0))
		var b: Vector2 = nav.nearest(rect.get_center() + Vector2(rect.size.x * 0.5 + 35, 0))
		var path: PackedVector2Array = nav.path(a, b)
		check(path.size() > 2, "Building requires a real detour")
		for i in range(1, path.size()):
			check(nav.segment_clear(path[i - 1], path[i]), "Route cuts through a solid")
		detours += 1
		if detours >= 12:
			break
	check(detours >= 5, "Exercise several buildings")
	for npc in get_nodes_in_group("city_residents"):
		npc.set_physics_process(false)
		npc.visible = false
		# Hidden actors must not remain physical obstacles.
		npc.collision_layer = 0
	world.get_node("PopulationSystem").residents.clear()
	var player = world.get_node("Player")
	player.set_physics_process(false)
	player.position = Vector2(310, 610)
	var walker = load("res://scripts/city_walker.gd").new()
	walker.position = Vector2(210, 610)
	walker.route.assign([walker.position, Vector2(410, 610)])
	walker.speed = 70
	world.add_child(walker)
	await process_frame
	walker.wait_time = 0
	walker.route_kind = "walk"
	check(nav.segment_clear(Vector2(210, 610), Vector2(410, 610)), "Encounter fixture starts on an unobstructed pavement")
	var max_y := 0.0
	for i in 1200:
		await physics_frame
		if i in [70, 130] and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://build/npc_player_%d.png" % i)
		max_y = maxf(max_y, absf(walker.position.y - 610.0))
		check(not Rect2(player.position - Vector2(7, 8), Vector2(14, 8)).has_point(walker.position), "NPC penetrates player")
		if walker.visits > 0:
			break
	check(walker.visits > 0, "NPC must go around stationary player and arrive")
	check(max_y > 15, "Player avoidance uses a detour")
	walker.wait_time = 3.0
	walker.activity = "phone"
	var idle_at: Vector2 = walker.position
	for i in 100:
		await physics_frame
	check(walker.position == idle_at, "Idle NPC must stay exactly still")
	# Opposing walkers need to pass, not yield to each other indefinitely.
	player.position = Vector2(900, 700)
	player.get_node("Camera2D").position = Vector2(-590, -90)
	player.get_node("Camera2D").reset_smoothing()
	walker.position = Vector2(210, 610)
	walker.route.assign([walker.position, Vector2(410, 610)])
	walker.destination = 1
	walker.path.clear()
	walker.visits = 0
	walker.wait_time = 0
	var other = load("res://scripts/city_walker.gd").new()
	other.position = Vector2(410, 610)
	other.route.assign([other.position, Vector2(210, 610)])
	world.add_child(other)
	await process_frame
	other.wait_time = 0
	for i in 1200:
		await physics_frame
		if i in [70, 130] and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://build/npc_encounter_%d.png" % i)
		if walker.visits > 0 and other.visits > 0:
			break
	check(walker.visits > 0 and other.visits > 0, "Oncoming walkers both complete their route")
	print("NAVIGATION REGRESSION: ", "PASS" if failures == 0 else "FAIL", " (", failures, ")")
	quit(0 if failures == 0 else 1)
