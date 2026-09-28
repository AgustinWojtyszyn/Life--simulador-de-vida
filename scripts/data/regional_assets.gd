class_name RegionalAssets
extends RefCounted

const HOMES := ["modern", "common", "compact", "duplex", "old", "restored", "apartments", "brick", "premium_home"]
const COUNTRY_HOMES := {
	"ar": ["house", "apartments", "modern", "common", "compact", "duplex", "old", "restored", "brick", "premium_home"],
	"br": ["house", "compact", "common", "modern", "duplex", "apartments", "restored", "old"],
	"jp": ["modern", "compact", "machiya", "apartments", "duplex", "common", "mixed_old"],
	"it": ["apartment", "old", "restored", "apartments", "premium_home", "common", "duplex", "brick"],
	"us": ["house", "brick", "duplex", "modern", "premium_home", "apartments", "common", "restored"],
}
const FRONTAGES := {
	"ar": ["cafe", "almacen", "panaderia", "kiosco"],
	"br": ["bakery_corner", "market", "padaria", "cafe"],
	"jp": ["cafe", "market", "konbini", "office"],
	"it": ["trattoria", "market", "pizzeria", "cafe"],
	"us": ["diner", "market", "coffee_shop", "cafe"],
}
const SHOPS := {
	"ar": ["market", "panaderia", "kiosco", "cafe", "bookshop", "workshop", "parrilla"],
	"br": ["padaria", "market", "cafe", "workshop"],
	"jp": ["konbini", "market", "cafe", "workshop"],
	"it": ["pizzeria", "trattoria", "market", "cafe", "workshop"],
	"us": ["coffee_shop", "market", "diner", "workshop"],
}
const TYPES := {
	"almacen": "market", "panaderia": "bakery", "padaria": "bakery", "bakery_corner": "bakery",
	"kiosco": "kiosk", "coffee_shop": "cafe", "apartments": "residential_apartment",
	"mixed_old": "residential_building", "machiya": "residential_house", "house": "residential_house",
	"apartment": "residential_apartment", "parrilla": "restaurant", "trattoria": "restaurant",
}
const LABELS := {
	"ar": {"market": "ALMACÉN", "bakery": "PANADERÍA", "kiosk": "KIOSCO", "cafe": "CAFÉ", "clinic": "CLÍNICA", "office": "OFICINAS", "workshop": "TALLER", "bookshop": "LIBRERÍA", "restaurant": "PARRILLA"},
	"br": {"market": "MERCADO", "bakery": "PADARIA", "cafe": "CAFÉ", "clinic": "CLÍNICA", "office": "ESCRITÓRIOS", "workshop": "OFICINA"},
	"jp": {"market": "AOBA MART", "konbini": "KONBINI", "cafe": "KISSA", "clinic": "CLINIC", "office": "OFFICES", "workshop": "REPAIR"},
	"it": {"market": "ALIMENTARI", "pizzeria": "PIZZERIA", "trattoria": "TRATTORIA", "cafe": "CAFFÈ", "clinic": "CLINICA", "office": "UFFICI", "workshop": "BOTTEGA", "restaurant": "TRATTORIA"},
	"us": {"market": "GROCERY", "cafe": "COFFEE SHOP", "diner": "DINER", "clinic": "CLINIC", "office": "OFFICES", "workshop": "REPAIR SHOP"},
}

