class_name HomeSystem
extends RefCounted

# Stable property identity and entry points. Ownership changes can be added here
# without changing doors, country scenes, profiles or the save schema.
const INTERIOR_SCENE := "res://scenes/home.tscn"
const INTERIOR_SPAWN := Vector2(390, 330)

static func starter_home(country: CountryData) -> Dictionary:
	return {"id": country.id + "_home", "kind": country.home_kind, "tenure": "starter", "interior_scene": INTERIOR_SCENE, "interior_spawn": INTERIOR_SPAWN, "street_spawn": country.cities[0].districts[0].home_position + Vector2(0, 34)}
