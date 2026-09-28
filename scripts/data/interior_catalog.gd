class_name InteriorCatalog
extends RefCounted

# Explicit building data selects a layout; node names never select gameplay.
enum Type { HOME, CAFE, BAKERY, ICE_CREAM_SHOP, GROCERY, SUPERMARKET, BOOKSTORE, GRILL, RESTAURANT, GYM, HOSPITAL, CLINIC, PHARMACY, OFFICE, GAS_STATION, WORKSHOP }
const TYPES := {
	"home": Type.HOME, "cafe": Type.CAFE, "bakery": Type.BAKERY,
	"ice_cream_shop": Type.ICE_CREAM_SHOP, "market": Type.GROCERY,
	"shop": Type.GROCERY, "store": Type.GROCERY, "kiosk": Type.GROCERY,
	"konbini": Type.GROCERY, "supermarket": Type.SUPERMARKET,
	"bookshop": Type.BOOKSTORE, "library": Type.BOOKSTORE,
	"grill": Type.GRILL, "parrilla": Type.GRILL, "restaurant": Type.RESTAURANT,
	"diner": Type.RESTAURANT, "pizzeria": Type.RESTAURANT, "trattoria": Type.RESTAURANT,
	"gym": Type.GYM, "hospital": Type.HOSPITAL, "hospital_ward": Type.HOSPITAL,
	"clinic": Type.CLINIC, "pharmacy": Type.PHARMACY, "office": Type.OFFICE,
	"gas_station": Type.GAS_STATION, "workshop": Type.WORKSHOP,
}

static func type_for(kind: String) -> Type:
	return TYPES.get(kind, Type.GROCERY)

static func is_food_service(kind: String) -> bool:
	return type_for(kind) in [Type.CAFE, Type.BAKERY, Type.ICE_CREAM_SHOP, Type.GRILL, Type.RESTAURANT]
