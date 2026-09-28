extends RefCounted

static func countries() -> Array[CountryData]:
	var result: Array[CountryData] = []
	var rows := [
		["ar", "Argentina", "Barrio del Sol", "Veredas amplias, cafés y plazas arboladas.", "d3b17b", 1810, 120, "Casa", ["ALMACÉN", "CAFÉ", "CLÍNICA", "KIOSCO", "OFICINAS"]],
		["us", "Estados Unidos", "Maple Junction", "Diners, ladrillo y un barrio de casas junto al centro.", "8ca8b5", 1810, 180, "Casa", ["GROCERY", "DINER", "CLINIC", "MARKET", "OFFICES"]],
		["jp", "Japón", "Aoba", "Comercios compactos, callejones y viviendas tranquilas.", "9fb8a5", 1780, 88, "Departamento", ["AOBA MART", "KISSA", "CLINIC", "KONBINI", "OFFICES"]],
		["it", "Italia", "Borgo Luce", "Balcones, pequeñas plazas y cafés mediterráneos.", "d8b58a", 1850, 96, "Departamento", ["ALIMENTARI", "CAFFÈ", "CLINICA", "TRATTORIA", "UFFICI"]],
		["br", "Brasil", "Jardim Aurora", "Comercios abiertos, fachadas cálidas y vegetación tropical.", "dca58f", 1790, 140, "Casa", ["MERCADO", "PADARIA", "CLÍNICA", "CAFÉ", "ESCRITÓRIOS"]],
	]
	for row in rows:
		var country := CountryData.new()
		country.id = row[0]
		country.title = row[1]
		country.description = row[3]
		country.accent = Color(row[4])
		country.home_kind = row[7]
		country.shop_names.assign(row[8])
		if country.id != "ar":
			country.facade = "res://assets/regions/%s.png" % country.id
		if country.id == "br":
			country.greenery = "res://assets/regions/palm.png"
		var city := CityData.new()
		city.id = country.id + "_city"
		city.title = row[2]
		var district := DistrictData.new()
		district.id = country.id + "_centro"
		district.title = city.title
		district.side_street_x = row[5]
		district.side_street_width = row[6]
		district.world_size = Vector2(4800, 3200)
		district.population = 44 if country.id in ["jp", "br"] else 38
		district.building_slots = preload("res://scripts/data/district_blocks.gd").starter_slots(district)
		city.districts.append(district)
		country.cities.append(city)
		result.append(country)
	return result

# Country resources remain a compatibility / asset library only.
static func vida_city() -> CityData:
	var city := CityData.new()
	city.id = "vida"
	city.title = "VIDA"
	for row in [["centro", "Centro / financiero"], ["residencial", "Residencial"], ["comercial", "Comercial"], ["industrial", "Industrial"], ["logistico", "Logístico"], ["salud", "Salud"], ["tecnologico", "Tecnológico"], ["periferia", "Periferia"]]:
		var district := DistrictData.new()
		district.id = row[0]
		district.title = row[1]
		district.available = district.id == "centro"
		district.district_style_weights = {"ar": 30, "it": 20, "jp": 15, "us": 25, "br": 10}
		if district.available:
			district.building_slots = DistrictBlocks.starter_slots(district)
		city.districts.append(district)
	return city
