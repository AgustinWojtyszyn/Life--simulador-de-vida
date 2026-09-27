extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	var world: Node2D = load("res://scenes/playground.tscn").instantiate()
	root.add_child(world)
	var player: CharacterBody2D = world.get_node("Player")
	player.set_physics_process(false)
	player.position = Vector2(550, 500)
	for car in get_nodes_in_group("city_traffic"):
		car.set_physics_process(false)
		car.collision_layer = 0
	Input.action_press("move_right")
	player._physics_process(1.0 / 60)
	check(player.velocity.x > 0 and player.velocity.x < 30, "Player starts gradually")
	for i in 20: player._physics_process(1.0 / 60)
	check(is_equal_approx(player.velocity.x, 140), "Walking reaches full pace")
	Input.action_release("move_right")
	var stop_start := player.position
	for i in 8: player._physics_process(1.0 / 60)
	check(player.velocity.is_zero_approx(), "Release stops promptly")
	check(player.position.distance_to(stop_start) < 10, "Stopping does not visibly slide")
	check(player.visual.pose == "idle", "Displacement controls animation")
	# Regression: diagonal and cardinal input must cover the same distance.
	player.position = Vector2(550, 500)
	player.velocity = Vector2.ZERO
	var cardinal_start := player.position
	Input.action_press("move_right")
	for i in 45: player._physics_process(1.0 / 60.0)
	Input.action_release("move_right")
	var cardinal_distance := player.position.distance_to(cardinal_start)
	player.position = Vector2(550, 500)
	player.velocity = Vector2.ZERO
	var diagonal_start := player.position
	Input.action_press("move_right")
	Input.action_press("move_down")
	for i in 45: player._physics_process(1.0 / 60.0)
	Input.action_release("move_right")
	Input.action_release("move_down")
	var diagonal_distance := player.position.distance_to(diagonal_start)
	check(absf(cardinal_distance - diagonal_distance) < 1.0, "Diagonal and cardinal travel must have equal speed")
	check(player.velocity.length() <= 140.01, "Diagonal input must never exceed walking speed")
	for i in 8: player._physics_process(1.0 / 60.0)
	check(player.velocity.is_zero_approx(), "Player must stop cleanly after diagonal input")
	for gender in ["male", "female"]:
		var profile := PlayerProfile.new()
		profile.gender = gender
		player.visual.apply_profile(profile)
		for direction in AssetOrientation.DIRECTIONS:
			var frames_in_cycle: Array[Texture2D] = player.visual.walk_cycle(direction)
			check(frames_in_cycle.size() >= 8, gender + " must animate eight frames toward " + direction)
			var images := {}
			for frame in frames_in_cycle: images[hash(frame.get_image().get_data())] = true
			check(images.size() >= 4, "Walk cycles must contain distinct authored steps")
			player.visual.animate_motion(AssetOrientation.vector(direction), 7.0)
			check(player.visual.facing == direction and player.visual.pose == "walk", "Every compass direction must walk instead of falling back to idle")
			player.visual.set_art("walk", direction, 0)
			var pivot: Vector2 = player.visual.sprite.position
			player.visual.set_art("walk", direction, 3)
			check(player.visual.sprite.position.is_equal_approx(pivot), "Walking keeps its authored ground pivot")
	var walker: CharacterBody2D = load("res://scripts/city_walker.gd").new()
	walker.route.assign([Vector2(100, 100), Vector2(300, 100)])
	walker.position = walker.route[0]
	walker.speed = 72
	root.add_child(walker)
	walker.set_physics_process(false)
	walker.wait_time = 0
	check(walker.collision_layer == 4 and walker.collision_mask == 5, "NPCs use foot-level physics collisions against world and residents")
	walker._physics_process(1.0 / 60)
	check(walker.velocity.length() > 0 and walker.velocity.length() < 10, "NPC eases into walking")
	for i in 60: walker._physics_process(1.0 / 60)
	check(walker.velocity.length() > 65, "NPC reaches a natural varied pace")
	walker.position = Vector2(295, 100)
	for i in 60: walker._physics_process(1.0 / 60)
	check(walker.position.x <= 300.01 and walker.wait_time > 0, "NPC brakes and pauses without overshooting")
	print("MOVEMENT: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
