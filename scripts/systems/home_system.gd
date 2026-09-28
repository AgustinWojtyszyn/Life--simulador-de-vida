class_name HomeSystem
extends RefCounted

# Stable property identity and entry points. Ownership changes can be added here
# without changing doors, country scenes, profiles or the save schema.
const INTERIOR_SCENE := "res://scenes/home.tscn"
const INTERIOR_SPAWN := Vector2(390, 350)

static func starter_home(country: CountryData, district: DistrictData = null) -> Dictionary:
	return {"id": country.id + "_home", "kind": country.home_kind, "tenure": "starter", "interior_scene": INTERIOR_SCENE, "interior_spawn": INTERIOR_SPAWN, "street_spawn": (district.home_position if district != null else Vector2(1550, 325)) + Vector2(0, 34)}
