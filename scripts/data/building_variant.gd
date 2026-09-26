class_name BuildingVariant
extends RefCounted

# A stable seed selects proportions and details; the country supplies materials.
const TYPES := {
	"ar": ["casa", "departamentos", "almacen", "oficina", "taller", "mercado"],
	"jp": ["machiya", "apartamentos", "konbini", "oficina", "casa_compacta", "mixto"],
	"us": ["suburbana", "apartamentos", "diner", "oficina", "motel", "tienda"],
	"it": ["pietra", "palazzo", "caffe", "oficina", "mediterranea", "bottega"],
	"br": ["casa", "apartamentos", "padaria", "oficina", "sobrado", "mercado"],
}

static func make(country: String, kind: String, index: int) -> Dictionary:
	var types: Array = TYPES.get(country, TYPES["ar"])
	var role := 0 if kind in ["home", "house"] else 3 if kind == "office" else 2 if kind == "shop" else 1
	var style: String = types[(role + index * 5) % types.size()]
	var floors := 1 + (index % 3)
	if style in ["apartamentos", "palazzo", "oficina", "mixto"]:
		floors += 1
	return {
		"style": style, "floors": floors, "width": 136 + (index * 19) % 48,
		"height": 111 + floors * 33, "windows": 2 + index % 2,
		"balcony": index % 3 == 0, "shopfront": kind == "shop",
		"roof": (index + country.length()) % 3, "seed": index,
	}
