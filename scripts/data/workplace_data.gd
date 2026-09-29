class_name WorkplaceData
extends Resource

@export var id := ""
@export var display_name := ""
@export var company_id := ""
@export var type := "office"
@export var industry_id: String = ""
@export var procedure_ids: Array[String] = []
@export var exterior_building_id := ""
@export_file("*.tscn") var interior_scene := ""
## World-space entrance position (where the player must stand to enter).
@export var entrance_world_position := Vector2.ZERO
@export var roles: Array[JobRoleData] = []
@export var scenarios: Array[ScenarioData] = []
