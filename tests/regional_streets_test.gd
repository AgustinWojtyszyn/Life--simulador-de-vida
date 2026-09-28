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
		var rendered_facades: Array[Rect2] = []
		for object in world.city_objects:
			if object.has_meta("building_type"):
				facades[object.facade.resource_path] = true
				check(object.get_child(0).z_index == 0, "Facade must share its ground anchor's Y sort")
				check(object.building_type != "station" or object.variant.get("family", "") == "service", "Station requires dedicated station art")
				if object.building_type.begins_with("residential"):
					check(object.interior_type.is_empty(), "Residential facade must not enter a shop")
				if object.building_type in ["clinic", "office"]:
					check(object.facade.resource_path.get_file().get_basename() == object.building_type, "Dedicated service facade")
				var sprite := object.get_child(0) as Sprite2D
				var rendered_size := sprite.region_rect.size * sprite.scale.abs()
				var rendered := Rect2(object.position + sprite.position - rendered_size * 0.5, rendered_size)
				var reserved: Rect2 = object.get_meta("visual_bounds")
				check(rendered.position.distance_to(reserved.position) < 0.05 and rendered.size.distance_to(reserved.size) < 0.05, country.id + ": reserved facade bounds must match final rendered sprite")
				rendered_facades.append(rendered)
			if object.has_meta("placement_bounds"):
				var bounds: Rect2 = object.get_meta("placement_bounds")
				for building in world.building_bounds:
					check(not bounds.intersects(building), country.id + ": prop intersects facade")
		for i in world.building_bounds.size():
			for j in range(i + 1, world.building_bounds.size()):
				check(not world.building_bounds[i].intersects(world.building_bounds[j]), country.id + ": facade overlaps another facade: " + str(i) + "/" + str(j) + " " + str(world.building_bounds[i]) + " " + str(world.building_bounds[j]))
		for i in rendered_facades.size():
			for j in range(i + 1, rendered_facades.size()):
				check(not rendered_facades[i].intersects(rendered_facades[j]), country.id + ": final rendered facades overlap: " + str(i) + "/" + str(j))
		for bounds in world.building_bounds:
			for road in world.roads():
				check(not bounds.intersects(road), country.id + ": facade extends into road")
		var special: String = {"ar": "panaderia", "br": "padaria", "jp": "konbini", "it": "pizzeria", "us": "coffee_shop"}[country.id]
		var landmark_present := facades.has("res://assets/buildings/%s/%s.png" % [country.id, special])
		if country.id == "it":
			landmark_present = facades.keys().any(func(path): return path.contains("/oriented/it/pizzeria/"))
		check(landmark_present, "Regional landmark must be visible: " + special)
		for prop in {"ar": [], "br": ["Moto"], "jp": ["Vending Machine", "Bicycle"], "it": ["Scooter"], "us": []}[country.id]:
			check(world.has_node(NodePath(prop)), "Regional prop must be placed: " + prop)
		if country.id == "ar":
			for asset in ["almacen", "panaderia", "kiosco"]:
				check(facades.has("res://assets/buildings/ar/" + asset + ".png"), "Argentina must integrate " + asset)
			for prop in ["Choripan Stand", "Parrilla"]:
				check(world.has_node(prop), "Argentina street food must be placed: " + prop)
			check(world.has_node("Colectivo") and world.has_node("Colectivo2"), "Argentina must have circulating buses")
			var types := []
			for node in world.get_children():
				if node.has_meta("building_type"): types.append(node.get_meta("building_type"))
			check("sports" in types and "transport_stop" in types, "Argentina needs a pitch and bus stop")
		check(facades.size() >= 10, country.id + ": diverse residential and commercial facades")
		var parked := get_nodes_in_group("parked_vehicles")
		check(parked.size() >= 4, "At least four valid parking spaces")
		print("REGIONAL STREET: ", country.id, " facades=", facades.size(), " objects=", world.city_objects.size())
		world.queue_free()
		await process_frame
	print("REGIONAL STREETS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