static func descriptor(country: String, kind: String, index: int, facing: String = "south") -> Dictionary:
	var mixed := kind == "mixed"
	var residential := kind in ["home", "house"]
	var homes: Array = COUNTRY_HOMES[country]
	var asset: String = homes[posmod(index, homes.size())] if residential else kind
	if kind == "shop":
		var choices: Array = SHOPS[country]
		asset = choices[posmod(index, choices.size())]
	var type: String = TYPES.get(asset, "residential_house" if residential else asset)
	# New named assets (house, machiya, apartment, parrilla, trattoria) live in buildings/
	var new_building_assets := ["house", "machiya", "apartment", "parrilla", "trattoria"]
	var folder := "buildings" if (not residential or asset in new_building_assets) else "houses"
	var path := "res://assets/%s/%s/%s.png" % [folder, country, asset]
	if mixed:
		type = "residential_building"
		path = "res://assets/buildings/ar/mixed_old.png" if country == "ar" else "res://assets/catalog/%s/low_apartments.tres" % country
	# Country atlases are sliced through AtlasTexture resources. Never render an
	# entire regional atlas as one facade and never borrow another country.
	if asset == "bakery_corner":
		path = "res://assets/catalog/%s/bakery.tres" % country
	elif asset == "diner":
		path = "res://assets/catalog/%s/restaurant.tres" % country
	if asset == "mixed_old":
		path = "res://assets/buildings/%s/mixed_old.png" % country
	# Explicit asset selection BEFORE any fallback logic
	if country == "ar" and asset in ["almacen", "market"]:
		path = "res://assets/buildings/ar/almacen_new.png"
	if not ResourceLoader.exists(path):
		var alt_path := "res://assets/buildings/%s/%s.png" % [country, asset]
		if ResourceLoader.exists(alt_path):
			path = alt_path
		else:
			var catalog_family: String = str({
				"clinic": "clinic", "office": "office", "workshop": "workshop",
				"market": "store", "almacen": "store", "konbini": "store", "kiosco": "store",
				"cafe": "cafe", "coffee_shop": "cafe",
				"panaderia": "bakery", "padaria": "bakery",
				"parrilla": "restaurant", "pizzeria": "restaurant", "trattoria": "restaurant",
			}.get(asset, "store"))
			var catalog_path := "res://assets/catalog/%s/%s.tres" % [country, catalog_family]
			if ResourceLoader.exists(catalog_path):
				path = catalog_path
			else:
				push_error("Missing regional facade: %s/%s" % [country, asset])
				path = "res://assets/catalog/%s/store.tres" % country
	var title: String = LABELS[country].get(type, type.to_upper())
	if residential:
		title = {"ar": "VIVIENDA", "br": "MORADIA", "jp": "RESIDENCE", "it": "CASA", "us": "HOME"}[country]
		if type in ["residential_apartment", "residential_building"]: title = "APARTMENTS" if country in ["us", "jp"] else "DEPARTAMENTOS" if country == "ar" else "APPARTAMENTI" if country == "it" else "APARTAMENTOS"
	if mixed:
		title = {"ar": "EDIFICIO MIXTO", "br": "EDIFÍCIO MISTO", "jp": "MIXED BUILDING", "it": "EDIFICIO MISTO", "us": "MIXED USE"}[country]
	var actual_facing := "south"
	var family := ""
	# Countries without a full residential asset library must never silently
	# fall back to Argentine houses. Their authored directional family is used
	# for every residence, which keeps each city regionally coherent.
	# Argentina has a broad authored south-facing residential library; use it
	# instead of replacing every third lot with the same directional house.
	# Directional families are reserved for lots that genuinely face another
	# street direction. Other countries still rely on their coherent oriented
	# family until their full residential libraries grow.
	if residential and (country != "ar" or facing != "south"):
		family = "res://assets/oriented/%s/house" % country
	elif country == "it" and asset == "pizzeria":
		family = "res://assets/oriented/it/pizzeria"
	if family != "":
		var oriented := AssetOrientation.family_path(family, facing)
		if oriented != "":
			path = oriented
			actual_facing = facing
			if residential:
				type = "residential_house"
				title = {"ar": "VIVIENDA", "br": "MORADIA", "jp": "RESIDENCE", "it": "CASA", "us": "HOME"}[country]
	return {"path": path, "type": type, "title": title, "residential": residential, "facing": actual_facing, "requested_facing": facing}

static func facade(country: String, residential: bool, index: int) -> String:
	return descriptor(country, "house" if residential else "shop", index).path
