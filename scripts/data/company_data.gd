class_name CompanyData
extends Resource

@export var id := ""
@export var display_name := ""
@export var description := ""
@export var district_id := "centro"
## Approximate world position of the company building (used for minimap/POI).
@export var map_position := Vector2(2400, 1600)
@export var workplaces: Array[WorkplaceData] = []
