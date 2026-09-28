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
	var saves := root.get_node("SaveSystem")
	var sim := root.get_node("LifeSimulation")
	var mission := root.get_node("MissionSystem")
	saves.save_path = "user://single_city_test.json"
	check(wm.city.id == "vida" and wm.city.districts.size() == 8, "One city, eight registered districts")
	check(not wm.activate_district("industrial") and wm.district.id == "centro", "Unbuilt districts cannot activate")
	for id in ["ar", "jp", "it", "br", "us"]:
		var p := PlayerProfile.new()
		p.player_name = "Legacy " + id
		p.country_id = id
		p.city_id = id + "_city"
		p.district_id = id + "_centro"
		p.home_id = id + "_home"
		var original := {"profile": p.to_dict(), "location": "street", "position": [1500, 360], "state": {"rested": true}, "life": {"money": 432, "energy": 76, "inventory": {"food": 3}}, "mission": {"stage": 3, "choice": "gift"}, "clock": {"minutes": 2300}}
		check(saves.write_save(original), "Write legacy fixture")
		check(wm.continue_game(), "Load legacy origin " + id)
		check(wm.city.id == "vida" and wm.district.id == "centro" and wm.country.id == "ar", "All origins resolve to same city")
		check(wm.profile.home_id == p.home_id and wm.profile.country_id == id, "Preserve origin / home identity")
		check(wm.profile.player_name == p.player_name and wm.basic_state.rested, "Preserve character and state")
		check(sim.money == 432 and sim.inventory.food == 3 and mission.stage == 3 and mission.choice == "gift", "Preserve progress")
		check(wm.spawn_position == Vector2(1500, 360), "Preserve city position")
		original.profile = wm.profile.to_dict()
		original.location = "hospital"
		check(saves.write_save(original) and wm.continue_game(), "Round-trip migrated save and public interior")
	var pools := {}
	for slot in wm.district.building_slots: pools[wm.district.asset_pool_at(slot.position)] = true
	check(pools.size() == 5, "Reuse all five architectural pools")
	for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(saves.save_path + suffix)
	print("SINGLE CITY: ", failures, " failures")
	quit(1 if failures else 0)
