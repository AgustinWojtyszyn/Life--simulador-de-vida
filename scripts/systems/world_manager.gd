extends Node

signal travel_requested
var countries: Array[CountryData] = []
var profile := PlayerProfile.new()
var country: CountryData
var district: DistrictData
var location := "home"
var spawn_position := HomeSystem.INTERIOR_SPAWN
var return_position := Vector2.ZERO
var active_world: Node2D
var playing := false
var basic_state := {"rested": false}
var settings := {"touch_controls": false}
const PUBLIC_INTERIORS := ["shop", "cafe", "market", "kiosk", "bakery", "pizzeria", "trattoria", "clinic", "office", "workshop", "bookshop", "diner"]

func _ready() -> void:
	countries = preload("res://scripts/data/world_catalog.gd").countries()
	select_country("ar")

func select_country(id: String) -> void:
	for item in countries:
		if item.id == id:
			country = item
			district = item.cities[0].districts[0]
			profile.country_id = id
			profile.city_id = item.cities[0].id
			profile.district_id = district.id
			profile.home_id = id + "_home"
			return

func new_game(new_profile: PlayerProfile, id: String) -> void:
	SaveSystem.new_slot()
	profile = new_profile
	select_country(id)
	location = "home"
	return_position = Vector2.ZERO
	spawn_position = HomeSystem.INTERIOR_SPAWN
	basic_state = {"rested": false}
	GameClock.restore({})
	WeatherSystem.restore({})
	LifeSimulation.restore({})
	MissionSystem.restore({})
	playing = true
	LifeEvents.profile_created.emit(profile)
	travel_requested.emit()

func continue_game() -> bool:
	var data := SaveSystem.read_save()
	if data.is_empty():
		return false
	profile = PlayerProfile.from_dict(data.profile)
	select_country(profile.country_id)
	location = data.location
	var return_data: Array = data.get("return_position", [])
	return_position = Vector2(float(return_data[0]), float(return_data[1])) if return_data.size() == 2 else Vector2.ZERO
	var limit := Vector2(800, 450) if location != "street" else district.world_size
	spawn_position = Vector2(float(data.position[0]), float(data.position[1])).clamp(Vector2(24, 24), limit - Vector2(24, 24))
	basic_state = data.get("state", {"rested": false}) if data.get("state") is Dictionary else {"rested": false}
	settings = data.get("settings", settings) if data.get("settings", settings) is Dictionary else settings
	GameClock.restore(data.get("clock", {}))
	WeatherSystem.restore(data.get("weather", {}))
	LifeSimulation.restore(data.get("life", {}))
	MissionSystem.restore(data.get("mission", {}))
	playing = true
	travel_requested.emit()
	return true

func travel(destination: String) -> void:
	if destination not in ["home", "street"] + PUBLIC_INTERIORS:
		return
	var previous := location
	location = destination
	var home := HomeSystem.starter_home(country)
	if destination == "home":
		spawn_position = home.interior_spawn
	elif destination in PUBLIC_INTERIORS:
		spawn_position = Vector2(390, 330)
	elif previous in PUBLIC_INTERIORS and return_position != Vector2.ZERO:
		spawn_position = return_position
	else:
		spawn_position = home.street_spawn
	travel_requested.emit()
	LifeEvents.location_changed.emit(country.id, district.id, location)

func save_game() -> bool:
	if not is_instance_valid(active_world):
		return false
	var player: CharacterBody2D = active_world.get_node("Player")
	var pos := player.position
	if player.seated:
		pos = active_world.get_node("Interactions").stand_position
	var result := SaveSystem.write_save({"profile": profile.to_dict(), "location": location, "position": [pos.x, pos.y], "return_position": [return_position.x, return_position.y], "settings": settings, "state": basic_state, "clock": GameClock.to_dict(), "weather": WeatherSystem.to_dict(), "life": LifeSimulation.to_dict(), "mission": MissionSystem.to_dict()})
	if result:
		LifeEvents.game_saved.emit()
	return result

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED and playing:
		save_game()
