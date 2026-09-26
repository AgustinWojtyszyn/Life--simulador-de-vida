extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func frames(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame


func run() -> void:
	var world: Node2D = load("res://scenes/playground.tscn").instantiate()
	root.add_child(world)
	var player: CharacterBody2D = world.get_node("Player")
	await frames(3)
	# Isolate locomotion regression probes; traffic interactions have their own suite.
	for vehicle in get_nodes_in_group("city_traffic"):
		vehicle.set_physics_process(false)
		vehicle.collision_layer = 0
	for path in ["environment/grass", "environment/ground", "environment/sidewalk",
		"environment/obstacle", "characters/resident/south", "characters/resident/north",
		"characters/resident/east", "characters/resident/west"]:
		var texture: Texture2D = load("res://assets/%s.png" % path)
		check(texture != null and texture.get_size() == Vector2(32, 32), "Asset must be 32x32: " + path)
	var sprite: Sprite2D = player.get_node("Sprite2D")
	check(sprite.texture == player.SOUTH, "Player must initially face south")
	check(player.get_node("Camera2D").is_current(), "Camera must be active")
	check(world.y_sort_enabled, "World must sort by ground contact")
	check(world.city_objects.size() >= 45, "Urban scene must be populated")
	for asset in ["buildings/cafe", "buildings/market", "vehicles/car", "vehicles/taxi", "vehicles/van", "vehicles/coupe", "vegetation/tree", "props/bench", "props/lamp", "props/planter", "props/fountain"]:
		var art: Texture2D = load("res://assets/city/%s.png" % asset)
		check(art != null and art.get_width() >= 48, "City asset must load: " + asset)
		var source := art.get_image()
		check(source != null and not source.is_invisible() and source.detect_alpha() != Image.ALPHA_NONE, "Art must have visible pixels and transparency: " + asset)
	for rect in world.solid_rects:
		check(not rect.grow(6).has_point(player.position), "Spawn must be clear of collisions")
	player.position = Vector2(620, 484)
	var start := player.position
	Input.action_press("move_left")
	await frames(30)
	check(player.position.x < start.x - 45, "Input must move the player")
	check(sprite.texture == player.WEST, "Left movement must display west sprite")
	check(absf(player.velocity.length() - 140) < 1, "Full speed must be reached")
	Input.action_press("move_up")
	await frames(15)
	check(player.velocity.length() <= 140.01, "Diagonal movement must be normalized")
	check(sprite.texture == player.NORTH, "Upward diagonal must display north sprite")
	Input.action_release("move_up")
	Input.action_release("move_left")
	await frames(12)
	check(player.velocity.is_zero_approx(), "Release must stop movement")
	check(sprite.texture == player.NORTH, "Stopping must preserve the last facing")
	player.position = Vector2(82, 286)
	player.velocity = Vector2.ZERO
	Input.action_press("move_right")
	await frames(40)
	check(player.position.x <= 102.1 and player.position.x >= 101, "Obstacle must block movement")
	check(sprite.texture == player.EAST, "Right movement must display east sprite")
	Input.action_press("move_down")
	var slide_start := player.position.y
	await frames(15)
	check(player.position.y > slide_start + 10, "Player must slide along obstacles")
	check(sprite.texture == player.SOUTH, "Downward diagonal must display south sprite")
	Input.action_release("move_down")
	Input.action_release("move_right")
	player.position = Vector2(40, 482)
	player.velocity = Vector2.ZERO
	Input.action_press("move_left")
	await frames(40)
	check(player.position.x >= 21.9 and player.position.x <= 23, "Map boundary must block movement")
	Input.action_release("move_left")
	player.position = Vector2(1100, 482)
	player.velocity = Vector2.ZERO
	await frames(40)
	check(player.get_node("Camera2D").get_screen_center_position().x > 950, "Camera must follow player")
	player.position = Vector2(195, 225)
	await frames(20)
	check(world.occluders[0].modulate.a < 0.6, "Buildings must fade when the player is behind")
	player.position = Vector2(590, 370)
	await frames(20)
	check(world.occluders[0].modulate.a > 0.99, "Buildings must restore opacity")
	# All four world edges and a parked car must block the player.
	for probe in [
		{"start": Vector2(1398, 480), "action": "move_right", "axis": "x", "expected": 1418.0},
		{"start": Vector2(910, 40), "action": "move_up", "axis": "y", "expected": 22.0},
		{"start": Vector2(910, 920), "action": "move_down", "axis": "y", "expected": 938.0},
		{"start": Vector2(88, 413), "action": "move_right", "axis": "x", "expected": 109.0},
	]:
		player.position = probe.start
		player.velocity = Vector2.ZERO
		Input.action_press(probe.action)
		await frames(30)
		Input.action_release(probe.action)
		check(absf(player.position[probe.axis] - probe.expected) < 1.0, "Collision probe: " + str(probe))
	print("PLAYGROUND TEST: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
