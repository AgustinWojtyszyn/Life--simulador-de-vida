class_name PoiData
extends RefCounted

# The closing minute is inclusive: 20:00 remains open, 20:01 is closed.
# Door, map and text all read this same schedule object.
const SHOP_HOURS := {"open": 540, "close": 1200}
const FUTURE_TRANSIT_TYPES := ["bus_stop", "station", "transit_hub"]
const PRIORITY := {"home": 100, "hospital": 95, "clinic": 90, "sports": 85, "supermarket": 75, "bakery": 70, "ice_cream_shop": 70, "bookshop": 65, "grill": 65, "restaurant": 65, "gym": 65}
const TYPE_NAMES := {"home": "Tu hogar", "hospital": "Hospital", "clinic": "Centro médico", "sports": "Cancha", "supermarket": "Supermercado", "market": "Almacén", "store": "Tienda", "cafe": "Cafetería", "bakery": "Panadería", "ice_cream_shop": "Heladería", "bookshop": "Librería", "grill": "Parrilla", "restaurant": "Restaurante", "office": "Oficina", "workshop": "Taller", "pharmacy": "Farmacia", "gym": "Gimnasio", "gas_station": "Estación de servicio"}

static func make(id: String, kind: String, title: String, at: Vector2, entrance: Vector2, country: String, city: String, district: String) -> Dictionary:
	return {"id": id, "type": kind, "display_name": title, "position": at,
		"entrance_position": entrance, "opening_hours": {} if kind in ["home", "sports"] or kind.begins_with("residential") else SHOP_HOURS.duplicate(),
		"map_priority": PRIORITY.get(kind, 45), "icon": kind,
		"country": country, "city": city, "district": district}

static func is_open(hours: Dictionary, minutes: float) -> bool:
	if hours.is_empty(): return true
	var minute := posmod(int(floor(minutes)), 1440)
	var start := int(hours.open)
	var end := int(hours.close)
	return minute >= start and minute <= end if start <= end else minute >= start or minute <= end

static func hours_text(hours: Dictionary) -> String:
	if hours.is_empty(): return "Siempre disponible"
	return "%02d:%02d - %02d:%02d" % [int(hours.open) / 60, int(hours.open) % 60, int(hours.close) / 60, int(hours.close) % 60]

static func status_text(hours: Dictionary, minutes: float) -> String:
	return ("ABIERTO" if is_open(hours, minutes) else "CERRADO") + " · " + hours_text(hours)
