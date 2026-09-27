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
	for country in wm.countries:
		wm.country = country
		wm.district = country.cities[0].districts[0]
		var world: Node2D = load("res://scenes/playground.tscn").instantiate()
		root.add_child(world)
		await process_frame
		var facades := {}
		for object in world.city_objects:
			if object.has_meta("building_type"):
				facades[object.facade.resource_path] = true
				check(object.get_child(0).z_index == 0, "Facade must share its ground anchor's Y sort")
				check(object.building_type != "station", "No station without station art")
				if object.building_type.begins_with("residential"):
					check(object.interior_type.is_empty(), "Residential facade must not enter a shop")
				if object.building_type in ["clinic", "office"]:
					check(object.facade.resource_path.get_file() == object.building_type + ".png", "Dedicated service facade")
			if object.has_meta("placement_bounds"):
				var bounds: Rect2 = object.get_meta("placement_bounds")
				for building in world.building_bounds:
					check(not bounds.intersects(building), country.id + ": prop intersects facade")
		for bounds in world.building_bounds:
			for road in world.roads():
				check(not bounds.intersects(road), country.id + ": facade extends into road")
		check(facades.size() >= 10, country.id + ": diverse residential and commercial facades")
		check(get_nodes_in_group("parked_vehicles").size() == 4, "Four valid parking spaces")
		print("REGIONAL STREET: ", country.id, " facades=", facades.size(), " objects=", world.city_objects.size())
		world.queue_free()
		await process_frame
	print("REGIONAL STREETS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
