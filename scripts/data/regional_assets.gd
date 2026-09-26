class_name RegionalAssets
extends RefCounted

const COMMERCIAL := ["market", "cafe", "clinic", "office", "workshop", "mixed_old", "premium", "cheap", "bakery", "bookshop", "warehouse", "tower"]
const HOMES := ["modest", "modern", "common", "compact", "duplex", "old", "restored", "apartments", "brick", "premium_home"]

static func facade(country: String, residential: bool, index: int) -> String:
	var names: Array = HOMES if residential else COMMERCIAL
	var folder := "houses" if residential else "buildings"
	var path := "res://assets/%s/%s/%s.png" % [folder, country, names[posmod(index, names.size())]]
	if ResourceLoader.exists(path): return path
	return "res://assets/regions/home.png" if residential else "res://assets/city/buildings/market.png" if country == "ar" else "res://assets/regions/%s.png" % country
