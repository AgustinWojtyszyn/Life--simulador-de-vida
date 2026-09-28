extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	var wm := root.get_node("WorldManager")
	var inputs := root.get_node("InputManager")
	wm.select_country("ar")
	wm.location = "street"
	wm.playing = false
	wm.spawn_position = Vector2(1550, 620)

	var world: Node2D = load("res://scenes/playground.tscn").instantiate()
	root.add_child(world)
	await physics_frame
	await process_frame

	check(wm.district.world_size == Vector2(4800, 3200), "Expanded city must be 4800x3200")
	check(world.map_size == Vector2(4800, 3200), "Playground must use district world size")
	check(world.city_objects.size() > 70, "Expanded district must contain substantial street content")
	check(get_nodes_in_group("city_traffic").size() >= 8, "Expanded district must retain active traffic")
	check(get_nodes_in_group("traffic_signals").size() == 16, "Every 4x4 road grid intersection must have a traffic signal")
	check(get_nodes_in_group("city_minimap").size() >= 1, "Street HUD must include a lightweight minimap")
	var first_signal = get_nodes_in_group("traffic_signals")[0]
	first_signal.horizontal_state = "red"
	first_signal.vertical_state = "green"
	var signal_probe: Vector2 = first_signal.global_position + Vector2(-float(first_signal.vertical_half) - 120.0, 0)
	check(first_signal.blocking_distance(signal_probe, Vector2.RIGHT) < 220.0, "Red signal must stop approaching horizontal traffic")
	first_signal.horizontal_state = "green"
	check(first_signal.blocking_distance(signal_probe, Vector2.RIGHT) == INF, "Green signal must release horizontal traffic")
	check(world.has_node("Colectivo") and world.has_node("Colectivo2"), "Argentina must retain both bus lines")
	check(world.has_node("Cancha Municipal"), "Argentina must contain the large municipal football ground")

	var directions := {}
	var kiosk_found := false
	for object in world.city_objects:
		if object.has_meta("building_type"):
			directions[object.get_meta("orientation")] = true
			if object.get_meta("building_type") == "kiosk":
				kiosk_found = true
				check(object.size.x <= 140, "Kiosk must remain compact and avoid low-quality upscaling")
	check(directions.size() >= 4, "Street architecture must use at least four real facade directions")
	check(kiosk_found, "Argentina must contain a kiosk")

	for i in world.building_bounds.size():
		for j in range(i + 1, world.building_bounds.size()):
			check(not world.building_bounds[i].intersects(world.building_bounds[j]), "Building visual bounds must not overlap")
		for road in world.roads():
			check(not world.building_bounds[i].intersects(road), "Building facade must not extend into a road")

	var pitch: Node2D = world.get_node("Cancha Municipal")
	check(pitch.get_meta("building_type") == "sports", "Football ground must be tagged as sports")
	var pitch_interactions := pitch.get_tree().get_nodes_in_group("interactables")
	check(not pitch_interactions.is_empty(), "Expanded world must expose interactions")

	# Mobile controls: movement and action can coexist on different fingers.
	inputs.touch_enabled = true
	var touch := Control.new()
	touch.set_script(load("res://scripts/ui/touch_controls.gd"))
	root.add_child(touch)
	await process_frame
	touch.context_available = true
	var stick := InputEventScreenTouch.new()
	stick.index = 0
	stick.pressed = true
	stick.position = touch.stick_center + Vector2(touch.radius * 0.75, 0)
	touch._input(stick)
	var action := InputEventScreenTouch.new()
	action.index = 1
	action.pressed = true
	action.position = touch.action_center
	touch._input(action)
	check(inputs.movement().x > 0.6, "Virtual joystick must move the player")
	check(inputs.touch_interaction, "Touch action button must trigger interaction")
	check(touch.stick_finger == 0 and touch.action_finger == 1, "Multitouch ownership must remain independent")
	stick.pressed = false
	touch._input(stick)
	check(inputs.touch_vector == Vector2.ZERO, "Joystick release must stop touch movement")
	inputs.reset()
	inputs.touch_enabled = false
	touch.queue_free()

	check(root.has_node("AudioSystem"), "Original audio system must be registered")
	check(root.get_node("AudioSystem").track_count() >= 5, "Soundtrack must expose at least five selectable songs")
	check(not root.get_node("AudioSystem").track_name().is_empty(), "Selectable soundtrack must expose a track name")

	world.queue_free()
	await process_frame
	print("ITERATION SMOKE: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
