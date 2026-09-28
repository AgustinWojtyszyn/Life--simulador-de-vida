class_name CityData
extends Resource

@export var id := ""
@export var title := ""
@export var districts: Array[DistrictData] = []

func find_district(district_id: String) -> DistrictData:
	for item in districts:
		if item.id == district_id:
			return item
	return null
