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

func activate() -> void:
	Input.action_press("interact")
	await frames(2)
	Input.action_release("interact")
	await frames(2)

func run() -> void:
	var world: Node2D = load("res://scenes/playground.tscn").instantiate()
	root.add_child(world)
	await frames(3)
	var player: CharacterBody2D = world.get_node("Player")
	var actions: Node = world.get_node("Interactions")
	var parked := get_nodes_in_group("parked_vehicles")
	check(parked.size() == 4, "Parking must have four vehicles")
	var bounds := Rect2(1034, 635, 362, 272)
	for car in parked:
		check(bounds.has_point(car.position), "Parked vehicles must be inside the dedicated lot")
		check(car.position.y > 600, "No parked cars may remain in active road lanes")
	var bench: Node2D = get_nodes_in_group("city_benches")[0]
	player.position = bench.position + Vector2(0, 20)
	await frames(2)
	check(actions.prompt.contains("Sentarte"), "Bench must advertise its action")
	await activate()
	check(player.transitioning and not player.seated, "Seating must begin with an approach, not teleport")
	await frames(75)
	check(player.seated and player.sprite.texture == player.SEATED, "E must seat the resident with the seated pose")
	var seat_position := player.position
	await frames(28)
	check(player.position == seat_position, "Resting must hold the seated position")
	await activate()
	await frames(30)
	check(not player.seated and player.collision_mask == 3 and player.collision_layer == 1, "E must restore movement and collisions")
	check(not player.test_move(player.transform, Vector2(0, 1)), "Standing spot must be clear")
	await frames(20)
	await activate()
	await frames(75)
	check(player.seated, "Bench can be used again")
	Input.action_press("move_right")
	await frames(6)
	Input.action_release("move_right")
	await frames(30)
	check(not player.seated, "Movement must also stand up")
	await frames(30)
	var resident: Node2D = get_nodes_in_group("city_residents")[0]
	player.position = resident.position + Vector2(0, 22)
	player.velocity = Vector2.ZERO
	await frames(2)
	check(actions.prompt.contains("Saludar"), "Nearby resident must advertise greeting")
	await activate()
	check(resident.greeting_time > 0 and player.wave_time > 0, "Both residents must visibly greet")
	var paused := resident.position
	await frames(20)
	check(resident.position == paused, "Neighbor must pause to respond")
	await frames(145)
	check(resident.position != paused, "Neighbor must resume walking after greeting")
	var fountain: Node2D = get_nodes_in_group("city_fountain")[0]
	player.position = fountain.position + Vector2(0, 20)
	player.velocity = Vector2.ZERO
	await frames(2)
	check(actions.prompt.contains("deseo"), "Fountain must advertise wishing")
	var before: float = fountain.water_time
	await activate()
	check(fountain.wishes == 1 and fountain.wish_time > 0, "Wish must trigger the splash effect")
	await frames(10)
	check(fountain.water_time > before, "Water animation must advance independently")
	player.position = Vector2(590, 370)
	await frames(30)
	await activate()
	check(fountain.wishes == 1, "Interactions must not trigger remotely")
	print("INTERACTIONS TEST: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
