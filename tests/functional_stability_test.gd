extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func base_save(location: String) -> Dictionary:
	return {
		"version": SaveSystem.VERSION,
		"profile": {"country_id": "ar", "city_id": "san_juan", "district_id": "barrio_del_sol", "player_name": "Test"},
		"location": location,
		"position": [200.0, 180.0],
		"return_position": [320.0, 240.0],
		"state": {"rested": true},
		"clock": {"minutes": 1234.0, "played_seconds": 99.0, "speed": 1.0},
		"life": {"money": 137, "energy": 63.0, "wellbeing": 71.0, "reputation": 4, "inventory": {"food": 2}},
	}

func run() -> void:
	var previous_path: String = SaveSystem.save_path
	SaveSystem.save_path = "user://vida_functional_stability_test.json"
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(SaveSystem.save_path + suffix):
			DirAccess.remove_absolute(SaveSystem.save_path + suffix)

	for location in WorldManager.VALID_LOCATIONS:
		var payload := base_save(location)
		check(SaveSystem.valid(payload), "Save validation must accept supported location: " + location)
		check(SaveSystem.write_save(payload), "Save write must succeed for: " + location)
		var loaded := SaveSystem.read_save()
		check(not loaded.is_empty() and loaded.get("location") == location, "Save/load must round-trip location: " + location)
		check(loaded.get("profile", {}).get("district_id") == "barrio_del_sol", "Save/load must preserve district identity")
		check(loaded.get("position") == [200.0, 180.0], "Save/load must preserve player position")
		check(loaded.get("state", {}).get("rested", false), "Save/load must preserve basic life state")
		check(int(loaded.get("life", {}).get("money", 0)) == 137 and int(loaded.get("life", {}).get("inventory", {}).get("food", 0)) == 2, "Save/load must preserve economy and inventory")
		check(is_equal_approx(float(loaded.get("clock", {}).get("minutes", 0.0)), 1234.0), "Save/load must preserve game time")
	check(not SaveSystem.valid(base_save("definitely_not_a_place")), "Unknown locations must remain invalid")

	GameClock.restore({"minutes": 480.0})
	WorldManager.playing = false
	WorldManager.basic_state = {"rested": false}
	LifeSimulation.restore({"money": 80, "energy": 40, "wellbeing": 50, "inventory": {}})
	var money_before := LifeSimulation.money
	var pc_message := LifeSimulation.act("pc")
	check(LifeSimulation.money == money_before, "Domestic PC use must not mint money")
	check(pc_message.contains("computadora"), "PC use must provide feedback")
	var before_rest := GameClock.total_minutes
	var energy_before_rest := LifeSimulation.energy
	var rest_message := LifeSimulation.act("rest")
	check(is_equal_approx(GameClock.total_minutes - before_rest, 30.0), "Sofa rest must be a short activity")
	check(LifeSimulation.energy > energy_before_rest and LifeSimulation.energy < 100.0, "Sofa rest must recover partially")
	check(not rest_message.is_empty(), "Rest must provide feedback")
	var before_sleep := GameClock.total_minutes
	var sleep_message := LifeSimulation.act("sleep")
	check(is_equal_approx(GameClock.total_minutes - before_sleep, 480.0), "Sleep must advance eight hours")
	check(is_equal_approx(LifeSimulation.energy, 100.0) and WorldManager.basic_state.get("rested", false), "Sleep must fully recover and mark rested")
	check(not sleep_message.is_empty(), "Sleep must provide feedback")
	var before_browse := GameClock.total_minutes
	check(not LifeSimulation.act("browse").is_empty(), "Book browsing must have a handled effect and feedback")
	check(is_equal_approx(GameClock.total_minutes - before_browse, 10.0), "Browsing must consume a small amount of game time")

	check(InteriorCatalog.type_for("gym") == InteriorCatalog.Type.GYM, "Gym must keep its own interior type")
	check(InteriorCatalog.type_for("pharmacy") == InteriorCatalog.Type.PHARMACY, "Pharmacy must keep its own interior type")
	check(InteriorCatalog.type_for("clinic") == InteriorCatalog.Type.CLINIC, "Clinic must keep its own interior type instead of silently becoming a hospital")
	check(InteriorCatalog.type_for("supermarket") == InteriorCatalog.Type.SUPERMARKET, "Supermarket must keep its own interior type")
	check(InteriorCatalog.type_for("gas_station") == InteriorCatalog.Type.GAS_STATION, "Gas station must keep its own interior type")

	var signal := CityTrafficSignal.new()
	root.add_child(signal)
	signal.set_process(false)
	signal.cycle_offset = 0.0
	signal.simulation_seconds = 0.0
	signal.refresh_state(true)
	var initial := signal.horizontal_state
	signal._process(CityTrafficSignal.GREEN_SECONDS + 0.2)
	signal.refresh_state(true)
	check(signal.horizontal_state != initial, "Traffic signal phase must advance from simulation delta")
	var frozen := signal.simulation_seconds
	signal.refresh_state(true)
	check(is_equal_approx(signal.simulation_seconds, frozen), "Refreshing a signal must not advance wall-clock time")
	signal.queue_free()

	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(SaveSystem.save_path + suffix):
			DirAccess.remove_absolute(SaveSystem.save_path + suffix)
	SaveSystem.save_path = previous_path
	print("FUNCTIONAL STABILITY: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
