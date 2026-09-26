extends RefCounted

static func countries() -> Array[CountryData]:
	var result: Array[CountryData] = []
	var rows := [
		["ar", "Argentina", "Barrio del Sol", "Veredas amplias, cafés y plazas arboladas.", "d3b17b", 1810, 120, "Casa", ["ALMACÉN", "CAFÉ", "CLÍNICA", "KIOSCO", "OFICINAS"]],
		["us", "Estados Unidos", "Maple Junction", "Diners, ladrillo y un barrio de casas junto al centro.", "8ca8b5", 1810, 180, "Casa", ["GROCERY", "DINER", "CLINIC", "MARKET", "OFFICES"]],
		["jp", "Japón", "Aoba", "Comercios compactos, callejones y viviendas tranquilas.", "9fb8a5", 1780, 88, "Departamento", ["AOBA MART", "KISSA", "CLINIC", "KONBINI", "STATION"]],
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
		district.population = 18 if country.id in ["jp", "br"] else 14
		var east := minf(district.side_street_x + district.side_street_width + 140, 2080)
		district.building_slots = [
			{"position": district.home_position, "kind": "home", "mode": "ENTERABLE"},
			{"position": Vector2(east, 330), "kind": "shop", "mode": "INTERACTABLE"},
			{"position": Vector2(minf(east + 245, 2270), 335), "kind": "office", "mode": "EXTERIOR_ONLY"},
			{"position": Vector2(1560, 780), "kind": "clinic", "mode": "INTERACTABLE"},
			{"position": Vector2(east, 800), "kind": "shop", "mode": "INTERACTABLE"},
			{"position": Vector2(minf(east + 225, 2270), 920), "kind": "house", "mode": "EXTERIOR_ONLY"},
			{"position": Vector2(230, 1460), "kind": "house", "mode": "EXTERIOR_ONLY"},
			{"position": Vector2(560, 1460), "kind": "shop", "mode": "INTERACTABLE"},
			{"position": Vector2(1160, 1460), "kind": "house", "mode": "EXTERIOR_ONLY"},
			{"position": Vector2(1530, 1460), "kind": "office", "mode": "EXTERIOR_ONLY"},
			{"position": Vector2(east, 1460), "kind": "house", "mode": "EXTERIOR_ONLY"},
		]
		if country.id == "jp":
			district.building_slots.append({"position": Vector2(1550, 1040), "kind": "shop", "mode": "INTERACTABLE"})
		city.districts.append(district)
		country.cities.append(city)
		result.append(country)
	return result
