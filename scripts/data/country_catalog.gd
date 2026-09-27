class_name CountryCatalog
extends RefCounted

# Sixteen genuinely different silhouettes per country. Existing directional
# families remain on side-facing lots; these authored fronts require south lots.
const FAMILIES := ["small_home", "medium_home", "modern_home", "low_apartments", "apartments", "tower", "store", "bakery", "restaurant", "cafe", "supermarket", "workshop", "service", "office", "public", "clinic"]
const HEIGHTS := [112, 140, 155, 175, 220, 290, 110, 130, 140, 125, 130, 140, 120, 215, 145, 135]
const LABELS := {
	"ar": ["CASA", "CASA CON PATIO", "CASA MODERNA", "DEPARTAMENTOS", "RESIDENCIAL", "TORRE", "KIOSCO", "PANADERÍA", "PARRILLA", "CAFÉ", "SUPERMERCADO", "TALLER", "ESTACIÓN DE SERVICIO", "OFICINAS", "ESCUELA", "CENTRO MÉDICO"],
	"jp": ["MACHIYA", "VIVIENDA", "CASA URBANA", "APARTMENTS", "RESIDENCE", "TOWER", "KONBINI", "RAMEN", "YAKITORI", "KISSA", "SUPERMARKET", "REPAIR", "PARKING", "OFFICES", "SCHOOL", "CLINIC"],
	"it": ["CASA", "CASA IN PIETRA", "CASA MODERNA", "APPARTAMENTI", "PALAZZO", "RESIDENZA", "ALIMENTARI", "PANIFICIO", "TRATTORIA", "CAFFÈ", "SUPERMERCATO", "OFFICINA", "BENZINA", "UFFICI", "BIBLIOTECA", "CLINICA"],
	"br": ["CASA", "SOBRADO", "CASA MODERNA", "APARTAMENTOS", "RESIDENCIAL", "TORRE", "MERCEARIA", "PADARIA", "CHURRASCARIA", "CAFÉ", "SUPERMERCADO", "OFICINA", "POSTO", "ESCRITÓRIOS", "ESCOLA", "CENTRO MÉDICO"],
	"us": ["HOME", "SUBURBAN HOME", "MODERN HOME", "TOWNHOUSE", "APARTMENTS", "RESIDENTIAL TOWER", "CORNER STORE", "BAKERY", "DINER", "COFFEE", "SUPERMARKET", "AUTO REPAIR", "GAS STATION", "OFFICES", "LIBRARY", "URGENT CARE"],
}

static func descriptor(country: String, index: int) -> Dictionary:
	var family: String = FAMILIES[index]
	return {"path": "res://assets/catalog/%s/%s.tres" % [country, family],
		"type": "residential_" + family if index < 6 else "parking" if index == 12 and country == "jp" else "station" if index == 12 else "school" if index == 14 and country in ["ar", "jp", "br"] else "library" if index == 14 else family,
		"title": LABELS[country][index], "residential": index < 6,
		"facing": "south", "requested_facing": "south", "family": family,
		"height": HEIGHTS[index]}
