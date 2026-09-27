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
	var walker: Node2D = load("res://scripts/city_walker.gd").new()
	walker.route.assign([Vector2(100, 100), Vector2(300, 100)])
	walker.position = walker.route[0]
	walker.speed = 72
	root.add_child(walker)
	walker.set_process(false)
	walker.wait_time = 0
	walker._process(1.0 / 60)
	check(walker.velocity.length() > 0 and walker.velocity.length() < 10, "NPC eases into walking")
	for i in 60: walker._process(1.0 / 60)
	check(walker.velocity.length() > 65, "NPC reaches a natural varied pace")
	walker.position = Vector2(295, 100)
	for i in 60: walker._process(1.0 / 60)
	check(walker.position.x <= 300.01 and walker.wait_time > 0, "NPC brakes and pauses without overshooting")
	print("MOVEMENT: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
