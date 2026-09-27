class_name RegionalAssets
extends RefCounted

const HOMES := ["modern", "common", "compact", "duplex", "old", "restored", "apartments", "brick", "premium_home"]
const COUNTRY_HOMES := {
	"ar": HOMES,
	"br": ["compact", "common", "modern", "duplex", "apartments", "restored", "old"],
	"jp": ["modern", "compact", "mixed_old", "apartments", "duplex", "common"],
	"it": ["old", "restored", "apartments", "premium_home", "common", "duplex", "brick"],
	"us": ["brick", "duplex", "modern", "premium_home", "apartments", "common", "restored"],
}
const FRONTAGES := {
	"ar": ["cafe", "almacen", "panaderia", "kiosco"],
	"br": ["bakery_corner", "market", "padaria", "cafe"],
	"jp": ["cafe", "market", "konbini", "office"],
	"it": ["trattoria", "market", "pizzeria", "cafe"],
	"us": ["diner", "market", "coffee_shop", "cafe"],
}
const SHOPS := {
	"ar": ["almacen", "panaderia", "kiosco", "cafe", "bookshop", "workshop"],
	"br": ["padaria", "market", "cafe", "workshop"],
	"jp": ["konbini", "market", "cafe", "workshop"],
	"it": ["pizzeria", "market", "cafe", "workshop"],
	"us": ["coffee_shop", "market", "diner", "workshop"],
}
const TYPES := {"almacen": "market", "panaderia": "bakery", "padaria": "bakery", "bakery_corner": "bakery", "kiosco": "kiosk", "coffee_shop": "cafe", "apartments": "residential_apartment", "mixed_old": "residential_building"}
const LABELS := {
	"ar": {"market": "ALMACÉN", "bakery": "PANADERÍA", "kiosk": "KIOSCO", "cafe": "CAFÉ", "clinic": "CLÍNICA", "office": "OFICINAS", "workshop": "TALLER", "bookshop": "LIBRERÍA"},
	"br": {"market": "MERCADO", "bakery": "PADARIA", "cafe": "CAFÉ", "clinic": "CLÍNICA", "office": "ESCRITÓRIOS", "workshop": "OFICINA"},
	"jp": {"market": "AOBA MART", "konbini": "KONBINI", "cafe": "KISSA", "clinic": "CLINIC", "office": "OFFICES", "workshop": "REPAIR"},
	"it": {"market": "ALIMENTARI", "pizzeria": "PIZZERIA", "trattoria": "TRATTORIA", "cafe": "CAFFÈ", "clinic": "CLINICA", "office": "UFFICI", "workshop": "BOTTEGA"},
	"us": {"market": "GROCERY", "cafe": "COFFEE SHOP", "diner": "DINER", "clinic": "CLINIC", "office": "OFFICES", "workshop": "REPAIR SHOP"},
}

static func descriptor(country: String, kind: String, index: int, facing: String = "south") -> Dictionary:
	var residential := kind in ["home", "house"]
	var homes: Array = COUNTRY_HOMES[country]
	var asset: String = homes[posmod(index, homes.size())] if residential else kind
	if kind == "shop":
		var choices: Array = SHOPS[country]
		asset = choices[posmod(index, choices.size())]
	var type: String = TYPES.get(asset, "residential_house" if residential else asset)
	var folder := "houses" if residential else "buildings"
	var path := "res://assets/%s/%s/%s.png" % [folder, country, asset]
	# A regional café/diner is never a fallback for a clinic, office or house.
	if asset in ["bakery_corner", "trattoria", "diner"]:
		path = "res://assets/regions/%s.png" % country
	if asset == "mixed_old": path = "res://assets/buildings/%s/mixed_old.png" % country
	if not ResourceLoader.exists(path):
		path = "res://assets/%s/ar/%s.png" % [folder, asset]
	var title: String = LABELS[country].get(type, type.to_upper())
	if residential:
		title = {"ar": "VIVIENDA", "br": "MORADIA", "jp": "RESIDENCE", "it": "CASA", "us": "HOME"}[country]
		if type in ["residential_apartment", "residential_building"]: title = "APARTMENTS" if country in ["us", "jp"] else "DEPARTAMENTOS" if country == "ar" else "APPARTAMENTI" if country == "it" else "APARTAMENTOS"
	var actual_facing := "south"
	var family := ""
	if residential and (facing != "south" or index % 3 == 0):
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
