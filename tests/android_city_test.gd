extends SceneTree

var failures := 0
func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func frames(count := 3) -> void:
	for i in count: await process_frame

func touch(controls: Control, index: int, at: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = at
	event.pressed = pressed
	controls._input(event)

func run() -> void:
	var wm := root.get_node("WorldManager")
	var inputs := root.get_node("InputManager")
	inputs.touch_enabled = true
	for country in wm.countries:
		wm.select_country(country.id)
		var world: Node2D = load("res://scenes/playground.tscn").instantiate()
		root.add_child(world)
		await frames()
		var families := {}
		for object in world.city_objects:
			if object.has_meta("building_type") and object.variant.has("family"):
				families[object.variant.family] = true
				check(object.facade is AtlasTexture, "Country atlas must be shared")
				check(object.facade.atlas.resource_path == "res://assets/catalog/%s.png" % country.id, "No foreign-country fallback")
				check(object.orientation == AssetOrientation.street_facing(object.position, world.roads(), false), "New facade must face its street")
				var door: Vector2 = object.position + object.door_offset
				for solid in world.solid_rects:
					check(not solid.grow(6).has_point(door), "Entrance/approach must be free")
		check(families.size() == 16, country.id + " must actually place all 16 new families")
		check(world.get_node("GroundCache").size == Vector2i(1200, 1200), "Mobile ground cache fits budget")
		var seats := 0
		for object in world.city_objects:
			if not object.is_in_group("public_benches"): continue
			seats += 1
			var base := Rect2(object.position - Vector2(29, 16), Vector2(58, 20))
			check(world.bench_zone().any(func(zone: Rect2): return zone.encloses(base)), "Benches only in authored public rest areas")
			for corridor in world.PEDESTRIAN_CORRIDORS:
				check(not base.intersects(corridor), "Seat cannot block the plaza promenade")
			for entrance in world.entrance_clearance:
				check(not base.intersects(entrance), "Seat cannot block a door")
		check(seats >= 2, "Keep usable public seating")
		world.queue_free()
		await frames()
	var app: Node = load("res://scenes/app.tscn").instantiate()
	root.add_child(app)
	await frames()
	for viewport_size in [Vector2i(800, 450), Vector2i(960, 432), Vector2i(640, 360)]:
		root.size = viewport_size
		app.menu.create_screen()
		await frames()
		var scroll := app.menu.panel.get_parent() as ScrollContainer
		check(scroll.get_h_scroll_bar().max_value <= scroll.size.x + 1, "Character creator must not need horizontal scrolling")
		for node in app.menu.find_children("*", "OptionButton", true, false):
			check(node.size.y >= 48, "Touch choices at least 48 canvas units")
		app.menu.country_screen()
		await frames()
		var countries: OptionButton
		for node in app.menu.panel.get_children():
			if node is OptionButton: countries = node
		check(countries.item_count == 5, "Selection is countries, never provinces")
		countries.item_selected.emit(2)
		check(app.menu.chosen == "jp", "Country picker operates by touch selection")
	# Dedicated controls use independent fingers and clear on every lifecycle edge.
	var controls: Control = load("res://scripts/ui/touch_controls.gd").new()
	app.add_child(controls)
	await frames()
	controls.context_available = true
	touch(controls, 4, controls.stick_center + Vector2(45, 0), true)
	touch(controls, 8, controls.action_center, true)
	check(inputs.movement().x > 0.7 and inputs.interact_pressed(), "Move and act simultaneously")
	check(not inputs.interact_pressed(), "Action fires once per press")
	touch(controls, 8, controls.action_center, false)
	check(inputs.movement().x > 0.7, "Releasing action must retain stick")
	controls._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(inputs.movement() == Vector2.ZERO and controls.stick_finger == -1, "Focus loss releases ownership")
	touch(controls, 6, controls.stick_center + Vector2(45, 0), true)
	controls.layout_controls()
	check(inputs.movement() == Vector2.ZERO and controls.stick_finger == -1, "Resize releases touch ownership")
	touch(controls, 6, controls.stick_center + Vector2(45, 0), true)
	paused = true
	controls._process(0.016)
	check(inputs.movement() == Vector2.ZERO, "Opening panels stops walking")
	paused = false
	app.queue_free()
	await frames()
	print("ANDROID CITY: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
