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
	var cars := all_cars.filter(func(vehicle): return vehicle.route_points.is_empty())
	var player: CharacterBody2D = world.get_node("Player")
	check(all_cars.size() == 8, "The turning street circuit must add two moving vehicles")
	check(cars.size() == 6, "Six moving vehicles must spawn")
	var models := {}
	var starts: Array[Vector2] = []
	for car in cars:
		models[car.model] = true
		starts.append(car.position)
		check(car.get_parent() == world, "Traffic must participate in world Y sorting")
		check(car.sprite.flip_h == (car.direction > 0), "Sprite must face its travel direction")
	await frames(60)
	for i in cars.size():
		check((cars[i].position.x - starts[i].x) * cars[i].direction > 15, "Both lanes must actually move")
		check(cars[i].position.y == starts[i].y, "Cars must stay in lane")
		cars[i].set_physics_process(false)
	check(models.size() == 4, "Traffic must use four distinct vehicle models")
	var car: AnimatableBody2D = cars[0]
	car.position = Vector2(340, 454)
	car.current_speed = 66.0
	player.position = Vector2(465, 444)
	for i in 240:
		car._physics_process(1.0 / 60.0)
	check(car.position.x < player.position.x - car.half_width - 12, "Car must brake before the resident")
	check(car.current_speed < 0.1, "Car must wait for the crossing to clear")
	player.position = Vector2(590, 370)
	var stopped_x: float = car.position.x
	for i in 60:
		car._physics_process(1.0 / 60.0)
	check(car.position.x > stopped_x + 10, "Car must resume after the resident leaves")
	var leader: AnimatableBody2D = cars[1]
	leader.position = Vector2(620, 454)
	car.position = Vector2(470, 454)
	car.current_speed = 66.0
	for i in 240:
		car._physics_process(1.0 / 60.0)
	check(leader.position.x - car.position.x >= leader.half_width + car.half_width + 21.9, "Queue must preserve clearance")
	check(car.current_speed < 0.1, "Follower must stop behind a stopped vehicle")
	car.position = Vector2(2539, 454)
	car.current_speed = 66.0
	car._physics_process(0.1)
	check(car.position.x < -120 and car.position.x >= -140, "Cars must recycle outside the visible map")
	car.position = Vector2(350, 454)
	player.position = Vector2(350 - car.half_width - 12, 444)
	await frames(3)
	check(player.test_move(player.transform, Vector2(25, 0)), "Moving vehicle body must block the player")
	print("TRAFFIC TEST: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
