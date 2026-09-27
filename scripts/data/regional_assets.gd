class_name RegionalAssets
extends RefCounted

const HOMES := ["modern", "common", "compact", "duplex", "old", "restored", "apartments", "brick", "premium_home"]
const SHOPS := {
	"ar": ["almacen", "panaderia", "kiosco", "cafe", "bookshop", "workshop"],
	"br": ["padaria", "market", "cafe", "workshop"],
	"jp": ["konbini", "market", "cafe", "workshop"],
	"it": ["pizzeria", "market", "cafe", "workshop"],
	"us": ["coffee_shop", "market", "diner", "workshop"],
}
const TYPES := {"almacen": "market", "panaderia": "bakery", "padaria": "bakery", "kiosco": "kiosk", "coffee_shop": "cafe", "apartments": "residential_apartment", "mixed_old": "residential_building"}
const LABELS := {
	"ar": {"market": "ALMACÉN", "bakery": "PANADERÍA", "kiosk": "KIOSCO", "cafe": "CAFÉ", "clinic": "CLÍNICA", "office": "OFICINAS", "workshop": "TALLER", "bookshop": "LIBRERÍA"},
	"br": {"market": "MERCADO", "bakery": "PADARIA", "cafe": "CAFÉ", "clinic": "CLÍNICA", "office": "ESCRITÓRIOS", "workshop": "OFICINA"},
	"jp": {"market": "AOBA MART", "konbini": "KONBINI", "cafe": "KISSA", "clinic": "CLINIC", "office": "OFFICES", "workshop": "REPAIR"},
	"it": {"market": "ALIMENTARI", "pizzeria": "PIZZERIA", "cafe": "CAFFÈ", "clinic": "CLINICA", "office": "UFFICI", "workshop": "BOTTEGA"},
	"us": {"market": "GROCERY", "cafe": "COFFEE SHOP", "diner": "DINER", "clinic": "CLINIC", "office": "OFFICES", "workshop": "REPAIR SHOP"},
}

static func descriptor(country: String, kind: String, index: int) -> Dictionary:
	var residential := kind in ["home", "house"]
	var asset: String = HOMES[posmod(index, HOMES.size())] if residential else kind
	if kind == "shop":
		var choices: Array = SHOPS[country]
		asset = choices[posmod(index, choices.size())]
	var type: String = TYPES.get(asset, "residential_house" if residential else asset)
	var folder := "houses" if residential else "buildings"
	var path := "res://assets/%s/%s/%s.png" % [folder, country, asset]
	# A regional café/diner is never a fallback for a clinic, office or house.
	if country in ["br", "it"] and asset == "cafe" or country == "us" and asset == "diner":
		path = "res://assets/regions/%s.png" % country
	if not ResourceLoader.exists(path):
		path = "res://assets/%s/ar/%s.png" % [folder, asset]
	var title: String = LABELS[country].get(type, type.to_upper())
	if residential:
		title = {"ar": "VIVIENDA", "br": "MORADIA", "jp": "RESIDENCE", "it": "CASA", "us": "HOME"}[country]
		if type == "residential_apartment": title = "APARTMENTS" if country in ["us", "jp"] else "DEPARTAMENTOS" if country == "ar" else "APPARTAMENTI" if country == "it" else "APARTAMENTOS"
	return {"path": path, "type": type, "title": title, "residential": residential}

static func facade(country: String, residential: bool, index: int) -> String:
	return descriptor(country, "house" if residential else "shop", index).path
