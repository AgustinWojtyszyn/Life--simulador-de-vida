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
	for path in ["environment/grass", "environment/ground", "environment/sidewalk",
		"environment/obstacle", "characters/resident/south", "characters/resident/north",
		"characters/resident/east", "characters/resident/west"]:
		var texture: Texture2D = load("res://assets/%s.png" % path)
		check(texture != null and texture.get_size() == Vector2(32, 32), "Asset must be 32x32: " + path)
	var sprite: Sprite2D = player.get_node("Sprite2D")
	check(sprite.texture == player.SOUTH, "Player must initially face south")
	check(player.get_node("Camera2D").is_current(), "Camera must be active")
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
	player.position = Vector2(560, 310)
	player.velocity = Vector2.ZERO
	Input.action_press("move_right")
	await frames(40)
	check(player.position.x <= 586.1 and player.position.x >= 584, "Obstacle must block movement")
	check(sprite.texture == player.EAST, "Right movement must display east sprite")
	Input.action_press("move_down")
	var slide_start := player.position.y
	await frames(15)
	check(player.position.y > slide_start + 10, "Player must slide along obstacles")
	check(sprite.texture == player.SOUTH, "Downward diagonal must display south sprite")
	Input.action_release("move_down")
	Input.action_release("move_right")
	player.position = Vector2(40, 320)
	player.velocity = Vector2.ZERO
	Input.action_press("move_left")
	await frames(40)
	check(player.position.x >= 21.9 and player.position.x <= 23, "Map boundary must block movement")
	Input.action_release("move_left")
	player.position = Vector2(800, 400)
	player.velocity = Vector2.ZERO
	await frames(40)
	check(player.get_node("Camera2D").get_screen_center_position().x > 600, "Camera must follow player")
	print("PLAYGROUND TEST: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
