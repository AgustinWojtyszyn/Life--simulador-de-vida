extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func run() -> void:
	var signal_node = load("res://scripts/traffic_signal.gd").new()
	signal_node.position = Vector2(500, 500)
	root.add_child(signal_node)
	signal_node.set_process(false)
	var cars := []
	var passages := {}
	var inside := {}
	for i in 5:
		var car = load("res://scripts/city_vehicle.gd").new()
		car.model = ["compact", "sedan", "colectivo", "van", "sports"][i]
		car.position = Vector2(150 - i * 170, 470) if i < 3 else Vector2(530, 150 - (i - 3) * 180)
		car.route_left = -400
		car.route_right = 1200
		if i >= 3:
			car.route_points.assign([Vector2(530,-400), Vector2(530,1200), Vector2(1500,1200), Vector2(1500,-400)])
		root.add_child(car)
		car.set_physics_process(false)
		cars.append(car)
		passages[car] = 0
		inside[car] = false
	# Queue at the exit must prevent a new claim.
	var blocker = load("res://scripts/city_vehicle.gd").new()
	blocker.position = Vector2(670,470)
	root.add_child(blocker)
	blocker.set_physics_process(false)
	cars[0].position.x = 330
	signal_node.horizontal_state = "green"
	check(signal_node.clearance_distance(cars[0], cars + [blocker]) < INF and signal_node.owner() == null, "Blocked exit denies entry")
	blocker.free()
	for tick in 3000:
		var phase := fmod(tick * .05, 18.2)
		signal_node.horizontal_state = "green" if phase < 7 else "amber" if phase < 8.35 else "red"
		signal_node.vertical_state = "green" if phase >= 9.1 and phase < 16.1 else "amber" if phase >= 16.1 and phase < 17.45 else "red"
		for car in cars:
			car._physics_process(.05)
			var now: bool = signal_node.junction().has_point(car.position)
			if inside[car] and not now: passages[car] += 1
			inside[car] = now
		# Crossing occupancy is exclusive; no solution by ghosting.
		var count := 0
		for car in cars:
			if inside[car]: count += 1
		check(count <= 1, "Conflicting axes cannot occupy intersection simultaneously")
		for i in cars.size():
			for j in range(i + 1, cars.size()):
				var a = cars[i]
				var b = cars[j]
				var separated := false
				for axis in [Vector2.RIGHT.rotated(a.heading), Vector2.DOWN.rotated(a.heading), Vector2.RIGHT.rotated(b.heading), Vector2.DOWN.rotated(b.heading)]:
					var ar: float = a.half_width * absf(axis.dot(Vector2.RIGHT.rotated(a.heading))) + 10 * absf(axis.dot(Vector2.DOWN.rotated(a.heading)))
					var br: float = b.half_width * absf(axis.dot(Vector2.RIGHT.rotated(b.heading))) + 10 * absf(axis.dot(Vector2.DOWN.rotated(b.heading)))
					if absf((a.position - b.position).dot(axis)) >= ar + br - .1: separated = true
				check(separated, "Physical vehicle footprints cannot overlap")
	for car in cars: check(passages[car] >= 2, "Every queued vehicle clears multiple cycles: " + car.model + " passages=" + str(passages[car]))
	var car = cars[0]
	signal_node.occupant = weakref(car)
	signal_node.entered = true
	car.position = Vector2(2000,2000)
	check(signal_node.owner() == null, "Recycled/exited vehicle releases claim")
	signal_node.occupant = weakref(car)
	car.free()
	cars.remove_at(0)
	check(signal_node.owner() == null, "Deleted vehicle releases claim")
	signal_node.horizontal_state = "red"
	check(is_finite(signal_node.blocking_distance(Vector2(300,500), Vector2.RIGHT, 10,260)), "Red blocks")
	signal_node.horizontal_state = "amber"
	check(is_finite(signal_node.blocking_distance(Vector2(360,500), Vector2.RIGHT,20,260)), "Slow vehicle stops on amber")
	check(not is_finite(signal_node.blocking_distance(Vector2(360,500),Vector2.RIGHT,180,260)), "Vehicle unable to brake clears amber")
	for item in cars: item.free()
	signal_node.free()
	print("INTERSECTION: ", failures, " failures")
	quit(1 if failures else 0)
