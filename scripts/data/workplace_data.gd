class_name WorkplaceData
extends Resource

@export var id := ""
@export var company_id := ""
@export var type := "office"
@export var exterior_building_id := ""
@export_file("*.tscn") var interior_scene := ""
@export var roles: Array[JobRoleData] = []
