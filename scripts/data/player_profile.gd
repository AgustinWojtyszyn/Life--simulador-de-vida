class_name PlayerProfile
extends Resource

var player_name := "Alex"
var gender := "male"
var skin := 0
var hair := 0
var hair_color := 0
var top := 0
var bottom := 0
var country_id := "ar"
var city_id := "ar_city"
var district_id := "ar_centro"
var home_id := "ar_home"

func to_dict() -> Dictionary:
	var result := {}
	for key in ["player_name", "gender", "skin", "hair", "hair_color", "top", "bottom", "country_id", "city_id", "district_id", "home_id"]:
		result[key] = get(key)
	return result

static func from_dict(data: Dictionary) -> PlayerProfile:
	var p := PlayerProfile.new()
	p.player_name = str(data.get("player_name", "Alex")).strip_edges().left(24)
	if p.player_name.is_empty():
		p.player_name = "Alex"
	p.gender = "female" if data.get("gender") == "female" else "male"
	for key in ["skin", "hair", "hair_color", "top", "bottom"]:
		p.set(key, clampi(int(data.get(key, 0)), 0, 2))
	for key in ["country_id", "city_id", "district_id", "home_id"]:
		p.set(key, str(data.get(key, p.get(key))))
	return p
