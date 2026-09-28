extends SceneTree
class TestWorld extends Node2D:
	var solid_rects: Array[Rect2] = [Rect2(220,160,50,80)]
	func walker_position_clear(at: Vector2) -> bool:
		return not solid_rects[0].grow(8).has_point(at)
var failures := 0
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var world := TestWorld.new()
	root.add_child(world)
	var body := StaticBody2D.new()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(50,80)
	collision.shape = shape
	body.position = Vector2(245,200)
	body.add_child(collision)
	world.add_child(body)
	var walkers := []
	for i in 5:
		var walker = load("res://scripts/city_walker.gd").new()
		walker.position = Vector2(120,190 + i * 30) if i < 2 else Vector2(400,190 + (i-2)*30)
		walker.route.assign([walker.position, Vector2(400 if i < 2 else 120, walker.position.y)])
		if i == 4:
			walker.position = Vector2(120,300)
			walker.route.assign([walker.position, Vector2(245,200)])
		world.add_child(walker)
		walker.wait_time = 0
		walkers.append(walker)
	for frame in 1000:
		await physics_frame
		for walker in walkers:
			if not world.walker_position_clear(walker.position):
				failures += 1
				push_error("Walker penetrated solid")
		for i in walkers.size():
			for j in range(i + 1, walkers.size()):
				var delta: Vector2 = walkers[i].position - walkers[j].position
				if absf(delta.x) < 11.8 and absf(delta.y) < 7.8:
					failures += 1
					push_error("Residents overlap")
	for walker in walkers:
		if walker.visits == 0:
			failures += 1
			push_error("Walker failed to recover: " + str(walker.position) + " detour=" + str(walker.detour) + " destination=" + str(walker.destination) + " blocked=" + str(walker.blocked_time))
	world.queue_free()
	await process_frame
	print("WALKER RECOVERY: ", failures, " failures")
	quit(1 if failures else 0)
