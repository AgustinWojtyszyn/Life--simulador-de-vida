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
	# Test home interior collisions
	var home: Node2D = load("res://scenes/home.tscn").instantiate()
	root.add_child(home)
	await frames(3)
	var player: CharacterBody2D = home.get_node("Player")
	
	# Test each furniture footprint - player should NOT be able to pass through
	var furniture_rects = [
		["bed", Rect2(147, 178, 86, 61)],
		["sofa", Rect2(380, 253, 100, 22)],
		["kitchen", Rect2(419, 124, 118, 35)],
		["wardrobe", Rect2(243, 148, 48, 18)],
		["tv", Rect2(395, 315, 70, 16)],
		["desk", Rect2(511, 228, 50, 14)],
		["dining", Rect2(572, 306, 56, 19)],
	]
	
	for entry in furniture_rects:
		var name: String = entry[0]
		var rect: Rect2 = entry[1]
		# Place player below furniture and try to move up through it
		player.position = rect.get_center() + Vector2(0, 40)
		player.velocity = Vector2.ZERO
		await frames(2)
		var before_y: float = player.position.y
		# Try to move up through the furniture for 30 frames
		for i in 30:
			player.velocity = Vector2(0, -100)
			await physics_frame
		# Player should have been blocked - should not have passed through
		var passed_through = player.position.y < rect.position.y
		check(not passed_through, "Player must not pass through " + name + " furniture. Before: " + str(before_y) + " After: " + str(player.position.y))
	
	home.queue_free()
	await frames(2)
	
	# Test shop interior collisions
	var shop: Node2D = load("res://scenes/shop.tscn").instantiate()
	root.add_child(shop)
	await frames(3)
	player = shop.get_node("Player")
	
	var shop_rects = [
		["counter", Rect2(495, 170, 132, 43)],
		["table1", Rect2(152, 175, 64, 25)],
		["table2", Rect2(311, 175, 64, 25)],
	]
	
	for entry in shop_rects:
		var name: String = entry[0]
		var rect: Rect2 = entry[1]
		player.position = rect.get_center() + Vector2(0, 40)
		player.velocity = Vector2.ZERO
		await frames(2)
		for i in 30:
			player.velocity = Vector2(0, -100)
			await physics_frame
		var passed_through = player.position.y < rect.position.y
		check(not passed_through, "Player must not pass through shop " + name + ". After: " + str(player.position.y))
	
	print("INTERIOR COLLISION TEST: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
